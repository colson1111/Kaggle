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
    return d.year, d.month, d.isoweekday()

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

# translate breed into dog group
breeds_group = np.array(pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/breed_group.csv', sep=','))

dog_groups = np.unique(breeds_group[:,1])
             
# identify dogs with "mix" in the breed and flag them as mix
# identify dogs with "/" in the breed and flag them as mix
# if there is a "/", keep both breed values (breed 1 and breed 2 and mix flag)
# if it is a mix, keep the breed (breed 1 and mix flag)


        
        
        
        
        
        

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
numerics = full_data[["AgeuponOutcome", "NameFrequency"]]
full_data.drop(["Name","OutcomeSubtype","DateTime","AgeuponOutcome","NameFrequency"], axis = 1, inplace = True)

# categorize variables
full_data_encode = pd.get_dummies(full_data, columns = full_data.columns)

# put age back in
full_data_encode = pd.concat([full_data_encode, numerics], axis = 1)



# split back into test and train
train = full_data_encode[full_data_encode["train_1"] == 1]
test = full_data_encode[full_data_encode["train_0"] == 1]

train.drop(["train_0", "train_1"], axis = 1, inplace = True)
test.drop(["train_0", "train_1"], axis = 1, inplace = True)


# random forest classification
from sklearn.ensemble import AdaBoostClassifier, RandomForestClassifier
from sklearn.cross_validation import train_test_split
from sklearn.metrics import log_loss
# create train/validation split to check accuracy of model before submission
X_train, X_val, y_train, y_val = train_test_split(train, train_outcome, test_size = 0.1)

# create adaboost model
adaboost = AdaBoostClassifier(base_estimator = RandomForestClassifier(n_estimators = 100,
                                                                      n_jobs = 4), 
                              n_estimators = 20,
                              algorithm = "SAMME.R",
                              learning_rate = 0.25)

# fit model on subset of training data                                        
adaboost.fit(X_train, y_train)

# predict validation set
y_pred_val = adaboost.predict_proba(X_val)

print(log_loss(y_val, y_pred_val))


# train model on complete training set and predict test set
adaboost.fit(train, train_outcome)
y_pred = adaboost.predict_proba(test)


results = pd.read_csv('C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Data/sample_submission.csv')

results['Adoption'], results['Died'], results['Euthanasia'], results['Return_to_owner'],results['Transfer'] = y_pred[:,0], y_pred[:,1], y_pred[:,2], y_pred[:,3], y_pred[:,4]
results.to_csv("C:/Users/Craig/Documents/Kaggle/Shelter_Animals/Submissions/submission_rf_adaboost2.csv", index = False)



    


