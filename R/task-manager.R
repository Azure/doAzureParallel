#' @export
TaskWorkflowManager <- R6::R6Class(
  "TaskManager",
  public = list(
    initialize = function(){
    },
    originalTaskCollection = NULL,
    tasksToAdd = NULL,
    results = NULL,
    failedTasks = NULL,
    errors = NULL,
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
      resourceFiles <- args$resourceFiles
      accountName <- storageClient$authentication$name

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
    handleTaskCollection = function(
      jobId,
      tasks,
      threads = 1
    ){
      size <- length(tasks)
      self$originalTaskCollection <- tasks
      
      self$tasksToAdd <- datastructures::queue()
      self$tasksToAdd <- datastructures::insert(self$tasksToAdd, tasks)
      
      self$results <- datastructures::queue()
      self$failedTasks <- datastructures::queue()
      self$errors <- datastructures::queue()
      
      config <- getConfiguration()
      batchClient <- config$batchClient

      tryCatch({
        while (datastructures::size(self$tasksToAdd) > 0 &&
               datastructures::size(self$errors) == 0) {
          maxTasks <- self$maxTasksPerRequest
          if (datastructures::size(self$tasksToAdd) < maxTasks) {
            maxTasks <- datastructures::size(self$tasksToAdd)
          }
          
          chunkTasksToAdd <- vector("list", maxTasks)
          index <- 1
          
          while (index <= maxTasks &&
                 datastructures::size(self$tasksToAdd) > 0){
            chunkTasksToAdd[[index]]<- datastructures::pop(self$tasksToAdd)
            index <- index + 1
          }
          
          report <- self$addBulkTasks(
            jobId,
            chunkTasksToAdd
          )
        }
      },
      error = function(e){
        
      })
    },
    addBulkTasks = function(
      jobId,
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
        if(length(chunkTasksToAdd) == 1){
          self$errors$push(response)
          
          stop("Failed to add task with ID %s due to the body" +
               " exceeding the maximum request size" + chunkTasksToAdd[[1]]$id)
        }
        
        upperBound <- length(chunkTasksToAdd)
        midBound <- upperBound / 2
        
        
        self$addBulkTasks(
          jobId,
          chunkTasksToAdd[1:midBound])
        
        self$addBulkTasks(
          jobId,
          chunkTasksToAdd[(midBound+1):upperBound])
      }
      else if (500 <= response$status_code &&
               response$status_code <= 599) {
        self$tasksToAdd <- datastructures::insert(self$tasksToAdd, chunkTasksToAdd)
      }
      else if (response$status_code == 200){
        values <- httr::content(response)$value
        
        for (i in 1:length(values)) {
          taskId <- values[[i]]$id
          
          if (compare(values[[i]]$status, "servererror")) {
            self$tasksToAdd <- datastructures::insert(self$tasksToAdd, self$originalTaskCollection[[taskId]])
          }
          else if (compare(values[[i]]$status, "clienterror") &&
                   values[[i]]$error$code != "TaskExists") {
            self$failedTasks <- datastructures::insert(self$failedTasks, values[[i]])
          }
          else {
            self$results <- datastructures::insert(self$results, values[[i]])
          }
        }
      }
      else {
        self$tasksToAdd <- datastructures::insert(self$tasksToAdd, chunkTasksToAdd)
        self$errors <- datastructures::insert(self$errors, response)
      }
    }
  )
)

TaskWorkflowManager <- TaskWorkflowManager$new()
