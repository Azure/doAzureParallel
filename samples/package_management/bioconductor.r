#Please see documentation at docs/20-package-management.md for more details on packagement management.

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# set your credentials
doAzureParallel::setCredentials("credentials.json")

# Create your cluster if not exist
cluster <- doAzureParallel::makeCluster("bioconductor_cluster.json")

# register your parallel backend
doAzureParallel::registerDoAzureParallel(cluster)

# check that your workers are up
doAzureParallel::getDoParWorkers()

summary <- foreach(i = 1:1) %dopar% {
  library(GenomeInfoDb) # Already installed as part of the cluster configuration
  library(IRanges) # Already installed as part of the cluster configuration

  sessionInfo()
  # Your algorithm
}

summary

summary <- foreach(i = 1:1, bioconductor=c('GenomeInfoDb', 'IRanges')) %dopar% {
  sessionInfo()
  # Your algorithm
}

summary
