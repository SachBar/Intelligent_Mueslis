#----------------------------------------------------#
#------------ MuesliMaker simulation ----------------#
#----------------------------------------------------#
# This simulator is inspired by the banking pyknow system used in exercises

""" Defining simulation parameters """
n_MM = 2 # number of mueslimaker devices
n_days = 5 # number of days
orders_per_day = 2 # orders per user per device per day
nIngredients = 13 # number of ingredients for stock in each MM, stock is unique to each MM
num_users = 2 # number of users

""" Defining custom functions """
def getFeedback(chosenIngredients, preferenceDatabase, userID):
    """Generates negative or positive feedback (0 or 1) based on the user and the chosen ingredients
    should only be applied if muesli suggestion is activated"""
    
    # Two or more ingredients not in preferences will result in negative feedback
    userPreference = preferenceDatabase.iloc[userID]
    userPreference = userPreference.to_frame()
    userPreference = userPreference.loc[userPreference[userID] > 0.5]
    userPreference = list(userPreference.index)
    
    nDisgusting = 0
    
    for i in range(0, len(chosenIngredients)):
        if not {chosenIngredients[i]}.issubset(set(userPreference)):
            nDisgusting += 1
            
    if nDisgusting > 1:
        print('Yikes, that was not pleasant!')
        return 0
    else:
        print('Yum, that tasted very good.')
        return 1
    

def print_engine(e):
    print("\nEngine: " + str(e))
    print("    \n\nfacts: " + str(e.facts))
    print("    \n\nrules: " + str(e.get_rules()))
    if len(e.agenda.activations) > 0:
        print("\n\nNumber of Activations: " + str(len(e.agenda.activations)))
        for a in e.agenda.activations:
            print("    \nACTIVATION: " + str([a.__repr__()]))
    else:
        print("    \n\nactivations: " + "NO_ACTIVATIONS")

        
def aprioriExtraction(muesliDF, ingredients):
    try:
        ingredientsDF = muesliDF[ingredients]
        # Format columns to binary values
        threshold = 5  # Where the user is likely to try the ingredient
        print(ingredientsDF.head())
        ingredientRules = ingredientsDF[ingredients] > threshold
        return ingredientRules.astype(int)
    except:
        print('Error: Ingredients are not in database!')
        return

#-------------------------------------------------------------------------#
        
#Importing libraries
from pyknow import *
import random as rd
import numpy as np
import pandas as pd
import time

# Loading database and creating necessary datasets
muesliDF = pd.read_csv('BreakfastDB.csv', skiprows=[0, 1, 2])

ingredient_list = list(muesliDF.columns[6:-1])

ingredientRules = aprioriExtraction(muesliDF, ingredient_list)

users = muesliDF.index  # load list of users from database

stock_list = [[] for i in range(0, n_MM)]

for i in range(0, n_MM):
    stock_list[i] = ['Oats', 'Cornflakes', 'Crunchy'] + rd.sample(ingredient_list[3::], nIngredients - 3) 
    # 10 random ingredients + standard 3 ingredients

users = [{'User_id': str(i), 'negativeCount' : 0} for i in range(num_users)]

stock = [{'MM' : mm, 'Stock' : stock_list[mm]} for mm in range(0, n_MM)]

""" Individual order attributes """
suggestion = [0, 1]  # yes or no if user wants to add suggested ingredients
weekday = [0, 1]  # bool
days = range(1, n_days + 2)  # resolution of days?

""" List of PyKnow specific technicalities """
Stored_data = pd.DataFrame([[0]*muesliDF.shape[1]], [0], muesliDF.columns) # empty storage of new data
feedbackDict = {}

""" List of orders to simulate """
orders = [{'order_id': str(d)+'_'+str(i), 'day': d, 'User': u['User_id'], 'MM_id' : mm,
           'Suggestion': rd.choice(suggestion),
           'Selected_ingredients': rd.sample(ingredient_list, 5),
           'Weekday': 1, 'Rating': rd.uniform(0, 1), 'OrderStatus': 'closed'}
          for d in days for i in range(0, orders_per_day) for u in users for mm in range(0, n_MM)]

#-----------------------------------------------------#

""" Fact base """

class MuesliMakerStock(Fact):
    pass


class User(Fact):
    pass


class Order(Fact):
    pass


class Today(Fact):
    pass

class StoredSelections(Fact):
    pass
    

#-----------------------------------------------------#

""" Rule base"""

class Dayprogress:
    # class for testing continuous operation
    # Rules to manage activation of transactions (flow of time, testing).
    @Rule(Today(MATCH.d),
          AS.O << Order(OrderStatus="closed",
                        day=MATCH.d, MM_id = MATCH.mm),
          salience = 5)  # a rule with priority 5
    def _activateOrder(self, O, d, mm):
        #orderChoice = rd.choice([order_status[1], order_status[-1]])
        orderChoice = 'open'
        self.modify(O, OrderStatus=orderChoice)
        print("Activating Order "+O['order_id'] +
              " for Day nr." + str(d)+" on MM_"+str(mm)+" as: "+ orderChoice)

    @Rule(AS.f << Today(MATCH.d),
          salience=0)  # a rule with priority 0
    # so that it is only activated after all else is completed
    def _next_day(self, d, f):
        self.modify(f, _0 = d + 1)
        print("Now starts Day nr." + str(d + 1))

    @Rule(Fact(final_day=MATCH.d),
          AS.f << Today(MATCH.d),
          salience=10)  # a rule with priority 10
    def _last_day(self, d, f):
        self.retract(f)
        print("Today is Day nr."+str(d)+", the end of days!")


class StockCheck:
    @Rule(AS.O << Order(order_id = MATCH.ID, OrderStatus = 'stored', Selected_ingredients=MATCH.ingredients,
                        User = MATCH.user, MM_id = MATCH.mm),
          AS.MM << MuesliMakerStock(MM = MATCH.mm, Stock = MATCH.stock),
          TEST(lambda ingredients, stock:  set(ingredients).issubset(set(stock))),
              salience = 5
          )
    def _completeOrder(self, O, ingredients, user, stock):
        print('Order for User', user, 'with selected ingredients:',
              list(ingredients), 'in stock!')
        self.modify(O, OrderStatus = 'checked')

    @Rule(AS.O << Order(order_id = MATCH.ID, OrderStatus = 'stored', Selected_ingredients=MATCH.ingredients,
                        User = MATCH.user, MM_id = MATCH.mm),
          AS.MM << MuesliMakerStock(MM = MATCH.mm, Stock = MATCH.stock),
          TEST(lambda ingredients, stock: not set(
              ingredients).issubset(set(stock))),
              salience = 5)
          
    def _failedOrder(self, O, ingredients, user, stock):
        notAvailableIng = []
        nNotAvailable = 0
        for ing in ingredients:       
            if not {ing}.issubset(set(stock)):
                notAvailableIng.append(ing)
                nNotAvailable += 1 
        print('Order failed: {} not in stock'.format(notAvailableIng))
        # Replace ingredient out of stock with random from stock
        availableIngredients = list(set(ingredients) - set(notAvailableIng))
        addedIng = rd.sample(list(set(stock) - set(availableIngredients)), nNotAvailable)
        newIngredients = availableIngredients
        newIngredients.extend(addedIng)
        self.modify(O, Selected_ingredients = newIngredients)
        print('Suggest {0} in stead of {1} \nFinal order is now: {2}'.format(addedIng, notAvailableIng, newIngredients))

class StoreData():
  @Rule(AS.O << Order(order_id = MATCH.ID, OrderStatus = 'open', Weekday = MATCH.wkday, Suggestion = MATCH.suggestion, 
     Selected_ingredients = MATCH.ingredients, User = MATCH.user),
     TEST ( lambda suggestion: suggestion < 0.5),
   	 salience = 5
    )
  def _storeData(self, O, ingredients, user, wkday):
    global Stored_data
    global muesliDF
    data = Stored_data
    order_data = pd.DataFrame([[0]*data.shape[1]], [data.index[-1] + 1], columns = data.columns)
    order_data[list(ingredients)] = 1
    order_data['User'] = user
    order_data['Age'] = muesliDF.at[int(user), 'Age']
    order_data['Gender'] = muesliDF.at[int(user), 'Gender']
    order_data['Weight (kg)'] = muesliDF.at[int(user), 'Weight (kg)']
    order_data['Disease'] = muesliDF.at[int(user), 'Disease']
    order_data['Exercise (#days/week)'] = muesliDF.at[int(user), 'Exercise (#days/week)']
    Stored_data = data.append(order_data, sort = False)
    print('Data stored to database of User {0}!'.format(user))
    self.modify(O, OrderStatus = 'stored') 
    
  @Rule(AS.O << Order(order_id = MATCH.ID, OrderStatus = 'open', Suggestion = MATCH.suggestion, 
     Selected_ingredients = MATCH.ingredients, User = MATCH.user),
     TEST ( lambda suggestion: suggestion > 0.5),
   	 salience = 5
    )
  def _skipStore(self, O, user):
        print('Suggestion activated, no data stored for user {0}'.format(user))
        self.modify(O, OrderStatus = 'stored')
    
class MMactions():
    @Rule(AS.O << Order(order_id = MATCH.ID, OrderStatus = 'checked',  
     Selected_ingredients = MATCH.ingredients, User = MATCH.user), 
    salience = 5)
    
    def _pour(self, O, user, ingredients):
        for i in ingredients:
            time.sleep(.2)
            print('Pouring {}'.format(i))
            
        self.modify(O, OrderStatus = 'poured')
        
    @Rule(AS.O << Order(OrderStatus = 'poured', order_id = MATCH.ID, 
                        Selected_ingredients = MATCH.ingredients,
                        User = MATCH.user,  Suggestion = MATCH.suggestion),
         AS.U << User(User_id = MATCH.user, negativeCount = MATCH.count),
         TEST ( lambda suggestion: suggestion > 0.5),
         salience = 5)
    
    def _collectFeedback(self, O, user, ID, ingredients, U, count):
        global feedbackDict
        global ingredientRules
                
        fb = getFeedback(ingredients, ingredientRules, int(user))
        
        if not fb == 1:
            global users
            users[int(user)]['negativeCount'] = count + 1
            self.modify(U, negativeCount = count + 1)
            #print('One more negative review, that makes it {0}!'.format(count + 1))

        feedbackDict.update({ID : fb})
        self.modify(O, OrderStatus = 'FBcollected')
        
    @Rule(Today(MATCH.d),
        AS.O << Order(OrderStatus = 'FBcollected',
                    day = MATCH.d,
                    order_id = MATCH.ID,
                    Selected_ingredients = MATCH.ingredients,
                    User = MATCH.user, Suggestion = MATCH.suggestion),
        AS.U << User(User_id = MATCH.user, negativeCount = MATCH.count),
        TEST ( lambda count : count < 3),
        salience = 5)
        
    def _noAlert(self, O, ID, count):
        print('No biggie :), only {} negative reviews'.format(count))
        self.modify(O, OrderStatus = 'alertCheked')

    @Rule(Today(MATCH.d),
            AS.O << Order(OrderStatus = 'FBcollected',
                        day = MATCH.d,
                        order_id = MATCH.ID,
                        Selected_ingredients = MATCH.ingredients,
                        User = MATCH.user, Suggestion = MATCH.suggestion),
            AS.U << User(User_id = MATCH.user, negativeCount = MATCH.count),
            TEST ( lambda count : count > 2),
            salience = 5)
    
    def _negativeFBalert(self, O, user, count, ID):
        print('ALERT!')
        print('User {0} has now left negative feedback {1} times :('.format(user, count))
        
        self.modify(O, OrderStatus = 'alertChecked')
        
#-----------------------------------------------------#

""" Pyknow engine """

class MuesliMaker(Dayprogress, StockCheck, StoreData, MMactions, KnowledgeEngine):

    @DefFacts()
    def first(self):
        for shtock in stock: yield MuesliMakerStock(**shtock)
        for order in orders:
            yield Order(**order)
        for user in users:
            yield User(**user)
        yield Fact(final_day=days[-1])


e = MuesliMaker()

e.reset()
e.declare(Today(0))
#print_engine(e)
#e.run(2)  # Stepwise
e.run()
