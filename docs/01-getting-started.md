# Getting started

doAzureParallel requires a few resources to be created in Azure. These include a Batch account and a Storage account. These exist inside of a container called a Resource Group which is simply a wrapper for a collection of resources to provide simpler resource management in Azure. The Batch Account is used as the Clustering and Scheduling service. It will manage the cluster(s) of Virtual Machines in Azure. This includes health monitoring, healing failed VMs, auto scaling the cluster and scheduling work. The Storage Account is used to store data between your local R client and the cloud, as well as save the outputs of jobs running foreach using doAzureParallel.

Once you have generated your resources and have your credentials, use the information to authenticate from your foreach loop. Follow the instructions to create a [credentials file](../README.md#getting-started) or [authenticate from code](./33-programmatically-generate-config.md).

## Azure CLI

You can either download the [Azure CLI V2](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) or use Azure Cloud Shell. This example will show the steps to get started using the Azure Cloud Shell.

Open a broswer and navigate to [Azure Cloud Shell](https://shell.azure.com). Make sure you have selected a **Bash** shell and run the commands listed below.

```sh
# Download the required setup scripts
wget https://raw.githubusercontent.com/Azure/doAzureParallel/inst/getting-started/manage_account

# Create resources in West US (westus). You can find a list of locations by running
# 'az account list-locations --output table'
# Make sure to use the 'Name' field and not the 'DisplayName' field

# Create a resource group, batch account and storage account
/bin/sh manage_account create westus

# Get the keys needed for doAzureParallel
/bin/sh manage_account list-keys
```

These commands will create 3 objects in Azure automatically.
1. A Resource Group that will contain a collection of resources called 'doazureparallel'.
2. A Batch Account within the Resource Group called 'doazureparallelbatch'
3. A Storage Account withing the Resource Group called 'doazureparallelstorage'

You can change the default names by passing additional parameters into the manage_account script. More information is available by running the command below.
```sh
/bin/sh manage_account --help
```

## Azure Portal
You can manage all of your cloud resources using the [Azure Portal](http://portal.azure.com). The following section will walk you through creating the following resources via the portal:

- Azure Batch Account ([Create an Azure Batch Account in the Portal](https://docs.microsoft.com/en-us/azure/Batch/batch-account-create-portal))
- Azure Storage Account (this can be created with the Batch Account)

This information can also be found in the Azure Portal inside your Batch Account:

![Azure Batch Account in the Portal](../vignettes/doAzureParallel-azurebatch-instructions.PNG "Azure Batch Acccount in the Portal")

For your Azure Storage Account, we need to get:
- Storage Account Name
- Storage Account Access Key

This information can be found in the Azure Portal inside your Azure Storage Account:

![Azure Storage Account in the Portal](../vignettes/doAzureParallel-azurestorage-instructions.PNG "Azure Storage Acccount in the Portal")