# Persistent Storage

When executing long-running jobs, users may not want to keep their session open to wait for results to be returned. 

The doAzureParallel package automatically stores the results of the *foreach* loop in a Azure Storage account - this means that when the user exits the session, their results won't be lost. Instead, users can simply pull the results down from Azure at any time and load it into their current session.

Each *foreach* loop is considered a *job* and is assigned an unique ID. So, to pull down the results from Azure Storage, users need to keep track of their **job ids**. The job id is returned to the user immediately after the *foreach* loop is executed.

When the user is ready to view their results in a new session, the user use the following command:

```R
my_job_id <- "job123456789"
results <- GetJobResult(my_job_id)
```
