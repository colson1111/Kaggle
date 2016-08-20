# shelter animals

import numpy as np
import pandas as pd
from datetime import datetime

train = pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/train.csv')
test = pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/test.csv')

# split SexUponOutcome by " "
def fixSex(data):
    data.ix[data.SexuponOutcome == 'Unknown', 'SexuponOutcome'] = 'Unknown Unknown'
    data['SexuponOutcome'] = data.SexuponOutcome.fillna('Unknown Unknown')
    data['Fixed'], data['Sex'] = zip(*data['SexuponOutcome'].apply(lambda x: x.split(' ', 1)))
    del(data['SexuponOutcome'])
    return data

train = fixSex(train)
test = fixSex(test)

# convert age to weeks
def fixAge(data):
    result = {}
    
    for value in data['AgeuponOutcome'].unique():
        if type(value) != type(""):
            result[value] = -1
        else:
            v1,v2 = value.split()
            if v2 in ["year", "years"]:
                result[value] = int(v1) * 52
            elif v2 in ["month", "months"]:
                result[value] = int(v1) * 4.5
            elif v2 in ["week", "weeks"]:
                result[value] = int(v1)
            elif v2 in ["day", "days"]:
                result[value] = int(v1) / 7
                
    data['_AgeuponOutcome'] = data['AgeuponOutcome'].map(result).astype(float)
    data = data.drop('AgeuponOutcome', axis = 1)
    data.rename(columns = {'_AgeuponOutcome' : 'AgeuponOutcome'}, inplace = True)
    return data
    
train = fixAge(train)
test = fixAge(test)

# convert DateTime to year, month, day of week
def fixDate(data):
    d = datetime.strptime(data, "%Y-%m-%d %H:%M:%S")
    return d.year, d.month, d.isoweekday() # 1 = Monday, 7 = Sunday

train["Year"], train["Month"], train["Weekday"] = zip(*train["DateTime"].map(fixDate))
test["Year"], test["Month"], test["Weekday"] = zip(*test["DateTime"].map(fixDate))

# function to get the frequency of occurrence for each name
def getNameFreq(data):
    data["Name"].fillna(value = "no name", inplace = True)
    counts = data["Name"].value_counts()
    counts = pd.DataFrame({'Name':counts.index, 'NameFrequency':counts})
    data = pd.merge(data, counts, on = ['Name'], how = 'left')
    data.loc[data.Name == "no name", 'NameFrequency'] = 0
    
    return data

train = getNameFreq(train)
test = getNameFreq(test)

# visualization
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns

# Plot distribution of Name Frequency
sns.distplot(train["NameFrequency"], kde = False)  # Names are quite infrequent

# Plot distribution of Age by Result
age_data = train[train["AgeuponOutcome"] > 0]

sns.boxplot(x = "OutcomeType", 
            y = "AgeuponOutcome", 
            hue = "AnimalType",
            data = age_data) # Older pets are more frequently euthanized or returned to owner

# Plot number of each result by day of week
df = train[["OutcomeType","Weekday"]]

df2 = df.groupby(["OutcomeType","Weekday"]).size()
df3 = df2.reset_index()
df3.columns = ["OutcomeType","Weekday","Count"]

sns.barplot(x = "Weekday", 
            y = "Count", 
            hue = "OutcomeType",
            data = df3)   # Pets are adopted more on weekends than other days






