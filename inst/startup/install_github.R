#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

# Assumption: devtools is already installed in the container
jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
.libPaths(c(jobPrepDirectory, "/mnt/batch/tasks/shared/R/packages", .libPaths()))

for (package in args) {
  packageDirectory <- strsplit(package, "/")[[1]]
  packageName <- packageDirectory[length(packageDirectory)]

  if (!require(packageName, character.only = TRUE)) {
    devtools::install_github(new = "$AZ_BATCH_JOB_PREP_WORKING_DIR", packageDirectory)
    require(packageName, character.only = TRUE)
  }
}

quit(save = "yes",
     status = 0,
     runLast = FALSE)
