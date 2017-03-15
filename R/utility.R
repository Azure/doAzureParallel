getInstallationCommand <- function(packages){
  installation <- ""

  for(package in packages){
    installation <- paste0(installation,
                           sprintf(" R -e \'install.packages(\"%s\", dependencies=TRUE)\'", package),
                           ";")
  }

  installation <- substr(installation, 1, nchar(installation) - 1)
}

getGithubInstallationCommand <- function(packages){
  installation <- ""
  installation <- paste0(installation,
                         sprintf(" R -e \'install.packages(\"%s\", dependencies=TRUE)\'", "devtools"),
                         ";")

  if(length(packages) != 0){
    for(package in packages){
      installation <- paste0(installation,
                             sprintf(" R -e \'library(%s); install_github(\"%s\")\'", "devtools", package),
                             ";")
    }
  }

  installation <- substr(installation, 1, nchar(installation) - 1)
}
