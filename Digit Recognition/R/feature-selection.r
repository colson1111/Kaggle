# Keep variables with >0 variance
library(tree)
library(randomForest)
library(caret)

digits <- read.csv("C:\\Users\\Ryan\\Desktop\\Kaggle\\digits\\train.csv")
test <- read.csv("C:\\Users\\Ryan\\Desktop\\Kaggle\\digits\\test.csv")


# change response (label) to a factor
digits$label <- as.factor(digits$label)

# function get only zero variance
zerovar <- function(dat) {
  out <- lapply(dat, function(x) length(unique(x)))
  want <- which(!out > 1)
  unlist(want)
}

zv <- zerovar(digits)
digits2 <- digits[,-zv]
zerovar <- digits[,zv]
