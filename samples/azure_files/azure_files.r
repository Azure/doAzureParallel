# =================
# ===== Setup =====
# =================

# install packages
library(devtools)
install_github("azure/doazureparallel")

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# generate a credentials json file
generateCredentialsConfig("credentials.json")

# set your credentials
setCredentials("credentials.json")

# Create your cluster if not exist
cluster <- makeCluster("sample_cluster.json")

# register your parallel backend
registerDoAzureParallel(cluster)

# check that your workers are up
getDoParWorkers()

# =====================================
# ===== Use data from Azure Files =====
# =====================================

# In this basic example, simply list all of the files in your azure files.
# As there are two nodes in the cluster, each iteration of the loop will be
# run on a different node. The output should be that both tasks outpu
# the same file list for each node.
files <- foreach(i = 1:2, .combine='rbind') %dopar% {
  setwd('/mnt/batch/tasks/shared/data')

  x <- list.files()
  return (x)
}

# Print result
files
