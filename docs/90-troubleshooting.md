# Debugging and Troubleshooting

## Debugging Tools

### Using %do% vs %dopar%
When developing at scale, it is always recommended that you test and debug your code locally first. Switch between *%dopar%* and *%do%* to toggle between running in parallel on Azure and running in sequence on your local machine.

```R 
# run your code sequentially on your local machine
results <- foreach(i = 1:number_of_iterations) %do% { ... }

# use the doAzureParallel backend to run your code in parallel across your Azure cluster
results <- foreach(i = 1:number_of_iterations) %dopar% { ... }
```

### Setting Verbose Mode to Debug

To debug your doAzureParallel jobs, you can set the package to operate on *verbose* mode:

```R
# turn on verbose mode
setVerbose(TRUE)

# turn off verbose mode
setVerbose(FALSE)
```
### Setting HttpTraffic to Debug

To debug your doAzureParallel jobs, you can set the package to operate on *verbose* mode:

```R
# turn on verbose mode
setVerbose(TRUE)

# turn off verbose mode
setVerbose(FALSE)
```
### Viewing files from Azure Storage
In every foreach run, the job will push its logs into Azure Storage that can be fetched by the user. For more information on reading log files, check out [managing storage](./41-managing-storage-via-R.md).

By default, when wait is set to TRUE, job and its result is automatically deleted after the run is completed. To keep the job and its result for investigation purpose, you can set a global environment setting or specify an option in foreach loop to keep it.

```R
# This will set a global setting to keep job and its result after run is completed. 
setAutoDeleteJob(FALSE)

# This will keep job and its result at each job level after run is completed.
options <- list(autoDeleteJob = FALSE)
foreach::foreach(i = 1:4, .options.azure = opt) %dopar% { ... }
```

### Viewing files directly from compute node
Cluster setup logs are not persisted. `getClusterFile` function will fetch any files including stdout and stderr log files in the cluster. This is particularly useful for users that utilizing [customize script](./30-customize-cluster.md) on their nodes and installing specific [packages](./20-package-management.md).

Cluster setup files include:
File name | Description
--- | ---
stdout.txt | Contains the standard output of files. This includes any additional logging done during cluster setup time
stderr.txt | Contains the verbose and error logging during cluster setup

```R
# This will download stderr.txt directly from the cluster. 
getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z", "stderr.txt", downloadPath = "pool-errors.txt")
```

When executing long-running jobs, users might want to check the status of the job by checking the logs. The logs and results are not uploaded to Azure Storage until tasks are completed. By running `getJobFile` function, the user is able to view log files in real time.

Job-related files include:
File name | Description
--- | ---
stdout.txt | Contains the standard output of files. This includes any additional logging done during job execution
stderr.txt | Contains the verbose and error logging during job execution
[jobId]-[taskId].txt | Contains R specific output thats produced by the foreach iteration

```R
# Allows users to read the stdout file in memory 
stdoutFile <- getJobFile("job20170824195123", "job20170824195123-task1", "stdout.txt")
cat(stdoutFile)
```

## Common Scenarios

## My job failed but I can't find my job and its result?
if you set wait = TRUE, job and its result is automatically deleted, to keep them for investigation purpose, you can set global option using setAutoDeleteJob(FALSE), or use autoDeleteJob option at foreach level.

### After creating my cluster, my nodes go to a 'startTaskFailed' state. Why?
The most common case for this is that there was an issue with package installation or the custom script failed to run. To troubleshoot this you can simply download the output logs from the node.

Node IDs are prepended with tvm. Lets say that when spinning up your cluster, the following 2 nodes failed while running the start task:

tvm-769611554_1-20170912t183413z-p
tvm-769611554_2-20170912t183413z-p

The following steps show how to debug this by pulling logs off of the nodes:

```r
cluster <- makeCluster('myConfig.json')

# Often you will see an error printed to the console such as:
#  The following 2 nodes failed while running the start task:
# tvm-769611554_1-20170912t183413z-p
# tvm-769611554_2-20170912t183413z-p

# If you do not get this message, you can list the Nodes in the cluster
# Look for the node$id values, for example:
# $value[[1]]$id
# [1] "tvm-769611554_1-20170912t183413z-p"
rAzureBatch::listPoolNodes('<CLUSTER_ID>')

# Get standard error file
getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z", "stderr.txt", downloadPath = "pool-errors.txt")

# Get standard log file
getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z", "stderr.txt", downloadPath = "pool-logs.txt")
```

The log files will contain any setup and error information that occured while the node was setting up.

### My job never starts running. How can I troubleshoot this issue?
This is often caused by the node not being in a good state. Take a look at the state of the nodes in the cluster to see if any of them are have an error or are in a failed state. If the node is in a startTaskFailed state follow the instructions above. If the node is in an 'unknown' or 'unusable' state you may need to manually reboot the node.

```r
# reboot a node
# your node_id typically looks something like this 'tvm-1170471534_2-20170829t072146z'
rAzureBatch::rebootNode('<my_cluster_id>', '<my_node_id>')
```

When rebooting the node, the necessary scripts and your command line changes will run to get your node setup to work as part of your doAzureParallel cluster.

### Why do some packages fail with the following error?
```sh
ERROR: compilation failed for package '__PACKAGE__'
* removing '/usr/lib64/microsoft-r/3.3/lib64/R/library/__PACKAGE__'
```

This issue is due to certain compiler flags not available in the default version of R used by doAzureParallel. In order to get around this issue you can add the following commands to the [command line](./30-customize-cluster.md#running-commands-when-the-cluster-starts) in the cluster configuration to make sure R has the right compiler flags set.

```json
"commandLine": [
    "r_conf=/usr/lib64/microsoft-r/3.3/lib64/R/etc/Makeconf",
    "sed -i 's/CXX1X = /CXX1X = gcc/g' $r_conf",
    "sed -i 's/CXX1XFLAGS = /CXX1XFLAGS = -fpic/g' $r_conf",
    "sed -i 's/CXX1XSTD =/CXX1XSTD = -std=c++11/g' $r_conf"
    ]
```

### Why do some of my packages install an older version of the package instead of the latest?
Since doAzureParallel uses Microsoft R Open version 3.3 as the default version of R, it will automatically try to pull package from [MRAN](https://mran.microsoft.com/) rather than CRAN. This is a big benefit when wanting to use a constant version of a package but does not always contain references to the latest versions. To use a specific version from CRAN or a different MRAN snapshot date, use the [command line](./30-customize-cluster.md#running-commands-when-the-cluster-starts) in the cluster configuration to manually install the packages you need.
