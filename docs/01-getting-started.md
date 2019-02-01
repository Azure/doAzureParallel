## Cluster and Credentials Objects 
To create a cluster, the user needs to set their credentials via **setCredentials** function in order to create the correct HTTP requests to the Batch service. Then the user will have to pass a cluster file/object to **makeCluster** function. The next following sections will demonstrate how JSON files can be used and how you can create them programatically.

Note: doAzureParallel has a bash script that will generate your credentials JSON file. For more information, see [Getting Started Scripts](./02-getting-started-script.md)

### JSON Configuration files

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
      "key": <Azure Storage Account Key>,
      "endpointSuffix": "core.windows.net"
    }
  },
  "githubAuthenticationToken": "",
  "dockerAuthentication": {
    "username": "",
    "password": "",
    "registry": ""
  }
}
```
Learn more:
 - [Batch account / Storage account](./README.md#azure-requirements)

#### Cluster Settings
Use your cluster configuration JSON file to define your cluster in Azure.

```javascript
{
  "name": <your cluster name>, // example: "myazurecluster"
  "vmSize": <your cluster VM size name>, // example: "Standard_F2"
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
  "containerImage": "rocker/tidyverse:latest",
  "rPackages": {
    "cran": ["some_cran_package", "some_other_cran_package"],
    "github": ["username/some_github_package", "another_username/some_other_github_package"]
  },
  "commandLine": [],
  "subnetId": ""
}
```
NOTE: If you do **not** want your cluster to autoscale, simply set the number of min nodes equal to max nodes for low-priority and dedicated.

NOTE: The *containerImage* property must include tag reference of the docker image. 

In addition to setting credentials and cluster configuration through json files, you can specify them programmatically. This allows users to generate the configuration on the fly at runtime.

## Create Azure Cluster and Credential Objects via Programmatically

The JSON configuration files are essentially list of lists R objects. You can also programatically generate your own configuration files by following the list of lists format.

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
