# Parallelizing Cores

Depending on the VM size you select, you may want your R code running on all the cores in each VM. To do this, we recommend nesting a Foreach loop using *doParallel* package inside the outer Foreach loop that uses doAzureParallel. 

The *doParallel* package can detect the number of cores on a computer and parallelizes each iteration of the foreach loop across those cores. Pairing this with the doAzureParallel package, we can schedule work to each core of each VM in the pool.

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
  
  # register the above cluster as the parallel backend within each VM
  registerDoParallel(cl)
  
  # execute your inner foreach loop that will use all the cores in the VM
  number_of_inner_iterations <- 20
  inner_results <- foreach(j = 1:number_of_inner_iterations) %dopar% {
    runAlgorithm()
  }
  
  return(inner_results)
}
```
