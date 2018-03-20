# =============
# === Setup ===
# =============

# install packages from github
library(devtools)
install_github("azure/razurebatch")
install_github("azure/doazureparallel")

# import packages
library(doAzureParallel)

# create credentials config files
generateCredentialsConfig("credentials.json")

# set azure credentials
setCredentials("credentials.json")

# generate cluster config json file
generateClusterConfig("cluster-caret.json")

# Creating an Azure parallel backend
cluster <- makeCluster(clusterSetting = "cluster-caret.json")

# Register your Azure parallel backend to the foreach implementation
registerDoAzureParallel(cluster)

# ===================================================
# === Random Search w/ Cross Validation using Caret ===
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

# split the data into training and testing
set.seed(998)
inTraining <- createDataPartition(spam7$yesno, p = .75, list = FALSE)
training <- spam7[ inTraining,]
testing  <- spam7[-inTraining,]

# Define the settings for the cv. Because we have already 
# registered our parallel backend, Caret will know to use it
fitControl <- trainControl(## 10-fold cross validation
                           method = "repeatedcv",
                           number = 2,
                           ## repeat 10 times
                           repeats = 2,
                           classProbs = TRUE,
                           summaryFunction = multiClassSummary,
                           search = "random",
                           ## run on the parallel backend
                           allowParallel = TRUE)


rf_fit <- train(## classification column
                 yesno ~ ., 
                 ## dataframe to train on
                 data = training, 
                 ## model to use - other models are also available (see caret documentation)
                 method = "rf",
                 ## the metric to use for evaluation
                 metric = "ROC",
                 ## # of random searches
                 tuneLength = 2,
                 ## tuning params
                 trControl = fitControl)


# print results
rf_fit

# print best tuning parameters
rf_fit$bestTune

# de-provision your cluster in Azure
stopCluster(cluster)
