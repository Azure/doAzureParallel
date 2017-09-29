getJobPackageInstallationCommand <- function(type, packages) {
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

getPoolPackageInstallationCommand <- function(type, packages) {
  poolInstallationCommand <- character(length(packages))

  if (type == "cran") {
    script <-
      "Rscript -e \'args <- commandArgs(TRUE)\' -e \'options(warn=2)\' -e \'install.packages(args[1])\' %s"
  }
  else if (type == "github") {
    script <-
      "Rscript -e \'args <- commandArgs(TRUE)\' -e \'options(warn=2)\' -e \'devtools::install_github(args[1])\' %s"
  }
  else {
    stop("Using an incorrect package source")
  }

  for (i in 1:length(packages)) {
    poolInstallationCommand[i] <- sprintf(script, packages[i])
  }

  poolInstallationCommand
}

linuxWrapCommands <- function(commands = c()) {
  # Do not allow absolute paths is enforced in lintr
  commandLine <-
    sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"",
            paste0(paste(
              commands, sep = " ", collapse = "; "
            ), ";"))

  commandLine
}

#' Get a list of job statuses from the given filter
#'
#' @param filter A filter containing job state
#'
#' @examples
#' \dontrun{
#' getJobList()
#' }
#' @export
getJobList <- function(filter = NULL) {
  filterClause <- ""

  if (!is.null(filter)) {
    if (!is.null(filter$state)) {
      filterClause <-
        paste0(filterClause, sprintf("state eq '%s'", filter$state))
    }
  }

  jobs <-
    rAzureBatch::listJobs(query = list("$filter" = filterClause, "$select" = "id,state"))

  id <- character(length(jobs$value))
  state <- character(length(jobs$value))
  status <- character(length(jobs$value))
  failedTasks <- integer(length(jobs$value))
  totalTasks <- integer(length(jobs$value))

  if (length(jobs$value) > 0) {
    for (j in 1:length(jobs$value)) {
      id[j] <- jobs$value[[j]]$id
      state[j] <- jobs$value[[j]]$state
      taskCounts <-
        rAzureBatch::getJobTaskCounts(jobId = jobs$value[[j]]$id)
      failedTasks[j] <-
        as.integer(taskCounts$failed)
      totalTasks[j] <-
        as.integer(taskCounts$active + taskCounts$running + taskCounts$completed)

      completed <- as.integer(taskCounts$completed)

      if (totalTasks[j] > 0) {
        status[j] <-
          sprintf("%s %%", ceiling(completed / totalTasks[j] * 100))
      }
      else {
        status[j] <- "No tasks in the job"
      }
    }
  }

  return (
    data.frame(
      Id = id,
      State = state,
      Status = status,
      FailedTasks = failedTasks,
      TotalTasks = totalTasks
    )
  )
}

#' Get a job for the given job id
#'
#' @param jobId A job id
#' @param verbose show verbose log output
#'
#' @examples
#' \dontrun{
#' getJob("job-001", FALSE)
#' }
#' @export
getJob <- function(jobId, verbose = TRUE) {
  if (is.null(jobId)) {
    stop("must specify the jobId parameter")
  }

  job <- rAzureBatch::getJob(jobId = jobId)

  metadata <-
    list(
      chunkSize = 1,
      enableCloudCombine = "TRUE",
      packages = ""
    )

  if (!is.null(job$metadata)) {
    for (i in 1:length(job$metadata)) {
      metadata[[job$metadata[[i]]$name]] <- job$metadata[[i]]$value
    }
  }

  if (verbose == TRUE) {
    cat(sprintf("Job Id: %s", job$id), fill = TRUE)
    cat("\njob metadata:", fill = TRUE)
    cat(sprintf("\tchunkSize: %s", metadata$chunkSize),
        fill = TRUE)
    cat(sprintf("\tenableCloudCombine: %s", metadata$enableCloudCombine),
        fill = TRUE)
    cat(sprintf("\tpackages: %s", metadata$packages),
        fill = TRUE)
  }

  taskCounts <- rAzureBatch::getJobTaskCounts(jobId = jobId)

  tasks <- list(
    active = taskCounts$active,
    running = taskCounts$running,
    completed = taskCounts$completed,
    succeeded = taskCounts$succeeded,
    failed = taskCounts$failed
  )

  if (verbose == TRUE) {
    cat("\ntasks:", fill = TRUE)
    cat(sprintf("\tactive: %s", taskCounts$active), fill = TRUE)
    cat(sprintf("\trunning: %s", taskCounts$running), fill = TRUE)
    cat(sprintf("\tcompleted: %s", taskCounts$completed), fill = TRUE)
    cat(sprintf("\t\tsucceeded: %s", taskCounts$succeeded), fill = TRUE)
    cat(sprintf("\t\tfailed: %s", taskCounts$failed), fill = TRUE)
    cat(
      sprintf(
        "\ttotal: %s",
        taskCounts$active + taskCounts$running + taskCounts$completed
      ),
      fill = TRUE
    )
  }

  jobObj <- list(jobId = job$id,
                 metadata = metadata,
                 tasks = tasks)

  return(jobObj)
}

#' Polling method to check status of cluster boot up
#'
#' @param poolId The cluster name to poll for
#' @param timeout Timeout in seconds, default timeout is one day
#'
#' @examples
#' \dontrun{
#' waitForNodesToComplete(poolId = "testCluster", timeout = 3600)
#' }
#' @export
waitForNodesToComplete <- function(poolId, timeout = 86400) {
  cat("Booting compute nodes. . . ", fill = TRUE)

  pool <- rAzureBatch::getPool(poolId)

  # Validate the getPool request first, before setting the progress bar
  if (!is.null(pool$code) && !is.null(pool$message)) {
    stop(sprintf("Code: %s - Message: %s", pool$code, pool$message))
  }

  if (pool$targetDedicatedNodes + pool$targetLowPriorityNodes <= 0) {
    stop("Pool count needs to be greater than 0.")
  }

  totalNodes <-
    pool$targetDedicatedNodes + pool$targetLowPriorityNodes

  pb <-
    txtProgressBar(min = 0,
                   max = totalNodes,
                   style = 3)

  timeToTimeout <- Sys.time() + timeout

  while (Sys.time() < timeToTimeout) {
    pool <- rAzureBatch::getPool(poolId)

    if (!is.null(pool$resizeErrors)) {
      cat("\n")

      resizeErrors <- ""
      for (i in 1:length(pool$resizeErrors)) {
        resizeErrors <-
          paste0(
            resizeErrors,
            sprintf(
              "Code: %s - Message: %s \n",
              pool$resizeErrors[[i]]$code,
              pool$resizeErrors[[i]]$message
            )
          )
      }

      stop(resizeErrors)
    }

    nodes <- rAzureBatch::listPoolNodes(poolId)

    if (!is.null(nodes$value) && length(nodes$value) > 0) {
      nodesWithFailures <- c()
      currentProgressBarCount <- 0

      for (i in 1:length(nodes$value)) {
        # The progress total count is the number of the nodes. Each node counts as 1.
        # If a node is not in idle, prempted, running, or start task failed, the value is
        # less than 1. The default value is 0 because the node has not been allocated to
        # the pool yet.
        nodeValue <- switch(
          nodes$value[[i]]$state,
          "idle" = {
            1
          },
          "creating" = {
            0.25
          },
          "starting" = {
            0.50
          },
          "waitingforstartask" = {
            0.75
          },
          "starttaskfailed" = {
            nodesWithFailures <- c(nodesWithFailures, nodes$value[[i]]$id)
            1
          },
          "preempted" = {
            1
          },
          "running" = {
            1
          },
          0
        )

        currentProgressBarCount <-
          currentProgressBarCount + nodeValue
      }

      if (currentProgressBarCount >= pb$getVal()) {
        setTxtProgressBar(pb, currentProgressBarCount)
      }

      if (length(nodesWithFailures) > 0) {
        nodesFailureWarningLabel <-
          sprintf(
            "The following %i nodes failed while running the start task:\n",
            length(nodesWithFailures)
          )
        for (i in 1:length(nodesWithFailures)) {
          nodesFailureWarningLabel <-
            paste0(nodesFailureWarningLabel,
                   sprintf("%s\n", nodesWithFailures[i]))
        }

        warning(nodesFailureWarningLabel)
      }
    }

    if (pb$getVal() >= totalNodes) {
      cat("\n")
      return(0)
    }

    Sys.sleep(30)
  }

  rAzureBatch::deletePool(poolId)
  stop("Timeout expired")
}

#' Download the results of the job
#' @param jobId The jobId to download from
#'
#' @return The results from the job.
#' @examples
#' \dontrun{
#' getJobResult(jobId = "job-001")
#' }
#' @export
getJobResult <- function(jobId) {
  cat("Getting job results...", fill = TRUE)

  if (nchar(jobId) < 3) {
    stop("jobId must contain at least 3 characters.")
  }

  tempFile <- tempFile <- tempfile("getJobResult", fileext = ".rds")

  results <- rAzureBatch::downloadBlob(
    jobId,
    paste0("result/", jobId, "-merge-result.rds"),
    downloadPath = tempFile,
    overwrite = TRUE
  )

  if (is.vector(results)) {
    results <- readRDS(tempFile)
  }

  return(results)
}

#' Utility function for creating an output file
#'
#' @param filePattern a pattern indicating which file(s) to upload
#' @param url the destination blob or virtual directory within the Azure Storage container
#'
#' @export
createOutputFile <- function(filePattern, url) {
  output <- list(
    filePattern = filePattern,
    destination = list(container = list(containerUrl = url)),
    uploadOptions = list(uploadCondition = "taskCompletion")
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
  virtualDirectory <-
    strsplit(substring(storageContainerPath, 2, nchar(storageContainerPath)), "/", fixed = TRUE)

  containerName <- virtualDirectory[[1]][1]
  containerUrl <-
    paste0(baseUrl, "/", containerName, "?", queryParameters)

  # Verify directory has multiple directories
  if (length(virtualDirectory[[1]]) > 1) {
    # Rebuilding output path for the file upload
    path <- ""
    for (i in 2:length(virtualDirectory[[1]])) {
      path <- paste0(path, virtualDirectory[[1]][i], "/")
    }

    path <- substring(path, 1, nchar(path) - 1)
    output$destination$container$path <- path
  }

  output$destination$container$containerUrl <- containerUrl
  output
}

#' Wait for current tasks to complete
#'
#' @export
waitForTasksToComplete <- function(jobId, timeout) {
  cat("Waiting for tasks to complete. . .", fill = TRUE)

  numOfTasks <- 0
  currentTasks <- rAzureBatch::listTask(jobId)

  if (is.null(currentTasks$value)) {
    stop(paste0("Error: ", currentTasks$message$value))
    return()
  }

  numOfTasks <- numOfTasks + length(currentTasks$value)

  # Getting the total count of tasks for progress bar
  repeat {
    if (is.null(currentTasks$odata.nextLink)) {
      break
    }

    skipTokenParameter <-
      strsplit(currentTasks$odata.nextLink, "&")[[1]][2]

    skipTokenValue <-
      substr(skipTokenParameter,
             nchar("$skiptoken=") + 1,
             nchar(skipTokenParameter))

    currentTasks <-
      rAzureBatch::listTask(jobId, skipToken = URLdecode(skipTokenValue))
    numOfTasks <- numOfTasks + length(currentTasks$value)
  }

  pb <- txtProgressBar(min = 0, max = numOfTasks, style = 3)

  timeToTimeout <- Sys.time() + timeout

  while (Sys.time() < timeToTimeout) {
    count <- 0
    currentTasks <- rAzureBatch::listTask(jobId)

    taskStates <-
      lapply(currentTasks$value, function(x)
        x$state != "completed")
    for (i in 1:length(taskStates)) {
      if (taskStates[[i]] == FALSE) {
        count <- count + 1
      }
    }

    repeat {
      if (is.null(currentTasks$odata.nextLink)) {
        break
      }

      skipTokenParameter <-
        strsplit(currentTasks$odata.nextLink, "&")[[1]][2]

      skipTokenValue <-
        substr(skipTokenParameter,
               nchar("$skiptoken=") + 1,
               nchar(skipTokenParameter))

      currentTasks <-
        rAzureBatch::listTask(jobId, skipToken = URLdecode(skipTokenValue))

      taskStates <-
        lapply(currentTasks$value, function(x)
          x$state != "completed")

      for (i in 1:length(taskStates)) {
        if (taskStates[[i]] == FALSE) {
          count <- count + 1
        }
      }
    }

    setTxtProgressBar(pb, count)

    if (all(taskStates == FALSE)) {
      cat("\n")
      return(0)
    }

    Sys.sleep(10)
  }

  stop("A timeout has occurred when waiting for tasks to complete.")
}

waitForJobPreparation <- function(jobId, poolId) {
  cat("Job Preparation Status: Package(s) being installed")

  filter <- paste(
    sprintf("poolId eq '%s' and", poolId),
    "jobPreparationTaskExecutionInfo/state eq 'completed'"
  )

  select <- "jobPreparationTaskExecutionInfo"

  repeat {
    statuses <- rAzureBatch::getJobPreparationStatus(jobId,
                                                     content = "parsed",
                                                     filter = filter,
                                                     select = select)

    statuses <- sapply(statuses$value, function(x) {
      x$jobPreparationTaskExecutionInfo$result == "Success"
    })

    if (TRUE %in% statuses) {
      break
    }

    # Verify that all the job preparation tasks are not failing
    if (all(FALSE %in% statuses)) {
      cat("\n")
      stop(
        paste(
          sprintf("Job '%s' unable to install packages.", jobId),
          "Use the 'getJobFile' function to get more information about",
          "job package installation."
        )
      )
    }

    cat(".")
    Sys.sleep(10)
  }

  cat("\n")
}

getXmlValues <- function(xmlResponse, xmlPath) {
  xml2::xml_text(xml2::xml_find_all(xmlResponse, xmlPath))
}

areShallowEqual <- function(a, b) {
  !is.null(a) && !is.null(b) && a == b
}
