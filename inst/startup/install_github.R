#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

# Assumption: devtools is already installed based on Azure DSVM
status <- tryCatch({
  for (package in args) {
    packageDirectory <- strsplit(package, "/")[[1]]
    packageName <- packageDirectory[length(packageDirectory)]

    if (!require(package, character.only = TRUE)) {
      devtools::install_github(packageDirectory)
      require(package, character.only = TRUE)
    }
  }

  return(0)
},
error = function(e) {
  cat(sprintf(
    "Error getting parent environment: %s\n",
    conditionMessage(e)
  ))

  # Install packages doesn't return a non-exit code.
  # Using '1' as the default non-exit code
  return(1)
})

quit(save = "yes",
     status = status,
     runLast = FALSE)
