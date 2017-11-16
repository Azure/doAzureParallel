# Programmatically generated credential and cluster config

You can set credentials and cluster config through json files, you can also programmatically generate credentials and cluster config, and it allows user to generate the config on the fly at runtime.

## Programmatically generated credentials

You can generate credentials by creating a R object as shown below:

```R
  credentials <- list(
    "batchAccount" = list(
      "name" = "batchaccountname",
      "key" = "batchaccountkey",
      "url" = "https://batchaccountname.region.batch.azure.com"
    ),
    "storageAccount" = list(
      "name" = "storageaccountname",
      "key" = "storageaccountkey"
    ),
    "githubAuthenticationToken" = ""
  )
  doAzureParallel::setCredentials(credentials)
```

### Programmatically generated cluster config

You can generate cluster config by creating a R object as shown below:

```R
  clusterConfig <- list(
    "name" = "clustername",
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

  cluster <- doAzureParallel::makeCluster(clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)
```
