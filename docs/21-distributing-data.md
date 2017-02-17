# Distributing Data

The doAzureParallel package lets you distribute the data you have in your R session across your Azure pool.

As long as the data you wish to distribute can fit in-memory on your local machine as well as in the memory of the VMs in your pool, the doAzureParallel package will be able to manage the data.

```R
my_data_set <- data_set
number_of_iterations <- 10

results <- foreach(i = 1:number_of_iterations) %dopar% {
  runAlgorithm(my_data_set)
}
```

## Chunking Data

A common scenario would be to chunk your data accross the pool so that your R code is running agaisnt a single chunk. In doAzureParallel, we help you achieve this by iterating through your chunks so that each chunk is mapped to an interation of the distributed *foreach* loop.

```R
chunks <- split(<data_set>, 10)

results <- foreach(chunk = iter(chunks)) %dopar% {
  runAlgorithm(chunk)
}
```

