# Kaggle Titanic Intro

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sys
import csv

train = pd.read_csv("C:\\Users\\Craig\\Documents\\Kaggle\\Titanic\\train.csv")
test = pd.read_csv("C:\\Users\\Craig\\Documents\\Kaggle\\Titanic\\test.csv")

test['TestFlag'] = 1
train['TestFlag'] = 0

df = train.append(pd.DataFrame(data = test))

ids = test['PassengerId']


# dimension of data
df.shape  # there are 1309 rows and 13 columns

df.head() # view first 5 rows

type(df) # datatype of dataframe itself

df.dtypes # datatypes of each columns

df.info() # bunch of useful info:  missing data in age, cabin, embarked

df.describe() # summary statistics for each column

# histograms of age and fare
df[["Age","Fare"]].hist()

# get the first 10 rows of the Age column
df['Age'][0:10]
df.Age[0:10]

df['Cabin'][0:5]
df.Cabin[0:10]

type(df['Age']) # type of the column: pandas Series

df['Age'].mean() # mean age was 29.699117
df['Age'].median() # median age was 28.0

# look at specific sets of data from the overall data set
# pass a list of columns to look at together
df[['Sex','Pclass','Age']]

# filtering the data
# get age column, filtered to people over 60
df[df['Age'] > 60]

# look at the three columns above and survival flag, filtered to people over 60
df2 = df[df['Age'] > 60][['Sex','Pclass','Age','Survived']]

# get the % of males
sex_ct = df2['Sex'].value_counts()
pct_male_60 = sex_ct[0] / float(sum(sex_ct))
print "{}% of the 60+ population was Male.".format(round(pct_male_60 * 100))

# time to investigate the missing age values
missing_age = df[df['Age'].isnull()][['Sex','Pclass','Age']]  # there are 177 missing age values

missing_age['Sex'].value_counts()[0] / float(sum(missing_age['Sex'].value_counts())) # 70% of missing ages are male

# count the number of males by Pclass
for i in range(1,4):
    print i,len(df[(df['Sex'] == 'male') & (df['Pclass'] == i)])

# 122 in class 1, 108 in class 2, 347 in class 3

# another histogram
df['Age'].dropna().hist(bins=16, range=(0,80), alpha = .5)


# cleaning the data
df['Gender'] = 4

df['Gender'] = df['Sex'].map(lambda x: x[0].upper())

df['Gender'] = df['Sex'].map({'female':0,'male':1}).astype(int)

# use the median for each gender/class combination to impute a new value for age
median_ages = np.zeros((2,3))
median_ages

for i in range(0,2):
    for j in range(0,3):
        median_ages[i,j] = df[(df['Gender'] == i) & (df['Pclass'] == j + 1)]['Age'].dropna().median()

median_ages

df['AgeFill'] = df['Age']

df.head()

df[ df['Age'].isnull() ][['Gender','Pclass','Age','AgeFill']].head(10)


# fill in AgeFill using medians
for i in range(0,2):
    for j in range(0,3):
        df.loc[ (df.Age.isnull()) & (df.Gender == i) & (df.Pclass == j+1), 'AgeFill'] = median_ages[i,j]
       
       
df[ df['Age'].isnull() ][['Gender','Pclass','Age','AgeFill']].head(10)

# create a column that records whether or not the age was initially missing
df['AgeIsNull'] = pd.isnull(df.Age).astype(int)

df.describe()


# Feature Engineering
# Parch is the number of this person's parents or children on board
# SibSp is the number of this person's siblings or spouses on board
# combine them to get family size
df['FamilySize'] = df['Parch'] + df['SibSp']

df['Age*Class'] = df.AgeFill * df.Pclass

df['FamilySize'].hist()
df['Age*Class'].hist()

# next steps: prepare data for sklearn model.
# 1. determine which columns are still not numeric
# 2. convert pandas dataframe into numpy array
df.dtypes
df.dtypes[df.dtypes.map(lambda x: x == 'object')]
# Name, Sex, Ticket, Cabin, Embarked are non-numeric, we aren't going to use them
df = df.drop(['Name', 'Sex', 'Ticket', 'Cabin', 'Embarked', 'Age', 'PassengerId'], axis = 1)

# move Survived column to the front
cols =df.columns.tolist()
cols = cols[4:] + cols[0:4]
df = df[cols]

# split back into test/train
train = df[df['TestFlag'] == 0]
test = df[df['TestFlag'] == 1]
del test['Survived']


# Impute a single missing Fare value in the test data

test.loc[test['Fare'].isnull(),'Fare'] = df['Fare'].median()


# use pandas dataframe .values method to convert to numpy array
train_data = train.values
train_data

test_data = test.values
test_data


# Building a Random Forest Model

from sklearn.ensemble import RandomForestClassifier
from sklearn.cross_validation import train_test_split
from sklearn.metrics import accuracy_score

X_train, X_test, y_train, y_test = train_test_split(train_data[0::,1::], train_data[0::,0], test_size = 0.20)
# Create the rf object
forest = RandomForestClassifier(n_estimators = 100)

# Fit the training data to the Survived labels and create the decision trees

forest = forest.fit(X_train, y_train)

# apply the model to the testing data
output = forest.predict(X_test)

# evaluate the performance
perf = accuracy_score(y_test, output) # 0.7486033


# Rebuild the model on the full data set
forest = forest.fit(train_data[0::,1::], train_data[0::,0])

# Take the same decision trees and run it on the true test data
output = forest.predict(test_data).astype(int)

# write to file to upload
predictions_file = open("C:\\Users\\Craig\\Documents\\Kaggle\\Titanic\\output.csv", "wb")
open_file_object = csv.writer(predictions_file)
open_file_object.writerow(["PassengerId","Survived"])
open_file_object.writerows(zip(ids, output))
predictions_file.close()
