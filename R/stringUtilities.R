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

printCluster <- function(cluster, resourceFiles = list()) {
  cat(strrep('=', options("width")), fill = TRUE)
  cat(sprintf("Id: %s", cluster$name), fill = TRUE)

  cat(sprintf("Configurations:"), fill = TRUE)
  cat(sprintf("\tNode Size: %s", cluster$vmSize), fill = TRUE)
  cat(sprintf("\tMaxTasksPerNode: %s", cluster$maxTasksPerNode), fill = TRUE)
  cat(sprintf("\tDocker Image: %s", cluster$containerImage), fill = TRUE)

  cranPackages <- cluster$rPackages$cran
  githubPackages <- cluster$rPackages$github
  bioconductorPackages <- cluster$rPackages$bioconductor
  getJobPackageSummary(cranPackages)
  getJobPackageSummary(githubPackages)
  getJobPackageSummary(bioconductorPackages)

  cat(sprintf("Nodes:"), fill = TRUE)
  cat(sprintf("\tAutoscale Formula: %s", cluster$poolSize$autoscaleFormula), fill = TRUE)
  cat(sprintf("\tDedicated:"), fill = TRUE)
  cat(sprintf("\t\tMin: %s", cluster$poolSize$dedicatedNodes$min), fill = TRUE)
  cat(sprintf("\t\tMax: %s", cluster$poolSize$dedicatedNodes$max), fill = TRUE)
  cat(sprintf("\tLow Priority:"), fill = TRUE)
  cat(sprintf("\t\tMin: %s", cluster$poolSize$lowPriorityNodes$min), fill = TRUE)
  cat(sprintf("\t\tMax: %s", cluster$poolSize$lowPriorityNodes$max), fill = TRUE)

  if (!is.null(resourceFiles) &&
      length(resourceFiles) > 0) {
    cat(sprintf("Resource Files:"), fill = TRUE)

    for (i in 1:length(resourceFiles)) {
      cat(sprintf("\t%s",
                  resourceFiles[[i]]$filePath), fill = TRUE)
    }
  }
  cat(strrep('=', options("width")), fill = TRUE)
}
