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

  sasToken <- createSasToken("r", "c", jobId)
  writeToken <- createSasToken("w", "c", jobId)

  envFileUrl <- createBlobUrl(storageCredentials$name, jobId, envFile, sasToken)
  resourceFiles <- list(createResourceFile(url = envFileUrl, fileName = envFile))

  if(!is.null(args$dependsOn)){
    dependsOn <- list(taskIds = dependsOn)
  }

  resultFile <- paste0(taskId, "-result", ".rds")
  accountName <- storageCredentials$name


  downloadCommand <- sprintf("env PATH=$PATH blobxfer %s %s %s --download --saskey $BLOBXFER_SASKEY --remoteresource . --include result/*.rds", accountName, jobId, "$AZ_BATCH_TASK_WORKING_DIR")

  containerUrl <- createBlobUrl(storageAccount = storageCredentials$name,
                                container = jobId,
                                sasToken = writeToken)

  outputFiles <- list(
    list(
      filePattern = resultFile,
      destination = list(
        container = list(
          path = paste0("result/", resultFile),
          containerUrl = containerUrl
        )
      ),
      uploadOptions = list(
        uploadCondition = "taskCompletion"
      )
    ),
    list(
      filePattern = paste0(taskId, ".txt"),
      destination = list(
        container = list(
          path = paste0("logs/", taskId, ".txt"),
          containerUrl = containerUrl
        )
      ),
      uploadOptions = list(
        uploadCondition = "taskCompletion"
      )
    ),
    list(
      filePattern = "../stdout.txt",
      destination = list(
        container = list(
          path = paste0("stdout/", taskId, "-stdout.txt"),
          containerUrl = containerUrl
        )
      ),
      uploadOptions = list(
        uploadCondition = "taskCompletion"
      )
    ),
    list(
      filePattern = "../stderr.txt",
      destination = list(
        container = list(
          path = paste0("stderr/", taskId, "-stderr.txt"),
          containerUrl = containerUrl
        )
      ),
      uploadOptions = list(
        uploadCondition = "taskCompletion"
      )
    )
  )

  commands <- c("export PATH=/anaconda/envs/py35/bin:$PATH", downloadCommand, rCommand)# downloadCommand, , logsCommand, autoUploadCommand, stderrUploadCommand)

  commands <- linuxWrapCommands(commands)

  sasToken <- createSasToken("rwcl", "c", jobId)
  queryParameterUrl <- "?"

  for(query in names(sasToken)){
    queryParameterUrl <- paste0(queryParameterUrl, query, "=", curlEscape(sasToken[[query]]), "&")
  }

  queryParameterUrl <- substr(queryParameterUrl, 1, nchar(queryParameterUrl) - 1)

  setting = list(name = "BLOBXFER_SASKEY",
                 value = queryParameterUrl)

  containerEnv = list(name = "CONTAINER_NAME",
                 value = jobId)

  addTask(jobId,
          taskId,
          environmentSettings = list(setting, containerEnv),
          resourceFiles = resourceFiles,
          commandLine = commands,
          dependsOn = dependsOn,
          outputFiles = outputFiles)
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

.addPool <- function(pool, packages, environmentSettings, resourceFiles){
  
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

  if(!is.null(environmentSettings)){
    startTask$environmentSettings = environmentSettings
  }
  
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
                      autoscaleFormula = getAutoscaleFormula(pool$poolSize$autoscaleFormula,
                                                             pool$poolSize$dedicatedNodes$min,
                                                             pool$poolSize$dedicatedNodes$max,
                                                             pool$poolSize$lowPriorityNodes$min,
                                                             pool$poolSize$lowPriorityNodes$max,
                                                             maxTasksPerNode = pool$maxTasksPerNode),
                      autoScaleEvaluationInterval = "PT5M",
                      maxTasksPerNode = pool$maxTasksPerNode,
                      raw = TRUE)

  return(response)
}
