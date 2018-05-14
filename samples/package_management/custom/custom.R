#Please see documentation at docs/20-package-management.md for more details on packagement management.

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# set your credentials
doAzureParallel::setCredentials("credentials.json")

# Create your cluster if not exist
cluster <- doAzureParallel::makeCluster("custom_packages_cluster.json")

# register your parallel backend
doAzureParallel::registerDoAzureParallel(cluster)

# check that your workers are up
doAzureParallel::getDoParWorkers()

summary <- foreach(i = 1:1, .packages = c("customR")) %dopar% {
  sessionInfo()
  # Method from customR
  hello()
}

summary
