# Getting logs without Azure Portal
## Viewing files from Azure Storage
In every foreach run, the job will push its logs into Azure Storage that can be fetched by the user. For more information on reading log files, check out [managing storage](./41-managing-storage-via-R.md). 

## Viewing files directly from compute node
Logs on a cluster node are not persisted through Azure Storage. `getClusterFile` function will fetch any files including stdout and stderr log files in the cluster. This is particularly useful for users that utilizing [customize script](./30-customize-cluster.md) on their nodes and installing specific [packages](./20-package-management.md).

```R
# This will download stderr.txt directly from the cluster. 
getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z", "stderr.txt", downloadPath = "pool-errors.txt")
```

When executing long-running jobs, users might want to check the status of the job by checking the logs. The logs and results are not uploaded to Azure Storage until tasks are completed. By running `getJobFile` function, the user is able to view log files in real time.

```R
# Allows users to read the stdout file in memory 
stdoutFile <- getJobFile("job20170824195123", "job20170824195123-task1", "stdout.txt")
cat(stdoutFile)
```
