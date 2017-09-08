## Debugging and Troubleshooting

### After creating my cluster, my nodes go to a 'startTaskFailed' state. Why?
The most common case for this is that there was an issue with package installation or the custom script failed to run. To troubleshoot this you can simply download the output logs from the node.

```r
cluster <- makeCluster('myConfig.json')
...
# Get standard error file
getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z", "stderr.txt", downloadPath = "pool-errors.txt")

# Get standard log file
getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z", "stderr.txt", downloadPath = "pool-errors.txt")
```

### My job never starts running. How can I troubleshoot this issue?
This is often caused by the node not being in a good state. Take a look at the state of the nodes in the cluster to see if any of there are and nodes in an error or failed state.

### Why do some packages fail with the following error?
```sh
ERROR: compilation failed for package '__PACKAGE__'
* removing '/usr/lib64/microsoft-r/3.3/lib64/R/library/__PACKAGE__'
```

This issue is due to certain compiler flags not available in the default version of R used by doAzureParallel. In order to get around this issue you can add the following commands to the command line in the cluster configuration to make sure R has the right compiler flags set.

```json
"commandLine": [
    "r_conf=/usr/lib64/microsoft-r/3.3/lib64/R/etc/Makeconf",
    "sed -i 's/CXX1X = /CXX1X = gcc/g' $r_conf",
    "sed -i 's/CXX1XFLAGS = /CXX1XFLAGS = -fpic/g' $r_conf",
    "sed -i 's/CXX1XSTD =/CXX1XSTD = -std=c++11/g' $r_conf"
    ]
```


### Why do some of my packages install an older version of the package instead of the latest?
Since doAzureParallel uses Microsoft R Open version 3.3 as the default version of R, it will automatically try to pull pacakge from [MRAN](https://mran.microsoft.com/) rather than CRAN. This is a big benefit when wanting to use a constant version of a package but does not always contain references to the latest versions. To use a specific version from CRAN or a different MRAN snapshot date, use the 'commandLine' in the cluster configuration to manually install the packages you need.

## Viewing files from Azure Storage
In every foreach run, the job will push its logs into Azure Storage that can be fetched by the user. For more information on reading log files, check out [managing storage](./41-managing-storage-via-R.md). 

## Viewing files directly from compute node
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
