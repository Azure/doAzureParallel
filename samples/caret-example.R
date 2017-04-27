library(doAzureParallel)
library(caret)
library(mlbench)

# Creating an Azure parallel backend
cluster <- makeCluster("credentials.json", "cluster_settings.json")

# Register your Azure parallel backend to the foreach implementation
registerDoAzureParallel(cluster)

# Set your chunk size of your tasks to 8
setChunkSize(8)

# For more details about using caret, https://topepo.github.io/caret/index.html
data(Sonar)
set.seed(998)
inTraining <- createDataPartition(Sonar$Class, p = .75, list = FALSE)
training <- Sonar[ inTraining,]
testing  <- Sonar[-inTraining,]

fitControl <- trainControl(method = "repeatedcv",
                           number = 4,
                           repeats = 2,
                           classProbs = TRUE,
                           summaryFunction = twoClassSummary,
                           search = "random")

rda_fit <- train(Class ~ ., data = training,
                 method = "rda",
                 metric = "ROC",
                 tuneLength = 2,
                 trControl = fitControl)

stopCluster(cluster)
