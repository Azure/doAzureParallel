# Getting Started Script

The provided account setup script creates and configures all of the required Azure resources.

The script will create and configure the following resources:
- Resource group
- Storage account
- Batch account
- Azure Active Directory application and service principal if AAD authentication is used, default is shared key authentication

The script outputs all of the necessary information to use `doAzureParallel`, just copy the output into your credentials.json file created by doAzureParallel::generateCredentialsConfig(). 

## Usage

### Create credentials
Copy and paste the following into an [Azure Cloud Shell](https://shell.azure.com):
```sh
wget -q https://raw.githubusercontent.com/Azure/doAzureParallel/master/account_setup.sh &&
chmod 755 account_setup.sh &&
/bin/bash account_setup.sh
```
A series of prompts will appear, and you can set the values you desire for each field. Default values appear in brackets `[]` and will be used if no value is provided.
```
Azure Region [westus]:
Resource Group Name [doazp]:
Storage Account Name [doazpstorage]:
Batch Account Name [doazpbatch]:
```

following prompts will only show up when you use AAD auth by running
```sh
wget -q https://raw.githubusercontent.com/Azure/doAzureParallel/master/account_setup.sh &&
chmod 755 account_setup.sh &&
/bin/bash account_setup.sh serviceprincipal
```
```
Active Directory Application Name [doazpapp]:
Active Directory Application Credential Name [doazp]:
Service Principal Name [doazpsp]
```

Once the script has finished running you will see the following output:

For Shared Key Authentication (Default):

```
"sharedKey": {
  "batchAccount": {
    "name": "batchaccountname",
    "key": "batch account key",
    "url": "https://batchaccountname.region.batch.azure.com"
  },
  "storageAccount": {
    "name": "storageaccoutname",
    "key": "storage account key",
    "endpointSuffix": "core.windows.net"
  }
}
```

For Azure Active Directory Authentication:

```
"service_principal": {
    "tenant_id": "<AAD Diretory ID>"
    "client_id": "<AAD App Application ID>"
    "credential": "<AAD App Password>"
    "batch_account_resource_id": "</batch/account/resource/id>"
    "storage_account_resource_id": "</storage/account/resource/id>"
}
```

Copy the entire section to your `credentials.json`. If you do not have a `credentials.json` file, you can create one in your current working directory by running `doAzureParallel::generateCredentialsConfig()`.

### Delete resource group
Copy and paste the following into an [Azure Cloud Shell](https://shell.azure.com):
```sh
wget -q https://raw.githubusercontent.com/Azure/doAzureParallel/master/account_setup.sh &&
chmod 755 account_setup.sh &&
/bin/bash account_setup.sh deleteresourcegroup
```
Following prompt will appear, and you can set the resource group name, and all resources contained in the resource group will be deleted.
```
Resource Group Name:
