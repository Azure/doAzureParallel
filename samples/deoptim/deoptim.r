# =============
# === Setup ===
# =============

# install packages
install.packages("DEoptim")
library(DEoptim)

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

# ==============================================================
# === Caling DEoptim with doAzureParallel cluster as backend ===
# ==============================================================

## The below examples shows how the call to DEoptim can be parallelized
## with doAzureParallel cluster as backend
Genrose <- function(x) {
  ## One generalization of the Rosenbrock banana valley function (n parameters)
  n <- length(x)
  ## simulate a long running task ...
  Sys.sleep(60)
  1.0 + sum (100 * (x[-n]^2 - x[-1])^2 + (x[-1] - 1)^2)
}

# get some run-time on simple problems
maxIt <- 5
n <- 5

options <- list(wait = TRUE, autoDeleteJob = TRUE)
foreachArgs <- list(.options.azure = options, .packages = c('httr'))
DEoptim(
  fn = Genrose,
  lower = rep(-25, n),
  upper = rep(25, n),
  control = list(
    NP = 10 * n,
    itermax = maxIt,
    parallelType = 2,
    foreachArgs = foreachArgs
  )
)

doAzureParallel::stopCluster(cluster)
