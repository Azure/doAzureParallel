# Distributing Data

The doAzureParallel package lets you distribute the data you have in your R session across your Azure pool.

As long as the data you wish to distribute can fit in-memory on your local machine as well as in the memory of the VMs in your pool, the doAzureParallel package will be able to manage the data.

```R
my_data_set <- data_set
number_of_iterations <- 10

results <- foreach(i = 1:number_of_iterations) %dopar% {
  runAlgorithm(my_data_set)
}
```

## Chunking Data

A common scenario would be to chunk your data accross the pool so that your R code is running agaisnt a single chunk. In doAzureParallel, we help you achieve this by iterating through your chunks so that each chunk is mapped to an interation of the distributed *foreach* loop.

```R
chunks <- split(<data_set>, 10)

results <- foreach(chunk = iter(chunks)) %dopar% {
  runAlgorithm(chunk)
}
```

## Pre-loading Data Into The Cluster

Some workloads may require data pre-loaded into the cluster as soon as the cluster is provisioned. doAzureParallel supports this with the concept of a *resource file* - a file that is automatically downloaded to each node of the cluster after the cluster is created.

**NOTE** The default setting for storage containers is _private_. You can either use a SAS (link to sas docs) to access the resources or [make the container public using the Azure Portal](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-manage-access-to-resources).

**IMPORTANT** Public storage containers can be ready by anyone who knows the URL. We do not recommend storing any private or sensitive information in public storage containers!

Here's an example that uses data stored in a public location on Azure Blob Storage:

```R
# define where to download data from
resource_files = list(
    list(
        url = "https://<accountname>.blob.core.windows.net/<container>/2010.csv",
        filePath = "2010.csv"
    ),
    list(
        url = "https://<accountname>.blob.core.windows.net/<container>/2011.csv",
        filePath = "2011.csv"
    )
)

# add the parameter 'resourceFiles'
cluster <- makeCluster("creds.json", "cluster.json", resourceFiles = resource_files)

# when the cluster is provisioned, register the cluster as your parallel backend
registerDoAzureParallel(cluster)

# the preloaded files are located in the location: "$AZ_BATCH_NODE_STARTUP_DIR/wd"
listFiles <- foreach(i = 2010:2011, .combine='c') %dopar% {
    fileDirectory <- paste0(Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"), "/wd")
    return(list.files(fileDirectory))
}

# this will print out "2010.csv" and "2011.csv"
```
For more information on using resource files, take a look at this [sample](https://github.com/Azure/doAzureParallel/blob/master/samples/resource_files/resource_files_example.R).
