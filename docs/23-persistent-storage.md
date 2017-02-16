# Persistent Storage

When executing long-running jobs, users may not want to keep their session open to wait for results to be returned. 

The doAzureParallel package automatically stores the results of the *foreach* loop in a Azure Storage account - this means that when the user exits the session, their results won't be lost. Instead, users can simply pull the results down from Azure at any time and load it into their current session.

To do so, users need to keep track of **job ids**. Each *foreach* loop is considered a *job* and is assigned an unique ID. The job id is returned to the user after the *foreach* loop is executed.

When the user returns and begin a new session, the user can pull down the results from their job.

```R
my_job_id <- "job123456789"
results <- GetJobResult(my_job_id)
```
