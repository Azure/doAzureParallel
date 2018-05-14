[![Build Status](https://travis-ci.org/Azure/doAzureParallel.svg?branch=master)](https://travis-ci.org/Azure/doAzureParallel)
# doAzureParallel

## Introduction

The *doAzureParallel* package is a parallel backend for the widely popular *foreach* package. With *doAzureParallel*, each iteration of the *foreach* loop runs in parallel on an Azure Virtual Machine (VM), allowing users to scale up their R jobs to tens or hundreds of machines.

*doAzureParallel* is built to support the *foreach* parallel computing package. The *foreach* package supports parallel execution - it can execute multiple processes across some parallel backend. With just a few lines of code, the *doAzureParallel* package helps create a cluster in Azure, register it as a parallel backend, and seamlessly connects to the *foreach* package.

NOTE: The terms *pool* and *cluster* are used interchangably throughout this document.

## Notable Features
- Ability to use low-priority VMs for an 80% discount [link](./docs/31-vm-sizes.md#low-priority-vms)
-  

## Dependencies

- R (>= 3.3.1)
- httr (>= 1.2.1)
- rjson (>= 0.2.15)
- RCurl (>= 1.95-4.8)
- digest (>= 0.6.9)
- foreach (>= 1.4.3)
- iterators (>= 1.0.8)
- bitops (>= 1.0.5)

## Setup 

1) Install doAzureParallel directly from Github.

```R
# install the package devtools
install.packages("devtools")

# install the doAzureParallel and rAzureBatch package
devtools::install_github("Azure/rAzureBatch")
devtools::install_github("Azure/doAzureParallel")
```

2) Create an doAzureParallel's credentials file
``` R
library(doAzureParallel)
generateCredentials.json("credentials.json")
```

3) Login or register for an Azure Account, navigate to [Azure Cloud Shell](https://shell.azure.com)

``` sh 
wget -q https://raw.githubusercontent.com/Azure/doAzureParallel/master/account_setup.sh &&
chmod 755 account_setup.sh &&
/bin/bash account_setup.sh
```
4) Follow the on screen prompts to create the necessary Azure resources and copy the output into your credentials file. For more information, see [Getting Started Scripts](./docs/02-getting-started-script.md).

To Learn More:
- [Azure Account Requirements for doAzureParallel](./docs/04-azure-requirements.md)

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

## Table of Contents 
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
