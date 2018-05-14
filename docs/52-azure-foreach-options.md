## Azure-specific Optional Flags

| Flag Name        | Default           | Type | Meaning  |
  | ------------- |:-------------:| -----:| -----:|
  | chunkSize      | 1 | Integer | Groups the number of foreach loop iterations into one task and execute them in a single R session. Consider using the chunkSize option if each iteration in the loop executes very quickly.  |
  | maxTaskRetryCount | 3 |  Integer | The number of retries the task will perform. |
  | enableCloudCombine | TRUE | Boolean | Enables the merge task to be performed  |
  | wait | TRUE      | Boolean | Set the job to a non-blocking state. This allows you to perform R tasks while waiting for your results to be complete. |
  | autoDeleteJob | TRUE | Boolean |   Deletes the job metadata and result after the foreach loop has been executed. |
  | job | The time of job creation |  Character | The name of you job. This name will appear in the RStudio console, Azure Batch, and Azure Storage. |

## Azure-specific Package Installation Flags

  | Flag Name        | Default           | Type | Meaning  |
  | ------------- |:-------------:| -----:| -----:|
  | github      | c() | Vector | A vector of github package names. The proper name format of installing a github package is the repository address: username/repo[/subdir]   |
  | bioconductor      | c() | Vector | A vector of bioconductor package names |
  


### Bypassing merge task 

Skipping the merge task is useful when the tasks results don't need to be merged into a list. To bypass the merge task, you can pass the *enableMerge* flag to the foreach object:

```R
# Enable merge task
foreach(i = 1:3, .options.azure = list(enableMerge = TRUE))

# Disable merge task
foreach(i = 1:3, .options.azure = list(enableMerge = FALSE))
```
Note: User defined functions for the merge task is on our list of features that we are planning on doing.

