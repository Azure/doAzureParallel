# Managing blob files in Azure Storage
## Accessing your storage files through R
Without installing Azure Storage Explorer or using the Azure Portal, users can access their resources through doAzureParallel wrapper functions around rAzureBatch's API calls.

A storage container provides a grouping of a set of blobs. An account can contain an unlimited number of storage containers. A storage container can store an unlimited number of blobs. _More information regarding Azure storage container naming requirements [here](https://docs.microsoft.com/en-us/rest/api/storageservices/naming-and-referencing-containers--blobs--and-metadata)_

Blob is a storage file of any type and size. The Azure Storage Blob service uses a flat storage scheme, not hierachical scheme.

_More information on general knowledge of Azure Storage Blob service [here](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-dotnet-how-to-use-blobs#what-is-blob-storage)_

### Viewing storage files and storage containers
By default, the new storage container is private, meaning you will need to use your storage access key from storage via 'setCredentials' function. 
``` R
containers <- listStorageContainers()
View(containers)
```
Job-related prefixes for listing storage files include:
Prefix | Description
--- | ---
stdout | Contains the standard output of files. This includes any additional logging done during job execution
stderr | Contains the verbose and error logging during job execution
logs | Contains the foreach R standard output
results | Contains the foreach results as RDS files
To list the blobs in the storage container, first you will need a storage container name. This will list the blobs and the subdirectories within it. The storage container name is added as an attribute for quick reference when adding storage files and deleting storage files.
``` R
# List all of the blobs that start with logs in container 'job20170824195123'
files <- listStorageFiles("job20170824195123", prefix = "logs")
View(files)

# Filtering on name client side
files[files$FilePath == 'stderr/job20170824195123-task2-stderr.txt',]
```

### Deleting storage files and storage containers
To delete a storage container, a storage container name is required. 
``` R
deleteStorageContainer(containers[1,]$Name)
```
Using the previous example 'files' object to delete the storage file. 
``` R
# Delete storage file
deleteStorageFile(attributes(files)$containerName, files[3,]$FilePath)
```
