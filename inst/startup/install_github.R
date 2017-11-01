#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

# Assumption: devtools is already installed in the container
jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
.libPaths(c(jobPrepDirectory, "/mnt/batch/tasks/shared/R/packages", .libPaths()))
status <- tryCatch({
    for (package in args) {
      packageDirectory <- strsplit(package, "/")[[1]]
      packageName <- packageDirectory[length(packageDirectory)]

      if (!require(packageName, character.only = TRUE)) {
        devtools::install_github(package)
        require(packageName, character.only = TRUE)
    }
  }

  0
},
error = function(e) {
  cat(sprintf(
    "Error getting parent environment: %s\n",
    conditionMessage(e)
  ))

  # Install packages doesn't return a non-exit code.
  # Using '1' as the default non-exit code
  1
})

quit(save = "yes",
     status = status,
     runLast = FALSE)
