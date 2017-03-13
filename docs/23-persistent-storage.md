# Persistent Storage

When executing long-running jobs, users may not want to keep their R session open to wait for results to be returned. 

The doAzureParallel package automatically stores the results of the *foreach* loop in a Azure Storage account - this means that when an R session is terminated, the results of the foreach loop won't be lost. Instead, users can simply pull the results down from Azure at any time and load it into their current session.

Each *foreach* loop is considered a *job* and is assigned an unique ID. So, to get the results from Azure Storage, users need to keep track of their **job ids**. 

In order to set your job id, you can use the **.options.azure** option inside the foreach loop:

```R
# set the .options.azure option in the foreach loop
job_id <- foreach(i = 1:number_of_iterations, .options.azure = list(job = 'unique_job_id', wait = FALSE)) %dopar% { ... }
```

Inside the **.options.azure** option, you can set two parameters: *job* and *wait*. 

Set *job* to the unique job id you want to associate your foreach loop to. This string must be unique otherwise the package will throw an error. 

By default, *wait* is set to TRUE. This blocks the R session. By setting *wait* to FALSE, the foreach loop will not block the R session, and you can continue working. Setting *wait* to FALSE will also change the return object of the foreach loop. Instead of returning the results, foreach will return the unique job ID associated to the foreach loop.

## Getting results from storage

When the user is ready to get their results in a new session, the user use the following command:

```R
my_job_id <- "my_unique_job_id"
results <- GetJobResult(my_job_id)
```

If the job is not completed, GetJobResult will return the state of your job. Otherwise, GetJobResult will return the results.
