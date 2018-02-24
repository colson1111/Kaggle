# PROJECT 1:  Identify hitters who are Hall of Fame worthy (and aren't in the HOF)


library(RSQLite)
library(dplyr)
library(data.table)
library(ggplot2)
library(magrittr)
library(sqldf)
library(tidyr)

# connect to SQLite database
db <- dbConnect(dbDriver("SQLite"), "C:\\Users\\Craig\\Documents\\Kaggle\\Baseball\\baseball\\database.sqlite")

# get list of table names in the database
tables <- dbGetQuery(db, "SELECT Name FROM sqlite_master WHERE type = 'table'")

# get a list of the hall of famers
hof <- dbGetQuery(db, "SELECT * FROM hall_of_fame")
players <- filter(hof, inducted == 'Y') %>% select(player_id)
players$hof = 1

# get the data for all players
# BATTERS ----------------------------------------------------------
batting <- dbGetQuery(db, "SELECT * FROM batting")

batting <- dplyr::group_by(batting, player_id) %>% 
           dplyr::summarise(years_b = (max(year) - min(year)),
                     g_b = sum(g), 
                     ab_b = sum(ab), 
                     r_b = sum(r), 
                     h_b = sum(h),
                     double_b = sum(double),
                     triple_b = sum(triple), 
                     hr_b = sum(hr), 
                     rbi_b = sum(rbi), 
                     sb_b = sum(sb), 
                     cs_b = sum(cs), 
                     bb_b = sum(bb), 
                     so_b = sum(so))
# ------------------------------------------------------------------


# FIELDING----------------------------------------------------------
fielding <- dbGetQuery(db, "SELECT * FROM fielding")

# get primary position for each player id
primary_pos <- sqldf("SELECT player_id, pos, sum(g) as games
                      FROM fielding
                      GROUP BY player_id, pos
                      ORDER BY games desc")
position <- spread(primary_pos, pos, games)
position[is.na(position)] <- 0
position$total <- apply(position[2:12],1,sum)
position$pct_pitcher <- position$P / position$total

fielding <- dplyr::group_by(fielding, player_id)
fielding <- dplyr::summarise(fielding,
                      g_f = sum(g), po_f = sum(po), a_f = sum(a), e_f = sum(e)) %>%
            arrange(desc(g_f))

# join position data onto fielding data
fielding <- left_join(fielding, position, by = "player_id")

# ------------------------------------------------------------------
stats <- full_join(batting, full_join(fielding, players, by = c("player_id")), by = c("player_id"))

stats[is.na(stats)] <- 0 # set all NAs to 0

# PLAYER AWARDS-----------------------------------------------------
player_award <- dbGetQuery(db, "SELECT player_id, award_id FROM player_award")

player_award <- group_by(player_award, player_id, award_id) %>%
                dplyr::summarise(count = n()) %>%
                arrange(desc(count))

player_award <- tidyr::spread(player_award,award_id,count)
player_award[is.na(player_award)] <- 0
player_award$total_awards <- apply(player_award[2:28],1,sum)
# ------------------------------------------------------------------

stats <- full_join(stats, player_award, by = "player_id") # join award data on to the rest of the data
stats <- filter(stats, pct_pitcher <= 0.50, g_b >= 162) # remove players who were pitchers in >50% of their games
stats$hof <- as.factor(stats$hof) # make hof a factor
table(stats$hof) # there are 169 batters in the hall of fame
colnames(stats) <- make.names(colnames(stats)) # fix column names

# move hof to the beginning and remove Pitching awards
stats <- subset(stats, select = c(hof, player_id:pct_pitcher,ALCS.MVP:total_awards))
stats <- subset(stats, select = -c(Cy.Young.Award, Rolaids.Relief.Man.Award, TSN.Fireman.of.the.Year,
                                   TSN.Pitcher.of.the.Year, TSN.Reliever.of.the.Year,
                                   Pitching.Triple.Crown, total, pct_pitcher, total_awards))
stats[is.na(stats)] <- 0 # set all NAs to 0



# graphs/visualizations
library(corrgram)
corrgram(stats, order=TRUE, lower.panel=panel.shade,
         upper.panel=NULL,
         main="Baseball Correlogram")

ggplot(stats, aes(x = h_b, fill = hof)) + geom_density(alpha = 0.75) + ggtitle("Hits")
ggplot(stats, aes(x = hr_b, fill = hof)) + geom_density(alpha = 0.75) + ggtitle("Home Runs")
ggplot(stats, aes(x = so_b, fill = hof)) + geom_density(alpha = 0.75) + ggtitle("Strikeouts")



# Build Random Forest to predict the HOF Members
library(caret)
library(e1071)
library(stats)

# using random forest allows us to use the OOB error rate - no need to split the data
trainX <- stats[,3:51]


set.seed(802)

# train and tune random forest
rf_train <- train(x = trainX,
                  y = stats$hof,
                  method = "rf",                 
                  preProc = c("center", "scale"),         # center and scale
                  metric = "Accuracy",
                  trControl = trainControl(method="cv", number = 10),
                  allowParallel = TRUE)

# check the best value of mtry
plot(rf_train)

# need to rerun using mtry = 52 to get the output I want (predictions made on training data)
rf <- randomForest(x = trainX, y = stats$hof, mtry = 25)

# variable importance
importance(rf)
varImpPlot(rf, sort = TRUE, n.var = 20, main = "Variable Importance Plot")

# predicted values (from training set) to the original data
stats$predicted <- rf$predicted

# take the true values and the predicted values and build table
rf$confusion

# The model correctly classifies 93 of the 169 Hall of Fame hitters (about 56%).  There are 76 HOFers that the
# model did not identify as HOFers.  There are 22 players that the model did identify as HOFers that are
# not in the Hall of Fame.  Let's see who they are:



# HOF worthy:
hof_worthy <- filter(stats, hof == 0 & predicted == 1)
View(hof_worthy)

# In HOF, but maybe shouldn't be
not_hof <- filter(stats, hof == 1 & predicted == 0)
View(not_hof)

# there are a few examples of managers who were not HOF-worthy players (Bobby Cox)




# PRINCIPAL COMPONENTS ANALYSIS
stats_sub <- subset(stats, select = -c(hof,player_id,predicted))
stats_hof <- stats$hof
stats_player <- stats$player_id

# scale and center
stats_pca <- prcomp(stats_sub,center = TRUE,scale = TRUE)
print(stats_pca)
plot(stats_pca, type='l')
summary(stats_pca)

# save PCA data for modeling, match to the response variable
pca_data <- data.frame(stats_pca$x)
pca_data$hof <- stats$hof
pca_data$player_id <- stats_player


scores <- data.frame(sample.groups, pca$x[,1:3])

library(ggExtra)

pc1.2 <- qplot(x=PC1, y=PC2, data=pca_data, colour=factor(hof)) +
  theme(legend.position="none") +
  scale_fill_hue(l=40)
ggExtra::ggMarginal(pc1.2, type = "density", colour = "red")

ggplot(pca_data, aes(x = PC1, fill = hof)) + geom_density(alpha = 0.75) + ggtitle("PC1")
ggplot(pca_data, aes(x = PC2, fill = hof)) + geom_density(alpha = 0.75) + ggtitle("PC2")
ggplot(pca_data, aes(x = PC3, fill = hof)) + geom_density(alpha = 0.75) + ggtitle("PC3")


# build random forest on PCA components and see if it's better or worse than the original

set.seed(802)

trainX2 <- pca_data[,3:49]



# train and tune random forest
rf_train <- train(x = trainX2,
                  y = stats$hof,
                  method = "rf",                 
                  preProc = c("center", "scale"),         # center and scale
                  metric = "Accuracy",
                  trControl = trainControl(method="cv", number = 10),
                  allowParallel = TRUE)


# need to rerun using mtry = 15 to get the output I want (predictions made on training data)
rf2 <- randomForest(x = trainX2, y = stats$hof, mtry = 47)


# variable importance
importance(rf2)
varImpPlot(rf2, sort = TRUE, n.var = 20, main = "Variable Importance Plot")

# predicted values (from training set) to the original data
stats$predicted_pca <- rf$predicted

# take the true values and the predicted values and build table
rf$confusion

# The model correctly classifies 93 of the 169 Hall of Fame hitters (about 56%).  There are 76 HOFers that the
# model did not identify as HOFers.  There are 22 players that the model did identify as HOFers that are
# not in the Hall of Fame.  Let's see who they are:



# HOF worthy:
hof_worthy <- filter(stats, hof == 0 & predicted_pca == 1)
View(hof_worthy)

# In HOF, but maybe shouldn't be
not_hof <- filter(stats, hof == 1 & predicted_pca == 0)
View(not_hof)






