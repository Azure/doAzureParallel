registerDoAzureParallel <- function(config){
  setDoPar(fun = .doAzureParallel, data = list(config = config), info = .info)
}

.info <- function(data, item){
  switch(item,
         workers = workers(data),
         name = "doAzureParallel",
         version = packageDescription("doAzureParallel", fields = "Version"),
         NULL)
}

.makeDotsEnv <- function(){
  list(...)
  function() NULL
}

workers <- function(data){
  id <- data$config$batchAccount$pool$name
  pool <- getPool(id)

  if(data$config$settings$verbose){
    getPoolWorkers(id)
  }

  return(pool$currentDedicated)
}

getparentenv <- function(pkgname) {
  parenv <- NULL

  # if anything goes wrong, print the error object and return
  # the global environment
  tryCatch({
    # pkgname is NULL in many cases, as when the foreach loop
    # is executed interactively or in an R script
    if (is.character(pkgname)) {
      # load the specified package
      if (require(pkgname, character.only=TRUE)) {
        # search for any function in the package
        pkgenv <- as.environment(paste0('package:', pkgname))
        for (sym in ls(pkgenv)) {
          fun <- get(sym, pkgenv, inherits=FALSE)
          if (is.function(fun)) {
            env <- environment(fun)
            if (is.environment(env)) {
              parenv <- env
              break
            }
          }
        }
        if (is.null(parenv)) {
          stop('loaded ', pkgname, ', but parent search failed', call.=FALSE)
        } else {
          message('loaded ', pkgname, ' and set parent environment')
        }
      }
    }
  },
  error=function(e) {
    cat(sprintf('Error getting parent environment: %s\n',
                conditionMessage(e)))
  })

  # return the global environment by default
  if (is.null(parenv)) globalenv() else parenv
}

.isError <- function(x){
  ifelse(inherits(x, "simpleError") || inherits(x, "try-error"), 1, 0)
}

.getSimpleErrorMessage <- function(e) {
  print(e$message)
  e$message
}
.getSimpleErrorCall <- function(e) deparse(e$call)

.doAzureParallel <- function(obj, expr, envir, data){
  stopifnot(inherits(obj, "foreach"))

  it <- iter(obj)
  argsList <- as.list(it)

  chunkSize <- 1
  jobTimeout <- 60 * 60 * 24

  if(!is.null(obj$options$azure$timeout)){
    jobTimeout <- obj$options$azure$timeout
  }

  exportenv <- tryCatch({
    qargs <- quote(list(...))
    args <- eval(qargs, envir)
    environment(do.call(.makeDotsEnv, args))
  },
  error=function(e) {
    new.env(parent=emptyenv())
  })
  noexport <- union(obj$noexport, obj$argnames)
  getexports(expr, exportenv, envir, bad = noexport)
  vars <- ls(exportenv)

  export <- unique(obj$export)
  ignore <- intersect(export, vars)
  if(length(ignore) > 0){
    export <- setdiff(export, ignore)
  }

  # add explicitly exported variables to exportenv
  if (length(export) > 0) {
    if (obj$verbose)
      cat(sprintf('explicitly exporting variables(s): %s\n',
                  paste(export, collapse=', ')))

    for (sym in export) {
      if (!exists(sym, envir, inherits=TRUE))
        stop(sprintf('unable to find variable "%s"', sym))
      val <- get(sym, envir, inherits=TRUE)
      if (is.function(val) &&
          (identical(environment(val), .GlobalEnv) ||
           identical(environment(val), envir))) {
        # Changing this function's environment to exportenv allows it to
        # access/execute any other functions defined in exportenv.  This
        # has always been done for auto-exported functions, and not
        # doing so for explicitly exported functions results in
        # functions defined in exportenv that can't call each other.
        environment(val) <- exportenv
      }
      assign(sym, val, pos=exportenv, inherits=FALSE)
    }
  }

  assign('expr', expr, .doAzureBatchGlobals)
  assign('exportenv', exportenv, .doAzureBatchGlobals)
  assign('packages', obj$packages, .doAzureBatchGlobals)

  time <- format(Sys.time(), "%Y%m%d%H%M%OS3", tz = "GMT")
  id <-  sprintf("%s%s",
                 "job",
                 time)


  retryCounter <- 0
  maxRetryCount <- 5
  while(retryCounter < maxRetryCount){
    
    # try to submit the job. We may run into naming conflicts. If so, try again
    tryCatch({
      retryCounter <- retryCounter + 1
      addJob(id, config = data$config, packages = obj$packages)
    },
    error=function(e) {
      if (retryCounter == maxRetryCount) {
        cat(sprintf('Error creating job: %s\n',
                  conditionMessage(e)))
      }

      time <- format(Sys.time(), "%Y%m%d%H%M%OS3", tz = "GMT")
      id <-  sprintf("%s%s",
                    "job",
                    time)
    })
  }

  print("Job Summary: ")
  job <- getJob(id)
  print(sprintf("Id: %s", job$id))

  chunkSize <- 1

  if(!is.null(obj$options$azure$chunkSize)){
    chunkSize <- obj$options$azure$chunkSize
  }

  if(!is.null(obj$options$azure$chunksize)){
    chunkSize <- obj$options$azure$chunksize
  }

  resourceFiles <- list()
  if(!is.null(obj$options$azure$resourceFiles)){
    resourceFiles <- obj$options$azure$resourceFiles
  }

  if(!is.null(obj$options$azure$resourcefiles)){
    resourceFiles <- obj$options$azure$resourcefiles
  }

  inputs <- FALSE
  if(!is.null(obj$options$azure$inputs)){
    storageCredentials <- getStorageCredentials()
    sasToken <- constructSas("2016-11-30", "r", "c", inputs, storageCredentials$key)

    assign("inputs", list(name = storageCredentials$name,
                          sasToken = sasToken),
           .doAzureBatchGlobals)
  }

  ntasks <- length(argsList)
  nout <- ceiling(ntasks / chunkSize)
  remainingtasks <- ntasks %% chunkSize

  startIndices <- seq(1, length(argsList), chunkSize)

  if(chunkSize > length(argsList)){
    endIndices <- seq(length(argsList), length(argsList))
  }
  else{
    endIndices <- seq(chunkSize, length(argsList), chunkSize)
  }

  minLength <- min(length(startIndices), length(endIndices))

  if(length(startIndices) > length(endIndices)){
    endIndices[length(startIndices)] <- ntasks
  }

  tasks <- lapply(1:length(endIndices), function(i){
    startIndex <- startIndices[i]
    endIndex <- endIndices[i]

    addTask(id,
            taskId = paste0(id, "-task", i),
            args = argsList[startIndex:endIndex],
            envir = .doAzureBatchGlobals,
            packages = obj$packages)

    return(paste0(id, "-task", i))
  })

  updateJob(id)

  i <- length(tasks) + 1
  r <- addTaskMerge(id,
             taskId = paste0(id, "-merge"),
             index = i,
             envir = .doAzureBatchGlobals,
             packages = obj$packages,
             dependsOn = tasks)

  waitForTasksToComplete(id, jobTimeout, progress = !is.null(obj$progress), tasks = nout + 1)

  results <- downloadBlob(id, paste0("result/", id, "-merge-result.rds"))

  failTasks <- sapply(results, .isError)

  numberOfFailedTasks <- sum(unlist(failTasks))

  if(numberOfFailedTasks > 0){
    .createErrorViewerPane(id, failTasks)
  }

  accumulator <- makeAccum(it)

  tryCatch(accumulator(results, seq(along = results)), error = function(e){
    cat('error calling combine function:\n')
    print(e)
  })

  # check for errors
  errorValue <- getErrorValue(it)
  errorIndex <- getErrorIndex(it)

  print(sprintf("Start Time: %s", job$executionInfo$startTime))
  startTime <- as.POSIXct(job$executionInfo$startTime, format="%FT%T", tz = "GMT")

  if(is.null(job$executionInfo$endTime)){
    endTime <- as.POSIXlt(Sys.time(), "UTC", "%FT%T")
    endTime <- paste0(strftime(endTime, "%FT%TZ"))
    print(sprintf("End Time: %s", endTime))
  }
  else{
    print(sprintf("End Time: %s", job$executionInfo$endTime))
    endTime <- as.POSIXct(job$executionInfo$endTime, format="%FT%T", tz = "GMT")
  }

  print(sprintf("Number of errors: %i", numberOfFailedTasks))

  deleteJob(id)

  if (identical(obj$errorHandling, 'stop') && !is.null(errorValue)) {
    msg <- sprintf('task %d failed - "%s"', errorIndex,
                   conditionMessage(errorValue))
    stop(simpleError(msg, call=expr))
  }
  else {
    getResult(it)
  }
}

.createErrorViewerPane <- function(id, failTasks){
  storageCredentials <- getStorageCredentials()

  sasToken <- constructSas("2016-11-30", "r", "c", id, storageCredentials$key)
  query <- generateSasUrl(sasToken)

  tempDir <- tempfile()
  dir.create(tempDir)
  htmlFile <- file.path(tempDir, paste0(id, ".html"))

  staticHtml <- "<h1>Errors:</h1>"
  for(i in 1:length(failTasks)){
    if(failTasks[i] == 1){
      stdoutFile <- sprintf("https://%s.blob.core.windows.net/%s/%s", storageCredentials$name, id, "stdout")
      stderrFile <- sprintf("https://%s.blob.core.windows.net/%s/%s", storageCredentials$name, id, "stderr")

      stdoutFile <- paste0(stdoutFile, "/", id, "-task", i, "-stdout.txt")
      stderrFile <- paste0(stderrFile, "/", id, "-task", i, "-stderr.txt")

      staticHtml <- paste0(staticHtml, 'Task ', i, ' | <a href="', paste0(stdoutFile, query),'">', "stdout.txt",'</a> |', ' <a href="', paste0(stderrFile, query),'">', "stderr.txt",'</a> <br/>')
    }
  }

  write(staticHtml, htmlFile)

  viewer <- getOption("viewer")
  if (!is.null(viewer)){
    viewer(htmlFile)
  }
}

getJobResult <- function(jobId = "", ...){
  args <- list(...)

  if(!is.null(args$container)){
    results <- downloadBlob(container, paste0("result/", jobId, "-merge-result.rds"))
  }
  else{
    results <- downloadBlob(jobId, paste0("result/", jobId, "-merge-result.rds"))
  }

  if(!is.null(args$pass) && args$pass){
    failTasks <- sapply(results, .isError)
  }

  return(results)
}
