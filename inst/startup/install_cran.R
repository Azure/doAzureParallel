#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

status <- tryCatch({
  for (package in args) {
    if (!require(package, character.only = TRUE)) {
      install.packages(pkgs = package, lib.loc="/mnt/batch/tasks/shared/R/packages")
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
