
# Kaggle Digit Recognizer

# Learning about Neural Networks using the Digit Recognition data set.

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

train = pd.read_csv("C:/Users/Craig/Documents/Kaggle/Digit Recognizer/train.csv")
test = pd.read_csv("C:/Users/Craig/Documents/Kaggle/Digit Recognizer/test.csv")

train.shape # 42000 rows by 785 columns

target = train[[0]].values.ravel()
train = train.iloc[:,1:].values

# do the random forest example first
from sklearn.ensemble import RandomForestClassifier
from sklearn.cross_validation import train_test_split
from sklearn.metrics import accuracy_score

import pybrain as pb

X_train, X_test, y_train, y_test = train_test_split(train, target, test_size=0.25, random_state=42)

rf = RandomForestClassifier(n_estimators = 100, n_jobs = 2) # build classifier

rf.fit(X_train,y_train) # fit training data

pred = rf.predict(X_test)  # apply to test data

accuracy_score(y_test, pred) # evaluate accuracy:  0.963



