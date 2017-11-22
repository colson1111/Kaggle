
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

zvar <- zerovar(digits)
digits2 <- digits[,-zvar]
digits2$label <- as.factor(digits2$label)

#  now we can ignore pixels with 0 variance and build a more complex model
samp <- sample(1:nrow(digits2), size = 10000, replace = FALSE)
digit_samp <- digits2[samp,]

#validate using test and training sets
set.seed(1)
train <- sample(1:nrow(digit_samp), round(nrow(digit_samp)*.7,2))
digit_train <- digit_samp[train,]
digit_test <- digit_samp[-train,]
results.test <- digit_samp$label[-train]

# what if we use the whole tree only to classify between 4 or 9 or neither, can we get them correct?
# then we do a separate randomforest for each combination of digits, whichever # gets the most votes wins


rf.pred <- matrix(ncol = 0, nrow = nrow(digit_test))

for (i in 1:3){
    print(paste("Starting Loop #", i))
  
    samp <- sample(0:9, 4, replace = FALSE)
    j <- samp[1]
    k <- samp[2]
    l <- samp[3]
    m <- samp[4]
    
    digit_train_loop <- digit_train
    
    digit_train_loop$label <- ifelse(digit_train_loop$label == j, j, 
                                     ifelse(digit_train_loop$label == k, k,
                                            ifelse(digit_train_loop$label == l, l,
                                                   ifelse(digit_train_loop$label == m, m, -1))))
                                            
    digit_train_loop$label <- factor(digit_train_loop$label)
    
    # build tree
    set.seed(1)
    rf.loop <- randomForest(label ~., ntree = 5, data = digit_train_loop, importance = TRUE, do.trace = TRUE)
    
    # predict new
    data <- predict(rf.loop, newdata = digit_test)
    data <- as.data.frame(data)
    
    # join onto rf.pred
    rf.pred <- cbind(rf.pred, data)
    colnames(rf.pred)[i] <- i
  
}






