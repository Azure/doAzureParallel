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

Once you have an Azure account, you'll need to create the following two services in the Azure portal:
- Azure Batch Account ([Create an Azure Batch Account in the Portal](https://docs.microsoft.com/en-us/azure/Batch/batch-account-create-portal))
- Azure Storage Account (this can be created with the Batch Account)

### Get Keys and Account Information
For your Azure Batch Account, we need to get:
- Batch Account Name
- Batch Account URL
- Batch Account Access Key

This information can be found in the Azure Portal inside your Batch Account:

![Azure Batch Acccount in the Portal](./vignettes/doAzureParallel-azurebatch-instructions.PNG "Azure Batch Acccount in the Portal")

For your Azure Storage Account, we need to get:
- Storage Account Name
- Storage Account Access Key

This information can be found in the Azure Portal inside your Azure Storage Account:

![Azure Storage Acccount in the Portal](./vignettes/doAzureParallel-azurestorage-instructions.PNG "Azure Storage Acccount in the Portal")

Keep track of the above keys and account information as it will be used to connect your R session with Azure.

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

## doAzureParallel Guide 
This section will provide information about how Azure works, how best to take advantage of Azure, and best practices when using the doAzureParallel package.

1. **Azure Introduction** [(link)](./docs/00-azure-introduction.md)

   Using *Azure Batch*

2. **Getting Started** [(link)](./docs/01-getting-started.md)

    Using the *Getting Started* to create credentials
    
    i. **Generate Credentials Script** [(link)](./docs/02-getting-started-script.md)

    - Pre-built bash script for getting Azure credentials without Azure Portal

    ii. **National Cloud Support** [(link)](./docs/03-national-clouds.md)

    - How to run workload in Azure national clouds

3. **Customize Cluster** [(link)](./docs/30-customize-cluster.md)

    Setting up your cluster to user's specific needs

    i. **Virtual Machine Sizes** [(link)](./docs/31-vm-sizes.md)
    
    - How do you choose the best VM type/size for your workload?

    ii. **Autoscale** [(link)](./docs/32-autoscale.md)
  
    - Automatically scale up/down your cluster to save time and/or money.
  
    iii. **Building Containers** [(link)](./docs/33-building-containers.md)
    
      - Creating your own Docker containers for reproducibility

4. **Managing Cluster** [(link)](./docs/40-clusters.md)

    Managing your cluster's lifespan

5. **Customize Job**

    Setting up your job to user's specific needs
    
    i. **Asynchronous Jobs** [(link)](./docs/51-long-running-job.md)
    
    - Best practices for managing long running jobs
  
    ii. **Foreach Azure Options** [(link)](./docs/52-azure-foreach-options.md)
        
    - Use Azure package-defined foreach options to improve performance and user experience
  
    iii. **Error Handling** [(link)](./docs/53-azure-foreach-options.md)
    
    - How Azure handles errors in your Foreach loop? 
    
6. **Package Management** [(link)](./docs/20-package-management.md)

    Best practices for managing your R packages in code. This includes installation at the cluster or job level as well as how to use different package providers.

7. **Storage Management**
    
    i. **Distributing your Data** [(link)](./docs/71-distributing-data.md)
    
    - Best practices and limitations for working with distributed data.

    ii. **Persistent Storage** [(link)](./docs/72-persistent-storage.md)

    - Taking advantage of persistent storage for long-running jobs
   
    iii. **Accessing Azure Storage through R** [(link)](./docs/73-managing-storage.md)
    
    - Manage your Azure Storage files via R 

8. **Performance Tuning** [(link)](./docs/80-performance-tuning.md)

    Best practices on optimizing your Foreach loop

9. **Debugging and Troubleshooting** [(link)](./docs/90-troubleshooting.md)
    
    Best practices on diagnosing common issues

10. **Azure Limitations** [(link)](./docs/91-quota-limitations.md)

    Learn about the limitations around the size of your cluster and the number of foreach jobs you can run in Azure.
   
## Additional Documentation
Read our [**FAQ**](./docs/92-faq.md) for known issues and common questions.

## Next Steps

For more information, please visit [our documentation](./docs/README.md).
