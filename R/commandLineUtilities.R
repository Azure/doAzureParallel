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
  
  #TODO: Plumb this in.
  sharedPackagesDirectory <- paste(
    Sys.getenv("AZ_BATCH_NODE_ROOT_DIR"),
    "shared",
    "R",
    "packages",
    sep = "/")
  
  # At this point we cannot use install_cran.R and install_github.R because they are not yet available.
  if (type == "cran") {
    script <-
      paste(
        "Rscript -e \'args <- commandArgs(TRUE)\'",
        "-e \'options(warn=2)\'",
        "-e \'.libPaths( c( \\\"/mnt/batch/tasks/shared/R/packages\\\", .libPaths()) );install.packages(args[1])\' %s",
        sep = " "
      )
  }
  else if (type == "github") {
    script <-
      paste(
        "Rscript -e \'args <- commandArgs(TRUE)\'",
        "-e \'options(warn=2)\'",
        "-e \'.libPaths( c( \\\"/mnt/batch/tasks/shared/R/packages\\\", .libPaths()) );devtools::install_github(args[1])\' %s",
        sep = " "
      )
  }
  else if (type == "bioconductor") {
    script <-
      paste(
        "Rscript -e \'args <- commandArgs(TRUE)\'",
        "-e \'options(warn=2)\'",
        "-e \'.libPaths( c( \\\"/mnt/batch/tasks/shared/R/packages\\\", .libPaths()) );devtools::install_github(args[1])\' %s",
        sep = " "
      )
  }
  else {
    stop("Using an incorrect package source")
  }
  
  for (i in 1:length(packages)) {
    poolInstallationCommand[i] <- sprintf(script, packages[i])
  }
  
  poolInstallationCommand
}

dockerRunCommand <-
  function(containerImage,
           command,
           containerName = NULL,
           runAsDaemon = FALSE) {
    dockerOptions <- paste(
      "--rm",
      "-v $AZ_BATCH_NODE_ROOT_DIR:$AZ_BATCH_NODE_ROOT_DIR",
      "-e AZ_BATCH_NODE_ROOT_DIR=$AZ_BATCH_NODE_ROOT_DIR",
      "-e AZ_BATCH_TASK_ID=$AZ_BATCH_TASK_ID",
      "-e AZ_BATCH_JOB_ID=$AZ_BATCH_JOB_ID",
      "-e AZ_BATCH_TASK_WORKING_DIR=$AZ_BATCH_TASK_WORKING_DIR",
      "-e AZ_BATCH_JOB_PREP_WORKING_DIR=$AZ_BATCH_JOB_PREP_WORKING_DIR",
      "-e AZ_BATCH_TASK_WORKING_DIR=$AZ_BATCH_TASK_WORKING_DIR",
      "-e BLOBXFER_SASKEY=$BLOBXFER_SASKEY",
      sep = " "
    )
    
    if (runAsDaemon) {
      dockerOptions <- paste("-d", dockerOptions, sep = " ")
    }
    
    if (!is.null(containerName)) {
      dockerOptions <-
        paste("--name", containerName, dockerOptions, sep = " ")
    }
    
    dockerRunCommand <-
      paste("docker run", dockerOptions, containerImage, command, sep = " ")
    dockerRunCommand
  }

linuxWrapCommands <- function(commands = c()) {
  # Sanitize the vector and don't allow empty values
  cleanCommands <- commands[lapply(commands, length) > 0]
  
  commandLine <- "ls"
  if (length(cleanCommands) > 0) {
    # Do not allow absolute paths is enforced in lintr
    commandLine <-
      sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"",
              paste0(paste(
                cleanCommands, sep = " ", collapse = "; "
              ), ";"))
  }
  
  commandLine
}