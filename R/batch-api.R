BatchUtilities <- R6::R6Class(
  "BatchUtilities",
  public = list(
    initialize = function(){

    },
    addTask = function(jobId, taskId, rCommand, ...) {
      config <- getConfiguration()
      storageClient <- config$storageClient
      batchClient <- config$batchClient

      args <- list(...)
      .doAzureBatchGlobals <- args$envir
      dependsOn <- args$dependsOn
      argsList <- args$args
      cloudCombine <- args$cloudCombine
      userOutputFiles <- args$outputFiles
      containerImage <- args$containerImage

      accountName <- storageClient$authentication$name

      resourceFiles <- args$resourceFiles
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

        environmentResourceFile <-
          rAzureBatch::createResourceFile(filePath = envFile, httpUrl = envFileUrl)

        if (is.null(resourceFiles))
        {
          resourceFiles <-
            list(environmentResourceFile)
        }
        else {
          resourceFiles <- append(resourceFiles, environmentResourceFile)
        }
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

      setting <- list(name = "BLOBXFER_SASKEY",
                      value = queryParameterUrl)

      containerEnv <- list(name = "CONTAINER_NAME",
                           value = jobId)

      batchClient$taskOperations$add(
        jobId,
        taskId,
        environmentSettings = list(setting, containerEnv),
        resourceFiles = resourceFiles,
        commandLine = commands,
        dependsOn = dependsOn,
        outputFiles = outputFiles,
        exitConditions = exitConditions,
        containerSettings = containerSettings
      )
    },
    addJob = function(jobId,
                       poolId,
                       resourceFiles,
                       metadata,
                       ...) {
      args <- list(...)
      packages <- args$packages
      github <- args$github
      bioconductor <- args$bioconductor
      containerImage <- args$containerImage
      poolInfo <- list("poolId" = poolId)

      config <- getConfiguration()
      batchClient <- config$batchClient

      # Default command for job preparation task to get resource files
      # for all tasks on one node
      commands <- c(
        "echo 'Installing R Packages & Downloading Resource Files'"
      )

      if (!is.null(packages)) {
        jobPackages <-
          dockerRunCommand(containerImage,
                           getJobPackageInstallationCommand("cran", packages),
                           jobId)
        commands <- c(commands, jobPackages)
      }

      if (!is.null(github) && length(github) > 0) {
        jobPackages <-
          dockerRunCommand(containerImage,
                           getJobPackageInstallationCommand("github", github),
                           jobId)
        commands <- c(commands, jobPackages)
      }

      if (!is.null(bioconductor) &&
          length(bioconductor) > 0) {
        jobPackages <-
          dockerRunCommand(containerImage,
                           getJobPackageInstallationCommand("bioconductor", bioconductor),
                           jobId)
        commands <- c(commands, jobPackages)
      }

      jobPreparationTask <- list(
        commandLine = linuxWrapCommands(commands),
        userIdentity = list(autoUser = list(
          scope = "pool",
          elevationLevel = "admin"
        )),
        waitForSuccess = TRUE,
        resourceFiles = resourceFiles,
        constraints = list(maxTaskRetryCount = 2)
      )

      usesTaskDependencies <- TRUE

      response <- batchClient$jobOperations$addJob(
        jobId,
        poolInfo = poolInfo,
        jobPreparationTask = jobPreparationTask,
        usesTaskDependencies = usesTaskDependencies,
        content = "response",
        metadata = metadata
      )

      return(response)
    },
    addPool =
      function(pool,
               packages,
               environmentSettings,
               resourceFiles,
               ...) {
        args <- list(...)
        commands <- c()

        config <- getConfiguration()
        batchClient <- config$batchClient

        if (!is.null(args$commandLine)) {
          commands <- c(commands, args$commandLine)
        }

        commands <- linuxWrapCommands(commands)
        if (!is.null(args$applicationInsights)) {
          commands <- gsub("wait",
                           "wait; ./batch-insights > node-stats.log &",
                           commands)
        }

        startTask <- list(
          commandLine = commands,
          userIdentity = list(autoUser = list(
            scope = "pool",
            elevationLevel = "admin"
          )),
          waitForSuccess = TRUE
        )

        if (!is.null(environmentSettings)) {
          startTask$environmentSettings <- environmentSettings
        }

        if (length(resourceFiles) > 0) {
          startTask$resourceFiles <- resourceFiles
        }

        virtualMachineConfiguration <- list(
          imageReference = list(
            publisher = "microsoft-azure-batch",
            offer = "ubuntu-server-container",
            sku = "16-04-lts",
            version = "latest"
          ),
          nodeAgentSKUId = "batch.node.ubuntu 16.04",
          containerConfiguration = args$containerConfiguration
        )

        response <- batchClient$poolOperations$addPool(
          pool$name,
          pool$vmSize,
          startTask = startTask,
          virtualMachineConfiguration = virtualMachineConfiguration,
          enableAutoScale = TRUE,
          metadata = list(list(name = "origin", value = "doAzureParallel")),
          autoscaleFormula = getAutoscaleFormula(
            pool$poolSize$autoscaleFormula,
            pool$poolSize$dedicatedNodes$min,
            pool$poolSize$dedicatedNodes$max,
            pool$poolSize$lowPriorityNodes$min,
            pool$poolSize$lowPriorityNodes$max,
            maxTasksPerNode = pool$maxTasksPerNode
          ),
          autoScaleEvaluationInterval = "PT5M",
          maxTasksPerNode = pool$maxTasksPerNode,
          networkConfiguration = args$networkConfiguration,
          content = "text"
        )

        return(response)
      }
  )
)

BatchUtilitiesOperations <- BatchUtilities$new()
