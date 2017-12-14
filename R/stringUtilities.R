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
