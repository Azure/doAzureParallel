getJobPackageInstallationCommand <- function(type, packages){
  script <- ""
  if (type == "cran") {
    script <- "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_cran.R"
  }
  else if (type == "github") {
    script <- "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_github.R"
  }
  else {
    stop("Using an incorrect package source")
  }

  if (!is.null(packages) && length(packages) > 0) {
    packageCommands <- paste0(packages, collapse = " ")
    script <- paste0(script, " ", packageCommands)
  }
}

getPoolPackageInstallationCommand <- function(type, packages){
  poolInstallationCommand <- character(length(packages))

  if (type == "cran") {
    script <- "Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1])\' %s"
  }
  else if (type == "github") {
    script <- "Rscript -e \'args <- commandArgs(TRUE)\' -e \'devtools::install_github(args[1])\' %s"
  }
  else {
    stop("Using an incorrect package source")
  }

  for (i in 1:length(packages)) {
    poolInstallationCommand[i] <- sprintf(script, packages[i])
  }

  poolInstallationCommand
}

linuxWrapCommands <- function(commands = c()){
  commandLine <- sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"",
                         paste0(paste(commands, sep = " ", collapse = "; "),"; "))

  commandLine
}

#' Get a list of job statuses from the given job ids
#'
#' @param jobIds A character vector of job ids
#'
#' @examples
#' \dontrun{
#' getJobList(c("job-001", "job-002"))
#' }
#' @export
getJobList <- function(jobIds = c()){
  filter <- ""

  if(length(jobIds) > 1){
    for(i in 1:length(jobIds)){
      filter <- paste0(filter, sprintf("id eq '%s'", jobIds[i]), " or ")
    }

    filter <- substr(filter, 1, nchar(filter) - 3)
  }

  jobs <- listJobs(query = list("$filter" = filter, "$select" = "id,state"))
  print("Job List: ")

  for(j in 1:length(jobs$value)){
    tasks <- listTask(jobs$value[[j]]$id)
    count <- 0
    if(length(tasks$value) > 0){
      taskStates <- lapply(tasks$value, function(x) x$state == "completed")

      for(i in 1:length(taskStates)){
        if(taskStates[[i]] == TRUE){
          count <- count + 1
        }
      }

      summary <- sprintf("[ id: %s, state: %s, status: %d", jobs$value[[j]]$id, jobs$value[[j]]$state, ceiling((count/length(tasks$value) * 100)))
      print(paste0(summary,  "% ]"))
    }
    else {
      print(sprintf("[ id: %s, state: %s, status: %s ]", jobs$value[[j]]$id, jobs$value[[j]]$state, "No tasks were run."))
    }
  }
}

#' Polling method to check status of cluster boot up
#'
#' @param clusterId The cluster name to poll for
#' @param timeout Timeout in seconds, default timeout is one day
#'
#' @examples
#' \dontrun{
#' waitForNodesToComplete(clusterId = "testCluster", timeout = 3600)
#' }
#' @export
waitForNodesToComplete <- function(clusterId, timeout = 86400){
  print("Booting compute nodes. . . ")

  pool <- getPool(clusterId)

  numOfNodes <- pool$targetDedicatedNodes + pool$targetLowPriorityNodes

  pb <- txtProgressBar(min = 0, max = pool$targetDedicatedNodes + pool$targetLowPriorityNodes, style = 3)
  prevCount <- 0
  timeToTimeout <- Sys.time() + timeout

  while(Sys.time() < timeToTimeout){
    nodes <- listPoolNodes(clusterId)

    startTaskFailed <- TRUE

    if(!is.null(nodes$value) && length(nodes$value) > 0){
      nodeStates <- lapply(nodes$value, function(x){
        if(x$state == "idle"){
          return(1)
        }
        else if(x$state == "creating"){
          return(0.25)
        }
        else if(x$state == "starting"){
          return(0.50)
        }
        else if(x$state == "waitingforstarttask"){
          return(0.75)
        }
        else if(x$state == "starttaskfailed"){
          startTaskFailed <- FALSE
          return(1)
        }
        else if(x$state == "preempted"){
          return(1)
        }
        else{
          return(0)
        }
      })

      count <- sum(unlist(nodeStates))

      if(count > prevCount){
        setTxtProgressBar(pb, count)
        prevCount <- count
      }

      stopifnot(startTaskFailed)

      if(count == numOfNodes){
        return(0);
      }
    }

    setTxtProgressBar(pb, prevCount)
    Sys.sleep(30)
  }

  deletePool(poolId)
  stop("Timeout expired")
}

#' Download the results of the job
#' @param ... Further named parameters
#' \itemize{
#'  \item{"container"}: {The container to download from.}
#' }
#' @param jobId The jobId to download from
#'
#' @return The results from the job.
#' @examples
#' \dontrun{
#' getJobResult(jobId = "job-001")
#' }
#' @export
getJobResult <- function(jobId = "", ...){
  args <- list(...)

  if(!is.null(args$container)){
    results <- downloadBlob(container, paste0("result/", jobId, "-merge-result.rds"))
  }
  else{
    results <- downloadBlob(jobId, paste0("result/", jobId, "-merge-result.rds"))
  }

  if(!is.null(args$pass) && args$pass){
    failTasks <- sapply(results, .isError)
  }

  return(results)
}

validateClusterConfig <- function(clusterFilePath){
  if (file.exists(clusterFilePath)) {
    pool <- rjson::fromJSON(file = clusterFilePath)
  }
  else{
    pool <- rjson::fromJSON(file = file.path(getwd(), clusterFilePath))
  }

  if (is.null(pool$poolSize)) {
    stop("Missing poolSize entry")
  }

  if (is.null(pool$poolSize$dedicatedNodes)) {
    stop("Missing dedicatedNodes entry")
  }

  if (is.null(pool$poolSize$lowPriorityNodes)) {
    stop("Missing lowPriorityNodes entry")
  }

  if (is.null(pool$poolSize$autoscaleFormula)) {
    stop("Missing autoscaleFormula entry")
  }

  if (is.null(pool$poolSize$dedicatedNodes$min)) {
    stop("Missing dedicatedNodes$min entry")
  }

  if (is.null(pool$poolSize$dedicatedNodes$max)) {
    stop("Missing dedicatedNodes$max entry")
  }

  if (is.null(pool$poolSize$lowPriorityNodes$min)) {
    stop("Missing lowPriorityNodes$min entry")
  }

  if (is.null(pool$poolSize$lowPriorityNodes$max)) {
    stop("Missing lowPriorityNodes$max entry")
  }

  stopifnot(is.character(pool$name))
  stopifnot(is.character(pool$vmSize))
  stopifnot(is.character(pool$poolSize$autoscaleFormula))
  stopifnot(pool$poolSize$autoscaleFormula %in% names(AUTOSCALE_FORMULA))

  stopifnot(pool$poolSize$dedicatedNodes$min <= pool$poolSize$dedicatedNodes$max)
  stopifnot(pool$poolSize$lowPriorityNodes$min <= pool$poolSize$lowPriorityNodes$max)
  stopifnot(pool$maxTasksPerNode >= 1)

  stopifnot(is.double(pool$poolSize$dedicatedNodes$min))
  stopifnot(is.double(pool$poolSize$dedicatedNodes$max))
  stopifnot(is.double(pool$poolSize$lowPriorityNodes$min))
  stopifnot(is.double(pool$poolSize$lowPriorityNodes$max))
  stopifnot(is.double(pool$maxTasksPerNode))

  TRUE
}

#' Validating cluster configuration files below doAzureParallel version 0.3.2
validateDeprecatedClusterConfig_0.3.2 <- function(clusterFilePath){
  if (file.exists(clusterFilePath)) {
    poolConfig <- rjson::fromJSON(file = clusterFilePath)
  }
  else{
    poolConfig <- rjson::fromJSON(file = file.path(getwd(), clusterFilePath))
  }

  if (is.null(poolConfig$pool$poolSize)) {
    stop("Missing poolSize entry")
  }

  if (is.null(poolConfig$pool$poolSize$dedicatedNodes)) {
    stop("Missing dedicatedNodes entry")
  }

  if (is.null(poolConfig$pool$poolSize$lowPriorityNodes)) {
    stop("Missing lowPriorityNodes entry")
  }

  if (is.null(poolConfig$pool$poolSize$autoscaleFormula)) {
    stop("Missing autoscaleFormula entry")
  }

  if (is.null(poolConfig$pool$poolSize$dedicatedNodes$min)) {
    stop("Missing dedicatedNodes$min entry")
  }

  if (is.null(poolConfig$pool$poolSize$dedicatedNodes$max)) {
    stop("Missing dedicatedNodes$max entry")
  }

  if (is.null(poolConfig$pool$poolSize$lowPriorityNodes$min)) {
    stop("Missing lowPriorityNodes$min entry")
  }

  if (is.null(poolConfig$pool$poolSize$lowPriorityNodes$max)) {
    stop("Missing lowPriorityNodes$max entry")
  }

  stopifnot(is.character(poolConfig$pool$name))
  stopifnot(is.character(poolConfig$pool$vmSize))
  stopifnot(is.character(poolConfig$pool$poolSize$autoscaleFormula))
  stopifnot(poolConfig$pool$poolSize$autoscaleFormula %in% names(AUTOSCALE_FORMULA))

  stopifnot(poolConfig$pool$poolSize$dedicatedNodes$min <= poolConfig$pool$poolSize$dedicatedNodes$max)
  stopifnot(poolConfig$pool$poolSize$lowPriorityNodes$min <= poolConfig$pool$poolSize$lowPriorityNodes$max)
  stopifnot(poolConfig$pool$maxTasksPerNode >= 1)

  stopifnot(is.double(poolConfig$pool$poolSize$dedicatedNodes$min))
  stopifnot(is.double(poolConfig$pool$poolSize$dedicatedNodes$max))
  stopifnot(is.double(poolConfig$pool$poolSize$lowPriorityNodes$min))
  stopifnot(is.double(poolConfig$pool$poolSize$lowPriorityNodes$max))
  stopifnot(is.double(poolConfig$pool$maxTasksPerNode))

  TRUE
}

#' Utility function for creating an output file
#'
#' @param filePattern a pattern indicating which file(s) to upload
#' @param url the destination blob or virtual directory within the Azure Storage container
#'
#' @export
createOutputFile <- function(filePattern, url){
  output <- list(
    filePattern = filePattern,
    destination = list(
      container = list(
        containerUrl = url
      )
    ),
    uploadOptions = list(
      uploadCondition = "taskCompletion"
    )
  )

  # Parsing url to obtain container's virtual directory path
  azureDomain <- "blob.core.windows.net"
  parsedValue <- strsplit(url, azureDomain)[[1]]

  accountName <- parsedValue[1]
  urlPath <- parsedValue[2]

  baseUrl <- paste0(accountName, azureDomain)
  parsedUrlPath <- strsplit(urlPath, "?", fixed = TRUE)[[1]]

  storageContainerPath <- parsedUrlPath[1]
  queryParameters <- parsedUrlPath[2]
  virtualDirectory <- strsplit(substring(storageContainerPath, 2, nchar(storageContainerPath)), "/", fixed = TRUE)

  containerName <- virtualDirectory[[1]][1]
  containerUrl <- paste0(baseUrl, "/", containerName, "?", queryParameters)

  # Verify directory has multiple directories
  if(length(virtualDirectory[[1]]) > 1){
    # Rebuilding output path for the file upload
    path <- ""
    for(i in 2:length(virtualDirectory[[1]])){
      path <- paste0(path, virtualDirectory[[1]][i], "/")
    }

    path <- substring(path, 1, nchar(path) - 1)
    output$destination$container$path <- path
  }

  output$destination$container$containerUrl <- containerUrl
  output
}

