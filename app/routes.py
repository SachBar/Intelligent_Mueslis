from app import app

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

import json
from apyori import apriori
import ast
from flask import jsonify

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
