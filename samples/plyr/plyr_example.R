# =============
# === Setup ===
# =============

# install packages from github
library(devtools)
install_github("azure/razurebatch")
install_github("azure/doazureparallel")

# import packages
library(doAzureParallel)

# set azure credentials
setCredentials("credentials.json")

# Creating an Azure parallel backend
cluster <- makeCluster(clusterSetting = "plyr_cluster.json")

# Register your Azure parallel backend to the foreach implementation
registerDoAzureParallel(cluster)

# ==========================================================
# === Using plyr with doAzureParallel's parallel backend ===
# ==========================================================

# import plyr
library(plyr)

# For more information on plyr, https://github.com/hadley/plyr
dlply(iris, .(Species), function(x)
  lm(x$Sepal.Width ~ x$Petal.Length, data=x),
  .parallel=TRUE, .paropts = list(.packages = NULL,.export="iris"))

# de-provision your cluster in Azure
stopCluster(cluster)
