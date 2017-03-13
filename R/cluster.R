generateClusterConfig <- function(fileName, ...){
  args <- list(...)
  
  batchAccount <- ifelse(is.null(args$batchAccount), "batch_account_name", args$batchAccount)
  batchKey <- ifelse(is.null(args$batchKey), "batch_account_key", args$batchKey)
  batchUrl <- ifelse(is.null(args$batchUrl), "batch_account_url", args$batchUrl)
  
  storageName <- ifelse(is.null(args$storageName), "storage_account_name", args$storageName)
  storageKey <- ifelse(is.null(args$storageKey), "storage_account_key", args$storageKey)
  
  packages <- ifelse(is.null(args$packages), list(), args$packages)
  
  if(!file.exists(paste0(getwd(), "/", fileName))){
    config <- list(
      batchAccount = list(
        name = batchAccount,
        key = batchKey,
        url = batchUrl,
        pool = list(
          name = "myPoolName",
          vmSize = "Standard_D2_v2",
          maxTasksPerNode = 1,
          poolSize = list(
            minNodes = 3,
            maxNodes = 10,
            autoscaleFormula = "QUEUE"
          )
        ),
        rPackages = list(
          cran = list(
            source = "http://cran.us.r-project.org",
            name = c(
              "devtools",
              "httr"
            )
          ),
          github = c(
            "twitter/AnomalyDetection",
            "hadley/httr"
          )
        )
      ),
      storageAccount = list(
        name = storageName,
        key = storageKey
      ),
      settings = list(
        verbose = FALSE
      )
    )
    
    configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
    write(configJson, file=paste0(getwd(), "/", fileName))
    
    print(sprintf("A config file has been generated %s. Please enter your Batch credentials.", paste0(getwd(), "/", fileName)))
    print("Note: To maximize all CPU cores, please set the maxTasksPerNode property to 4x the number of cores for the VM size.")
  }
}

makeCluster <- function(fileName = "az_config.json", fullName = FALSE, waitForPool = TRUE){
  setPoolOption(fileName, fullName)
  config <- getOption("az_config")
  pool <- config$batchAccount$pool
  
  response <- addPool(
    pool$name,
    pool$vmSize,
    autoscaleFormula = getAutoscaleFormula(pool$poolSize$autoscaleFormula, pool$poolSize$minNodes, pool$poolSize$maxNodes),
    maxTasksPerNode = pool$maxTasksPerNode,
    raw = TRUE,
    packages = config$batchAccount$rPackages$github)
  
  pool <- getPool(pool$name)
  
  if(grepl("AuthenticationFailed", response)){
    stop("Check your credentials and try again.");
  }
  
  if(grepl("PoolExists", response)){
    print("The specified pool already exists. Will use existing pool.")
  }
  else{
    if(waitForPool){
      waitForNodesToComplete(pool$id, 60000, targetDedicated = pool$targetDedicated)
    }
  }
  
  print("Your pool has been registered.")
  print(sprintf("Node Count: %i", pool$targetDedicated))
  return(getOption("az_config"))
}

stopCluster <- function(pool){
  deletePool(pool$batchAccount$pool$name)
}

setPoolOption <- function(fileName = "az_config.json", fullName = FALSE){
  if(fullName){
    config <- rjson::fromJSON(file=paste0(fileName))
  }
  else{
    config <- rjson::fromJSON(file=paste0(getwd(), "/", fileName))
  }
  
  options("az_config" = config)
}

getPoolWorkers <- function(poolId, ...){
  args <- list(...)
  raw <- !is.null(args$RAW)
  
  batchCredentials <- getBatchCredentials()
  
  nodes <- listPoolNodes(poolId)
  
  if(length(nodes$value) > 0){
    for(i in 1:length(nodes$value)){
      print(sprintf("Node: %s - %s - %s", nodes$value[[i]]$id, nodes$value[[i]]$state, nodes$value[[i]]$ipAddress))
    }
  }
  else{
    print("There are currently no nodes in the pool.")
  }
  
  if(raw){
    return(nodes)
  }
}