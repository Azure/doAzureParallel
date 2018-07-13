### Error Handling
The errorhandling option specifies how failed tasks should be evaluated. By default, the error handling is 'stop' to ensure users' can have reproducible results. If a combine function is assigned, it must be able to handle error objects.

Error Handling Type | Description
--- | ---
stop | The execution of the foreach will stop if an error occurs
pass | The error object of the task is included the results
remove | The result of a failed task will not be returned 

```R 
# Remove R error objects from the results
res <- foreach::foreach(i = 1:4, .errorhandling = "remove") %dopar% {
  if (i == 2 || i == 4) {
    randomObject
  }
  
  mean(1:3)
}

#> res
#[[1]]
#[1] 2
#
#[[2]]
#[1] 2
```

```R 
# Passing R error objects into the results 
res <- foreach::foreach(i = 1:4, .errorhandling = "pass") %dopar% {
  if (i == 2|| i == 4) {
    randomObject
  }
  
  sum(i, 1)
}

#> res
#[[1]]
#[1] 2
#
#[[2]]
#<simpleError in eval(expr, envir, enclos): object 'randomObject' not found>
#
#[[3]]
#[1] 4
#
#[[4]]
#<simpleError in eval(expr, envir, enclos): object 'randomObject' not found>
```
