#' Creates a credentials file for rAzureBatch package authentication
#'
#' @param fileName Credentials file name
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
#' generateCredentialsConfig("test_config.json")
#' generateCredentialsConfig("test_config.json", batchAccount = "testbatchaccount",
#'    batchKey = "test_batch_account_key", batchUrl = "http://testbatchaccount.azure.com",
#'    storageAccount = "teststorageaccount", storageKey = "test_storage_account_key")
#' }
#' @export
generateCredentialsConfig <- function(fileName, ...){
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
        url = batchUrl
      ),
      storageAccount = list(
        name = storageName,
        key = storageKey
      )
    )

    configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
    write(configJson, file=paste0(getwd(), "/", fileName))

    print(sprintf("A config file has been generated %s. Please enter your Batch credentials.", paste0(getwd(), "/", fileName)))
  }
}

#' Creates a configuration file for the user's cluster setup.
#'
#' @param fileName Cluster settings file name
#' @return The request to the Batch service was successful.
#' @examples {
#' generateClusterConfig("test_config.json")
#' generateClusterConfig("test_config.json")
#' }
#'
#' @export
generateClusterConfig <- function(fileName, ...){
  args <- list(...)

  packages <- ifelse(is.null(args$packages), list(), args$packages)

  if(!file.exists(fileName) || !file.exists(paste0(getwd(), "/", fileName))){
    config <- list(
      name = "myPoolName",
      vmSize = "Standard_D2_v2",
      maxTasksPerNode = 1,
      poolSize = list(
        dedicatedNodes = list(
          min = 3,
          max = 3
        ),
        lowPriorityNodes = list(
          min = 3,
          max = 3
        ),
        autoscaleFormula = "QUEUE"
      ),
      rPackages = list(
        cran = vector(),
        github = vector()
      )
    )

    configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
    write(configJson, file=paste0(getwd(), "/", fileName))

    print(sprintf("A cluster settings has been generated %s. Please enter your cluster specification.", paste0(getwd(), "/", fileName)))
    print("Note: To maximize all CPU cores, set the maxTasksPerNode property up to 4x the number of cores for the VM size.")
  }
}

#' Creates an Azure cloud-enabled cluster.
#'
#' @param clusterSetting Cluster configuration's file name
#' @param fullName A boolean flag for checking the file full name
#' @param wait A boolean flag to wait for all nodes to boot up
#' @param resourceFiles A list of files that Batch will download to the compute node before running the command line
#'
#' @return The request to the Batch service was successful.
#' @examples
#' \dontrun{
#' cluster <- makeCluster("cluster_config.json", fullName = TRUE, wait = TRUE)
#' }
#' @export
makeCluster <- function(clusterSetting = "cluster_settings.json", fullName = FALSE, wait = TRUE, resourceFiles = list()){
  validateClusterConfig(clusterSetting)

  if(fullName){
    pool <- rjson::fromJSON(file=paste0(clusterSetting))
  }
  else{
    pool <- rjson::fromJSON(file = paste0(getwd(), "/", clusterSetting))
  }

  config <- getOption("az_config")
  if (is.null(config)) {
    stop("Credentials were not set.")
  }

  config$poolId = pool$name
  options("az_config" = config)

  installCranCommand <- NULL
  installGithubCommand <- NULL

  if (!is.null(pool$rPackages) && !is.null(pool$rPackages$cran) && length(pool$rPackages$cran) > 0) {
    installCranCommand <- getPoolPackageInstallationCommand("cran", pool$rPackages$cran)
  }

  if (!is.null(pool$rPackages) && !is.null(pool$rPackages$github) && length(pool$rPackages$github) > 0) {
    installGithubCommand <- getPoolPackageInstallationCommand("github", pool$rPackages$github)
  }

  packages <- NULL
  if (!is.null(installCranCommand)) {
    packages <- installCranCommand
  }

  if (!is.null(installGithubCommand) && is.null(packages)) {
    packages <- installGithubCommand
  }
  else if (!is.null(installGithubCommand) && !is.null(packages)) {
    packages <- c(installCranCommand, installGithubCommand)
  }

  response <- .addPool(
    pool = pool,
    packages = packages,
    resourceFiles = resourceFiles)

  pool <- getPool(pool$name)

  if (grepl("AuthenticationFailed", response)) {
    stop("Check your credentials and try again.");
  }

  if (grepl("PoolExists", response)) {
    print("The specified pool already exists. Will use existing pool.")
  }
  else{
    if (wait) {
      waitForNodesToComplete(pool$id, 60000)
    }
  }

  print("Your pool has been registered.")
  print(sprintf("Dedicated Node Count: %i", pool$targetDedicatedNodes))
  print(sprintf("Low Priority Node Count: %i", pool$targetLowPriorityNodes))
  return(getOption("az_config"))
}

#' Deletes the cluster from your Azure account.
#'
#' @param cluster The cluster configuration that was created in \code{makeCluster}
#'
#' @examples
#' \dontrun{
#' clusterConfiguration <- makeCluster("cluster_settings.json")
#' stopCluster(clusterConfiguration)
#' }
#' @export
stopCluster <- function(cluster){
  deletePool(cluster$poolId)

  print(sprintf("Your %s cluster has been destroyed.", cluster$poolId))
}

#' Set azure credentials to R session.
#'
#' @param fileName The cluster configuration that was created in \code{makeCluster}
#'
#' @export
setCredentials <- function(fileName = "az_config.json"){
  if(file.exists(fileName)){
    config <- rjson::fromJSON(file=paste0(fileName))
  }
  else{
    config <- rjson::fromJSON(file=paste0(getwd(), "/", fileName))
  }

  options("az_config" = config)
  print("Your azure credentials have been set.")
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
