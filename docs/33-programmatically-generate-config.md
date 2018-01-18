# Programmatically generated credential and cluster configuration

In addition to setting credentials and cluster configuration through json files, you can specify them programmatically. This allows users to generate the configuration on the fly at runtime.

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

If using a private docker registry, add the docker authentication section

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
    "githubAuthenticationToken" = "",
    "dockerAuthentication" = list("username" = "registryusername",
                                  "password" = "registrypassword",
                                  "registry" = "registryurl")
  )
```

## Programmatically generated cluster configuration

You can generate cluster configuration by creating a R object as shown below:

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
