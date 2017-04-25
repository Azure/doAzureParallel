getInstallationCommand <- function(packages){
  installation <- ""

  for(package in packages){
    # CRAN Caret (6.0.73) package is not up to date as github. Need at least version 6.0.75 to work.
    if(package == "caret"){
      installation <- paste0(installation,
                             sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'devtools::install_github(args[1])\' %s", "topepo/caret/pkg/caret"),
                             ";")
    }
    else{
      installation <- paste0(installation,
                           sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1], dependencies=TRUE)\' %s", package),
                           ";")
    }
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
  commandLine <- sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"", paste0(paste(commands, sep = " ", collapse = "; "),"; "))
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

resizeCluster <- function(cluster, min, max, algorithm = "QUEUE", timeInterval = "PT5M"){
  resizePool(cluster$poolId,
             autoscaleFormula = getAutoscaleFormula(algorithm, min, max),
             autoscaleInterval = timeInterval)
}
