# Persistent Storage

When executing long-running jobs, users may not want to keep their R session open to wait for results to be returned. 

The doAzureParallel package automatically stores the results of the *foreach* loop in a Azure Storage account - this means that when an R session is terminated, the results of the foreach loop won't be lost. Instead, users can simply pull the results down from Azure at any time and load it into their current session.

Each *foreach* loop is considered a *job* and is assigned an unique ID. So, to get the results from Azure Storage, users need to keep track of their **job ids**. 

In order to set your job id, you can use the **.options.azure** option inside the foreach loop:

```R
# set the .options.azure option in the foreach loop
opt <- list(job = 'unique_job_id', wait = FALSE)
job_id <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar% { ... }
```

Inside the **.options.azure** option, you can set two parameters: *job* and *wait*. 

Set *job* to the unique job id you want to associate your foreach loop to. This string must be unique otherwise the package will throw an error. 

By default, *wait* is set to TRUE. This blocks the R session. By setting *wait* to FALSE, the foreach loop will not block the R session, and you can continue working. Setting *wait* to FALSE will also change the return object of the foreach loop. Instead of returning the results, foreach will return the unique job ID associated to the foreach loop.

## Getting results from storage

When the user is ready to get their results in a new session, the user uses the following command:

```R
my_job_id <- "my_unique_job_id"
results <- GetJobResult(my_job_id)
```

If the job is not completed, GetJobResult will return the state of your job. Otherwise, GetJobResult will return the results.

### Output Files
Batch will automatically handle your output files when the user assigns a file pattern and storage container url.

```R
# Pushing output files
storageAccount <- "storageAccountName"
outputFolder <- "outputs"

createContainer(outputFolder)
writeToken <- rAzureBatch::createSasToken("w", "c", outputFolder)
containerUrl <- rAzureBatch::createBlobUrl(storageAccount = storageAccount,
                                           containerName = outputFolder,
                                           sasToken = writeToken)

output <- createOutputFile("test-*.txt", containerUrl)

foreach(i = 1:3, .options.azure = list(outputFiles = list(output))) %dopar% {
  fileName <- paste0("test-", i, ".txt")
  file.create(fileName) 
  fileConn<-file(fileName)
  close(fileConn)
  NULL
}
```

The tasks in a foreach may produce files that have the same name. Because each task runs in its own context, these files don't conflict on the node's file system. However, when you upload files from multiple tasks to a shared storage container, you'll need to disambiguate files with the same name or else the last task that gets executed will be the output file that the user will see.

Our recommendation is users' supply file patterns with wildcards (*) in createOutputFile function. In order to differentiate results, we recommend appending a unique identification that can be assign to files in the foreach. For example, arguments in the foreach is a good way of identifying tasks outputs.

The filePattern property in createOutputFile supports standard filesystem wildcards such as * (for non-recursive matches) and 
** (for recursive matches).

Note: The foreach object always expects a value. We use NULL as a default value for the foreach to process the list of results. 

```R
# Bad practice
writeToken <- rAzureBatch::createSasToken("w", "c", outputFolder)
containerUrl <- rAzureBatch::createBlobUrl(storageAccount = storageAccount,
                                           containerName = outputFolder,
                                           sasToken = writeToken)

output <- createOutputFile("a.txt", containerUrl)

# The task output would be one of the three outputs instead of one output 
foreach(i = 1:3, .options.azure = list(outputFiles = list(output))) %dopar% {
  fileName <- paste0("a.txt")
  
  file.create(fileName) 
  fileConn<-file(fileName)
  writeLines(paste0(i), fileConn)
  close(fileConn)
  
  fileName
}
```
