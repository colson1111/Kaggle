
library(tree)

digits <- read.csv("C:\\Users\\Craig\\Desktop\\Kaggle\\Digits\\train.csv")

sample <- sample(1:nrow(digits), size = 15000, replace = FALSE)

digit_samp <- digits[sample,]

# change response (label) to a factor
digit_samp$label <- as.factor(digit_samp$label)

# Fit a classification tree to the data

  #validate using test and training sets
  set.seed(1)
  train <- sample(1:nrow(digit_samp), round(nrow(digit_samp)*.7,2))
  
  digit_train <- digit_samp[train,]
  digit_test <- digit_samp[-train,]
  
  results.test <- digit_samp$label[-train]
  
  # build model
  tree.digits <- tree(label~., digit_train)
  
  # make predictions
  tree.pred <- predict(tree.digits, digit_test, type = "class")
  
  # confusion matrix
  t <- table(tree.pred, results.test)
  sum(339, 443, 304, 289, 219, 70, 224, 391, 247, 315)/(4500)
  # the simple classification tree correctly predicts 63.13% of the test set labels
  
  # use cross validation to determine the optimal prune of the tree
  set.seed(3)
  cv.digits <- cv.tree(tree.digits, FUN = prune.misclass)
  names(cv.digits)

  # plot the error rate
  par(mfrow=c(1,2))
  plot(cv.digits$size, cv.digits$dev, type = "b")
  plot(cv.digits$k, cv.digits$dev, type = "b")
  
  par(mfrow=c(1,1))
  prune.digits <- prune.misclass(tree.digits, best = 16)
  plot(prune.digits)
  text(prune.digits, pretty = 0)
  
  # test pruned classification tree on test data
  tree.pred <- predict(prune.digits, digit_test, type = "class")
  table(tree.pred, results.test)
  sum(361, 443, 304, 289, 219, 33, 196, 391, 247, 315) / 4500
  # after using the optimal prune, the model correctly predicts 62.17% of the test set labels

  # this isn't very good, so it's time to try something new
