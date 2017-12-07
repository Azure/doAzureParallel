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

  jobs <-
    rAzureBatch::listJobs(query = list("$filter" = filterClause, "$select" = "id,state"))

  id <- character(length(jobs$value))
  state <- character(length(jobs$value))
  status <- character(length(jobs$value))
  failedTasks <- integer(length(jobs$value))
  totalTasks <- integer(length(jobs$value))

  if (length(jobs$value) > 0) {
    if (is.null(jobs$value[[1]]$id)) {
      stop(jobs$value)
    }
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

#' Wait for current tasks to complete
#'
#' @export
waitForTasksToComplete <-
  function(jobId, timeout, errorHandling = "stop") {
    cat("Waiting for tasks to complete. . .", fill = TRUE)

    totalTasks <- 0
    currentTasks <- rAzureBatch::listTask(jobId)

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
        rAzureBatch::listTask(jobId, skipToken = URLdecode(skipTokenValue))

      totalTasks <- totalTasks + length(currentTasks$value)
    }

    if (enableCloudCombine) {
      totalTasks <- totalTasks - 1
    }

    timeToTimeout <- Sys.time() + timeout

    repeat {
      taskCounts <- rAzureBatch::getJobTaskCounts(jobId)

      # Assumption: Merge task will always be the last one in the queue
      if (enableCloudCombine) {
        if (taskCounts$completed > totalTasks) {
          taskCounts$completed <- totalTasks
        }

        if (taskCounts$active >= 1) {
          taskCounts$active <- taskCounts$active - 1
        }
      }

      runningOutput <- paste0("Running: ", taskCounts$running)
      queueOutput <- paste0("Queue: ", taskCounts$active)
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

      validationFlag <-
        (taskCounts$validationStatus == "Validated" &&
           totalTasks <= 200000) ||
        totalTasks > 200000

      if (taskCounts$failed > 0 &&
          errorHandling == "stop" &&
          validationFlag) {
        cat("\n")

        select <- "id, executionInfo"
        failedTasks <-
          rAzureBatch::listTask(jobId, select = select)

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
          if (!is.null(failedTasks$value[[i]]$executionInfo$result) &&
              failedTasks$value[[i]]$executionInfo$result == "Failure") {
            tasksFailureWarningLabel <-
              paste0(tasksFailureWarningLabel,
                     sprintf("%s\n", failedTasks$value[[i]]$id))
          }
        }

        warning(sprintf(tasksFailureWarningLabel,
                        taskCounts$failed))

        response <- rAzureBatch::terminateJob(jobId)
        httr::stop_for_status(response)

        stop(sprintf(
          getTaskFailedErrorString("Errors have occurred while running the job '%s'."),
          jobId
        ))
      }

      if (Sys.time() > timeToTimeout) {
        stop(sprintf(
          paste(
            "Timeout has occurred while waiting for tasks to complete.",
            "Users will have to manually track the job '%s' and get the results.",
            "Use the getJobResults function to obtain the results and getJobList for",
            "tracking job status. To change the timeout, set 'timeout' property in the",
            "foreach's options.azure."
          )
        ),
        jobId)
      }

      if (taskCounts$completed >= totalTasks &&
          (taskCounts$validationStatus == "Validated" ||
           totalTasks >= 200000)) {
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
        mergeTask <- rAzureBatch::getTask(jobId, paste0(jobId, "-merge"))

        # This test needs to go first as Batch service will not return an execution info as null
        if (is.null(mergeTask$executionInfo$result)) {
          cat(".")
          Sys.sleep(5)
          next
        }

        if (mergeTask$executionInfo$result == "Success") {
          break
        }
        else {
          rAzureBatch::terminateJob(jobId)

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
