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
from sklearn.mixture import GaussianMixture as GMM
from collections import defaultdict
import random as rd


class DataExtractor:
    def __init__(self, ingredientList):
        self.DB = None
        self.ingredientList = ingredientList
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
        principlecomponents = DataPreprocess.doPCA(Xnew)
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
        return customerProfiles.iloc[standardMuesliGroup], standardMuesliGroup

    def generateMuesliCombos(self, customerProfilesDF):
        standardMuesliDFs = customerProfilesDF[ingredients] > 4
        muesliCombos = []
        for i in range (len(standardMuesliDFs.index)):
            muesliCombos.append((standardMuesliDFs.columns[(standardMuesliDFs == True).iloc[i]]).tolist())
        self.standardMeal = muesliCombos
        return muesliCombos
        
    def generateCustomCombos(self, muesliCombos):
        numIng = len(muesliCombos) 
        cerealList = ['Oats', 'Crunchy', 'Cornflakes']
        meal1 = rd.sample(muesliCombos, int(numIng/4))
        meal2 = rd.sample(muesliCombos, int(numIng/2))
        meal3 = rd.sample(muesliCombos, int(numIng))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal1:
            meal1.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal2:
            meal2.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal3:
            meal3.append(rd.choice(cerealList))
        return set(meal1), set(meal2), set(meal3)   
        

########################################################################################
ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',	
               'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds', 
               'Pumpkin seeds',	'Raisins' ,'Coconut flakes',	
               'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon', 
               'Vanilla', 'Dry fruit', 'Dry berries']
skiprows = [0,1,2]
########################################################################################

################## Extracting the Database ####################

DataExtract = DataExtractor(ingredients)
DataExtract.loaddata('BreakfastDB.csv', rows=skiprows)
extractedData = DataExtract.dropColumns(columns='Weekday')
    
###############################################################


################## Preprocessing the Database ####################

DataPreprocess = DataPreprocess(extractedData)
Xkcoded = DataPreprocess.oneoutofK('Disease')
Xstandardized, Xmean, Xvar = DataPreprocess.standardize(Xkcoded)    
PCAs = DataPreprocess.doPCA(Xstandardized)

###############################################################


################## Apriori Extraction ###########################

Apriori = aprioriExtraction(extractedData, ingredients)
binthreshold = 7
AprioriDF = Apriori.getAprioriDF(binthreshold)
ingredientRules = Apriori.aprioriFormat(AprioriDF)

#################################################################


################## Clustering ###########################

standardMeals = standardMeals(Xstandardized, ingredients)
nProfile=5
customerProfiles = standardMeals.clusterProfiles(nProfile)
standardMeals.visualizeClustering()


#################################################################


################# Predict New Meals from Clusters ################
keys = Xkcoded.columns
vals = customerProfiles
vals = DataPreprocess.unstandardize(vals, Xmean, Xvar)
customerProfiles = pd.DataFrame.from_dict(dict(zip(keys, vals.T)))
customerInput = customerProfiles.iloc[2]
muesliCluster, muesliGroup = standardMeals.predictMuesliCluster(customerProfiles, customerInput)
muesliCombos = standardMeals.generateMuesliCombos(customerProfiles)
meal1, meal2, meal3 = standardMeals.generateCustomCombos(muesliCombos[muesliGroup])

print('Meal 1: ' , meal1)
print('Meal 2: ' , meal2)
print('Meal 3: ' , meal3)
#####################################################################





