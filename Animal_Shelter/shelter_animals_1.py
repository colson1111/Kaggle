# shelter animals

import numpy as np
import pandas as pd
from datetime import datetime

train = pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/train.csv')
test = pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/test.csv')

# split SexUponOutcome by " "
def fix_sex(data):
    data.ix[data.SexuponOutcome == 'Unknown', 'SexuponOutcome'] = 'Unknown Unknown'
    data['SexuponOutcome'] = data.SexuponOutcome.fillna('Unknown Unknown')
    data['Fixed'], data['Sex'] = zip(*data['SexuponOutcome'].apply(lambda x: x.split(' ', 1)))
    del(data['SexuponOutcome'])
    return data

train = fix_sex(train)
test = fix_sex(test)


# convert ages to years
age_check = set(train['AgeuponOutcome'])  # check all possible values

# split AgeuponOutcome by " "
def fix_age(data):
    data['AgeuponOutcome'] = data.AgeuponOutcome.fillna('Unknown Unknown')
    data['Age'], data['Units'] = zip(*data['AgeuponOutcome'].apply(lambda x: x.split(' ', 1)))
    
    data.Age = pd.to_numeric(data.Age, errors = 'coerce')
    
    data['Age'] = np.where(data['Units'] == 'week', 1.0 / 52, data['Age'])
    data['Age'] = np.where(data['Units'] == 'weeks', data['Age'] / 52, data['Age'])
    data['Age'] = np.where(data['Units'] == 'month', 1.0 / 12, data['Age'])
    data['Age'] = np.where(data['Units'] == 'months', data['Age'] / 12, data['Age'])
    del(data['Units'])
    del(data['AgeuponOutcome'])
    return data

train = fix_age(train)
test = fix_age(test)

# convert DateTime to year, month, day of week
def fix_date(data):
    d = datetime.strptime(data, "%Y-%m-%d %H:%M:%S")
    return d.year, d.month, d.isoweekday()

train["Year"], train["Month"], train["Weekday"] = zip(*train["DateTime"].map(fix_date))
test["Year"], test["Month"], test["Weekday"] = zip(*test["DateTime"].map(fix_date))

# separate out the IDs and response variable
train_id = train[["AnimalID"]]
test_id = test[["ID"]]
train.drop("AnimalID", axis = 1, inplace = True)
test.drop("ID", axis = 1, inplace = True)

train_outcome = train["OutcomeType"]
train.drop("OutcomeType", axis = 1, inplace = True)

# encode categorical variables as numeric
train["train"] = 1
test["train"] = 0

full_data = pd.concat([train,test])


# drop some columns for now
age = full_data["Age"]
full_data.drop(["Name", "OutcomeSubtype", "DateTime", "Age"], axis = 1, inplace = True)

# categorize variables
full_data_encode = pd.get_dummies(full_data, columns = full_data.columns)

# put age back in
full_data_encode = pd.concat([full_data_encode, age], axis = 1)





# split back into test and train
train = full_data_encode[full_data_encode["train_1"] == 1]
test = full_data_encode[full_data_encode["train_0"] == 1]

train.drop(["train_0", "train_1"], axis = 1, inplace = True)
test.drop(["train_0", "train_1"], axis = 1, inplace = True)


# random forest classification
from sklearn.ensemble import RandomForestClassifier
from sklearn.cross_validation import train_test_split
from sklearn.metrics import log_loss
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import Imputer

# create train/validation split to check accuracy of model before submission
X_train, X_val, y_train, y_val = train_test_split(train, train_outcome, test_size = 0.1)

# create model with imputer for missing values of age
forest = Pipeline([("imputer", Imputer(missing_values = "NaN", 
                                       strategy = "median",
                                       axis = 0)),
                   ("forest", RandomForestClassifier(n_estimators = 5000,
                                                     n_jobs = 4))])
             
# fit model on subset of training data                                        
forest.fit(X_train, y_train)

# predict validation set
y_pred_val = forest.predict_proba(X_val)

print(log_loss(y_val, y_pred_val))

# 500 estimators log loss: 0.971
# 1000 estimators log loss: 0.920

# train model on complete training set and predict test set
forest.fit(train, train_outcome)
y_pred = forest.predict_proba(test)


results = pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/sample_submission.csv')

results['Adoption'], results['Died'], results['Euthanasia'], results['Return_to_owner'],results['Transfer'] = y_pred[:,0], y_pred[:,1], y_pred[:,2], y_pred[:,3], y_pred[:,4]
results.to_csv("C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Submissions/submission_rf1.csv", index = False)



    


