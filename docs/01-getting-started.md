# Azure Cluster and Credentials Objects 

### Configuration JSON files

#### Credentials
Use your credential config JSON file to enter your credentials.

```javascript 
{ 
  "sharedKey": {
    "batchAccount": {
      "name": <Azure Batch Account Name>,
      "key": <Azure Batch Account Key>,
      "url": <Azure Batch Account URL>
    },
    "storageAccount": {
      "name": <Azure Storage Account Name>,
      "key": <Azure Storage Account Key>
    }
  },
  "githubAuthenticationToken": {}
}
```
Learn more:
 - [Batch account / Storage account](./README.md#azure-requirements)
 - [Create your secrets configuration in code](./docs/33-programmatically-generate-config.md)


#### Cluster Settings
Use your pool configuration JSON file to define your pool in Azure.

```javascript
{
  "name": <your pool name>, // example: "myazurecluster"
  "vmSize": <your pool VM size name>, // example: "Standard_F2"
  "maxTasksPerNode": <num tasks to allocate to each node>, // example: "2"
  "poolSize": {
    "dedicatedNodes": {  // dedicated vms
        "min": 2,
        "max": 2
    },
    "lowPriorityNodes": { // low priority vms 
        "min": 1,
        "max": 10
    },
    "autoscaleFormula": "QUEUE"
  },
  "rPackages": {
    "cran": ["some_cran_package", "some_other_cran_package"],
    "github": ["username/some_github_package", "another_username/some_other_github_package"]
  },
  "commandLine": []
}
```
NOTE: If you do **not** want your cluster to autoscale, simply set the number of min nodes equal to max nodes for low-priority and dedicated.

In addition to setting credentials and cluster configuration through json files, you can specify them programmatically. This allows users to generate the configuration on the fly at runtime.

## Create Azure Cluster and Credential Objects via Programmatically

You can generate credentials by creating a R object as shown below:

```R
  credentials <- list(
    "sharedKey" = list(
      "batchAccount" = list(
        "name" = "batchaccountname",
        "key" = "batchaccountkey",
        "url" = "https://batchaccountname.region.batch.azure.com"
      ),
      "storageAccount" = list(
        "name" = "storageaccountname",
        "key" = "storageaccountkey",
        "endpointSuffix" = "core.windows.net"
      )
    ),
    "githubAuthenticationToken" = "",
    "dockerAuthentication" = list("username" = "",
                                  "password" = "",
                                  "registry" = "")
  )
  doAzureParallel::setCredentials(credentials)
```

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
