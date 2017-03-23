.addTask <- function(jobId, taskId, ...){
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
  saveRDS(.doAzureBatchGlobals, file = envFile)
  uploadBlob(jobId, paste0(getwd(), "/", envFile))
  file.remove(envFile)

  sasToken <- constructSas("r", "c", jobId, storageCredentials$key)

  taskPrep <- getInstallationCommand(packages)
  rCommand <- sprintf("Rscript --vanilla --verbose $AZ_BATCH_JOB_PREP_WORKING_DIR/%s %s %s > %s.txt", "worker.R", "$AZ_BATCH_TASK_WORKING_DIR", envFile, taskId)

  resultFile <- paste0(taskId, "-result", ".rds")
  logsCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource logs/%s", storageCredentials$name, jobId, paste0(taskId, ".txt"), paste0(taskId, ".txt"))
  autoUploadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource result/%s", storageCredentials$name, jobId, resultFile, resultFile)
  downloadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include result/*.rds", storageCredentials$name, jobId, "$AZ_BATCH_TASK_WORKING_DIR")
  logsCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource logs/%s", storageCredentials$name, jobId, paste0(taskId, ".txt"), paste0(taskId, ".txt"))

  commands <- c("export PATH=/anaconda/envs/py35/bin:$PATH", downloadCommand, rCommand, logsCommand, autoUploadCommand)
  if(taskPrep != ""){
    commands <- c(taskPrep, commands)
  }

  sasToken <- constructSas("rwcl", "c", jobId, storageCredentials$key)
  sasQuery <- generateSasUrl(sasToken)

  setting = list(name = "BLOBXFER_SASKEY",
                 value = sasQuery)

  resourceFiles <- list(generateResourceFile(storageCredentials$name, jobId, envFile, sasToken))

  addTask(jobId,
          taskId,
          environmentSettings = list(setting),
          resourceFiles = resourceFiles,
          commandLine = linuxWrapCommands(commands))
}

.addTaskMerge <- function(jobId, taskId, ...){
  storageCredentials <- getStorageCredentials()

  args <- list(...)
  .doAzureBatchGlobals <- args$envir
  argsList <- args$args
  packages <- args$packages
  numOfTasks <- args$numOfTasks
  dependsOn <- args$dependsOn

  if(!is.null(argsList)){
    assign('argsList', argsList, .doAzureBatchGlobals)
  }

  envFile <- paste0(taskId, ".rds")
  saveRDS(.doAzureBatchGlobals, file = envFile)
  uploadBlob(jobId, paste0(getwd(), "/", envFile))
  file.remove(envFile)

  sasToken <- constructSas("r", "c", jobId, storageCredentials$key)

  taskPrep <- getInstallationCommand(packages)
  rCommand <- sprintf("Rscript --vanilla --verbose $AZ_BATCH_JOB_PREP_WORKING_DIR/%s %s %s %s %s %s > %s.txt", "merger.R", "$AZ_BATCH_TASK_WORKING_DIR", envFile, length(dependsOn), jobId, numOfTasks, taskId)

  resultFile <- paste0(taskId, "-result", ".rds")
  logsCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource logs/%s", storageCredentials$name, jobId, paste0(taskId, ".txt"), paste0(taskId, ".txt"))
  autoUploadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource result/%s", storageCredentials$name, jobId, resultFile, resultFile)
  downloadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include result/*.rds", storageCredentials$name, jobId, "$AZ_BATCH_TASK_WORKING_DIR")
  logsCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --upload --saskey $BLOBXFER_SASKEY --remoteresource logs/%s", storageCredentials$name, jobId, paste0(taskId, ".txt"), paste0(taskId, ".txt"))

  commands <- c("export PATH=/anaconda/envs/py35/bin:$PATH", downloadCommand, rCommand, logsCommand, autoUploadCommand)
  if(taskPrep != ""){
    commands <- c(taskPrep, commands)
  }

  sasToken <- constructSas("rwcl", "c", jobId, storageCredentials$key)
  sasQuery <- generateSasUrl(sasToken)

  setting = list(name = "BLOBXFER_SASKEY",
                 value = sasQuery)

  resourceFiles <- list(generateResourceFile(storageCredentials$name, jobId, envFile, sasToken))

  addTask(jobId,
          taskId,
          environmentSettings = list(setting),
          resourceFiles = resourceFiles,
          commandLine = linuxWrapCommands(commands),
          dependsOn = list(taskIds = dependsOn))
}

.addJob <- function(jobId,
                    poolId,
                    resourceFiles,
                    ...){
  args <- list(...)
  packages <- args$packages

  poolInfo <- list("poolId" = poolId)

  commands <- linuxWrapCommands(c("ls"))
  if(!is.null(packages)){
    commands <- paste0(commands, ";", getInstallationCommand(packages))
  }

  jobPreparationTask <- list(
    commandLine = commands,
    userIdentity = list(
      autoUser = list(
        scope = "task",
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

.addPool <- function(pool, packages){
  commands <- c("sed -i -e 's/Defaults    requiretty.*/ #Defaults    requiretty/g' /etc/sudoers",
                "export PATH=/anaconda/envs/py35/bin:$PATH",
                "sudo env PATH=$PATH pip install --no-dependencies blobxfer")

  commands <- paste0(linuxWrapCommands(commands), ";", packages)

  startTask <- list(
    commandLine = commands,
    userIdentity = list(
      autoUser = list(
        scope = "task",
        elevationLevel = "admin"
      )
    ),
    waitForSuccess = TRUE
  )

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
