getLinuxAptGetSoftwardInstallationCommand <- function() {
  command <- paste("apt-get -y upgrade;",
                   "apt-get -y install libcurl4-openssl-dev;",
                   "apt-get -y install libssl-dev",
                   sep = " ")
  command
}

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
  
  # At this point we cannot use install_cran.R and install_github.R because they are not yet available.
  if (type == "cran") {
    script <-
      "Rscript -e \'args <- commandArgs(TRUE)\' -e \'options(warn=2)\' -e \'install.packages(args[1], lib=\"/mnt/batch/tasks/shared/R/packages\")\' %s"
  }
  else if (type == "github") {
    script <-
      "Rscript -e \'args <- commandArgs(TRUE)\' -e \'options(warn=2)\' -e \'devtools::install_github(new = \"/mnt/batch/tasks/shared/R/packages\", args[1])\' %s"
  }
  else {
    stop("Using an incorrect package source")
  }
  
  for (i in 1:length(packages)) {
    poolInstallationCommand[i] <- sprintf(script, packages[i])
  }
  
  poolInstallationCommand
}

dockerRunCommand <- function(containerName, containerImage, command, runAsDaemon = TRUE) {
  dockerOptions <- paste("--rm",
                         "-v /mnt/batch/tasks:/mnt/batch/tasks",
                         "-e DOCKER_WORKING_DIR=/batch/startup/wd",
                         "-e AZ_BATCH_JOB_PREP_WORKING_DIR=$AZ_BATCH_JOB_PREP_WORKING_DIR",
                         "-e AZ_BATCH_TASK_WORKING_DIR=$AZ_BATCH_TASK_WORKING_DIR",
                         "-e BLOBXFER_SASKEY=$BLOBXFER_SASKEY",
                         sep = " ")
  
  if (runAsDaemon) {
    dockerOptions <- paste("-d", dockerOptions, sep = " ")
  }
  
  dockerRunCommand <- paste("docker run", dockerOptions, "--name", containerName, containerImage, command, sep = " ")
  dockerRunCommand
}

dockerExecCommand <- function(containerName, command) {
  dockerExecCommand <- paste("docker exec", containerName, command, sep = " ")
  dockerExecCommand
}

dockerStopCommand <- function(containerName) {
  dockerStopCommand <- paste("docker stop", containerName, sep = " ")
  dockerStopCommand
}

linuxWrapCommands <- function(commands = c()) {
  
  # Sanitize the vector and don't allow empty values
  cleanCommands <- commands[lapply(commands, length)>0]
  
  # Do not allow absolute paths is enforced in lintr
  commandLine <-
    sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"",
            paste0(paste(
              cleanCommands, sep = " ", collapse = "; "
            ), ";"))
  
  commandLine
}