# Managing blob files in Azure Storage
## Accessing your storage files through R
Without installing Azure Storage Explorer or using the Azure Portal, users can access their resources through doAzureParallel wrapper functions around rAzureBatch's API calls.

A container provides a grouping of a set of blobs. All blobs must be in a container. An account can contain an unlimited number of containers. A container can store an unlimited number of blobs. **Note** that the container name must be lowercase.

Blob is a storage file of any type and size. The Azure Storage Blob service uses a flat storage scheme, not hierachical scheme.

### Viewing storage files and storage containers
By default, the new container is private, meaning you will need to use your storage access key from storage via 'setCredentials' function. 
``` R
containers <- listStorageContainers()
View(containers)
```

To list the blobs in the container, first you will need a container name. This will list the blobs and the subdirectories within it. The container name is added as an attribute for quick reference when adding storage files and deleting storage files.
``` R
# List all of the blobs that start with logs in container 'job20170824195123'
files <- listStorageFiles("job20170824195123", prefix = "logs")
View(files)

# Filtering on name client side
files[files$FilePath == 'stderr/job20170824195123-task2-stderr.txt',]
```

### Deleting storage files and storage containers
To delete a container, a container name is required. 
``` R
deleteStorageContainer(containers[1,]$Name)
```
Using the previous example 'files' object to delete the storage file. 
``` R
# Delete storage file
deleteStorageFile(attributes(files)$containerName, files[3,]$FilePath)
```
