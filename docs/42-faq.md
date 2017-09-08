# FAQ

## Is doAzureParallel available on CRAN?
No. At the moment doAzureParallel is only being distributed via GitHub.

## Which version of R does doAzureParallel use?
By default, doAzureParallel uses Microsoft R Open 3.3.

## Does doAzureParallel support a custom version of R?
No. We are looking into support for different versions of R as well as custom version of R but that is not supported today.

## How much does doAzureParallel cost?
doAzureParallel is built on top of the Azure Batch service. You are billed by the minute for each node that is assigned to your cluster. You can find more infomration on Azure Batch pricing [here](https://azure.microsoft.com/en-us/pricing/details/batch/).

## Does doAzureParallel support custom pacakge installations?
Yes. The 'commandLine' feature in the cluster configuration enables running custom commands on each node in the cluster before it is ready to do work. Leverage this mechanism to do any custom installations such as installing custom software or mounting network drives.

## Does doAzureParallel work with Windows-specific packages?
No. doAzureParallel is built on top of the Linux CentOS distribution and will not work with Windows-specific packages.

