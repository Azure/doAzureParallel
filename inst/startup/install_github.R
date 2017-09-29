#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

# Assumption: devtools is already installed based on Azure DSVM

for (package in args) {
  packageDirectory <- strsplit(package, "/")[[1]]
  packageName <- packageDirectory[length(packageDirectory)]

  if (!require(packageName, character.only = TRUE)) {
    devtools::install_github(new = "/mnt/batch/tasks/shared/R/packages", packageDirectory)
    require(packageName, character.only = TRUE)
  }
}

quit(save = "yes",
     status = 0,
     runLast = FALSE)
