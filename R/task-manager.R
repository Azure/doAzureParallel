#' @export
TaskWorkflowManager <- R6::R6Class(
  "TaskManager",
  public = list(
    initialize = function(){
      errors = list()
    },
    
    errors = list(),
    threads = 1,
    maxTasksPerRequest = 100,
    createTask = function(jobId, taskId, rCommand, ...) {
      config <- getConfiguration()
      storageClient <- config$storageClient

      args <- list(...)
      .doAzureBatchGlobals <- args$envir
      dependsOn <- args$dependsOn
      argsList <- args$args
      cloudCombine <- args$cloudCombine
      userOutputFiles <- args$outputFiles
      containerImage <- args$containerImage

      accountName <- storageClient$authentication$name

      resourceFiles <- NULL
      if (!is.null(argsList)) {
        envFile <- paste0(taskId, ".rds")
        saveRDS(argsList, file = envFile)
        storageClient$blobOperations$uploadBlob(
          jobId,
          file.path(getwd(), envFile)
        )
        file.remove(envFile)

        readToken <- storageClient$generateSasToken("r", "c", jobId)
        envFileUrl <-
          rAzureBatch::createBlobUrl(
            storageClient$authentication$name,
            jobId,
            envFile,
            readToken,
            config$endpointSuffix)
        resourceFiles <-
          list(rAzureBatch::createResourceFile(url = envFileUrl, fileName = envFile))
      }

      # Only use the download command if cloudCombine is enabled
      # Otherwise just leave it empty
      commands <- c()

      containerSettings <- list(
        imageName = containerImage,
        containerRunOptions = "--rm"
      )

      if (!is.null(cloudCombine)) {
        assign("cloudCombine", cloudCombine, .doAzureBatchGlobals)
        containerSettings$imageName <- "brianlovedocker/doazureparallel-merge-dockerfile:0.12.1"

        copyCommand <- sprintf(
          "%s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include results/*.rds --endpoint %s",
          accountName,
          jobId,
          "$AZ_BATCH_TASK_WORKING_DIR",
          config$endpointSuffix
        )

        commands <- c(paste("blobxfer", copyCommand))
      }

      exitConditions <- NULL
      if (!is.null(args$dependsOn)) {
        dependsOn <- args$dependsOn
      }
      else {
        exitConditions <- list(default = list(dependencyAction = "satisfy"))
      }

      containerUrl <-
        rAzureBatch::createBlobUrl(
          storageAccount = storageClient$authentication$name,
          containerName = jobId,
          sasToken = storageClient$generateSasToken("w", "c", jobId),
          storageEndpointSuffix = config$endpointSuffix
        )

      outputFiles <- list(
        list(
          filePattern = paste0(taskId, ".txt"),
          destination = list(container = list(
            path = paste0("logs/", taskId, ".txt"),
            containerUrl = containerUrl
          )),
          uploadOptions = list(uploadCondition = "taskCompletion")
        ),
        list(
          filePattern = "../stdout.txt",
          destination = list(container = list(
            path = paste0("stdout/", taskId, "-stdout.txt"),
            containerUrl = containerUrl
          )),
          uploadOptions = list(uploadCondition = "taskCompletion")
        ),
        list(
          filePattern = "../stderr.txt",
          destination = list(container = list(
            path = paste0("stderr/", taskId, "-stderr.txt"),
            containerUrl = containerUrl
          )),
          uploadOptions = list(uploadCondition = "taskCompletion")
        )
      )

      outputFiles <- append(outputFiles, userOutputFiles)

      commands <-
        c(commands,
          rCommand)

      commands <- linuxWrapCommands(commands)

      sasToken <- storageClient$generateSasToken("rwcl", "c", jobId)
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

      body <- list(id = taskId,
                   commandLine = commands,
                   userIdentity = list(
                     autoUser = list(
                       scope = "pool",
                       elevationLevel = "admin"
                     )
                   ),
                   resourceFiles = resourceFiles,
                   dependsOn = dependsOn,
                   outputFiles = outputFiles,
                   constraints = list(
                     maxTaskRetryCount = 3
                   ),
                   exitConditions = exitConditions,
                   containerSettings = containerSettings)

      body <- Filter(length, body)

      body
    },
    addTaskCollection = function(
      jobId,
      tasksToAdd,
      chunksToAdd,
      threads = 1
    ){
      config <- getConfiguration()
      batchClient <- config$batchClient

      len <- length(tasks)

      startIndex <- 1
      endIndex <- self$maxTasksPerRequest
      front <- 1
      back <- length(tasks)

      failedToAdd <- vector("list", length = length(tasks))

      chunkTasksToAdd <- list()
      while (endIndex < len) {
        chunkTasksToAdd <- tasks[startIndex:endIndex]
        response <- batchClient$taskOperations$addCollection(
          jobId,
          list(value = chunkTasksToAdd),
          content = "response"
        )

        values <- httr::content(response)$value
        if (response$status_code == 413) {

        }
        else if (500 <= response$status_code &&
            response$status_code <= 599) {

        }
        else {

        }

        for (i in 1:length(values)) {
          if (compare(values[[i]]$status, "servererror")) {

          }
          else if (compare(values[[i]]$status, "clienterror") &&
                   values[[i]]$error$code != "TaskExists") {
            failedToAdd
          }
          else {

          }
        }

        startIndex = startIndex + self$maxTasksPerRequest
        endIndex = endIndex + self$maxTasksPerRequest
      }

      if (startIndex < len) {
        response <- batchClient$taskOperations$addCollection(
          jobId,
          list(value = tasks[startIndex:len]),
          content = "response"
        )

        print(response)
      }
    },
    addTasks = function(
      jobId,
      tasks,
      chunkTasksToAdd
    ){
      config <- getConfiguration()
      batchClient <- config$batchClient

      response <- batchClient$taskOperations$addCollection(
        jobId,
        list(value = chunkTasksToAdd),
        content = "response"
      )
      
      # In case of a chunk exceeding the MaxMessageSize split chunk in half
      # and resubmit smaller chunk requests
      if (response$status_code == 413) {
        midpoint <- length(chunkTasksToAdd) / 2
        addTasks(jobId,
                 tasks,
                 chunkTasksToAdd[1:midpoint])
        
        <- addTasks(jobId,
                 tasks,
                 chunkTasksToAdd[midpoint:length(chunkTasksToAdd)])
      }
      else if (500 <= response$status_code &&
               response$status_code <= 599) {
        
      }
      else {

      }
      
      values <- httr::content(response)$value
      
      for (i in 1:length(values)) {
        if (compare(values[[i]]$status, "servererror")) {

        }
        else if (compare(values[[i]]$status, "clienterror") &&
                 values[[i]]$error$code != "TaskExists") {
          failedToAdd
        }
        else {

        }
      }
      
      return(list(
        addedTasks = addedTasks,
        failedTasks = failedToAdd
      ))
    }
  )
)

TaskWorkflowManager <- TaskWorkflowManager$new()