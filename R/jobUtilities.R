#' Get a list of job statuses from the given job ids
#'
#' @param jobIds A character vector of job ids
#'
#' @examples
#' \dontrun{
#' getJobList(c("job-001", "job-002"))
#' }
#' @export
getJobList <- function(jobIds = c()) {
  filter <- ""
  
  if (length(jobIds) > 1) {
    for (i in 1:length(jobIds)) {
      filter <- paste0(filter, sprintf("id eq '%s'", jobIds[i]), " or ")
    }
    
    filter <- substr(filter, 1, nchar(filter) - 3)
  }
  
  jobs <-
    rAzureBatch::listJobs(query = list("$filter" = filter, "$select" = "id,state"))
  print("Job List: ")
  
  for (j in 1:length(jobs$value)) {
    tasks <- rAzureBatch::listTask(jobs$value[[j]]$id)
    count <- 0
    if (length(tasks$value) > 0) {
      taskStates <-
        lapply(tasks$value, function(x)
          x$state == "completed")
      
      for (i in 1:length(taskStates)) {
        if (taskStates[[i]] == TRUE) {
          count <- count + 1
        }
      }
      
      summary <-
        sprintf(
          "[ id: %s, state: %s, status: %d",
          jobs$value[[j]]$id,
          jobs$value[[j]]$state,
          ceiling(count / length(tasks$value) * 100)
        )
      print(paste0(summary,  "% ]"))
    }
    else {
      print(
        sprintf(
          "[ id: %s, state: %s, status: %s ]",
          jobs$value[[j]]$id,
          jobs$value[[j]]$state,
          "No tasks were run."
        )
      )
    }
  }
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
getJobResult <- function(jobId = "", ...) {
  args <- list(...)
  
  if (!is.null(args$container)) {
    results <-
      rAzureBatch::downloadBlob(args$container, paste0("result/", jobId, "-merge-result.rds"))
  }
  else{
    results <-
      rAzureBatch::downloadBlob(jobId, paste0("result/", jobId, "-merge-result.rds"))
  }
  
  return(results)
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
  cat(sprintf("Job Preparation Status for job %s: Package(s) being installed", jobId))
  
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
      print("job prep object")
      print(x)
      print("result")
      print(x$jobPreparationTaskExecutionInfo$result)
    })
    
    print("statuses")
    print(statuses)
    
    if (TRUE %in% statuses) {
      break
    }
    
    # Verify that all the job preparation tasks are not failing
    if (all(FALSE %in% statuses)) {
      cat("\n")
      stop(paste(
        sprintf("Job '%s' unable to install packages.", jobId),
        "Use the 'getJobFile' function to get more information about",
        "job package installation."
      ))
    }
    
    cat(".")
    Sys.sleep(10)
  }
  
  cat("\n")
}