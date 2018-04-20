# SAS Resource Files

The following sample show show to transfer data using secure [SAS blob tokens](https://docs.microsoft.com/en-us/azure/storage/common/storage-dotnet-shared-access-signature-part-1). This allows secure transfer to and from cloud storage from your local computer or the nodes in the cluster.

As part of this example you will see how to create a secure write-only SAS and upload files to the cloud. Then create a secure read-only SAS and download those files to the nodes in your cluster. Finally, you will enumerate the files on each node in the cluster and can operate against them however you choose.

Make sure to replace the storage account you want to use. The the storage account listed in the credentials.json file must be used for this sample to work.

```R
storageAccountName <- "<YOUR_STORAGE_ACCOUNT>"
```