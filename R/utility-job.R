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

  config <- getConfiguration()
  job <- config$batchClient$jobOperations$getJob(jobId)

  metadata <-
    list(
      chunkSize = 1,
      enableCloudCombine = "TRUE",
      packages = "",
      errorHandling = "stop",
      wait = "TRUE"
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
    cat(sprintf("\terrorHandling: %s", metadata$errorHandling),
        fill = TRUE)
    cat(sprintf("\twait: %s", metadata$wait),
        fill = TRUE)
  }

  taskCounts <- config$batchClient$jobOperations$getJobTaskCounts(
    jobId)

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
    cat(sprintf("\njob state: %s", job$state), fill = TRUE)
  }

  jobObj <- list(jobId = job$id,
                 metadata = metadata,
                 tasks = tasks,
                 jobState = job$state)

  return(jobObj)
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
      for (i in 1:length(filter$state)) {
        filterClause <-
          paste0(filterClause,
                 sprintf("state eq '%s'", filter$state[i]),
                 " or ")
      }

      filterClause <-
        substr(filterClause, 1, nchar(filterClause) - 3)
    }
  }
  config <- getOption("az_config")
  jobs <-
    config$batchClient$jobOperations$listJobs(
      query = list("$filter" = filterClause, "$select" = "id,state"))

  id <- character(length(jobs$value))
  state <- character(length(jobs$value))
  status <- character(length(jobs$value))
  failedTasks <- integer(length(jobs$value))
  totalTasks <- integer(length(jobs$value))

  if (length(jobs$value) > 0) {
    if (is.null(jobs$value[[1]]$id)) {
      stop(jobs$value)
    }
    config <- getOption("az_config")

    for (j in 1:length(jobs$value)) {
      id[j] <- jobs$value[[j]]$id
      state[j] <- jobs$value[[j]]$state
      taskCounts <-
        config$batchClient$jobOperations$getJobTaskCounts(
          jobId = jobs$value[[j]]$id)
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
  config <- getConfiguration()
  storageClient <- config$storageClient

  if (nchar(jobId) < 3) {
    stop("jobId must contain at least 3 characters.")
  }

  metadata <- readMetadataBlob(jobId)

  if (!is.null(metadata)) {
    job <- getJob(jobId, verbose = FALSE)

    if (job$jobState == "active") {
      stop(sprintf("job %s has not finished yet, please try again later",
                   job$jobId))
    } else if (job$jobState != "completed") {
      stop(sprintf(
        "job %s is in %s state, no job result is available",
        job$jobId,
        job$jobState
      ))
    }

    # if the job has failed task
    if (job$tasks$failed > 0) {
      if (metadata$errorHandling == "stop") {
        stop(
          sprintf(
            "job %s has failed tasks and error handling is set to 'stop', no result will be available",
            job$jobId
          )
        )
      } else {
        if (job$tasks$succeeded == 0) {
          stop(sprintf(
            "all tasks failed for job %s, no result will be available",
            job$jobId
          ))
        }
      }
    }

    if (metadata$enableCloudCombine == "FALSE") {
      cat("enableCloudCombine is set to FALSE, we will merge job result locally",
          fill = TRUE)

      results <- .getJobResultLocal(job)
      return(results)
    }
  }

  tempFile <- tempfile("getJobResult", fileext = ".rds")

  retryCounter <- 0
  maxRetryCount <- 3
  repeat {
    if (retryCounter > maxRetryCount) {
      stop(
        sprintf(
          "Error getting job result: Maxmium number of retries (%d) reached\r\n%s",
          maxRetryCount,
          paste0(results, "\r\n")
        )
      )
    } else {
      retryCounter <- retryCounter + 1
    }

    results <- storageClient$blobOperations$downloadBlob(
      jobId,
      "results/merge-result.rds",
      downloadPath = tempFile,
      overwrite = TRUE
    )

    if (is.vector(results)) {
      results <- readRDS(tempFile)
      return(results)
    }

    # wait for 5 seconds for the result to be available
    Sys.sleep(5)
  }
}

.getJobResultLocal <- function(job) {
  config <- getConfiguration()
  storageClient <- config$storageClient

  results <- vector("list", job$tasks$completed)
  count <- 1

  for (i in 1:job$tasks$completed) {
    retryCounter <- 0
    maxRetryCount <- 3
    repeat {
      if (retryCounter > maxRetryCount) {
        stop(
          sprintf("Error getting job result: Maxmium number of retries (%d) reached\r\n",
                  maxRetryCount)
        )
      } else {
        retryCounter <- retryCounter + 1
      }

      tryCatch({
        # Create a temporary file on disk
        tempFile <- tempfile(fileext = ".rds")

        # Create the temporary file's directory if it doesn't exist
        dir.create(dirname(tempFile), showWarnings = FALSE)

        # Download the blob to the temporary file
        storageClient$blobOperations$downloadBlob(
          containerName = job$jobId,
          blobName = paste0("results/", i, "-result.rds"),
          downloadPath = tempFile,
          overwrite = TRUE
        )

        #Read the rds as an object in memory
        taskResult <- readRDS(tempFile)

        for (t in 1:length(taskResult)) {
          if (isError(taskResult[[t]])) {
            if (metadata$errorHandling == "stop") {
              stop("Error found")
            }
            else if (metadata$errorHandling == "pass") {
              results[[count]] <- NA
              count <- count + 1
            }
          } else {
            results[[count]] <- taskResult[[t]]
            count <- count + 1
          }
        }

        # Delete the temporary file
        file.remove(tempFile)

        break
      },
      error = function(e) {
        warning(sprintf(
          "error downloading task result %s from blob, retrying...\r\n%s",
          paste0(job$jobId, "results/", i, "-result.rds"),
          e
        ))
      })
    }
  }
  # Return the object
  return(results)
}

#' Delete a job
#'
#' @param jobId A job id
#'
#' @examples
#' \dontrun{
#' deleteJob("job-001")
#' }
#' @export
deleteJob <- function(jobId, verbose = TRUE) {
  config <- getConfiguration()
  batchClient <- config$batchClient

  deleteStorageContainer(jobId, verbose)

  response <- batchClient$jobOperations$deleteJob(jobId, content = "response")

  tryCatch({
      httr::stop_for_status(response)

      if (verbose) {
        cat(sprintf("Your job '%s' has been deleted.", jobId),
            fill = TRUE)
      }
    },
    error = function(e) {
      if (verbose) {
        response <- httr::content(response, encoding = "UTF-8")
        cat("Call: deleteJob", fill = TRUE)
        cat(sprintf("Exception: %s", response$message$value),
            fill = TRUE)
      }
    }
  )
}

#' Terminate a job
#'
#' @param jobId A job id
#'
#' @examples
#' \dontrun{
#' terminateJob("job-001")
#' }
#' @export
terminateJob <- function(jobId) {
  config <- getConfiguration()
  batchClient <- config$batchClient

  response <- batchClient$jobOperations$terminateJob(jobId, content = "response")

  if (response$status_code == 202) {
    cat(sprintf("Your job '%s' has been terminated.", jobId),
        fill = TRUE)
  } else if (response$status_code == 404) {
    cat(sprintf("Job '%s' does not exist.", jobId),
        fill = TRUE)
  } else if (response$status_code == 409) {
    cat(sprintf("Job '%s' has already completed.", jobId),
        fill = TRUE)
  }
}

#' Wait for current tasks to complete
#'
#' @export
waitForTasksToComplete <-
  function(jobId, timeout, errorHandling = "stop") {
    cat("\nWaiting for tasks to complete. . .", fill = TRUE)
    config <- getConfiguration()
    batchClient <- config$batchClient

    totalTasks <- 0
    currentTasks <- batchClient$taskOperations$list(jobId)

    jobInfo <- getJob(jobId, verbose = FALSE)
    enableCloudCombine <- as.logical(jobInfo$metadata$enableCloudCombine)

    if (is.null(currentTasks$value)) {
      stop(paste0("Error: ", currentTasks$message$value))
      return()
    }

    totalTasks <- totalTasks + length(currentTasks$value)

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
        batchClient$taskOperations$list(jobId, skipToken = URLdecode(skipTokenValue))

      totalTasks <- totalTasks + length(currentTasks$value)
    }

    if (enableCloudCombine) {
      totalTasks <- totalTasks - 1
    }

    timeToTimeout <- Sys.time() + timeout

    repeat {
      taskCounts <- batchClient$jobOperations$getJobTaskCounts(jobId)

      # Assumption: Merge task will always be the last one in the queue
      if (enableCloudCombine) {
        if (taskCounts$completed > totalTasks) {
          taskCounts$completed <- totalTasks
        }

        if (taskCounts$completed == totalTasks && taskCounts$running == 1) {
          taskCounts$running <- 0
        }

        if (taskCounts$active >= 1) {
          taskCounts$active <- taskCounts$active - 1
        }
      }

      runningOutput <- paste0("Running: ", taskCounts$running)
      queueOutput <- paste0("Queued: ", taskCounts$active)
      completedOutput <- paste0("Completed: ", taskCounts$completed)
      failedOutput <- paste0("Failed: ", taskCounts$failed)

      cat("\r",
          sprintf("| %s | %s | %s | %s | %s |",
                  paste0("Progress: ", sprintf("%.2f%% (%s/%s)", (taskCounts$completed / totalTasks) * 100,
                                               taskCounts$completed,
                                               totalTasks)),
                  runningOutput,
                  queueOutput,
                  completedOutput,
                  failedOutput),
          sep = "")

      flush.console()

      if (taskCounts$failed > 0 &&
          errorHandling == "stop") {
        cat("\n")

        select <- "id, executionInfo"
        filter <- "executionInfo/result	eq 'failure'"
        failedTasks <-
          batchClient$taskOperations$list(jobId, select = select, filter = filter)

        tasksFailureWarningLabel <-
          sprintf(
            paste(
              "%i task(s) failed while running the job.",
              "This caused the job to terminate automatically.",
              "To disable this behavior and continue on failure, set .errorHandling='remove | pass'",
              "in the foreach loop\n"
            ),
            taskCounts$failed
          )

        for (i in 1:length(failedTasks$value)) {
            tasksFailureWarningLabel <-
              paste0(tasksFailureWarningLabel,
                     sprintf("%s\n", failedTasks$value[[i]]$id))
        }

        warning(sprintf(tasksFailureWarningLabel,
                        taskCounts$failed))

        response <- batchClient$jobOperations$terminateJob(jobId)
        httr::stop_for_status(response)

        stop(sprintf(
          getTaskFailedErrorString("Errors have occurred while running the job '%s'."),
          jobId
        ))
      }

      if (Sys.time() > timeToTimeout) {
        stop(
          sprintf(
            paste(
              "Timeout has occurred while waiting for tasks to complete.",
              "Users will have to manually track the job '%s' and get the results.",
              "Use the getJobResults function to obtain the results and getJobList for",
              "tracking job status. To change the timeout, set 'timeout' property in the",
              "foreach's options.azure."
            ),
            jobId
          )
        )
      }

      jobInfo <- getJob(jobId, verbose = FALSE)
      if (taskCounts$completed >= totalTasks ||
          jobInfo$jobState == "completed" ||
          jobInfo$jobState == "terminating") {
        cat("\n")
        break
      }

      Sys.sleep(10)
    }

    cat("Tasks have completed. ")
    if (enableCloudCombine) {
      cat("Merging results")

      # Wait for merge task to complete
      repeat {
        # Verify that the merge cloud task didn't have any errors
        mergeTask <- batchClient$taskOperations$get(jobId, "merge")

        # This test needs to go first as Batch service will not return an execution info as null
        if (is.null(mergeTask$executionInfo$result)) {
          cat(".")
          Sys.sleep(5)
          next
        }

        if (grepl(mergeTask$executionInfo$result, "success", ignore.case = TRUE)) {
          cat(" Completed.")
          break
        }
        else {
          batchClient$jobOperations$terminateJob(jobId)

          # The foreach will not be able to run properly if the merge task fails
          # Stopping the user from processing a merge task that has failed
          stop(sprintf(
            getTaskFailedErrorString("An error has occurred in the merge task of the job '%s'."),
            jobId
          ))
        }

        cat(".")
        Sys.sleep(5)
      }
    }

    cat("\n")
  }

waitForJobPreparation <- function(jobId, poolId) {
  cat("\nJob Preparation Status: Package(s) being installed")
  config <- getConfiguration()
  batchClient <- config$batchClient

  filter <- paste(
    sprintf("poolId eq '%s' and", poolId),
    "jobPreparationTaskExecutionInfo/state eq 'completed'"
  )

  select <- "jobPreparationTaskExecutionInfo"

  repeat {
    statuses <- batchClient$jobOperations$getJobPreparationStatus(
      jobId,
      content = "parsed",
      filter = filter,
      select = select
    )

    statuses <- sapply(statuses$value, function(x) {
      grepl(x$jobPreparationTaskExecutionInfo$result,
            "success",
            ignore.case = TRUE)
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
}

isError <- function(x) {
  inherits(x, "simpleError") || inherits(x, "try-error")
}
