getSettings <- function(dedicatedMin = 2,
                        dedicatedMax = 2,
                        lowPriorityMin = 2,
                        lowPriorityMax = 2,
                        poolName = "test-pool"){
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
      "name" = poolName,
      "vmSize" = "Standard_D2_v2",
      "maxTasksPerNode" = 1,
      "poolSize" = list(
        "dedicatedNodes" = list(
          "min" = dedicatedMin,
          "max" = dedicatedMax
        ),
        "lowPriorityNodes" = list(
          "min" = lowPriorityMin,
          "max" = lowPriorityMax
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
