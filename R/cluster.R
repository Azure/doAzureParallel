#' Creates a configuration file for the user's cluster setup.
#'
#' @param fileName Cluster configuration's file name.
#' @param ... Further named parameters
#' \itemize{
#'  \item{"batchAccount"}: {A list of files that the Batch service will download to the compute node before running the command line.}
#'  \item{"batchKey"}: {Arguments in the foreach parameters that will be used for the task running.}
#'  \item{"batchUrl"}: {A list of packages that the Batch service will download to the compute node.}
#'  \item{"storageAccount"}: {The R environment that the task will run under.}
#'  \item{"storageKey"}: {The R environment that the task will run under.}
#'}
#' @return The request to the Batch service was successful.
#' @examples {
#' generateClusterConfig("test_config.json")
#' generateClusterConfig("test_config.json", batchAccount = "testbatchaccount", batchKey = "test_batch_account_key", batchUrl = "http://testbatchaccount.azure.com", storageAccount = "teststorageaccount", storageKey = "test_storage_account_key")
#' }
generateClusterConfig <- function(fileName, ...){
  args <- list(...)

  batchAccount <- ifelse(is.null(args$batchAccount), "batch_account_name", args$batchAccount)
  batchKey <- ifelse(is.null(args$batchKey), "batch_account_key", args$batchKey)
  batchUrl <- ifelse(is.null(args$batchUrl), "batch_account_url", args$batchUrl)

  storageName <- ifelse(is.null(args$storageAccount), "storage_account_name", args$storageAccount)
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
          cran = vector(),
          github = vector()
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
    print("Note: To maximize all CPU cores, set the maxTasksPerNode property up to 4x the number of cores for the VM size.")
  }
}

#' Creates an Azure cloud-enabled cluster.
#'
#' @param fileName Cluster configuration's file name
#' @param fullName A boolean flag for checking the file full name
#' @param wait A boolean flag to wait for all nodes to boot up
#'
#' @return The request to the Batch service was successful.
#' @examples
#' cluster <- makeCluster("cluster_config.json", fullName = TRUE, wait = TRUE)
makeCluster <- function(fileName = "az_config.json", fullName = FALSE, wait = TRUE, resourceFiles = list()){
  setPoolOption(fileName, fullName)
  config <- getOption("az_config")
  pool <- config$batchAccount$pool

  packages <- NULL
  if(!is.null(config$batchAccount$rPackages) && !is.null(config$batchAccount$rPackages$cran) && length(config$batchAccount$rPackages$cran) > 0){
    packages <- getInstallationCommand(config$batchAccount$rPackages$cran)
  }

  if(!is.null(config$batchAccount$rPackages) && !is.null(config$batchAccount$rPackages$github) && length(config$batchAccount$rPackages$github) > 0){
    if(is.null(packages)){
      packages <- getGithubInstallationCommand(config$batchAccount$rPackages$github)
    }
    else{
      packages <- paste0(packages, ";", getGithubInstallationCommand(config$batchAccount$rPackages$github))
    }
  }

  response <- .addPool(
    pool = pool,
    packages = packages,
    resourceFiles = resourceFiles)

  pool <- getPool(pool$name)

  if(grepl("AuthenticationFailed", response)){
    stop("Check your credentials and try again.");
  }

  if(grepl("PoolExists", response)){
    print("The specified pool already exists. Will use existing pool.")
  }
  else{
    if(wait){
      waitForNodesToComplete(pool$id, 60000, targetDedicated = pool$targetDedicated)
    }
  }

  print("Your pool has been registered.")
  print(sprintf("Node Count: %i", pool$targetDedicated))
  return(getOption("az_config"))
}

#' Deletes the cluster from your Azure account.
#'
#' @param cluster The cluster configuration that was created in \code{makeCluster}
#'
#' @return The request to the Batch service was successful.
#' @examples
#' clusterConfiguration <- makeCluster("pool_configuration.json")
#' stopCluster(clusterConfiguration)
stopCluster <- function(cluster){
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
