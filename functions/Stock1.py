# -*- coding: utf-8 -*-
"""
Created on Sun Dec  2 10:32:24 2018

@author: Steffen-PC
"""

# -*- coding: utf-8 -*-
"""
Created on Thu Nov 22 14:36:15 2018

@author: Steffen-PC

1. Run simulation and figure out the best containersizes (Which gets depleted the quickes0/slowest)
2. Run simulation and figure out when we should fill up stock.
"""
import random as rd
import numpy as np
import pandas as pd

#Initializing values, atm just for testing. 
#Need a ingredientstock, taken from list.

#dailyAverage={} #Uncomment after first run
IngredientSize = { "Small" : 5,              #Ingredientsizes
                  "Medium" : 10,
                  "Large" : 15,
                  "X-Large" : 25,}

#MONTHLY REFILL
categories = {'cereals':['Oats', 'Cornflakes', 'Crunchy'], #15KG
              'nuts':['Peanuts', 'Almonds', 'Walnuts', 'Macadamia', 'Pecan nuts', 'Cashews'], #6.5KG
              'seeds':['Chia seeds', 'Sunflower seeds', 'Pumpkin seeds'], #5KG
              'toppings':['Raisins' ,'Coconut flakes', 'Cocoa beans', 'Dry fruit'], #5.5KG
              'powders':['Protein powder', 'Cacao'], #2.5KG
              'spices':['Cinnamon', 'Vanilla']} #2.5KG

STOCK_VAL_CEREAL = 15000
STOCK_VAL = 15000
STOCK_VAL_POWDERS = 15000
STOCK_VAL_NUTS=15000
Ingredients ={'Oats' : STOCK_VAL_CEREAL,				#Dictionary for stock ingredients.
              'Cornflakes': STOCK_VAL_CEREAL,
              'Crunchy': STOCK_VAL_CEREAL,
              'Peanuts' : STOCK_VAL_NUTS,
              'Almonds' : STOCK_VAL_NUTS,
              'Walnuts' : STOCK_VAL_NUTS,
              'Macadamia' : STOCK_VAL_NUTS,
              'Pecan nuts' : STOCK_VAL_NUTS,
              'Cashews' : STOCK_VAL_NUTS,
              'Chia seeds' : STOCK_VAL_NUTS,
              'Sunflower seeds' : STOCK_VAL_NUTS,
              'Pumpkin seeds' : STOCK_VAL_NUTS,
              'Raisins' : STOCK_VAL_NUTS,
              'Coconut flakes' : STOCK_VAL_NUTS,
              'Cocoa beans' : STOCK_VAL_NUTS,
              'Protein powder' : STOCK_VAL_POWDERS,
              'Cacao' : STOCK_VAL_POWDERS,
              'Cinnamon' : STOCK_VAL_POWDERS,
              'Vanilla' : STOCK_VAL_POWDERS,
              'Dry fruit' : STOCK_VAL_NUTS}
dailyConsumption ={'Oats' : STOCK_VAL_CEREAL,				#Dictionary for stock ingredients.
              'Cornflakes': STOCK_VAL_CEREAL,
              'Crunchy': STOCK_VAL_CEREAL,
              'Peanuts' : STOCK_VAL_NUTS,
              'Almonds' : STOCK_VAL_NUTS,
              'Walnuts' : STOCK_VAL_NUTS,
              'Macadamia' : STOCK_VAL_NUTS,
              'Pecan nuts' : STOCK_VAL_NUTS,
              'Cashews' : STOCK_VAL_NUTS,
              'Chia seeds' : STOCK_VAL_NUTS,
              'Sunflower seeds' : STOCK_VAL_NUTS,
              'Pumpkin seeds' : STOCK_VAL_NUTS,
              'Raisins' : STOCK_VAL_NUTS,
              'Coconut flakes' : STOCK_VAL_NUTS,
              'Cocoa beans' : STOCK_VAL_NUTS,
              'Protein powder' : STOCK_VAL_POWDERS,
              'Cacao' : STOCK_VAL_POWDERS,
              'Cinnamon' : STOCK_VAL_POWDERS,
              'Vanilla' : STOCK_VAL_POWDERS,
              'Dry fruit' : STOCK_VAL_NUTS}
def dailyCon():
    dailyConsumption.update({'Oats' : STOCK_VAL_CEREAL,				#Dictionary for stock ingredients.
              'Cornflakes': STOCK_VAL_CEREAL,
              'Crunchy': STOCK_VAL_CEREAL,
              'Peanuts' : STOCK_VAL_NUTS,
              'Almonds' : STOCK_VAL_NUTS,
              'Walnuts' : STOCK_VAL_NUTS,
              'Macadamia' : STOCK_VAL_NUTS,
              'Pecan nuts' : STOCK_VAL_NUTS,
              'Cashews' : STOCK_VAL_NUTS,
              'Chia seeds' : STOCK_VAL_NUTS,
              'Sunflower seeds' : STOCK_VAL_NUTS,
              'Pumpkin seeds' : STOCK_VAL_NUTS,
              'Raisins' : STOCK_VAL_NUTS,
              'Coconut flakes' : STOCK_VAL_NUTS,
              'Cocoa beans' : STOCK_VAL_NUTS,
              'Protein powder' : STOCK_VAL_POWDERS,
              'Cacao' : STOCK_VAL_POWDERS,
              'Cinnamon' : STOCK_VAL_POWDERS,
              'Vanilla' : STOCK_VAL_POWDERS,
              'Dry fruit' : STOCK_VAL_NUTS})
def warning(): #This needs to be changed to match the different containersizes
    for keys,values in dailyAverage.items():
        if dailyConsumption[keys] > dailyAverage[keys]+50:
            print("WARNING: USAGE TODAY IS HIGHER THAN USUAL FOR {}".format(keys))
            print("Today: {}, Average: {}".format(dailyConsumption[keys],dailyAverage[keys]))
        if Ingredients[keys] < STOCK_VAL*0.2:
            print("WARNING: Storage in {} below 20%.".format(keys))

n_cust=100
customers = ["MR"+str(xid) for xid in range(1,n_cust)]       #Customers MRn to n

n_days = 32
days = range(0,n_days)      #Used for simulation later on, run for n_days
mixmeal = rd.randint(2,6)   #Random number of combos
transperday = [rd.randint(60,80) for _ in days] #Random number of transactions (0-5)

#Filehandling stuff
f_orders=open("Orders.txt", "w+") #Creating file
f_stock=open("StockPlot.csv", "w+")
f_stockcal=open("StockCalc.csv", "a+")
    
#Writing headers
f_orders.write("Day,customer,order,size")
f_stock.write("Day,Oats,Cornflakes,Crunchy,Peanuts,Almonds,Walnuts,Macadamia,Pecan nuts,Cashews,Chia seeds,Sunflower seeds,"
              "Pumpkin seeds,Raisins,Coconut flakes,Cocoa beans,Protein powder,Cacao,Cinnamon,Vanilla,Dry fruit")	#Creating header

tot_trans=0
IngTest=[]
cereals = ['Oats','Cornflakes','Crunchy']
for x in range(1,n_days):
    transthatday = transperday[x]
    mealsperday = []
    sizeperday = []
    print("Day {0} had {1} transactions.".format(x, transthatday))
    tot_trans+=transthatday
    dailyCon()
    if (transthatday >= 1):     #If transactions are more than 0
        for i in range(0,transthatday): #Go through each transaction
            sizedummy = []
            mealrd = np.random.choice(list(Ingredients), mixmeal, replace=False) #Choosing random ingredient from list
            if not any(elem in cereals for elem in mealrd): #Adds cereal to the order
                dummyrd = np.random.choice(cereals)
                mealrd = mealrd.tolist()
                mealrd.append(dummyrd)
            for ing_in_meal in mealrd:              #Percentchances for sizes, for realism
                if(ing_in_meal in categories['cereals']):
                    sizerd = np.random.choice(list(IngredientSize),p=[0, 0.25, 0.45, 0.3])
                    sizedummy.append(sizerd)
                elif(ing_in_meal in categories['nuts']):
                    sizerd = np.random.choice(list(IngredientSize),p=[0.1, 0.40, 0.40, 0.1])
                    sizedummy.append(sizerd)
                elif(ing_in_meal in categories['seeds']):
                    sizerd = np.random.choice(list(IngredientSize),p=[0.3, 0.45, 0.25, 0.0])
                    sizedummy.append(sizerd)
                elif(ing_in_meal in categories['spices']):
                    sizerd = np.random.choice(list(IngredientSize),p=[1, 0.0, 0.0, 0.0])
                    sizedummy.append(sizerd)
                elif(ing_in_meal in categories['powders']):
                    sizerd = np.random.choice(list(IngredientSize),p=[1, 0.0, 0.0, 0.0])
                    sizedummy.append(sizerd)
                elif(ing_in_meal in categories['toppings']):
                    sizerd = np.random.choice(list(IngredientSize),p=[0.25, 0.40, 0.30, 0.05])
                    sizedummy.append(sizerd)
            for z in range(0,len(mealrd)): #Updating the values in Ingredients for each transaction
                Ingredients[mealrd[z]] -= IngredientSize[sizedummy[z]]
                dailyConsumption[mealrd[z]] -= IngredientSize[sizedummy[z]]
            mealsperday.append(mealrd)
            sizeperday.append(sizedummy)
        print("Transactions on day {0} were:".format(x))
        for k,v in dailyConsumption.items():
            dailyConsumption[k] = STOCK_VAL - dailyConsumption[k]
        warning()
        for a in range(0,len(mealsperday)): #For printing each unique transaction
            #print("{0} ordered {1} with sizes {2} on day {3}.".format(customers[a], 
            #      mealsperday[a], sizeperday[a], x))
            f_orders.write("\n{0},{1},{2},{3}".format(x,customers[a],
                           mealsperday[a], sizeperday[a], x))
        #Write to file the stock values for each day
        f_stock.write("\n{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14},{15},{16},{17},{18},{19},{20}".format(x-1,
                    Ingredients['Oats']/STOCK_VAL_CEREAL*100,Ingredients['Cornflakes']/STOCK_VAL_CEREAL*100,Ingredients['Crunchy']/STOCK_VAL_CEREAL*100,
                    Ingredients['Peanuts']/STOCK_VAL_NUTS*100,Ingredients['Almonds']/STOCK_VAL_NUTS*100,Ingredients['Walnuts']/STOCK_VAL_NUTS*100,
                    Ingredients['Macadamia']/STOCK_VAL_NUTS*100,Ingredients['Pecan nuts']/STOCK_VAL_NUTS*100,Ingredients['Cashews']/STOCK_VAL_NUTS*100,
                    Ingredients['Chia seeds']/STOCK_VAL_NUTS*100,Ingredients['Sunflower seeds']/STOCK_VAL_NUTS*100,Ingredients['Pumpkin seeds']/STOCK_VAL_NUTS*100,
                    Ingredients['Raisins']/STOCK_VAL_NUTS*100,Ingredients['Coconut flakes']/STOCK_VAL_NUTS*100,Ingredients['Cocoa beans']/STOCK_VAL_NUTS*100,
                    Ingredients['Dry fruit']/STOCK_VAL_NUTS*100,Ingredients['Protein powder']/STOCK_VAL_POWDERS*100,Ingredients['Cacao']/STOCK_VAL_POWDERS*100,
                    Ingredients['Cinnamon']/STOCK_VAL_POWDERS*100,Ingredients['Vanilla']/STOCK_VAL_POWDERS*100))
        #warning()
print("----------------------")
print("----------------------")
print("----------------------")
print("Total transactions: {0}".format(tot_trans))
print("Levels of stock: {0}".format(Ingredients))  #Printing the stockvalues after n-days

#for key,val in Ingredients.items():
#    f_stockcal.write("{0},".format(val))
#for key in Ingredients.keys():
   # f_stockcal.write(",{0}".format(Ingredients[key]))
#f_stockcal.write("\n")
#Closing files
f_orders.close()
f_stock.close()
#f_stockcal.close()

df = pd.read_csv('StockPlot.csv')
df.set_index('Day', inplace=True)

ax = df.plot(figsize=(3,3),color = ['#C00000','#C00000','#C00000','#D69D9A','#D69D9A','#D69D9A','#D69D9A','#D69D9A','#D69D9A',
             '#D69D9A','#D69D9A','#D69D9A','#D69D9A', '#D69D9A','#D69D9A','#D69D9A','#878787','#878787','#878787','#878787'],legend=False, fontsize=22)
ax.set_ylabel("Container levels (%)", Fontsize=30)
ax.set_xlabel('Day',Fontsize=30)
ax.set_title('Stock simulation', Fontsize=38)
ax.xaxis.grid(True)
ax.legend(['Cereals', 'Nuts and toppings', 'Powders'], loc='lower left', fontsize=18)
leg = ax.get_legend()
leg.legendHandles[0].set_color('#C00000')
leg.legendHandles[1].set_color('#D69D9A')
leg.legendHandles[2].set_color('#878787')
fig = ax.get_figure()
fig.savefig("MuesliPlot.eps")

