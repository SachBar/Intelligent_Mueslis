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
from sklearn.mixture import GaussianMixture
from sklearn import model_selection
import random as rd
import csv


""" Some classes which are useful for extracting/preprocessing data & doing clustering """

class DataExtractor:
    def __init__(self):
        self.DB = None

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
        self.X = X
        self.ingredients = ingredients
        self.customerProfiles = None
        self.customerProfilesDF = None
        self.standardMeal = None
        self.clusterLabels = None
    
    # This will be useful if we use GMMs
    def determiningK(self):
        # Range of K's to try # This method is useful for GMMs!
        KRange = range(1,12)
        T = len(KRange)        
        covar_type = 'diag'
        reps = 10              # number of fits with different initalizations, best result will be kept        
        # Allocate variables
        CVE = np.zeros((T,))
        CVEtrain = np.zeros((T,))            
        # K-fold crossvalidation
        CV = model_selection.KFold(n_splits=10, random_state=None, shuffle=True)        
        for t,K in enumerate(KRange):
                print('Fitting model for K={0}'.format(K))
                # Fit Gaussian mixture model
                gmm = GaussianMixture(n_components=K, covariance_type=covar_type, n_init=reps).fit(self.X)
                # For each crossvalidation fold
                for train_index, test_index in CV.split(self.X):       
                    # extract training and test set for current CV fold
                    X_train = self.X[train_index]
                    X_test = self.X[test_index]  
                    # Fit Gaussian mixture model to X_train
                    gmm = GaussianMixture(n_components=K, covariance_type=covar_type, n_init=reps).fit(X_train)
                    # compute negative log likelihood of X_test
                    CVE[t] += -gmm.score_samples(X_test).sum() 
                    CVEtrain[t] += -gmm.score_samples(X_train).sum() 
        # Plot results  
        plt.figure(1); 
        plt.plot(KRange, 2*CVE,'-ok')
        #plt.plot(KRange, 10*1000*CVEtrain,'-or')
        #plt.legend(['Test', 'Train'])
        plt.ylabel('Negative Log likelihood')
        plt.xlabel('K')
        plt.show()
        return CVE
    
    def determiningOptK(self):
        # ELBOW METHOD TO FIND OPTIMAL NUM_CLUSTERS
        KtoTest = (self.X)[:,1].size
        Nc = range(1, KtoTest)
        kmeans = [KMeans(n_clusters=i) for i in Nc]
        score = [kmeans[i].fit(self.X).score(self.X) for i in range(len(kmeans))]
        scorenp = np.array(score)
        scorenp = (scorenp-scorenp.min())/(scorenp.max()-scorenp.min()) # Normalize score
        score_data = dict(zip(scorenp, Nc))
        optK = min([i for i in scorenp if i > 0.8])
        numClusters = score_data[optK]
        plt.plot(Nc,scorenp)
        plt.xlabel('Number of Clusters')  
        plt.ylabel('Score')
        plt.title('Elbow Curve')
        plt.show()
        return numClusters
    
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
                   cmap='rainbow', s=2000)
        ax.scatter(PCA1[:N], PCA2[:N], c=self.clusterLabels, cmap='rainbow')
        plt.title('K means Clustering', fontsize=24)
        plt.xlabel('PC1', fontsize=20)
        plt.ylabel('PC2', fontsize=20)
        plt.axhline(linewidth=0.2, color='k'), plt.axvline(
            linewidth=0.2, color='k')
        ax = plt.gca()
        ax.tick_params(axis = 'both', labelsize = 18)
        plt.legend()

    def predictMuesliCluster(self, customerProfilesDF, customerInput):
        distance = []
        for i in range(len(customerProfilesDF[:])):
            distance.append(np.linalg.norm(customerProfilesDF.iloc[i]-customerInput))
        standardMuesliGroup = np.argmin(distance)
        return customerProfilesDF.iloc[standardMuesliGroup], standardMuesliGroup

    def generateMuesliCombos(self, customerProfilesDF):
        standardMuesliDFs = customerProfilesDF[self.ingredients] > 4.5
        muesliCombos = []
        for i in range (len(standardMuesliDFs.index)):
            muesliCombos.append((standardMuesliDFs.columns[(standardMuesliDFs == True).iloc[i]]).tolist())
        self.standardMeal = muesliCombos
        return muesliCombos
        
    def generateCustomCombos(self, muesliCombos, diseaseIngs):
        numIng = len(muesliCombos) 
        cerealList = ['Oats', 'Crunchy', 'Cornflakes']
        meal1 = rd.sample(muesliCombos, int(numIng))
        meal2 = rd.sample(muesliCombos, int(numIng/2))
        meal3 = rd.sample(muesliCombos, int(numIng/4))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal1:
            meal1.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal2:
            meal2.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal3:
            meal3.append(rd.choice(cerealList))
        # Remove empty items
        if diseaseIngs in meal1:
            meal1.remove(diseaseIngs)
        if diseaseIngs in meal2:
            meal2.remove(diseaseIngs)
        if diseaseIngs in meal3:
            meal3.remove(diseaseIngs)
        meal1 = [x for x in meal1 if x.strip()]
        meal2 = [x for x in meal2 if x.strip()]
        meal3 = [x for x in meal3 if x.strip()]
        return set(meal1), set(meal2), set(meal3)   
        
    def checkDisease(self, userDisease):
        diseaseNuts = ['Disease_Peanuts', 'Disease_Almonds', 'Disease_Walnut',
                       'Disease_Macadamia', 'Disease_Pecan nuts', 'Disease_Cashews']
        foundDisease = []
        for disease in userDisease.columns:
            diseaseCols = userDisease.loc[lambda userDisease: userDisease[disease] == 1]
            if(not diseaseCols.empty):
                foundDisease.append(disease)     
        for disease in diseaseNuts:
            if disease in foundDisease:
                return disease    

########################################################################################
""" Specific to a database, basically skipping rows and columns we don't want """
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

""" Done only once - we got a 'dirty' database from google sheets """
#getDatabase('cleanDatabase.csv', skiprows, colsDrop)    

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
    ingredientRules.remove([])
    ingredientRulesDF = pd.DataFrame(ingredientRules)
    ingredientRulesDF.to_csv('aprioriIngredients.csv', index=False, header=False)
    return ingredientRules

""" Generates the apriori rules database"""
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
    nProfiles=stdMeals.determiningOptK()
    print("Optimal Number of Clusters: ", nProfiles)
    customerProfiles = stdMeals.clusterProfiles(nProfiles)
    keys = Xkcoded.columns
    vals = customerProfiles
    vals = DataPrep.unstandardize(vals, Xmean, Xvar)
    customerProfiles = pd.DataFrame.from_dict(dict(zip(keys, vals.T)))
    customerProfiles.to_csv('clusterCentres.csv', header=customerProfiles.columns, index=False)
    muesliCombos = stdMeals.generateMuesliCombos(customerProfiles)
    mCombos = pd.DataFrame(muesliCombos)
    mCombos.to_csv('muesliClusters.csv', header=None, index=False)
    # Uncomment to visualize the cluster centres - projected over the first 2 Principal Components
    #stdMeals.visualizeClustering()

""" Uncomment this to perform clustering """
#performClustering('cleanDatabase.csv')

# App calls this function whenever we want to recommend a meal (clustering) to a user
def scoreMeal(userPref, recommendedMeals):
    score = 0
    threshold  = 5
    userPref = userPref >= threshold
    prefIng = list(userPref.iloc[0].astype(int))
    userPref = list(userPref.columns[np.where(prefIng)[0]])
    for meal in recommendedMeals:
        commonPref = set(meal).intersection(userPref)
        score = (len(commonPref)/len(meal))*100 + score
    return score/3

""" User Profile must be in the form of a row in 'cleanDatabase.csv """
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
    muesliClustered = []
    for muesliClust in muesliClusters:
        muesliClustered.append(list(filter(None, muesliClust)))
    diseaseIngredients = stdMeals.checkDisease(diseaseDF)
    muesliCombos = stdMeals.generateCustomCombos(muesliClustered[muesliGroup], diseaseIngredients)
    score = scoreMeal(userProfileDF[ingredients], muesliCombos)
    return muesliCombos, score

def generateUserProfiles(n):
    with open('cleanDatabase.csv', 'r') as f:
        reader = csv.reader(f)
        userProfiles = list(reader)
    genProfile = []
    userProfiles.pop(0)
    for i in range(n):
        disease = userProfiles[i].pop(3)
        profileSettings = list(map(int, userProfiles[i]))
        profileSettings.insert(3, disease)
        genProfile.append(profileSettings)
        genProfile[i] = np.array(genProfile[i], dtype=object).reshape(1,25)
    return genProfile

""" A base case version of the system """
def recommendMealDummy(userProfile):
    ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',	
   'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds', 
   'Pumpkin seeds',	'Raisins' ,'Coconut flakes',	
   'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon', 
   'Vanilla', 'Dry fruit']
    DataExtract = DataExtractor()
    cleanDB = DataExtract.loaddata('cleanDatabase.csv')
    # Need to one-out-of-k code an observation
    userProfileDF = pd.DataFrame(userProfile, columns=cleanDB.columns)
    muesliCombos = [['Crunchy', 'Peanuts', 'Almonds', 'Walnuts', 'Vanilla'], 
                    ['Cornflakes', 'Cacao', 'Cinnamon', 'Macadamia', 'Vanilla', 'Coconut flakes' ,'Protein Powder'],
                    ['Oats', 'Chia seeds', 'Sunflower seeds', 'Pumpkin seeds', 'Raisins', 'Dry fruit']]
    score = scoreMeal(userProfileDF[ingredients], muesliCombos)
    return muesliCombos, score


""" Testing the how the app calls the server and what the server outputs """
""" Input from client/app """    
userProfileData =  np.array([1,30,64,None,2,9,5,5,7,6,3,4,6,6,2,3,5,3,8,2,9,1,4,8,8], dtype=object).reshape(1,25)
""" Output from server - recommended meals in muesliCombos & relevant score """
#muesliCombos, score=recommendMeal(userProfileData)  
#for meal in muesliCombos:
#    print(meal)

""" Simulating Clustering Performance over Time """ 

def simulateUserProfiles(userProfiles):    
    scores = []
    scoresDummy = []
    for profile in userProfiles:
        mCs, scoreDummy = recommendMealDummy(profile)
        mCs, score = recommendMeal(profile)
        scores.append(score)
        scoresDummy.append(scoreDummy)
        # Uncomment this to simulate only one time - and get test performance as a bar chart
#    i = np.arange((len(userProfiles)))
#    opacity = 0.4
#    bar_width = 0.35
#    plt.figure(figsize=(20,10))
#    plt.bar(i, scoresDummy, bar_width)
#    plt.bar(i+ bar_width, scores, bar_width,
#            alpha=opacity, color='r')
#    plt.legend(['Base Case', 'With Clustering'], fontsize=18)
#    plt.title('User Score', fontsize=18)
#    plt.ylabel('Score (%)', fontsize=18)
#    plt.xlabel('User ID', fontsize=18)
#    #plt.xticks(i + bar_width / 2)
#    ax = plt.gca()
#    ax.tick_params(axis = 'both', labelsize = 18)
#    plt.savefig('foo.png', bbox_inches='tight')
    return scores, scoresDummy


#nProfiles = 45 
#sc, scD = simulateUserProfiles(generateUserProfiles(nProfiles)) 


def simOverTime():
    score = []
    scoreDummy = []
    filenames = ['cleanDatabase5.csv', 'cleanDatabase10.csv', 'cleanDatabase15.csv', 'cleanDatabase20.csv',
                 'cleanDatabase25.csv', 'cleanDatabase30.csv', 'cleanDatabase35.csv', 'cleanDatabase40.csv',
                 'cleanDatabase45.csv']
    time = range(len(filenames))
    for file in filenames:
        print('Simulating ', file)
        performClustering(file)
        nProfiles = 45
        sc, scD = simulateUserProfiles(generateUserProfiles(nProfiles)) 
        score.append(np.mean(sc))
        scoreDummy.append(np.mean(scD))
    return score, scoreDummy, time


""" Does simulation of clustering performance over time & plots"""
scores, scoresDummy, time = simOverTime()
time = [5, 10, 15, 20, 25, 30, 35, 40, 45]
plt.figure(1); 
plt.plot(time, scores,'--r', LineWidth=4)
plt.plot(time, scoresDummy,'--', color = 'gray', LineWidth=4)
plt.legend(['With Clustering', 'Base Case'], fontsize=16)
plt.title('Why Intelligence?', FontSize=18)
plt.ylabel('Score (%)', FontSize=18)
plt.xlabel('Number of Registered Users', FontSize=18)
plt.savefig('ClusteringPerformance.png', bbox_inches='tight')
ax = plt.gca()
ax.tick_params(axis = 'both', labelsize = 18)
plt.show()
