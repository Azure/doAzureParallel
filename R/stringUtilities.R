getTaskFailedErrorString <- function(...) {
  errorMessage <- paste(
    ...,
    "Error handling is set to 'stop' and has proceeded to terminate the job.",
    "The user will have to handle deleting the job.",
    "If this is not the correct behavior, change the errorHandling property to 'pass'",
    " or 'remove' in the foreach object. Use the 'getJobFile' function to obtain the logs.",
    "For more information about getting job logs, follow this link:",
    paste0(
      "https://github.com/Azure/doAzureParallel/blob/master/docs/",
      "40-troubleshooting.md#viewing-files-directly-from-compute-node"
    )
  )

  return(errorMessage)
}

getJobPackageSummary <- function(packages) {
  if (length(packages) > 0) {
    cat(sprintf("%s: ", deparse(substitute(packages))), fill = TRUE)
    cat("\t")
    for (i in 1:length(packages)) {
      cat(packages[i], "; ", sep = "")
    }
    cat("\n")
  }
}

printJobInformation <- function(jobId,
                                chunkSize,
                                enableCloudCombine,
                                errorHandling,
                                wait,
                                autoDeleteJob,
                                cranPackages,
                                githubPackages,
                                bioconductorPackages) {
  cat(strrep('=', options("width")), fill = TRUE)
  cat(sprintf("Id: %s", jobId), fill = TRUE)
  cat(sprintf("chunkSize: %s", as.character(chunkSize)), fill = TRUE)
  cat(sprintf("enableCloudCombine: %s", as.character(enableCloudCombine)), fill = TRUE)

  packages <- cranPackages
  getJobPackageSummary(packages)
  getJobPackageSummary(githubPackages)
  getJobPackageSummary(bioconductorPackages)

  cat(sprintf("errorHandling: %s", as.character(errorHandling)), fill = TRUE)
  cat(sprintf("wait: %s", as.character(wait)), fill = TRUE)
  cat(sprintf("autoDeleteJob: %s", as.character(autoDeleteJob)), fill = TRUE)
  cat(strrep('=', options("width")), fill = TRUE)
}
