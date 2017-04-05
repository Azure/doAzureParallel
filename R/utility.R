getInstallationCommand <- function(packages){
  installation <- ""

  for(package in packages){
    installation <- paste0(installation,
                           sprintf("Rscript -e \'args <- commandArgs(TRUE)\' -e \'install.packages(args[1], dependencies=TRUE)\' %s", package),
                           ";")
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
