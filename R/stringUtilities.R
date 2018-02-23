getTaskFailedErrorString <- function(...) {
  errorMessage <- paste(
    ...,
    "Error handling is set to 'stop' and has proceeded to terminate the job.",
    "The user will have to handle deleting the job.",
    "If this is not the correct behavior, change the errorhandling property to 'pass'",
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

printSharedKeyInformation <- function(config) {
  cat(sprintf("Batch Account: %s",
              config$batchAccount$name), fill = TRUE)
  cat(sprintf("Batch Account Url: %s",
              config$batchAccount$url),fill = TRUE)

  cat(sprintf("Storage Account: %s",
              config$storageAccount$name), fill = TRUE)
  cat(sprintf("Storage Account Url: %s", sprintf("https://%s.blob.core.windows.net",
                                                 config$storageAccount$name)),
      fill = TRUE)
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

extractResourceGroupname <- function(x) gsub(".*?/resourceGroups/(.*?)(/.*)*$",  "\\1", x)

extractSubscriptionID <- function(x) gsub(".*?/subscriptions/(.*?)(/.*)*$",   "\\1", x)

extractAccount <- function(x) gsub(".*?/*Accounts/(.*?)(/.*)*$", "\\1", x)

getAccountInformation <- function(x) {
  list(
    account = extractAccount(x),
    resourceGroup = extractResourceGroupname(x),
    subscriptionId = extractSubscriptionID(x)
  )
}
