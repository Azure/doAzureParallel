# install packages
library(devtools)
install_github("azure/doazureparallel")

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# set your credentials
setCredentials("credentials.json")

# Create your cluster if not exist
cluster <- makeCluster("bioconductor_cluster.json")

# register your parallel backend
registerDoAzureParallel(cluster)

# check that your workers are up
getDoParWorkers()

summary <- foreach(i = 1:1) %dopar% {
  library(GenomeInfoDb) # Already installed as part of the cluster configuration
  library(IRanges) # Already installed as part of the cluster configuration

  sessionInfo()
  # Your algorithm

}

summary
