# FAQ

## Is doAzureParallel available on CRAN?
No. At the moment doAzureParallel is only being distributed via GitHub.

## Which version of R does doAzureParallel use?
By default, doAzureParallel uses _rocker/tidyverse:latest_, the latest R environment provided by the R Studio community pre-packaged with a large number of popular R packages.

## Does doAzureParallel support a custom version of R?
No. We are looking into support for different versions of R as well as custom versions of R but that is not supported today.

## How much does doAzureParallel cost?
doAzureParallel itself is free to use and is built on top of the Azure Batch service. You are billed by the minute for each node that is assigned to your cluster. You can find more infomration on Azure Batch pricing [here](https://azure.microsoft.com/en-us/pricing/details/batch/).

## Does doAzureParallel support custom package installations?
Yes. The [command line](./30-customize-cluster.md#running-commands-when-the-cluster-starts) feature in the cluster configuration enables running custom commands on each node in the cluster before it is ready to do work. Leverage this mechanism to do any custom installations such as installing custom software or mounting network drives.

## Does doAzureParallel work with Windows-specific packages?
No. doAzureParallel is built on top of the Linux Ubuntu distribution and will not work with Windows-specific packages.

## Why am I getting the error: could not find function "startsWith"?
doAzureParallel requires you to run R 3.3 or greater on you local machine.

## My job failed but I can't find my job and its result?
if you set wait = TRUE, job and its result is automatically deleted, to keep them for investigation purpose, you can set global option using setAutoDeleteJob(FALSE), or use autoDeleteJob option at foreach level.

## How do I cancel a job?
You can call terminateJob(jobId) to cancel a job.
