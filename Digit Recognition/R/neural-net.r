library(neuralnet)
library(tree)
library(randomForest)
library(caret)

digits <- read.csv("~\\train.csv")
test <- read.csv("~\\test.csv")


# change response (label) to a factor
digits$label <- as.factor(digits$label)
digits$lab0 <- ifelse(digits$label == 0, 1, 0)
digits$lab1 <- ifelse(digits$label == 1, 1, 0)
digits$lab2 <- ifelse(digits$label == 2, 1, 0)
digits$lab3 <- ifelse(digits$label == 3, 1, 0)
digits$lab4 <- ifelse(digits$label == 4, 1, 0)
digits$lab5 <- ifelse(digits$label == 5, 1, 0)
digits$lab6 <- ifelse(digits$label == 6, 1, 0)
digits$lab7 <- ifelse(digits$label == 7, 1, 0)
digits$lab8 <- ifelse(digits$label == 8, 1, 0)
digits$lab9 <- ifelse(digits$label == 9, 1, 0)

# function get only zero variance
zerovar <- function(dat) {
  out <- lapply(dat, function(x) length(unique(x)))
  want <- which(!out > 1)
  unlist(want)
}

zv <- zerovar(digits)
digits2 <- digits[,-zv]
zerovar <- digits[,zv]

#  now we can ignore pixels with 0 variance and build a complex model
samp <- sample(1:nrow(digits2), size = 10000, replace = FALSE)
digit_samp <- digits2[samp,]

#validate using test and training sets
set.seed(1)
train <- sample(1:nrow(digit_samp), round(nrow(digit_samp)*.7,2))
digit_train <- digit_samp[train,]
digit_test <- digit_samp[-train,]
results.test <- digit_samp$label[-train]


# create formula for neural net function
n <- names(digit_train[,2:(ncol(digit_train) - 10)])
f<- as.formula(paste('lab0 + lab1 + lab2 + lab3 + lab4 + lab5 + lab6 + lab7 + lab8 + lab9 ~ ',
                     paste(paste(n[!n %in% "y"], collapse='+'))))

net.digit <- neuralnet(f, data = digit_train, hidden=100, err.fct = "sse", linear.output = FALSE)

# set up the test data
digit_test$label <- NULL
digit_test2 <- digit_test[,1:(ncol(digit_test)-10)]
responses <- digit_test[,(ncol(digit_test)-9):ncol(digit_test)]

#Test the neural network on some test data
net.results <- compute(net.digit, digit_test2, rep = 1)

check <- as.data.frame(net.results$net.result)
colnames(check)<-c("0", "1", "2", "3", "4" ,"5", "6", "7", "8", "9")
check$prediction <- colnames(check)[apply(check, 1, which.max)]
check$prediction <- as.numeric(check$prediction)

colnames(responses)<-c("0", "1", "2", "3", "4" ,"5", "6", "7", "8", "9")
responses$response <- colnames(responses)[apply(responses, 1, which.max)]
responses$response <- as.numeric(responses$response)


table(responses$response, check$prediction)

(189 + 80 + 23 + 194 + 167 + 45 + 237 + 180 + 38 + 96) / 1500
