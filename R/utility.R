getInstallationCommand <- function(packages){
  installation <- ""

  for(package in packages){
    installation <- paste0(installation,
                         sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1], dependencies=TRUE)\' %s", package),
                         ";")
  }

  installation <- substr(installation, 1, nchar(installation) - 1)
}

getGithubInstallationCommand <- function(packages){
  installation <- ""
  installation <- paste0(installation,
                         sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1], dependencies=TRUE)\' %s", "devtools"),
                         ";")

  if(length(packages) != 0){
    for(package in packages){
      installation <- paste0(installation,
                             sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'devtools::install_github(args[1])\' %s", package),
                             ";")
    }
  }

  installation <- substr(installation, 1, nchar(installation) - 1)
}

linuxWrapCommands <- function(commands = c()){
  commandLine <- sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"",
                         paste0(paste(commands, sep = " ", collapse = "; "),"; "))
}

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

waitForNodesToComplete <- function(poolId, timeout, ...){
  print("Booting compute nodes. . . ")

  args <- list(...)

  if(!args$targetDedicated){
    stop("Pool's current target dedicated not calculated. Please try again.")
  }

  numOfNodes <- args$targetDedicated

  pb <- txtProgressBar(min = 0, max = numOfNodes, style = 3)
  prevCount <- 0
  timeToTimeout <- Sys.time() + timeout

  while(Sys.time() < timeToTimeout){
    nodes <- listPoolNodes(poolId)

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
          return(0)
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
