from app import app

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

import json
from apyori import apriori
import ast
from flask import jsonify


import os
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
from sklearn.mixture import GaussianMixture as GMM
from collections import defaultdict
import random as rd
import csv

@app.route('/')
@app.route('/index')
def index():
    return "Hello, World!"

@app.route('/init_rb')
def init_rb():
    # Data Preprocessing
    dataset = pd.read_csv('data/data.txt', sep = ",",header=None)
    records = []
    for i in range(0, len(dataset)):
        records.append([str(dataset.values[i,j]) for j in range(0, 4)])

    # apriori
    from apyori import apriori
    rules = apriori(records, min_support = 0.5, min_confidence = 0.9)
    association_results = list(rules)

    # get the rules into a dataframe
    df = pd.DataFrame()
    for item in association_results:
        pair = item[0]
        items = [x for x in pair]

        #we don't need rule with only one item
        if len(items) != 1:

            #we take all the items
            list_item = []
            for i in range(len(items)):
                list_item.append(items[i])

            df.loc[len(df),"item"]  = str(set(list_item))
            df.loc[len(df)-1,"support"]  = item[1]
            df.loc[len(df)-1,"confidence"] = item[2][0][2]

            #sort by confidence
            df = df.sort_values(by='confidence', ascending=False)

            #eliminate the duplicate and keep the first one which are the one with the more confidence
            df = df.groupby('item').first().reset_index()
    df.to_csv("data/df_ar.csv", index=False)
    return jsonify(
        message="Initialisation done !"
    )

@app.route('/app/<proposition>',methods=['GET'])
def apriori(proposition):
    # Data Preprocessing
    df = pd.read_csv('data/df_ar.csv')
    proposition = proposition.split("-")
    df_recommandation = pd.DataFrame()
    for i in range(len(df)):

        #we can the set of item of the row
        item_set = ast.literal_eval(df.loc[i,"item"])

        #we make a recommandation if there are one element in the combination than in the choice of the user
        if (len(item_set) == len(proposition)+1 and set(proposition).issubset(item_set) == True):
            df_recommandation = df_recommandation.append(df.loc[i])
    return df_recommandation.to_json(orient='records')

####################################
####################################

class DataExtractor:
    def __init__(self):
        self.DB = None
        print("Database Extraction")

    # Loading data as a pandas dataframe
    def loaddata(self, filename, rows=[], path="data"):
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

        ingredientsDF = self.X[self.ingList]
        # Format columns to binary values
        threshold = binthresh  # Where the user is likely to try the ingredient
        aprioriDF = ingredientsDF[self.ingList] > threshold
        return aprioriDF


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
        standardMuesliDFs = customerProfilesDF[self.ingredients] > 4
        muesliCombos = []
        for i in range (len(standardMuesliDFs.index)):
            muesliCombos.append((standardMuesliDFs.columns[(standardMuesliDFs == True).iloc[i]]).tolist())
        self.standardMeal = muesliCombos
        return muesliCombos

    def generateCustomCombos(self, muesliCombos):
        numIng = len(muesliCombos)
        cerealList = ['Oats', 'Crunchy', 'Cornflakes']
        meal1 = rd.sample(muesliCombos, int(numIng/4))
        meal2 = rd.sample(muesliCombos, int(numIng/4))
        meal3 = rd.sample(muesliCombos, int(numIng/4))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal1:
            meal1.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal2:
            meal2.append(rd.choice(cerealList))
        if 'Oats' and 'Crunchy' and 'Cornflakes' not in meal3:
            meal3.append(rd.choice(cerealList))
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

@app.route('/preprocess_database')
def getDatabase(fileName="cleanDatabase.csv", skiprows=[], colsDrop=[]):

    #skiprows = [0,1,2]
    #colsDrop = 'Weekday'

    DataExtract = DataExtractor()
    extractedData = DataExtract.loaddata('BreakfastDB.csv', rows=skiprows)
    extractedData = DataExtract.dropColumns(columns=colsDrop)
    extractedData.to_csv(fileName, header=extractedData.columns, index=False)
    return jsonify(
        message="Preprocess database done !"
    )

# Call this whenever you want to get rules from a database and save them in another DB
# I also return them in a variable: ingredientRules
@app.route('/preprocess_rules_data')
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
    return jsonify(
        message="Preprocess data format rules done !"
    )

@app.route('/perform_clustering')
def performClustering(cleanBreakfastDB="cleanDatabase.csv"):

    ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',
                   'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds',
                   'Pumpkin seeds',	'Raisins' ,'Coconut flakes',
                   'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon',
                   'Vanilla', 'Dry fruit']

    nProfiles=5

    DataExtract = DataExtractor()
    X = pd.read_csv("data/"+cleanBreakfastDB)
    DataPrep = DataPreprocess(X)
    Xkcoded = DataPrep.oneoutofK('Disease')
    print(Xkcoded.head())
    Xstandardized, Xmean, Xvar = DataPrep.standardize(Xkcoded)
    stdMeals = standardMeals(Xstandardized, ingredients)
    customerProfiles = stdMeals.clusterProfiles(nProfiles)
    keys = Xkcoded.columns
    vals = customerProfiles
    vals = DataPrep.unstandardize(vals, Xmean, Xvar)
    customerProfiles = pd.DataFrame.from_dict(dict(zip(keys, vals.T)))
    customerProfiles.to_csv('data/clusterCentres.csv', header=customerProfiles.columns, index=False)
    muesliCombos = stdMeals.generateMuesliCombos(customerProfiles)
    mCombos = pd.DataFrame(muesliCombos)
    mCombos.to_csv('data/muesliClusters.csv', header=None, index=False)
    return jsonify(
        message="Clustering done !"
    )



    """ User Profile must be in the form of a row in 'cleanDatabase.csv """
    """ Need a global variable called ingredients in server """



import json
class SetEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, set):
            return list(obj)
        return json.JSONEncoder.default(self, obj)

@app.route('/recommend/<user_id>',methods=['GET'])
def recommendMeal(user_id):
    ingredients = ['Oats', 'Cornflakes', 'Crunchy', 'Peanuts',	'Almonds', 'Walnuts',
       'Macadamia',	'Pecan nuts', 'Cashews', 'Chia seeds', 'Sunflower seeds',
       'Pumpkin seeds',	'Raisins' ,'Coconut flakes',
       'Cocoa beans', 'Protein powder',	'Cacao', 'Cinnamon',
       'Vanilla', 'Dry fruit']

    clusterCentres = pd.read_csv('data/clusterCentres.csv')
    cleanDB = pd.read_csv('data/cleanDatabase.csv')

    # Need to one-out-of-k code an observation
    diseasecols = [s for s in list(clusterCentres.columns) if "Disease" in s]

    userProfile = pd.read_csv('data/userDB.csv', header = None)
    userProfile = userProfile.iloc[[user_id]]

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
    userProfileDF = pd.concat(DFs, axis=1)
    # User profile is now one-out-of-k coded
    stdMeals = standardMeals(clusterCentres, ingredients)
    diseaseIngredients = stdMeals.checkDisease(diseaseDF)
    muesliCluster, muesliGroup = stdMeals.predictMuesliCluster(clusterCentres, userProfileDF)
    
    with open('data/muesliClusters.csv', 'r') as f:
        reader = csv.reader(f)
        muesliClusters = list(reader)

    muesliCombos = stdMeals.generateCustomCombos(muesliClusters[muesliGroup], diseaseIngredients)
    return json.dumps(muesliCombos, cls=SetEncoder)
    
