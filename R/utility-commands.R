getJobPackageInstallationCommand <- function(type, packages) {
  script <- ""
  if (type == "cran") {
    script <- "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_cran.R"
  }
  else if (type == "github") {
    script <- "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_github.R"
  }
  else if (type == "bioconductor") {
    script <-
      "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_bioconductor.R"
  }
  else {
    stop("Using an incorrect package source")
  }

  if (!is.null(packages) && length(packages) > 0) {
    packageCommands <- paste0(packages, collapse = " ")
    script <- paste0(script, " ", packageCommands)
  }
}

getPoolPackageInstallationCommand <- function(type, packages, githubAuthenticationToken = "") {
  sharedPackagesDirectory <- "/mnt/batch/tasks/shared/R/packages"

  libPathsCommand <- paste0('\'.libPaths( c( \\\"',
                            sharedPackagesDirectory,
                            '\\\", .libPaths()));')

  installCommand <-
    paste("Rscript -e \'args <- commandArgs(TRUE)\'",
          "-e \'options(warn=2)\'")

  # At this point we cannot use install_cran.R and install_github.R because they are not yet available.
  if (type == "cran") {
    poolInstallationCommand <-
      paste(installCommand,
            paste("-e",
                  libPathsCommand,
                  "install.packages(args)\'")
            )
  }
  else if (type == "github") {
    if (githubAuthenticationToken != "") {
      installCommand <-
        paste(installCommand,
              sprintf("-e \'githubAuthToken <- \\\"%s\\\"\'", githubAuthenticationToken),
              "-e \'Sys.setenv(GITHUB_PAT = githubAuthToken)\'")
    }

    poolInstallationCommand <-
      paste(
        installCommand,
        paste(
          "-e",
          libPathsCommand,
          "devtools::install_github(args)\'"
        )
      )
  }
  else if (type == "bioconductor") {
    poolInstallationCommand <- "Rscript /mnt/batch/tasks/startup/wd/install_bioconductor.R"
  }
  else {
    stop("Using an incorrect package source")
  }

  for (i in 1:length(packages)) {
    poolInstallationCommand <- paste(poolInstallationCommand, packages[i])
  }

  poolInstallationCommand
}

dockerLoginCommand <-
  function(username,
           password,
           registry) {
    writePasswordCommand <- paste(
      "echo",
      password,
      ">> ~/pwd.txt"
    )

    loginCommand <- paste(
      "cat ~/pwd.txt |",
      "docker login",
      "-u",
      username,
      "--password-stdin",
      registry
    )

    return(c(writePasswordCommand, loginCommand))
  }

dockerPullCommand <-
  function(containerImage) {
    pullCommand <- paste(
      "docker pull",
      containerImage
    )

    return(pullCommand)
  }

dockerRunCommand <-
  function(containerImage,
           command,
           containerName = NULL,
           runAsDaemon = FALSE,
           includeEnvironmentVariables = TRUE) {
    dockerOptions <- paste(
      "--rm",
      "-v $AZ_BATCH_NODE_ROOT_DIR:$AZ_BATCH_NODE_ROOT_DIR",
      "-e AZ_BATCH_NODE_ROOT_DIR=$AZ_BATCH_NODE_ROOT_DIR",
      "-e AZ_BATCH_NODE_STARTUP_DIR=$AZ_BATCH_NODE_STARTUP_DIR"
    )

    if (runAsDaemon) {
      dockerOptions <- paste(dockerOptions, "-d", dockerOptions, sep = " ")
    }

    if (!is.null(containerName)) {
      dockerOptions <-
        paste(dockerOptions, "--name", containerName, dockerOptions)
    }

    if (includeEnvironmentVariables) {
      dockerOptions <-
        paste(
          dockerOptions,
          "-e AZ_BATCH_NODE_SHARED_DIR=$AZ_BATCH_NODE_SHARED_DIR",
          "-e AZ_BATCH_TASK_ID=$AZ_BATCH_TASK_ID",
          "-e AZ_BATCH_JOB_ID=$AZ_BATCH_JOB_ID",
          "-e AZ_BATCH_TASK_WORKING_DIR=$AZ_BATCH_TASK_WORKING_DIR",
          "-e AZ_BATCH_JOB_PREP_WORKING_DIR=$AZ_BATCH_JOB_PREP_WORKING_DIR",
          "-e BLOBXFER_SASKEY=$BLOBXFER_SASKEY"
        )

      config <- getConfiguration()
      if (!is.null(config$githubAuthenticationToken)
          && config$githubAuthenticationToken != "") {
        dockerOptions <-
          paste(
            dockerOptions,
            "-e GITHUB_PAT=$GITHUB_PAT"
          )
      }
    }

    dockerRunCommand <-
      paste("docker run", dockerOptions, containerImage, command)
    dockerRunCommand
  }

linuxWrapCommands <- function(commands = c()) {
  # Sanitize the vector and don't allow empty values
  cleanCommands <- commands[lapply(commands, length) > 0]

  commandLine <- ""
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
