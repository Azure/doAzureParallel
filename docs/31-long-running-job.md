# Long Running Job Management

The doAzureParallel package allows you to manage long running jobs easily. There are 2 ways to run a job:
- Synchronous
- Asynchronous

Long running job should run in asynchronous mode.

## How to configure a job to run asynchronously
You can configure a job to run asynchronously by specifying wait = FALSE in job options:

```R
  options <- list(wait = FALSE)
  jobId <- foreach(i = 1:number_of_iterations, .options.azure = options) %dopar% { ... }
```
The returned value is the job ID associated with the foreach loop. Use this returned value you can get job status and job result.

## Get job status

getJob returns job metadata, such as chunk size, whether cloud combine is enabled, and packages specified for the job, it also returns task acount in different state

```R
  getJob(jobId)
  getJob(jobId, verbose = TRUE)

  sample output:
  --------------
  job metadata:
    chunkSize: 1
	enableCloudCombine: TRUE
	packages: httr

  tasks:
	active: 1
	running: 0
	completed: 5
		succeeded: 0
		failed: 5
	total: 6
```

## Get job list
You can use getJobList() to get a summary of all jobs.

```R
  getJobList()

  sample output:
  --------------
                  Id     State              Status FailedTasks TotalTasks
1              job11    active No tasks in the job           0          0
2  job20170714215517    active                 0 %           0          6
3  job20170714220129    active                 0 %           0          6
4  job20170714221557    active                84 %           4          6
5  job20170803210552    active                 0 %           0          6
6  job20170803212205    active                 0 %           0          6
7  job20170803212558    active                 0 %           0          6
8  job20170714211502 completed               100 %           5          6
9  job20170714223236 completed               100 %           0          6  
```

You can also filter job list by job state such as Active or Completed
```R
  filter <- filter <- list()
  filter$state <- c("active", "completed")
  getJobList(filter)
```

## Retrieve long running job result
Once job is completed successfully, you can call getJobResult to retrieve the job result:

```R
  jobResult <- getJobResult(jobId)
```

### Clean up

Once you get the job result, you can delete the job.
```R
  rAzureBatch::deleteJob(jobId)
```

A [working sample](../samples/long_running_job/long_running_job.R) can be found in the samples directory.
