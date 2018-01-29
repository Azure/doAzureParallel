[![Build Status](https://travis-ci.org/Azure/doAzureParallel.svg?branch=master)](https://travis-ci.org/Azure/doAzureParallel)
# doAzureParallel

```R
# set your credentials
setCredentials("credentials.json")

# setup your cluster with a simple config file
cluster<- makeCluster("cluster.json")

# register the cluster as your parallel backend
registerDoAzureParallel(cluster)

# run your foreach loop on a distributed cluster in Azure
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations) %dopar% {
    myParallelAlgorithm()
}
```

## Introduction

The *doAzureParallel* package is a parallel backend for the widely popular *foreach* package. With *doAzureParallel*, each iteration of the *foreach* loop runs in parallel on an Azure Virtual Machine (VM), allowing users to scale up their R jobs to tens or hundreds of machines.

*doAzureParallel* is built to support the *foreach* parallel computing package. The *foreach* package supports parallel execution - it can execute multiple processes across some parallel backend. With just a few lines of code, the *doAzureParallel* package helps create a cluster in Azure, register it as a parallel backend, and seamlessly connects to the *foreach* package.

NOTE: The terms *pool* and *cluster* are used interchangably throughout this document.

## Dependencies

- R (>= 3.3.1)
- httr (>= 1.2.1)
- rjson (>= 0.2.15)
- RCurl (>= 1.95-4.8)
- digest (>= 0.6.9)
- foreach (>= 1.4.3)
- iterators (>= 1.0.8)
- bitops (>= 1.0.5)

## Installation 

Install doAzureParallel directly from Github.

```R
# install the package devtools
install.packages("devtools")

# install the doAzureParallel and rAzureBatch package
devtools::install_github("Azure/rAzureBatch")
devtools::install_github("Azure/doAzureParallel")
```

## Azure Requirements

To run your R code across a cluster in Azure, we'll need to get keys and account information.

### Setup Azure Account
First, set up your Azure Account ([Get started for free!](https://azure.microsoft.com/en-us/free/))

Once you have an Azure account, you'll need to create the following resources in Azure:
- Azure Batch Account
- Azure Storage Account

#### Using Azure CLI
You can either download the [Azure CLI V2](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) or use Azure Cloud Shell. This example will show the steps to get started using the Azure Cloud Shell.

Open a broswer and navigate to [Azure Cloud Shell](https://shell.azure.com). Make sure you have selected a **Bash** shell and run the following commands

```sh
# Download the required setup scripts
wget https://raw.githubusercontent.com/Azure/doAzureParallel/feature/gettingstarted/inst/getting-started/manage_account.sh

# Create resources in West US (westus). You can find a list of locations by running
# 'az account list-locations'
# Make sure to use the 'name' field and not the 'displayName' field

# Create a resource group, batch account and storage account
/bin/sh manage_account.sh create westus

# Get the keys needed for doAzureParallel
/bin/sh manage_account.sh list-keys
```

Once they keys are listed, simply copy and paste them into your credentials.json file explained in the [Getting Started](#getting-started) section. If you lose track of your keys, you can simply re-run the 'list-keys' command any time to get them again.

More information on using the setup scripts can be found [here](./docs/01-getting-started.md).

## Getting Started

Import the package
```R
library(doAzureParallel)
```

Set up your parallel backend with Azure. This is your set of Azure VMs.
```R
# 1. Generate your credential and cluster configuration files.  
generateClusterConfig("cluster.json")
generateCredentialsConfig("credentials.json")

# 2. Fill out your credential config and cluster config files.
# Enter your Azure Batch Account & Azure Storage keys/account-info into your credential config ("credentials.json") and configure your cluster in your cluster config ("cluster.json")

# 3. Set your credentials - you need to give the R session your credentials to interact with Azure
setCredentials("credentials.json")

# 4. Register the pool. This will create a new pool if your pool hasn't already been provisioned.
cluster <- makeCluster("cluster.json")

# 5. Register the pool as your parallel backend
registerDoAzureParallel(cluster)

# 6. Check that your parallel backend has been registered
getDoParWorkers()
```

Run your parallel *foreach* loop with the *%dopar%* keyword. The *foreach* function will return the results of your parallel code.

```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations) %dopar% {
  # This code is executed, in parallel, across your cluster.
  myAlgorithm()
}
```

After you finish running your R code in Azure, you may want to shut down your cluster of VMs to make sure that you are not being charged anymore.

```R
# shut down your pool
stopCluster(cluster)
```

### Configuration JSON files

#### Credentials
Use your credential config JSON file to enter your credentials.

```javascript 
{ 
  "batchAccount": {
    "name": <Azure Batch Account Name>,
    "key": <Azure Batch Account Key>,
    "url": <Azure Batch Account URL>
  },
  "storageAccount": {
    "name": <Azure Storage Account Name>,
    "key": <Azure Storage Account Key>
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

Learn more:
 - [Choosing VM size](./docs/10-vm-sizes.md#vm-size-table)
 - [Create your cluster configuration in code](./docs/33-programmatically-generate-config.md)
 - [MaxTasksPerNode](./docs/22-parallelizing-cores.md)
 - [LowPriorityNodes](#low-priority-vms)
 - [Autoscale](./docs/11-autoscale.md)
 - [PoolSize Limitations](./docs/12-quota-limitations.md)
 - [rPackages](./docs/20-package-management.md)

### Low Priority VMs
Low-priority VMs are a way to obtain and consume Azure compute at a much lower price using Azure Batch. Since doAzureParallel is built on top of Azure Batch, this package is able to take advantage of low-priority VMs and allocate compute resources from Azure's surplus capacity at up to **80% discount**. 

Low-priority VMs come with the understanding that when you request it, there is the possibility that we'll need to take some or all of it back. Hence the name *low-priority* - VMs may not be allocated or may be preempted due to higher priority allocations, which equate to full-priced VMs that have an SLA.

And as the name suggests, this significant cost reduction is ideal for *low priority* workloads that do not have a strict performance requirement.

With Azure Batch's first-class support for low-priority VMs, you can use them in conjunction with normal on-demand VMs (*dedicated VMs*) and enable job cost to be balanced with job execution flexibility:

 * Batch pools can contain both on-demand nodes and low-priority nodes. The two types can be independently scaled, either explicitly with the resize operation or automatically using auto-scale. Different configurations can be used, such as maximizing cost savings by always using low-priority nodes or spinning up on-demand nodes at full price, to maintain capacity by replacing any preempted low-priority nodes.
 * If any low-priority nodes are preempted, then Batch will automatically attempt to replace the lost capacity, continually seeking to maintain the target amount of low-priority capacity in the pool.
 * If tasks are interrupted when the node on which it is running is preempted, then the tasks are automatically re-queued to be re-run.

For more information about low-priority VMs, please visit the [documentation](https://docs.microsoft.com/en-us/azure/batch/batch-low-pri-vms).

You can also check out information on low-priority pricing [here](https://azure.microsoft.com/en-us/pricing/details/batch/).

### Distributing Data
When developing at scale, you may also want to chunk up your data and distribute the data across your nodes. Learn more about that [here](./docs/21-distributing-data.md#chunking-data)

### Using %do% vs %dopar%
When developing at scale, it is always recommended that you test and debug your code locally first. Switch between *%dopar%* and *%do%* to toggle between running in parallel on Azure and running in sequence on your local machine.

```R 
# run your code sequentially on your local machine
results <- foreach(i = 1:number_of_iterations) %do% { ... }

# use the doAzureParallel backend to run your code in parallel across your Azure cluster
results <- foreach(i = 1:number_of_iterations) %dopar% { ... }
```

### Error Handling
The errorhandling option specifies how failed tasks should be evaluated. By default, the error handling is 'stop' to ensure users' can have reproducible results. If a combine function is assigned, it must be able to handle error objects.

Error Handling Type | Description
--- | ---
stop | The execution of the foreach will stop if an error occurs
pass | The error object of the task is included the results
remove | The result of a failed task will not be returned 

```R 
# Remove R error objects from the results
res <- foreach::foreach(i = 1:4, .errorhandling = "remove") %dopar% {
  if (i == 2 || i == 4) {
    randomObject
  }
  
  mean(1:3)
}

#> res
#[[1]]
#[1] 2
#
#[[2]]
#[1] 2
```

```R 
# Passing R error objects into the results 
res <- foreach::foreach(i = 1:4, .errorhandling = "pass") %dopar% {
  if (i == 2|| i == 4) {
    randomObject
  }
  
  sum(i, 1)
}

#> res
#[[1]]
#[1] 2
#
#[[2]]
#<simpleError in eval(expr, envir, enclos): object 'randomObject' not found>
#
#[[3]]
#[1] 4
#
#[[4]]
#<simpleError in eval(expr, envir, enclos): object 'randomObject' not found>
```

### Long-running Jobs + Job Management

doAzureParallel also helps you manage your jobs so that you can run many jobs at once while managing it through a few simple methods.


```R 
# List your jobs:
getJobList()
# Get your job by job id:
getJob(jobId = 'unique_job_id', verbose = TRUE)
```

This will also let you run *long running jobs* easily.

With long running jobs, you will need to keep track of your jobs as well as set your job to a non-blocking state. You can do this with the *.options.azure* options:

```R
# set the .options.azure option in the foreach loop 
opt <- list(job = 'unique_job_id', wait = FALSE)

# NOTE - if the option wait = FALSE, foreach will return your unique job id
job_id <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar % { ... }

# get back your job results with your unique job id
results <- getJobResult(job_id)
```

Finally, you may also want to track the status of jobs by state (active, completed etc):

```R
# List jobs in completed state:
filter <- list()
filter$state <- c("active", "completed")
jobList <- getJobList(filter)
View(jobList)
```

You can learn more about how to execute long-running jobs [here](./docs/23-persistent-storage.md). 

With long-running jobs, you can take advantage of Azure's autoscaling capabilities to save time and/or money. Learn more about autoscale [here](./docs/11-autoscale.md).

### Using the 'chunkSize' option

doAzureParallel also supports custom chunk sizes. This option allows you to group iterations of the foreach loop together and execute them in a single R session.

```R
# set the chunkSize option
opt <- list(chunkSize = 3)
results <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar% { ... }
```

You should consider using the chunkSize if each iteration in the loop executes very quickly.

If you have a static cluster and want to have a single chunk for each worker, you can compute the chunkSize as follows:

```R
# compute the chunk size
cs <- ceiling(number_of_iterations / getDoParWorkers())

# run the foreach loop with chunkSize optimized
opt <- list(chunkSize = cs)
results <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar% { ... }
```

### Resizing Your Cluster

At some point, you may also want to resize your cluster manually. You can do this simply with the command *resizeCluster*.

```R
cluster <- makeCluster("cluster.json")

# resize so that we have a min of 10 dedicated nodes and a max of 20 dedicated nodes
# AND a min of 10 low priority nodes and a max of 20 low priority nodes
resizeCluster(
    cluster, 
    dedicatedMin = 10, 
    dedicatedMax = 20, 
    lowPriorityMin = 10, 
    lowPriorityMax = 20, 
    algorithm = 'QUEUE', 
    timeInterval = '5m' )
```

If your cluster is using autoscale but you want to set it to a static size of 10, you can also use this method:

```R
# resize to a static cluster of 10
resizeCluster(cluster, 
    dedicatedMin = 10, 
    dedicatedMax = 10,
    lowPriorityMin = 0,
    lowPriorityMax = 0)
```

### Setting Verbose Mode to Debug

To debug your doAzureParallel jobs, you can set the package to operate on *verbose* mode:

```R
# turn on verbose mode
setVerbose(TRUE)

# turn off verbose mode
setVerbose(FALSE)
```
### Bypassing merge task 

Skipping the merge task is useful when the tasks results don't need to be merged into a list. To bypass the merge task, you can pass the *enableMerge* flag to the foreach object:

```R
# Enable merge task
foreach(i = 1:3, .options.azure = list(enableMerge = TRUE))

# Disable merge task
foreach(i = 1:3, .options.azure = list(enableMerge = FALSE))
```
Note: User defined functions for the merge task is on our list of features that we are planning on doing.

## Next Steps

For more information, please visit [our documentation](./docs/README.md).
