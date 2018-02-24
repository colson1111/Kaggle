
# random forest using a sample of the training set, success ~93% on hold out data

library(tree)
library(randomForest)

digits <- read.csv("C:\\Users\\Craig\\Desktop\\Kaggle\\Digits\\train.csv")

test <- read.csv("C:\\Users\\Craig\\Desktop\\Kaggle\\Digits\\test.csv")

sample <- sample(1:nrow(digits), size = 10000, replace = FALSE)

digit_samp <- digits[sample,]

# change response (label) to a factor
digit_samp$label <- as.factor(digit_samp$label)

#validate using test and training sets
set.seed(1)
train <- sample(1:nrow(digit_samp), round(nrow(digit_samp)*.7,2))

digit_train <- digit_samp[train,]
digit_test <- digit_samp[-train,]

results.test <- digit_samp$label[-train]

# Fit random forest
set.seed(1)
rf.digit <- randomForest(label ~ ., ntree = 100, data = digit_train, importance = TRUE)
rf.digit

# Validation
rf.pred <- predict(rf.digit, newdata = digit_test)
plot(rf.pred, results.test)
table(rf.pred, results.test)

# can just use out of bag error rate instead of validation set for random forests
