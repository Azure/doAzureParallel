# =============
# === Setup ===
# =============

# install packages from github
library(devtools)
install_github("azure/razurebatch", ref="release")
install_github("azure/doazureparallel", ref="release")

# import packages
library(doAzureParallel)

# create credentials config files
generateCredentialsConfig("credentials.json")

# set azure credentials
setCredentials("credentials.json")

# generate cluster config json file
generateClusterConfig("cluster.json")

# Creating an Azure parallel backend
cluster <- makeCluster(clusterSetting = "cluster.json")

# Register your Azure parallel backend to the foreach implementation
registerDoAzureParallel(cluster)

# ===================================================
# === Grid Search w/ Cross Validation using Caret ===
# ===================================================

# For more details about using caret:
# https://topepo.github.io/caret/index.html
library(caret)

# Set your chunk size of your tasks to 8 
# So that caret knows in group tasks into larger chunks
setChunkSize(8)

# install DAAG to download the dataset 'spam7'
install.packages("DAAG")
library(DAAG)

# 'spam7' is a data set that consists of 4601 email items, 
# of which 1813 items were identified as spam. This sample 
# has 7 features, one of which is titled 'yesno'. In this 
# example, we will be classifying our data into 'yesno' to 
# identify which rows are spam, and which are not.

# split the data into 
set.seed(998)
inTraining <- createDataPartition(spam7$yesno, p = .75, list = FALSE)
training <- spam7[ inTraining,]
testing  <- spam7[-inTraining,]

# Define the settings for the cv. Because we have already 
# registered our parallel backend, Caret will know to use it
fitControl <- trainControl(## 10-fold cross validation
                           method = "repeatedcv",
                           number = 10,
                           ## repeat 10 times
                           repeats = 10,
                           ## toggle between sequential and parallel execution 
                           allowParallel = TRUE)

# Define the grid of parameters to tune 
gbmGrid <- expand.grid(interaction.depth = c(1, 5, 9), 
                       n.trees = (1:30)*50, 
                       shrinkage = c(0.1, 0.3, 0.5),
                       n.minobsinnode = 20)

# show the number of combinations with the tuning parameters to test
nrow(gbmGrid)

# Set up a grid of tuning parameters for the classification 
# routine, fits each model and calculates a resampling base 
# performance measure
gbm_fit <- train(## classification column
                 yesno ~ ., 
                 ## dataframe to train on
                 data = training,
                 ## ML algorithm to use - other models are also available (see caret documentation)
                 method = "gbm",
                 ## the metric to use for evaluation
                 metric = "Accuracy",
                 ## run cv across the following tuneGrid
                 tuneGrid = gbmGrid,
                 ## train control - defines settings of this functions
                 trControl = fitControl)

# print results
gbm_fit

# print best tuning parameters
gbm_fit$bestTune

# de-provision your cluster in Azure
stopCluster(cluster)
