addFinalMergeTask <- function(jobId, taskId, rCommand, ...){
  storageCredentials <- rAzureBatch::getStorageCredentials()

  args <- list(...)
  dependsOn <- args$dependsOn
  cloudCombine <- args$cloudCombine
  containerImage <- args$containerImage

  resultFile <- paste0(taskId, "-result", ".rds")
  accountName <- storageCredentials$name

  # Only use the download command if cloudCombine is enabled
  # Otherwise just leave it empty
  commands <- c()

  if (!is.null(cloudCombine)) {
    assign("cloudCombine", cloudCombine, .doAzureBatchGlobals)

    copyCommand <- sprintf(
      "%s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include results/*.rds",
      accountName,
      jobId,
      "$AZ_BATCH_TASK_WORKING_DIR"
    )

    downloadCommand <-
      dockerRunCommand("alfpark/blobxfer:0.12.1", copyCommand, "blobxfer", FALSE)

    commands <- c(downloadCommand)
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
      storageAccount = storageCredentials$name,
      containerName = jobId,
      sasToken = rAzureBatch::createSasToken("w", "c", jobId)
    )

  outputFiles <- list(
    list(
      filePattern = resultFile,
      destination = list(container = list(
        path = paste0("results/", resultFile),
        containerUrl = containerUrl
      )),
      uploadOptions = list(uploadCondition = "taskCompletion")
    ),
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

  commands <-
    c(commands,
      dockerRunCommand(containerImage, rCommand))

  commands <- linuxWrapCommands(commands)

  sasToken <- rAzureBatch::createSasToken("rwcl", "c", jobId)
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

  rAzureBatch::addTask(
    jobId,
    taskId,
    environmentSettings = list(setting, containerEnv),
    commandLine = commands,
    dependsOn = dependsOn,
    outputFiles = outputFiles,
    exitConditions = exitConditions
  )
}

addSubMergeTask <- function(jobId, taskId, rCommand, ...){
  storageCredentials <- rAzureBatch::getStorageCredentials()
  accountName <- storageCredentials$name

  args <- list(...)
  dependsOn <- args$dependsOn
  containerImage <- args$containerImage
  outputFiles <- args$outputFiles

  copyCommand <- sprintf(
    "%s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include %s/*.rds",
    accountName,
    jobId,
    "$AZ_BATCH_TASK_WORKING_DIR",
    taskId
  )

  exitConditions <- NULL
  if (!is.null(args$dependsOn)) {
    dependsOn <- args$dependsOn
  }
  else {
    exitConditions <- list(default = list(dependencyAction = "satisfy"))
  }

  downloadCommand <-
    dockerRunCommand("alfpark/blobxfer:0.12.1", copyCommand, "blobxfer", FALSE)

  commands <- c(downloadCommand, dockerRunCommand(containerImage, rCommand))
  commands <- linuxWrapCommands(commands)

  sasToken <- rAzureBatch::createSasToken("rwcl", "c", jobId)
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

  rAzureBatch::addTask(
    jobId,
    taskId,
    commandLine = commands,
    environmentSettings = list(setting),
    dependsOn = dependsOn,
    outputFiles = outputFiles,
    exitConditions = exitConditions
  )
}

.addTask <- function(jobId, taskId, rCommand, ...) {
  storageCredentials <- rAzureBatch::getStorageCredentials()

  args <- list(...)
  .doAzureBatchGlobals <- args$envir
  dependsOn <- args$dependsOn
  argsList <- args$args
  cloudCombine <- args$cloudCombine
  userOutputFiles <- args$outputFiles
  containerImage <- args$containerImage

  accountName <- storageCredentials$name

  resourceFiles <- NULL
  if (!is.null(argsList)) {
    envFile <- paste0(taskId, ".rds")
    saveRDS(argsList, file = envFile)
    rAzureBatch::uploadBlob(jobId, file.path(getwd(), envFile))
    file.remove(envFile)

    readToken <- rAzureBatch::createSasToken("r", "c", jobId)
    envFileUrl <-
      rAzureBatch::createBlobUrl(storageCredentials$name, jobId, envFile, readToken)
    resourceFiles <-
      list(rAzureBatch::createResourceFile(url = envFileUrl, fileName = envFile))
  }

  # Only use the download command if cloudCombine is enabled
  # Otherwise just leave it empty
  commands <- c()

  if (!is.null(cloudCombine)) {
    assign("cloudCombine", cloudCombine, .doAzureBatchGlobals)
    copyCommand <- sprintf(
      "%s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include result/*.rds",
      accountName,
      jobId,
      "$AZ_BATCH_TASK_WORKING_DIR"
    )

    downloadCommand <-
      dockerRunCommand("alfpark/blobxfer:0.12.1", copyCommand, "blobxfer", FALSE)
    commands <- c(downloadCommand)
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
      storageAccount = storageCredentials$name,
      containerName = jobId,
      sasToken = rAzureBatch::createSasToken("w", "c", jobId)
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
      dockerRunCommand(containerImage, rCommand))

  commands <- linuxWrapCommands(commands)

  sasToken <- rAzureBatch::createSasToken("rwcl", "c", jobId)
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

  rAzureBatch::addTask(
    jobId,
    taskId,
    environmentSettings = list(setting, containerEnv),
    resourceFiles = resourceFiles,
    commandLine = commands,
    dependsOn = dependsOn,
    outputFiles = outputFiles,
    exitConditions = exitConditions
  )
}

.addJob <- function(jobId,
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

  # Default command for job preparation task
  commands <- c("ls")

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

  response <- rAzureBatch::addJob(
    jobId,
    poolInfo = poolInfo,
    jobPreparationTask = jobPreparationTask,
    usesTaskDependencies = usesTaskDependencies,
    content = "response",
    metadata = metadata
  )

  return(response)
}

.addPool <-
  function(pool,
           packages,
           environmentSettings,
           resourceFiles,
           ...) {
    args <- list(...)
    commands <- c()

    if (!is.null(args$commandLine)) {
      commands <- c(commands, args$commandLine)
    }

    startTask <- list(
      commandLine = linuxWrapCommands(commands),
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
        publisher = "Canonical",
        offer = "UbuntuServer",
        sku = "16.04-LTS",
        version = "latest"
      ),
      nodeAgentSKUId = "batch.node.ubuntu 16.04"
    )

    response <- rAzureBatch::addPool(
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
      content = "text"
    )

    return(response)
  }
