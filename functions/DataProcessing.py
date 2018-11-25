# -*- coding: utf-8 -*-
"""
Created on Mon Nov 12 19:57:54 2018

@author: Alessandro
"""

import pandas as pd
import numpy as np
import os
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
import random as rd
import csv


class DataExtractor:
    def __init__(self):
        self.DB = None
        print("Database Extraction")

    # Loading data as a pandas dataframe
    def loaddata(self, filename, rows=[], path="C:\DTU Masters\Semester 3\Intelligent Systems\Project"):
        os.chdir(path)  # Change path to where data is found
        self.DB = pd.read_csv(filename, skiprows=rows)
        return self.DB

    def dropColumns(self, columns):
        self.DB.drop(columns=columns, inplace=True)
        return self.DB

    def insertDataFrame(self, DF):
        self.DB = DF
        return self.DB


class DataPreprocess:
    def __init__(self, X):
        self.X = X
        print("Data Preprocessing")

    def standardize(self, X):
        scaler = StandardScaler()
        Xstandardized = scaler.fit_transform(X)
        return Xstandardized, scaler.mean_, scaler.var_

    def unstandardize(self, Xstand, mean, var):
        Xunstand = Xstand[:, ]*np.sqrt(var) + mean
        return Xunstand

    def oneoutofK(self, cols):
        Xk = pd.get_dummies(self.X, cols)
        return Xk

    def doPCA(self, X, n_comp=2):
        pca = PCA(n_components=n_comp)
        return pca.fit_transform(X)


class aprioriExtraction:
    def __init__(self, X, ingredientList):
        self.X = X
        self.ingList = ingredientList
        self.aprioriRules = None
        print("Extracting DF into Apriori format")

    # Extract a subset of the database to be used for the apriori algorithm
    def getAprioriDF(self, binthresh=5):
        try:
            ingredientsDF = self.X[self.ingList]
            # Format columns to binary values
            threshold = binthresh  # Where the user is likely to try the ingredient
            aprioriDF = ingredientsDF[self.ingList] > threshold
            return aprioriDF
        except:
            print('Error: Ingredients are not in database!')
            return

    def aprioriFormat(self, aprioriDF):
        self.aprioriRules = [list(np.array(aprioriDF.columns)[ingredient])
                                  for ingredient in aprioriDF.values]
        return self.aprioriRules


class standardMeals:
    def __init__(self, X, ingredients):
        print("Generate Clusters and predict User group!")
        self.X = X
        self.ingredients = ingredients
        self.customerProfiles = None
        self.customerProfilesDF = None
        self.standardMeal = None
        self.clusterLabels = None

    def clusterProfiles(self, numClusters):
        kmeans = KMeans(n_clusters=numClusters, n_init=1000).fit(self.X)
        self.customerProfiles = kmeans.cluster_centers_
        self.clusterLabels = kmeans.labels_
        return self.customerProfiles

    def visualizeClustering(self):
        # Size of X
        N, M = self.X.shape
        # Append centres to 'X' and project data on PCA
        Xnew = np.concatenate((self.X, self.customerProfiles))
        dataPre = DataPreprocess(Xnew)
        principlecomponents = dataPre.doPCA(Xnew)
        PCA1 = principlecomponents[:, 0]
        PCA2 = principlecomponents[:, 1]
        # Plotting the projected data with the cluster centres
        fig, ax = plt.subplots(figsize=(15, 15))
        ax.scatter(PCA1[N:], PCA2[N:], marker='*',
                   cmap='rainbow', s=1000, label='Cluster centers')
        ax.scatter(PCA1[:N], PCA2[:N], c=self.clusterLabels, cmap='rainbow')
        plt.title('K means Clustering', fontsize=20)
        plt.xlabel('PC1', fontsize=20)
        plt.ylabel('PC2', fontsize=20)
        plt.axhline(linewidth=0.2, color='k'), plt.axvline(
            linewidth=0.2, color='k')
        plt.legend()

    def predictMuesliCluster(self, customerProfilesDF, customerInput):
        distance = []
        for i in range(len(customerProfilesDF[:])):
            distance.append(np.linalg.norm(customerProfilesDF.iloc[i]-customerInput))
        standardMuesliGroup = np.argmin(distance)
        print('You belong to group: ', standardMuesliGroup)
        return customerProfilesDF.iloc[standardMuesliGroup], standardMuesliGroup

    def generateMuesliCombos(self, customerProfilesDF):
        standardMuesliDFs = customerProfilesDF[self.ingredients] > 3
        muesliCombos = []
        for i in range (len(standardMuesliDFs.index)):
            muesliCombos.append((standardMuesliDFs.columns[(standardMuesliDFs == True).iloc[i]]).tolist())
        self.standardMeal = muesliCombos
        return muesliCombos
        
    def generateCustomCombos(self, muesliCombos):
        numIng = len(muesliCombos) 
        cerealList = ['Oats', 'Crunchy', 'Cornflakes']
        meal1 = rd.sample(muesliCombos, int(numIng/2))
        meal2 = rd.sample(muesliCombos, int(numIng/2))
        meal3 = rd.sample(muesliCombos, int(numIng/2))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal1:
            meal1.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal2:
            meal2.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal3:
            meal3.append(rd.choice(cerealList))
        # Remove empty items
        meal1 = [x for x in meal1 if x.strip()]
        meal2 = [x for x in meal2 if x.strip()]
        meal3 = [x for x in meal3 if x.strip()]
        return set(meal1), set(meal2), set(meal3)   





def sendRecommendation(meal1, meal2 , meal3):
    mealRec = [list(meal1), list(meal2), list(meal3)]
    print(mealRec)
    return mealRec        




########################################################################################
    # This information needs to be stored in the server somewhat
skiprows = [0,1,2]
colsDrop = 'Weekday'
########################################################################################


""" Local Server Functions """

################## Extracting the Database ####################

# Call this just once to get from Google Sheets format to a 'clean' database

def getDatabase(fileName, skiprows=[], colsDrop=[]):
    DataExtract = DataExtractor()
    extractedData = DataExtract.loaddata('BreakfastDB.csv', rows=skiprows)
    extractedData = DataExtract.dropColumns(columns=colsDrop)
    extractedData.to_csv(fileName, header=extractedData.columns, index=False)


getDatabase('cleanDatabase.csv', skiprows, colsDrop)    


# Call this whenever you want to get rules from a database and save them in another DB
# I also return them in a variable: ingredientRules

def aprioriRules(binthreshold=7):
    ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',	
               'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds', 
               'Pumpkin seeds',	'Raisins' ,'Coconut flakes',	
               'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon', 
               'Vanilla', 'Dry fruit']
    DataExtract = DataExtractor()
    breakfastDF = DataExtract.loaddata('cleanDatabase.csv')
    Apriori = aprioriExtraction(breakfastDF, ingredients)
    AprioriDF = Apriori.getAprioriDF(binthreshold)
    ingredientRules = Apriori.aprioriFormat(AprioriDF)
    ingredientRulesDF = pd.DataFrame(ingredientRules)
    ingredientRulesDF.to_csv('aprioriIngredients.csv', index=False, header=False)
    return ingredientRules

ingredientRules = aprioriRules()



def performClustering(cleanBreakfastDB, nProfiles=5):
    ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',	
           'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds', 
           'Pumpkin seeds',	'Raisins' ,'Coconut flakes',	
           'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon', 
           'Vanilla', 'Dry fruit']
    DataExtract = DataExtractor()
    X = DataExtract.loaddata(cleanBreakfastDB)
    DataPrep = DataPreprocess(X)
    Xkcoded = DataPrep.oneoutofK('Disease')
    Xstandardized, Xmean, Xvar = DataPrep.standardize(Xkcoded)    
    stdMeals = standardMeals(Xstandardized, ingredients)
    customerProfiles = stdMeals.clusterProfiles(nProfiles)
    keys = Xkcoded.columns
    vals = customerProfiles
    vals = DataPrep.unstandardize(vals, Xmean, Xvar)
    customerProfiles = pd.DataFrame.from_dict(dict(zip(keys, vals.T)))
    customerProfiles.to_csv('clusterCentres.csv', header=customerProfiles.columns, index=False)
    muesliCombos = stdMeals.generateMuesliCombos(customerProfiles)
    mCombos = pd.DataFrame(muesliCombos)
    mCombos.to_csv('muesliClusters.csv', header=None, index=False)
    stdMeals.visualizeClustering()

    
performClustering('cleanDatabase.csv')
# App calls this function whenever we want to recommend a meal (clustering) to a user

""" User Profile must be in the form of a row in 'cleanDatabase.csv """
""" Need a global variable called ingredients in server """
def recommendMeal(userProfile):
    ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',	
       'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds', 
       'Pumpkin seeds',	'Raisins' ,'Coconut flakes',	
       'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon', 
       'Vanilla', 'Dry fruit']
    DataExtract = DataExtractor()
    clusterCentres = DataExtract.loaddata('clusterCentres.csv')
    cleanDB = DataExtract.loaddata('cleanDatabase.csv')
    # Need to one-out-of-k code an observation
    diseasecols = [s for s in list(clusterCentres.columns) if "Disease" in s]
    userProfileDF = pd.DataFrame(userProfile, columns=cleanDB.columns)
    userProfileDisease = str(userProfileDF['Disease'].iloc[0])
    diseaseDict = dict()
    for disease in diseasecols:
        diseaseDict[disease] = [0]
        if userProfileDisease in disease:
            diseaseDict[disease] = [1]
    diseaseDF = pd.DataFrame.from_dict(diseaseDict)
    userProfileDFk = userProfileDF.drop('Disease', axis=1)
    DFs = [userProfileDFk, diseaseDF]
    userProfileDF = pd.concat(DFs, axis=1)
    # User profile is now one-out-of-k coded
    stdMeals = standardMeals(clusterCentres, ingredients)
    muesliCluster, muesliGroup = stdMeals.predictMuesliCluster(clusterCentres, userProfileDF)
    with open('muesliClusters.csv', 'r') as f:
        reader = csv.reader(f)
        muesliClusters = list(reader)

    muesliCombos = stdMeals.generateCustomCombos(muesliClusters[muesliGroup])
    return muesliCombos
    
""" Input from client/app """    
userProfileData =  np.array([1,55,80,None,1,9,1,10,10,10,10,2,6,6,2,3,5,9,8,8,9,1,4,0,8]).reshape(1,25)


""" Output set from server """
muesliCombos=recommendMeal(userProfileData)    
#for meal in muesliCombos:
#    print(meal)


    




