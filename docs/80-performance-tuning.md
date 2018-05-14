
# Performance Tuning

## Parallelizing Cores
If you are using a VM size that have more than one core, you may want your R code running on all the cores in each VM. 

There are two methods to do this today:


### MaxTasksPerNode
MaxTasksPerNode is a property that tells Azure how many tasks it should send to each node in your cluster.

The maxTasksPerNode property can be configured in the configuration json file when creating your Azure pool. By default, we set this equal to 1, meaning that only one iteration of the foreach loop will execute on each node at a time. However, if you want to maximize the different cores in your cluster, you can set this number up to four times (4X) the number of cores in each node. For example, if you select the VM Size of Standard_F2 which has 2 cores, then can set the maxTasksPerNode property up to 8. 

However, because R is single threaded, we recommend setting the maxTasksPerNode equal to the number of cores in the VM size that you selected. For example, if you select a VM Size of Standard_F2 which has 2 cores, then we recommend that you set the maxTasksPerNode property to 2. This way, Azure will know to run each iteration of the foreach loop on each core (as opposed to each node).

Here's an example of how you may want to set your JSON configuration file:
```javascript
{
  ...
  "vmSize": "Standard_F2",
  "maxTasksPerNode": 2
  ...
}
```

### Nested doParallel 
To take advantage of all the cores on each node, you can nest a *foreach* loop using *doParallel* package inside the outer *foreach* loop that uses doAzureParallel. 

The *doParallel* package can detect the number of cores on a computer and parallelizes each iteration of the *foreach* loop across those cores. Pairing this with the doAzureParallel package, we can schedule work to each core of each VM in the pool.

```R

# register your Azure pool as the parallel backend
registerDoAzureParallel(pool)

# execute your outer foreach loop to schedule work to the pool
number_of_outer_iterations <- 10
results <- foreach(i = 1:number_of_outer_iterations, .packages='doParallel') %dopar% {

  # detect the number of cores on the VM
  cores <- detectCores()
  
  # make your 'cluster' using the nodes on the VM
  cl <- makeCluster(cores)
  
  # register the above pool as the parallel backend within each VM
  registerDoParallel(cl)
  
  # execute your inner foreach loop that will use all the cores in the VM
  number_of_inner_iterations <- 20
  inner_results <- foreach(j = 1:number_of_inner_iterations) %dopar% {
    runAlgorithm()
  }
  
  return(inner_results)
}
```

## Using the 'chunkSize' option

doAzureParallel also supports custom chunk sizes. This option allows you to group iterations of the foreach loop together and execute them in a single R session.

```R
# set the chunkSize option
opt <- list(chunkSize = 3)
results <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar% { ... }
```

You should consider using the chunkSize if each iteration in the loop executes very quickly.

If you have a static cluster and want to have a single chunk for each worker, you can compute the chunkSize as follows:

```R
# compute the chunk size
cs <- ceiling(number_of_iterations / getDoParWorkers())

# run the foreach loop with chunkSize optimized
opt <- list(chunkSize = cs)
results <- foreach(i = 1:number_of_iterations, .options.azure = opt) %dopar% { ... }
```
