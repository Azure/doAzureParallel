#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

for (package in args) {
  if (!require(package, character.only = TRUE)) {
    install.packages(pkgs = package)
    require(package, character.only = TRUE)
  }
}

quit(save = "yes",
     status = 0,
     runLast = FALSE)
