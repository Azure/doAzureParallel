# =============
# === Setup ===
# =============

# install packages
library(devtools)
install_github("azure/razurebatch")
install_github("azure/doazureparallel")

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

credentialsFileName <- "credentials.json"
clusterFileName <- "cluster.json"

# generate a credentials json file
generateCredentialsConfig(credentialsFileName)

# set your credentials
setCredentials(credentialsFileName)

# generate a cluster config file
generateClusterConfig(clusterFileName)

# Create your cluster if not exist
cluster <- makeCluster(clusterFileName)

# register your parallel backend
registerDoAzureParallel(cluster)

# check that your workers are up
getDoParWorkers()

# =======================================================
# === Create long running job and get progress/result ===
# =======================================================

options <- list(wait = FALSE)
'%dopar%' <- foreach::'%dopar%'
jobId <-
  foreach::foreach(
    i = 1:4,
    .packages = c('httr'),
    .options.azure = opt
  ) %dopar% {
    mean(1:3)
  }

job <- getJob(jobId)

# get active/running job list
filter <- filter <- list()
filter$state <- c("active", "completed")
getJobList(filter)

# get job list for all jobs
getJobList()

# wait 2 minutes for long running job to finish
Sys.sleep(120)

# get job result
jobResult <- getJobResult(jobId)

doAzureParallel::stopCluster(cluster)

# delete the job
rAzureBatch::deleteJob(jobId)
