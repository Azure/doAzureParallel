.addTask <- function(jobId, taskId, rCommand, ...){
  storageCredentials <- getStorageCredentials()

  args <- list(...)
  .doAzureBatchGlobals <- args$envir
  argsList <- args$args
  packages <- args$packages
  dependsOn <- args$dependsOn

  if(!is.null(argsList)){
    assign('argsList', argsList, .doAzureBatchGlobals)
  }

  envFile <- paste0(taskId, ".rds")
  saveRDS(argsList, file = envFile)
  uploadBlob(jobId, paste0(getwd(), "/", envFile))
  file.remove(envFile)

  sasToken <- constructSas("r", "c", jobId, storageCredentials$key)

  if(!is.null(args$dependsOn)){
    dependsOn <- list(taskIds = dependsOn)
  }

  resultFile <- paste0(taskId, "-result", ".rds")
  logsCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource logs/%s", storageCredentials$name, jobId, paste0(taskId, ".txt"), paste0(taskId, ".txt"))
  autoUploadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource result/%s", storageCredentials$name, jobId, resultFile, resultFile)
  downloadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include result/*.rds", storageCredentials$name, jobId, "$AZ_BATCH_TASK_WORKING_DIR")
  stdoutUploadCommand <- sprintf("env PATH=$PATH blobxfer %s %s $AZ_BATCH_TASK_DIR/%s --upload --saskey $BLOBXFER_SASKEY --remoteresource %s", storageCredentials$name, jobId, "stdout.txt", paste0("stdout/", taskId, "-stdout.txt"))
  stderrUploadCommand <- sprintf("env PATH=$PATH blobxfer %s %s $AZ_BATCH_TASK_DIR/%s --upload --saskey $BLOBXFER_SASKEY --remoteresource %s", storageCredentials$name, jobId, "stderr.txt", paste0("stderr/", taskId, "-stderr.txt"))

  commands <- c("export PATH=/anaconda/envs/py35/bin:$PATH", downloadCommand, rCommand, logsCommand, autoUploadCommand, stderrUploadCommand, stdoutUploadCommand)

  commands <- linuxWrapCommands(commands)

  sasToken <- constructSas("rwcl", "c", jobId, storageCredentials$key)
  sasQuery <- generateSasUrl(sasToken)

  setting = list(name = "BLOBXFER_SASKEY",
                 value = sasQuery)

  resourceFiles <- list(generateResourceFile(storageCredentials$name, jobId, envFile, sasToken))

  addTask(jobId,
          taskId,
          environmentSettings = list(setting),
          resourceFiles = resourceFiles,
          commandLine = commands,
          dependsOn = dependsOn)
}

.addJob <- function(jobId,
                    poolId,
                    resourceFiles,
                    ...){
  args <- list(...)
  packages <- args$packages

  poolInfo <- list("poolId" = poolId)

  commands <- c("ls")
  if(!is.null(packages)){
    commands <- c(commands, getInstallationCommand(packages))
  }

  jobPreparationTask <- list(
    commandLine = linuxWrapCommands(commands),
    userIdentity = list(
      autoUser = list(
        scope = "pool",
        elevationLevel = "admin"
      )
    ),
    waitForSuccess = TRUE,
    resourceFiles = resourceFiles,
    constraints = list(
      maxTaskRetryCount = 2
    )
  )

  usesTaskDependencies <- TRUE

  response <- addJob(jobId,
         poolInfo = poolInfo,
         jobPreparationTask = jobPreparationTask,
         usesTaskDependencies = usesTaskDependencies,
         raw = TRUE)

  return(response)
}

.addPool <- function(pool, packages, resourceFiles){
  commands <- c("export PATH=/anaconda/envs/py35/bin:$PATH",
                "env PATH=$PATH pip install --no-dependencies blobxfer")

  if(!is.null(packages)){
    commands <- c(commands, packages)
  }

  startTask <- list(
    commandLine = linuxWrapCommands(commands),
    userIdentity = list(
      autoUser = list(
        scope = "pool",
        elevationLevel = "admin"
      )
    ),
    waitForSuccess = TRUE
  )

  if(length(resourceFiles) > 0){
    startTask$resourceFiles = resourceFiles
  }

  virtualMachineConfiguration <- list(
    imageReference = list(publisher = "microsoft-ads",
                          offer = "linux-data-science-vm",
                          sku = "linuxdsvm",
                          version = "latest"),
    nodeAgentSKUId ="batch.node.centos 7")

  response <- addPool(pool$name,
                      pool$vmSize,
                      startTask = startTask,
                      virtualMachineConfiguration = virtualMachineConfiguration,
                      enableAutoScale = TRUE,
                      autoscaleFormula = getAutoscaleFormula(pool$poolSize$autoscaleFormula, pool$poolSize$minNodes, pool$poolSize$maxNodes),
                      autoScaleEvaluationInterval = "PT5M",
                      maxTasksPerNode = pool$maxTasksPerNode,
                      raw = TRUE)

  return(response)
}
