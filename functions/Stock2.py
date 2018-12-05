# -*- coding: utf-8 -*-
"""
Created on Mon Nov 19 12:33:20 2018

@author: Steffen-PC
"""

import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter as c
import matplotlib as mpl


df = pd.read_csv('StockLevels.csv')
df.set_index('Day', inplace=True)
#print(df)

df.plot(figsize=(15,7),color = ['r', 'gray'])


#Calculate mean stocksize over n_sim (lines of code)
df1 = pd.read_csv('StockCalc.csv')
df1 = df1.dropna(axis=1)
df1.columns = ["Oats","Cornflakes","Crunchy","Peanuts","Almonds",
               "Walnuts","Macadamia","Pecan nuts","Cashews","Chia seeds",
               "Sunflower seeds","Pumpkin seeds","Raisins","Coconut flakes",
               "Cocoa beans","Protein powder","Cacao","Cinnamon","Vanilla",
               "Dry fruit"]
#df1.set_index('Day', inplace=True)
n_sim = len(df1)
df1_list = []
dailyAverage={}
for index in range(0,len(df1.columns)):
    df1_vals = df1.iloc[:,index]
    df1_sum = sum(STOCK_VAL-df1_vals)/n_sim
    df1_list.append(df1_sum)
df1_list = [ int(round(elem, 2)) for elem in df1_list]
IngAverage={'Oats' : df1_list[0],				#Dictionary for stock ingredients.
            'Cornflakes': df1_list[1],
            'Crunchy': df1_list[2],
            'Peanuts' : df1_list[3],
            'Almonds' : df1_list[4],
            'Walnuts' : df1_list[5],
            'Macadamia' : df1_list[6],
            'Pecan nuts' : df1_list[7],
            'Cashews' : df1_list[8],
            'Chia seeds' : df1_list[9],
            'Sunflower seeds' : df1_list[10],
            'Pumpkin seeds' : df1_list[11],
            'Raisins' : df1_list[12],
            'Coconut flakes' : df1_list[13],
            'Cocoa beans' : df1_list[14],
            'Protein powder' : df1_list[15],
            'Cacao' : df1_list[16],
            'Cinnamon' : df1_list[17],
            'Vanilla' : df1_list[18],
            'Dry fruit' : df1_list[19]}

for keys,values in IngAverage.items():
    dailyAverage[keys] = int(IngAverage[keys]/n_days)
print("Average monthly consumption: {}".format(IngAverage))
print("\nAverage daily consumption: {}".format(dailyAverage))