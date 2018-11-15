from app import app

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

import json

@app.route('/')
@app.route('/index')
def index():
    return "Hello, World!"

@app.route('/app/<proposition>',methods=['GET'])
def apriori(proposition):
    # Data Preprocessing
    dataset = pd.read_csv('data/data.txt', sep = ",", header=None)
    proposition = proposition.split("-")

    records = []
    for i in range(0, len(dataset)):
        records.append([str(dataset.values[i,j]) for j in range(0, 4)])

    # apriori
    from apyori import apriori
    rules = apriori(records, min_support = 0.5, min_confidence = 0.9)
    association_results = list(rules)
    listRules = [list(association_results[i][0]) for i in range(0,len(association_results))]


    list_temp = []
    for i in range(len(listRules)):
        if (len(listRules[i]) == len(proposition)+1 and set(proposition).issubset(listRules[i]) == True):
            list_temp.append(listRules[i])

    return json.dumps(list_temp)
