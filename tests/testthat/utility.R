setup <- function(){
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)
}

getSettings <- function(){
  list(
    credentials = list(
      "sharedKey" = list(
        "batchAccount" = list(
          "name" = Sys.getenv("BATCH_ACCOUNT_NAME"),
          "key" = Sys.getenv("BATCH_ACCOUNT_KEY"),
          "url" = Sys.getenv("BATCH_ACCOUNT_URL")
        ),
        "storageAccount" = list(
          "name" = Sys.getenv("STORAGE_ACCOUNT_NAME"),
          "key" = Sys.getenv("STORAGE_ACCOUNT_KEY"),
          "endpointSuffix" = "core.windows.net"
        )
      ),
      "githubAuthenticationToken" = "",
      "dockerAuthentication" = list("username" = "",
                                    "password" = "",
                                    "registry" = "")
    ),
    clusterConfig = list(
      "name" = "test-pool",
      "vmSize" = "Standard_D2_v2",
      "maxTasksPerNode" = 1,
      "poolSize" = list(
        "dedicatedNodes" = list(
          "min" = 0,
          "max" = 0
        ),
        "lowPriorityNodes" = list(
          "min" = 1,
          "max" = 1
        ),
        "autoscaleFormula" = "QUEUE"
      ),
      "containerImage" = "rocker/tidyverse:latest",
      "rPackages" = list(
        "cran" = list(),
        "github" = list(),
        "bioconductor" = list()
      ),
      "commandLine" = list()
    )
  )
}
