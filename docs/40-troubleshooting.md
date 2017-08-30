# Getting logs without Azure Portal
Logs on a cluster node are not persisted through Azure Storage. `getClusterLogs` function will fetch the boot up script that users use in [customize script](./30-customize-cluster.md) and [package installation](./20-package-management.md).

```R
# This call will fetch the stderr.txt file and save it as a text file named "pool-errors.txt"
getClusterLogs(cluster, "tvm-1170471534_2-20170829t072146z", type = "stderr", localPath = "abc.txt")
```

In every foreach run, the job will push its logs into Azure Storage that can be fetched by the user. Without using Azure Storage Explorer or Azure Portal, `getJobLogs` function will fetch logs via R. There are three types of log files in the foreach job. 

- "rlogs": These log files contain information about the expression that gets executed within the foreach. Errors related to R could be found here or in the stderr type depending on the issue.
- "stdout": Non R-output files will contain information about the job package installation and file uploads regarding the use of blobxfer. 
- "stderr": Any errors that are not related to R will be in this file. 

```R
# This call will fetch the task's R output file"
getJobLogs("job20170822055031", "job20170822055031-task1", type = "rlogs")
```
