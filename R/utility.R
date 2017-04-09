getInstallationCommand <- function(packages){
  installation <- ""

  for(package in packages){
    # CRAN Caret (6.0.73) package is not up to date as github. Need at least version 6.0.75 to work.
    if(package == "caret"){
      installation <- paste0(installation,
                             sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'devtools::install_github(args[1])\' %s", "topepo/caret/pkg/caret"),
                             ";")
    }
    else{
      installation <- paste0(installation,
                           sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1], dependencies=TRUE)\' %s", package),
                           ";")
    }
  }

  installation <- substr(installation, 1, nchar(installation) - 1)
}

getGithubInstallationCommand <- function(packages){
  installation <- ""
  installation <- paste0(installation,
                         sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1], dependencies=TRUE)\' %s", "devtools"),
                         ";")

  if(length(packages) != 0){
    for(package in packages){
      installation <- paste0(installation,
                             sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'devtools::install_github(args[1])\' %s", package),
                             ";")
    }
  }

  installation <- substr(installation, 1, nchar(installation) - 1)
}

linuxWrapCommands <- function(commands = c()){
  commandLine <- sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"", paste0(paste(commands, sep = " ", collapse = "; "),"; "))
}
