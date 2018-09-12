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
