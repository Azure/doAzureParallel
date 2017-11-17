#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)
jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
.libPaths(c("/mnt/batch/tasks/shared/R/packages", .libPaths()))

if (jobPrepDirectory != "") {
  .libPaths(c(jobPrepDirectory, .libPaths()))
}

status <- tryCatch({

  library(BiocInstaller)
  for (package in args) {
    if (!require(package, character.only = TRUE)) {
      biocLite(pkgs = package)
      require(package, character.only = TRUE)
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
