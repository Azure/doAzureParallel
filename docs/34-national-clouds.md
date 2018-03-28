# Configuration for national clouds

By default, doAzureParallel is configured to run in public Azure cloud, if you want to run workload in national clouds, you can configure endpoint suffix for storage account in cluster config, it tells doAzureParallel which national cloud environment the storage account resides.

EndpointSuffix is the last part of the Connection string shown in the Storage Account Access keys blade from Azure portal. The possible values usually are:

Azure public cloud: core.windows.net
Azure China cloud: core.chinacloudapi.cn
Azure US government cloud: core.usgovcloudapi.net
Azure German cloud: core.cloudapi.de

The value may be different if a DNS redirect is used, so better to double check its value on Storage Account Access keys blade.

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