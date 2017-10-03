#' Polling method to check status of cluster boot up
#'
#' @param poolId The cluster name to poll for
#' @param timeout Timeout in seconds, default timeout is one day
#'
#' @examples
#' \dontrun{
#' waitForNodesToComplete(poolId = "testCluster", timeout = 3600)
#' }
#' @export
waitForNodesToComplete <- function(poolId, timeout = 86400) {
  cat("Booting compute nodes. . . ", fill = TRUE)

  cat(poolId)
  pool <- rAzureBatch::getPool(poolId)

  # Validate the getPool request first, before setting the progress bar
  if (!is.null(pool$code) && !is.null(pool$message)) {
    stop(sprintf("Code: %s - Message: %s", pool$code, pool$message))
  }

  if (pool$targetDedicatedNodes + pool$targetLowPriorityNodes <= 0) {
    stop("Pool count needs to be greater than 0.")
  }

  totalNodes <-
    pool$targetDedicatedNodes + pool$targetLowPriorityNodes

  pb <-
    txtProgressBar(min = 0,
                   max = totalNodes,
                   style = 3)

  timeToTimeout <- Sys.time() + timeout

  while (Sys.time() < timeToTimeout) {
    pool <- rAzureBatch::getPool(poolId)

    if (!is.null(pool$resizeErrors)) {
      cat("\n")

      resizeErrors <- ""
      for (i in 1:length(pool$resizeErrors)) {
        resizeErrors <-
          paste0(
            resizeErrors,
            sprintf(
              "Code: %s - Message: %s \n",
              pool$resizeErrors[[i]]$code,
              pool$resizeErrors[[i]]$message
            )
          )
      }

      stop(resizeErrors)
    }

    nodes <- rAzureBatch::listPoolNodes(poolId)

    if (!is.null(nodes$value) && length(nodes$value) > 0) {
      nodesWithFailures <- c()
      currentProgressBarCount <- 0

      for (i in 1:length(nodes$value)) {
        # The progress total count is the number of the nodes. Each node counts as 1.
        # If a node is not in idle, prempted, running, or start task failed, the value is
        # less than 1. The default value is 0 because the node has not been allocated to
        # the pool yet.
        nodeValue <- switch(
          nodes$value[[i]]$state,
          "idle" = {
            1
          },
          "creating" = {
            0.25
          },
          "starting" = {
            0.50
          },
          "waitingforstartask" = {
            0.75
          },
          "starttaskfailed" = {
            nodesWithFailures <- c(nodesWithFailures, nodes$value[[i]]$id)
            1
          },
          "preempted" = {
            1
          },
          "running" = {
            1
          },
          0
        )

        currentProgressBarCount <-
          currentProgressBarCount + nodeValue
      }

      if (currentProgressBarCount >= pb$getVal()) {
        setTxtProgressBar(pb, currentProgressBarCount)
      }

      if (length(nodesWithFailures) > 0) {
        nodesFailureWarningLabel <-
          sprintf(
            "The following %i nodes failed while running the start task:\n",
            length(nodesWithFailures)
          )
        for (i in 1:length(nodesWithFailures)) {
          nodesFailureWarningLabel <-
            paste0(nodesFailureWarningLabel,
                   sprintf("%s\n", nodesWithFailures[i]))
        }

        warning(nodesFailureWarningLabel)
      }
    }

    if (pb$getVal() >= totalNodes) {
      cat("\n")
      return(0)
    }

    Sys.sleep(30)
  }

  rAzureBatch::deletePool(poolId)
  stop("Timeout expired")
}

#' Utility function for creating an output file
#'
#' @param filePattern a pattern indicating which file(s) to upload
#' @param url the destination blob or virtual directory within the Azure Storage container
#'
#' @export
createOutputFile <- function(filePattern, url) {
  output <- list(
    filePattern = filePattern,
    destination = list(container = list(containerUrl = url)),
    uploadOptions = list(uploadCondition = "taskCompletion")
  )

  # Parsing url to obtain container's virtual directory path
  azureDomain <- "blob.core.windows.net"
  parsedValue <- strsplit(url, azureDomain)[[1]]

  accountName <- parsedValue[1]
  urlPath <- parsedValue[2]

  baseUrl <- paste0(accountName, azureDomain)
  parsedUrlPath <- strsplit(urlPath, "?", fixed = TRUE)[[1]]

  storageContainerPath <- parsedUrlPath[1]
  queryParameters <- parsedUrlPath[2]
  virtualDirectory <-
    strsplit(substring(storageContainerPath, 2, nchar(storageContainerPath)), "/", fixed = TRUE)

  containerName <- virtualDirectory[[1]][1]
  containerUrl <-
    paste0(baseUrl, "/", containerName, "?", queryParameters)

  # Verify directory has multiple directories
  if (length(virtualDirectory[[1]]) > 1) {
    # Rebuilding output path for the file upload
    path <- ""
    for (i in 2:length(virtualDirectory[[1]])) {
      path <- paste0(path, virtualDirectory[[1]][i], "/")
    }

    path <- substring(path, 1, nchar(path) - 1)
    output$destination$container$path <- path
  }

  output$destination$container$containerUrl <- containerUrl
  output
}

getXmlValues <- function(xmlResponse, xmlPath) {
  xml2::xml_text(xml2::xml_find_all(xmlResponse, xmlPath))
}

areShallowEqual <- function(a, b) {
  !is.null(a) && !is.null(b) && a == b
}
