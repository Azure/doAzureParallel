# Job Management and Asynchronous Jobs
The doAzureParallel package allows you to manage long running jobs easily. There are 2 ways to run a job:
- Synchronous
- Asynchronous

Long-running job should be run in non-interactive and asynchronous mode.

doAzureParallel also helps you manage your jobs so that you can run many jobs at once while managing it through a few simple methods.

```R 
# List your jobs:
getJobList()

# Get your job by job id:
getJob(jobId = 'unique_job_id', verbose = TRUE)
```

This will also let you run *long running jobs* easily.

With long running jobs, you will need to keep track of your jobs as well as set your job to a non-blocking state. You can do this with the *.options.azure* options:

```R
# set the .options.azure option in the foreach loop 
opt <- list(job = 'unique_job_id', wait = FALSE)

# NOTE - if the option wait = FALSE, foreach will return your unique job id
job_id <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar % { ... }

# get back your job results with your unique job id
results <- getJobResult(job_id)
```

Finally, you may also want to track the status of jobs by state (active, completed etc):

```R
# List jobs in completed state:
filter <- list()
filter$state <- c("active", "completed")
jobList <- getJobList(filter)
View(jobList)
```

You can learn more about how to execute long-running jobs [here](./docs/72-persistent-storage.md). 

With long-running jobs, you can take advantage of Azure's autoscaling capabilities to save time and/or money. Learn more about autoscale [here](./docs/32-autoscale.md).

## Configuring an asynchronous job
You can configure a job to run asynchronously by specifying wait = FALSE in job options:

```R
  options <- list(wait = FALSE)
  jobId <- foreach(i = 1:number_of_iterations, .options.azure = options) %dopar% { ... }
```
The returned value is the job Id associated with the foreach loop. Use this returned value you can get job status and job result.

You can optionally specify the job Id in options as shown below:
```R
  options <- list(wait = FALSE, job = 'myjob')
  foreach(i = 1:number_of_iterations, .options.azure = options) %dopar% { ... }
```

## Listing jobs
You can list all jobs currently running in your account by running:

``` R
  getJobList()
```

Example output:
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

You can also filter job list by job state such as active or completed
```R
  filter <- filter <- list()
  filter$state <- c("active", "completed")
  getJobList(filter)
```

## Viewing a Job

getJob returns job metadata, such as chunk size, whether cloud combine is enabled, and packages specified for the job, it also returns task counts in different state

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

  job state: completed
```


## Retrieving the Results

Once job is completed successfully, you can call getJobResult to retrieve the job result:

```R
  jobResult <- getJobResult(jobId)
```

### Deleting a Job

Once you get the job result, you can delete the job and its result. Please note deleteJob will delete the job at batch service and the storage container holding the job result.

```R
  deleteJob(jobId)
```

A [working sample](../samples/long_running_job/long_running_job.R) can be found in the samples directory.
