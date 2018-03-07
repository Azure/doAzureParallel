#' The registerDoAzureParallel function is used to register
#' the Azure cloud-enabled parallel backend with the foreach package.
#'
#' @param cluster The cluster object to use for parallelization
#'
#' @examples
#' registerDoAzureParallel(cluster)
#' @export
registerDoAzureParallel <- function(cluster) {
  foreach::setDoPar(
    fun = .doAzureParallel,
    data = list(
      config = list(cluster$batchAccount, cluster$storageAccount),
      poolId = cluster$poolId,
      containerImage = cluster$containerImage
    ),
    info = .info
  )
}

.info <- function(data, item) {
  switch(
    item,
    workers = workers(data),
    name = "doAzureParallel",
    version = packageDescription("doAzureParallel", fields = "Version"),
    NULL
  )
}

.makeDotsEnv <- function(...) {
  list(...)
  function()
    NULL
}

workers <- function(data) {
  id <- data$poolId
  pool <- rAzureBatch::getPool(id)

  verboseFlag <- getOption("azureVerbose")
  if (!is.null(verboseFlag) && verboseFlag) {
    getPoolWorkers(id)
  }

  (pool$currentDedicatedNodes * pool$maxTasksPerNode) + (pool$currentLowPriorityNodes * pool$maxTasksPerNode)
}

.isError <- function(x) {
  ifelse(inherits(x, "simpleError") || inherits(x, "try-error"), 1, 0)
}

.getSimpleErrorMessage <- function(e) {
  print(e$message)
  e$message
}
.getSimpleErrorCall <- function(e)
  deparse(e$call)

#' Groups iterations of the foreach loop together per task.
#'
#' @param value The number of iterations to group
#'
#' @examples
#' setChunkSize(10)
#' @export
setChunkSize <- function(value = 1) {
  if (!is.numeric(value))
    stop("setChunkSize requires a numeric argument")

  value <- max(round(value), 1)

  assign("chunkSize", value, envir = .doAzureBatchGlobals)
}

#' Specify whether to delete job and its result after asychronous job is completed.
#'
#' @param value boolean of TRUE or FALSE
#'
#' @examples
#' setAutoDeleteJob(FALSE)
#' @export
setAutoDeleteJob <- function(value = TRUE) {
  if (!is.logical(value))
    stop("setAutoDeleteJob requires a boolean argument")

  assign("autoDeleteJob", value, envir = .doAzureBatchGlobals)
}

#' Apply reduce function on a group of iterations of the foreach loop together per task.
#'
#' @param fun The number of iterations to group
#' @param ... The arguments needed for the reduction function
#'
#' @export
setReduce <- function(fun = NULL, ...) {
  args <- list(...)

  if (missing(fun))
  {
    # Special case: defer assignment of the function until foreach is called,
    # then set it equal to the .combine function.
    return(assign("gather", TRUE, envir = .doAzureBatchGlobals))
  }

  # Otherwise explicitly set or clear the function
  if (!(is.function(fun) ||
        is.null(fun)))
    stop("setGather requires a function or NULL")

  assign("gather", fun, envir = .doAzureBatchGlobals)
  assign("gatherArgs", args, envir = .doAzureBatchGlobals)
}

#' Set the verbosity for calling httr rest api calls
#'
#' @param value Boolean value for turning on and off verbose mode
#'
#' @examples
#' setVerbose(TRUE)
#' @export
setVerbose <- function(value = FALSE) {
  if (!is.logical(value))
    stop("setVerbose requires a logical argument")

  options(azureVerbose = value)
}

#' Set the verbosity for calling httr rest api calls
#'
#' @param value Boolean value for turning on and off verbose mode
#'
#' @examples
#' setVerbose(TRUE)
#' @export
setHttpTraffic <- function(value = FALSE) {
  if (!is.logical(value))
    stop("setVerbose requires a logical argument")

  options(azureHttpTraffic = value)
}

.doAzureParallel <- function(obj, expr, envir, data) {
  stopifnot(inherits(obj, "foreach"))

  githubPackages <- eval(obj$args$github)
  bioconductorPackages <- eval(obj$args$bioconductor)

  # Remove special arguments, github and bioconductor, from args list
  if (!is.null(obj$args[["github"]])) {
    obj$args[["github"]] <- NULL
  }

  if (!is.null(obj$args[["bioconductor"]])) {
    obj$args[["bioconductor"]] <- NULL
  }

  storageCredentials <- rAzureBatch::getStorageCredentials()

  it <- iterators::iter(obj)
  argsList <- as.list(it)

  chunkSize <- 1
  jobTimeout <- 60 * 60 * 24

  if (!is.null(obj$options$azure$timeout)) {
    jobTimeout <- obj$options$azure$timeout
  }

  exportenv <- tryCatch({
    qargs <- quote(list(...))
    args <- eval(qargs, envir)
    environment(do.call(.makeDotsEnv, args))
  },
  error = function(e) {
    new.env(parent = emptyenv())
  })
  noexport <- union(obj$noexport, obj$argnames)
  foreach::getexports(expr, exportenv, envir, bad = noexport)
  vars <- ls(exportenv)

  export <- unique(obj$export)
  ignore <- intersect(export, vars)
  if (length(ignore) > 0) {
    export <- setdiff(export, ignore)
  }

  # add explicitly exported variables to exportenv
  if (length(export) > 0) {
    if (obj$verbose)
      cat(sprintf(
        "explicitly exporting variables(s): %s\n",
        paste(export, collapse = ", ")
      ))

    for (sym in export) {
      if (!exists(sym, envir, inherits = TRUE))
        stop(sprintf("unable to find variable '%s'", sym))

      val <- get(sym, envir, inherits = TRUE)
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
      assign(sym, val, pos = exportenv, inherits = FALSE)
    }
  }

  pkgName <- if (exists("packageName", mode = "function"))
    packageName(envir)
  else
    NULL

  assign("expr", expr, .doAzureBatchGlobals)
  assign("exportenv", exportenv, .doAzureBatchGlobals)
  assign("packages", obj$packages, .doAzureBatchGlobals)
  assign("github", githubPackages, .doAzureBatchGlobals)
  assign("bioconductor", bioconductorPackages, .doAzureBatchGlobals)
  assign("pkgName", pkgName, .doAzureBatchGlobals)
  assign("it", it, .doAzureBatchGlobals)

  isDataSet <- hasDataSet(argsList)

  if (!isDataSet) {
    assign("argsList", argsList, .doAzureBatchGlobals)
  }

  if (!is.null(obj$options$azure$job)) {
    id <- obj$options$azure$job
  }
  else {
    time <- format(Sys.time(), "%Y%m%d%H%M%S", tz = "GMT")
    id <-  sprintf("%s%s", "job", time)
  }

  tryCatch({
    validation$isValidStorageContainerName(id)
    validation$isValidJobName(id)
  },
  error = function(e){
    stop(paste("Invalid job name: \n",
               e))
  })

  wait <- TRUE
  if (!is.null(obj$options$azure$wait)) {
    wait <- obj$options$azure$wait
  }

  # by default, delete both job and job result after synchronous job is completed
  autoDeleteJob <- TRUE

  if (exists("autoDeleteJob", envir = .doAzureBatchGlobals)) {
    autoDeleteJob <- get("autoDeleteJob", envir = .doAzureBatchGlobals)
  }

  if (!is.null(obj$options$azure$autoDeleteJob) &&
      is.logical(obj$options$azure$autoDeleteJob)) {
    autoDeleteJob <- obj$options$azure$autoDeleteJob
  }

  inputs <- FALSE
  if (!is.null(obj$options$azure$inputs)) {
    storageCredentials <- rAzureBatch::getStorageCredentials()
    sasToken <- rAzureBatch::createSasToken("r", "c", inputs)

    assign(
      "inputs",
      list(name = storageCredentials$name,
           sasToken = sasToken),
      .doAzureBatchGlobals
    )
  }

  cloudCombine <- list()
  enableCloudCombine <- TRUE
  if (!is.null(obj$options$azure$enableCloudCombine) &&
      is.logical(obj$options$azure$enableCloudCombine)) {
    enableCloudCombine <- obj$options$azure$enableCloudCombine
  }

  if (!is.null(obj$options$azure$cloudCombine)) {
    # TODO: Add user defined functions for combining results in Azure
  }

  if (!enableCloudCombine) {
    cloudCombine <- NULL
  }

  if (!is.null(obj$options$azure$reduce) &&
      is.function(obj$options$azure$reduce)) {
    assign("gather", obj$options$azure$reduce, envir = .doAzureBatchGlobals)
  }

  assign("enableCloudCombine", enableCloudCombine, envir = .doAzureBatchGlobals)
  assign("cloudCombine", cloudCombine, envir = .doAzureBatchGlobals)

  resourceFiles <- list()
  if (!is.null(obj$options$azure$resourceFiles)) {
    resourceFiles <- obj$options$azure$resourceFiles
  }

  if (!is.null(obj$options$azure$resourcefiles)) {
    resourceFiles <- obj$options$azure$resourcefiles
  }

  enableCloudCombineKeyValuePair <-
    list(name = "enableCloudCombine", value = as.character(enableCloudCombine))

  chunkSize <- 1

  if (exists("chunkSize", envir = .doAzureBatchGlobals)) {
    chunkSize <- get("chunkSize", envir = .doAzureBatchGlobals)
  }

  if (!is.null(obj$options$azure$chunkSize)) {
    chunkSize <- obj$options$azure$chunkSize
  }

  if (!is.null(obj$options$azure$chunksize)) {
    chunkSize <- obj$options$azure$chunksize
  }

  chunkSizeKeyValuePair <-
    list(name = "chunkSize", value = as.character(chunkSize))

  metadata <-
    list(enableCloudCombineKeyValuePair, chunkSizeKeyValuePair)

  if (!is.null(obj$packages)) {
    packagesKeyValuePair <-
      list(name = "packages",
           value = paste(obj$packages, collapse = ";"))

    metadata[[length(metadata) + 1]] <- packagesKeyValuePair
  }

  if (!is.null(obj$errorHandling)) {
    errorHandlingKeyValuePair <-
      list(name = "errorHandling",
           value = as.character(obj$errorHandling))

    metadata[[length(metadata) + 1]] <- errorHandlingKeyValuePair
  }

  if (!is.null(obj$options$azure$wait)) {
    waitKeyValuePair <-
      list(name = "wait",
           value = as.character(obj$options$azure$wait))

  }
  else {
    waitKeyValuePair <-
      list(name = "wait",
           value = as.character(FALSE))
  }

  metadata[[length(metadata) + 1]] <- waitKeyValuePair

  retryCounter <- 0
  maxRetryCount <- 5
  startupFolderName <- "startup"

  repeat {
    if (retryCounter > maxRetryCount) {
      stop(
        sprintf(
          "Error creating job: Maximum number of retries (%d) exceeded",
          maxRetryCount
        )
      )
    }
    else {
      retryCounter <- retryCounter + 1
    }

    containerResponse <- rAzureBatch::createContainer(id, content = "response")

    if (containerResponse$status_code >= 400 && containerResponse$status_code <= 499) {
      containerContent <- xml2::as_list(httr::content(containerResponse))

      if (!is.null(obj$options$azure$job) && containerContent$Code[[1]] == "ContainerAlreadyExists") {
        stop(paste("Error creating job: Job's storage container already exists for an unique job id.",
                 "Either delete the storage container or change the job argument in the foreach."))
      }

      Sys.sleep(retryCounter * retryCounter)

      time <- format(Sys.time(), "%Y%m%d%H%M%S", tz = "GMT")
      id <-  sprintf("%s%s",
                     "job",
                     time)
      next
    }
    else if (containerResponse$status_code >= 500 && containerResponse$status_code <= 599) {
      containerContent <- xml2::as_list(httr::content(containerResponse))
      stop(paste0("Error creating job: ", containerContent$message$value))
    }

    # Uploading common job files for the worker node
    rAzureBatch::uploadBlob(id,
                            system.file(startupFolderName, "worker.R", package = "doAzureParallel"))
    rAzureBatch::uploadBlob(id,
                            system.file(startupFolderName, "merger.R", package = "doAzureParallel"))
    rAzureBatch::uploadBlob(id,
                            system.file(startupFolderName, "install_github.R", package = "doAzureParallel"))
    rAzureBatch::uploadBlob(id,
                            system.file(startupFolderName, "install_cran.R", package = "doAzureParallel"))
    rAzureBatch::uploadBlob(id,
                            system.file(startupFolderName, "install_bioconductor.R", package = "doAzureParallel"))

    # Creating common job environment for all tasks
    jobFileName <- paste0(id, ".rds")
    saveRDS(.doAzureBatchGlobals, file = jobFileName)
    rAzureBatch::uploadBlob(id, paste0(getwd(), "/", jobFileName))
    file.remove(jobFileName)

    # Creating read-only SAS token blob resource file urls
    sasToken <- rAzureBatch::createSasToken("r", "c", id)
    workerScriptUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name, id, "worker.R", sasToken)
    mergerScriptUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name, id, "merger.R", sasToken)
    installGithubScriptUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name,
                                 id,
                                 "install_github.R",
                                 sasToken)
    installCranScriptUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name, id, "install_cran.R", sasToken)
    installBioConductorScriptUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name, id, "install_bioconductor.R", sasToken)
    jobCommonFileUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name, id, jobFileName, sasToken)

    requiredJobResourceFiles <- list(
      rAzureBatch::createResourceFile(url = workerScriptUrl, fileName = "worker.R"),
      rAzureBatch::createResourceFile(url = mergerScriptUrl, fileName = "merger.R"),
      rAzureBatch::createResourceFile(url = installGithubScriptUrl, fileName = "install_github.R"),
      rAzureBatch::createResourceFile(url = installCranScriptUrl, fileName = "install_cran.R"),
      rAzureBatch::createResourceFile(url = installBioConductorScriptUrl, fileName = "install_bioconductor.R"),
      rAzureBatch::createResourceFile(url = jobCommonFileUrl, fileName = jobFileName)
    )

    resourceFiles <-
      append(resourceFiles, requiredJobResourceFiles)

    ntasks <- length(argsList)

    startIndices <- seq(1, length(argsList), chunkSize)

    endIndices <-
      if (chunkSize >= length(argsList))
      {
        c(length(argsList))
      }
    else {
      seq(chunkSize, length(argsList), chunkSize)
    }

    if (length(startIndices) > length(endIndices)) {
      endIndices[length(startIndices)] <- ntasks
    }

    indices <- cbind(startIndices, endIndices)
    mergeSize <- 10
    buckets <- ceiling(nrow(indices) / mergeSize)
    bucketSeq <- rep(1:buckets, each = mergeSize, length.out = nrow(indices))
    indices <- cbind(indices, bucketSeq)

    bucketsKeyValuePair <-
      list(name = "buckets",
           value = as.character(buckets))

    metadata[[length(metadata) + 1]] <- bucketsKeyValuePair

    response <- .addJob(
      jobId = id,
      poolId = data$poolId,
      resourceFiles = resourceFiles,
      metadata = metadata,
      packages = obj$packages,
      github = githubPackages,
      bioconductor = bioconductorPackages,
      containerImage = data$containerImage
    )

    if (response$status_code == 201) {
      break
    }
    else {
      jobContent <- httr::content(response, content = "parsed")

      if (jobContent$code == "JobExists" && !is.null(obj$options$azure$job)) {
        stop(paste("Error in creating job: Job already exists with the unique job id.",
                   "Either delete the job or change the job argument in the foreach loop.",
                   jobContent$message$value))
      }
      else if (jobContent$code == "JobExists") {
        Sys.sleep(retryCounter * retryCounter)

        time <- format(Sys.time(), "%Y%m%d%H%M%S", tz = "GMT")
        id <-  sprintf("%s%s",
                       "job",
                       time)
        next
      }

      if (jobContent$code == "ActiveJobAndScheduleQuotaReached") {
        stop(
          paste(
            "Error in creating job: Your active job quota has been reached.",
            "To increase your active job quota,",
            "go to https://docs.microsoft.com/en-us/azure/batch/batch-quota-limit"
          )
        )
      }

      stop("Error in creating job: ", jobContent$message$value)
    }
  }

  job <- rAzureBatch::getJob(id)
  outputContainerUrl <-
    rAzureBatch::createBlobUrl(
      storageAccount = storageCredentials$name,
      containerName = id,
      sasToken = rAzureBatch::createSasToken("w", "c", id)
    )

  printJobInformation(
    jobId = job$id,
    chunkSize = chunkSize,
    enableCloudCombine = enableCloudCombine,
    errorHandling = obj$errorHandling,
    wait = wait,
    autoDeleteJob = autoDeleteJob,
    cranPackages = obj$packages,
    githubPackages = githubPackages,
    bioconductorPackages = bioconductorPackages
  )

  if (!is.null(job$id)) {
    saveMetadataBlob(job$id, metadata)
  }

  tasks <- lapply(1:nrow(indices), function(i) {
    storageCredentials <- rAzureBatch::getStorageCredentials()

    startIndex <- indices[i,][1]
    endIndex <- indices[i,][2]
    taskId <- as.character(i)

    args <- NULL
    if (isDataSet) {
      args <- argsList[startIndex:endIndex]
    }

    resultFile <- paste0(taskId, "-result", ".rds")

    if (buckets > 1) {
      mergeOutput <- list(
        list(
          filePattern = resultFile,
          destination = list(container = list(
            path = paste0("m", indices[i,][3], "/", resultFile),
            containerUrl = outputContainerUrl
          )),
          uploadOptions = list(uploadCondition = "taskCompletion")
        )
      )
    }
    else {
      mergeOutput <- list(
        list(
          filePattern = resultFile,
          destination = list(container = list(
            path = paste0("results", "/", resultFile),
            containerUrl = outputContainerUrl
          )),
          uploadOptions = list(uploadCondition = "taskCompletion")
        )
      )
    }

    mergeOutput <- append(obj$options$azure$outputFiles, mergeOutput)

    .addTask(
      jobId = id,
      taskId = taskId,
      rCommand =  sprintf(
        paste("Rscript --no-save --no-environ --no-restore --no-site-file",
        "--verbose $AZ_BATCH_JOB_PREP_WORKING_DIR/worker.R %i %i %i > $AZ_BATCH_TASK_ID.txt"),
        startIndex,
        endIndex,
        isDataSet,
        as.character(obj$errorHandling)),
      envir = .doAzureBatchGlobals,
      packages = obj$packages,
      outputFiles = mergeOutput,
      containerImage = data$containerImage,
      args = args
    )

    cat("\r", sprintf("Submitting tasks (%s/%s)", i, length(endIndices)), sep = "")
    flush.console()

    return(taskId)
  })

  if (enableCloudCombine) {
    cat("\nSubmitting merge task")

    if (buckets > 1) {
      taskDependencies <- list(taskIds = lapply(1:buckets, function(x) paste0("m", x)))

      bucket <- 1
      bucketIndex <- 1

      while (bucket <= buckets) {
        subTaskId <- paste0("m", bucket)
        resultFile <- paste0(subTaskId, "-result", ".rds")

        mergeOutput <- list(
          list(
            filePattern = resultFile,
            destination = list(container = list(
              path = paste0("results", "/", resultFile),
              containerUrl = outputContainerUrl
            )),
            uploadOptions = list(uploadCondition = "taskCompletion")
          )
        )

        addSubMergeTask(
          jobId = id,
          taskId = subTaskId,
          rCommand = sprintf(
            "Rscript --vanilla --verbose $AZ_BATCH_JOB_PREP_WORKING_DIR/merger.R %s %s %s > $AZ_BATCH_TASK_ID.txt",
            rle(bucketSeq)$lengths[bucket],
            chunkSize,
            as.character(obj$errorHandling)
          ),
          envir = .doAzureBatchGlobals,
          packages = obj$packages,
          dependsOn = list(taskIdRanges = list(list(
            start = bucketIndex,
            end = bucketIndex + rle(bucketSeq)$lengths[bucket] - 1))),
          cloudCombine = cloudCombine,
          outputFiles = append(obj$options$azure$outputFiles, mergeOutput),
          containerImage = data$containerImage
        )

        bucketIndex <- bucketIndex + rle(bucketSeq)$lengths[bucket]
        bucket <- bucket + 1
      }

      tasksCount <- buckets
    }
    else {
      taskDependencies <- list(taskIdRanges = list(list(
        start = 1,
        end = length(tasks))))

      tasksCount <- length(tasks)
    }

    resultFile <- paste0("merge", "-result", ".rds")

    mergeOutput <- list(
      list(
        filePattern = resultFile,
        destination = list(container = list(
          path = paste0("results", "/", resultFile),
          containerUrl = outputContainerUrl
        )),
        uploadOptions = list(uploadCondition = "taskCompletion")
      )
    )

    addFinalMergeTask(
      jobId = id,
      taskId = "merge",
      rCommand = sprintf(
        paste("Rscript --no-save --no-environ --no-restore --no-site-file",
        "--verbose $AZ_BATCH_JOB_PREP_WORKING_DIR/merger.R %s %s %s > $AZ_BATCH_TASK_ID.txt"),
        as.character(tasksCount),
        chunkSize,
        as.character(obj$errorHandling)
      ),
      envir = .doAzureBatchGlobals,
      packages = obj$packages,
      dependsOn = taskDependencies,
      cloudCombine = cloudCombine,
      outputFiles = append(obj$options$azure$outputFiles, mergeOutput),
      containerImage = data$containerImage,
      buckets = buckets
    )

    cat(". . .")
  }

  # Updating the job to terminate after all tasks are completed
  rAzureBatch::updateJob(id)

  if (wait) {
    if (!is.null(obj$packages) ||
        !is.null(githubPackages) ||
        !is.null(bioconductorPackages)) {
      waitForJobPreparation(id, data$poolId)
    }

    tryCatch({
        waitForTasksToComplete(id, jobTimeout, obj$errorHandling)

        if (typeof(cloudCombine) == "list" && enableCloudCombine) {
          tempFile <- tempfile("doAzureParallel", fileext = ".rds")

          response <-
            rAzureBatch::downloadBlob(
              id,
              paste0("results/", "merge-result.rds"),
              sasToken = sasToken,
              accountName = storageCredentials$name,
              downloadPath = tempFile,
              overwrite = TRUE
            )

          results <- readRDS(tempFile)
          failTasks <- sapply(results, .isError)

          numberOfFailedTasks <- sum(unlist(failTasks))

          if (numberOfFailedTasks > 0 && autoDeleteJob == FALSE) {
            .createErrorViewerPane(id, failTasks)
          }

          accumulator <- foreach::makeAccum(it)

          tryCatch({
              accumulator(results, seq(along = results))
            },
            error = function(e) {
              cat("error calling combine function:\n")
              print(e)
            }
          )

          # check for errors
          errorValue <- foreach::getErrorValue(it)
          errorIndex <- foreach::getErrorIndex(it)

          # delete job from batch service and job result from storage blob
          if (autoDeleteJob) {
            # Default behavior is to delete the job data
            deleteJob(id, verbose = !autoDeleteJob)
          }

          if (identical(obj$errorHandling, "stop") &&
              !is.null(errorValue)) {
            msg <-
              sprintf(
                paste0(
                  "task %d failed - '%s'.\r\nBy default job and its result is deleted after run is over, use",
                  " setAutoDeleteJob(FALSE) or autoDeleteJob = FALSE option to keep them for investigation."
                ),
                errorIndex,
                conditionMessage(errorValue)
              )
            stop(simpleError(msg, call = expr))
          }
          else {
            foreach::getResult(it)
          }
        }
      },
      error = function(ex){
        message(ex)
      }
    )
  }
  else{
    print(
      paste0(
        "Because the 'wait' parameter is set to FALSE, the returned value is the job ID associated with ",
        "the foreach loop. Use this returned value with getJobResults(job_id) to get the results ",
        "when the foreach loop is completed in Azure"
      )
    )
    return(id)
  }
}

.createErrorViewerPane <- function(id, failTasks) {
  storageCredentials <- rAzureBatch::getStorageCredentials()

  sasToken <- rAzureBatch::createSasToken("r", "c", id)

  queryParameterUrl <- "?"

  for (query in names(sasToken)) {
    queryParameterUrl <-
      paste0(queryParameterUrl,
             query,
             "=",
             RCurl::curlEscape(sasToken[[query]]),
             "&")
  }

  queryParameterUrl <-
    substr(queryParameterUrl, 1, nchar(queryParameterUrl) - 1)

  tempDir <- tempfile()
  dir.create(tempDir)
  htmlFile <- file.path(tempDir, paste0(id, ".html"))
  azureStorageUrl <-
    paste0("http://",
           storageCredentials$name,
           ".blob.core.windows.net/",
           id)

  staticHtml <- "<h1>Errors:</h1>"
  for (i in 1:length(failTasks)) {
    if (failTasks[i] == 1) {
      stdoutFile <- paste0(azureStorageUrl, "/", "stdout")
      stderrFile <- paste0(azureStorageUrl, "/", "stderr")
      rlogFile <- paste0(azureStorageUrl, "/", "logs")

      stdoutFile <-
        paste0(stdoutFile,
               "/",
               id,
               "-task",
               i,
               "-stdout.txt",
               queryParameterUrl)
      stderrFile <-
        paste0(stderrFile,
               "/",
               id,
               "-task",
               i,
               "-stderr.txt",
               queryParameterUrl)
      rlogFile <-
        paste0(rlogFile,
               "/",
               id,
               "-task",
               i,
               ".txt",
               queryParameterUrl)

      staticHtml <-
        paste0(
          staticHtml,
          "Task ",
          i,
          " | <a href='",
          stdoutFile,
          "'>",
          "stdout.txt",
          "</a> |",
          " <a href='",
          stderrFile,
          "'>",
          "stderr.txt",
          "</a> | <a href='",
          rlogFile,
          "'>",
          "R output",
          "</a> <br/>"
        )
    }
  }

  write(staticHtml, htmlFile)

  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    viewer(htmlFile)
  }
}
