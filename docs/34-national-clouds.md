# Configuration for national clouds

doAzureParallel is configured to run in public Azure cloud by default. To run workloads in national clouds, configure endpoint suffix for storage account in the cluster config which tells doAzureParallel which national cloud environment the storage account resides.

EndpointSuffix is the last part of the connection string shown in the Storage Account Access keys blade from Azure portal. The possible values usually are:

Azure public cloud: core.windows.net
Azure China cloud: core.chinacloudapi.cn
Azure US government cloud: core.usgovcloudapi.net
Azure German cloud: core.cloudapi.de

The value may be different if a DNS redirect is used, so it is better to double check its value on Storage Account Access keys blade.

Below is a sample of credential config with endpoint suffix specified:

```R
{ 
  "batchAccount": {
    "name": <Azure Batch Account Name>,
    "key": <Azure Batch Account Key>,
    "url": <Azure Batch Account URL>
  },
  "storageAccount": {
    "name": <Azure Storage Account Name>,
    "key": <Azure Storage Account Key>,
    "endpointSuffix": <Azure Storage Account Endpoint Suffix>
  },
  "githubAuthenticationToken": {}
}
```