#' Get node log files from compute nodes. By default, this operation will print the files on screen.
#'
#' @param cluster The cluster object
#' @param nodeId Id of the node
#' @param filePath  The path to the file that you want to get the contents of
#' @param verbose Flag for printing log files onto console
#'
#' @param ... Further named parameters
#' \itemize{
#'  \item{"localPath"}: { Path to save file to }
#'  \item{"overwrite"}: { Will only overwrite existing localPath }
#'}
#'
#' @examples
#' stdoutText <- getClusterFile(cluster, "tvm-1170471534_1-20170829t072146z",
#' filePath = "stdout.txt", verbose = FALSE)
#' getClusterFile(cluster, "tvm-1170471534_2-20170829t072146z",
#' filePath = "wd/output.csv", localPath = "output.csv", overwrite = TRUE)
#' @export
getClusterFile <-
  function(cluster,
           nodeId,
           filePath,
           verbose = TRUE,
           overwrite = FALSE,
           localPath = NULL) {
    prefixfilePath <- "startup/%s"

    if (startsWith(filePath, "/")) {
      filePath <- substring(filePath, 2)
    }

    filePath <- sprintf(prefixfilePath, filePath)

    nodeFileContent <- rAzureBatch::getNodeFile(
      cluster$poolId,
      nodeId,
      filePath,
      content = "text",
      progress = TRUE,
      localPath = localPath,
      overwrite = overwrite
    )

    if (verbose) {
      cat(nodeFileContent)
    }

    nodeFileContent
  }

#' Get job log files from cluster node. By default, this operation will print the files on screen.
#'
#' @param jobId Id of the foreach job
#' @param taskId Id of the task
#' @param filePath  the path to the task file that you want to get the contents of
#' @param verbose Flag for printing the log files onto console
#' @param ... Further named parameters
#' \itemize{
#'  \item{"localPath"}: { Path to save file to }
#'  \item{"overwrite"}: { Will only overwrite existing localPath }
#'}
#'
#' @examples
#' stdoutFile <- getJobFile("job20170822055031", "job20170822055031-task1", type = "stdout")
#' getJobFile("job20170822055031", "job20170822055031-task1", type = "rlogs", localPath = "hello.txt")
#' @export
getJobFile <-
  function(jobId,
           taskId,
           filePath,
           downloadPath = NULL,
           verbose = TRUE,
           overwrite = FALSE) {

    if (startsWith(filePath, "/")) {
      filePath <- substring(filePath, 2)
    }

    jobFileContent <-
      rAzureBatch::getTaskFile(
        jobId,
        taskId,
        filePath,
        content = "text",
        localDest = downloadPath,
        overwrite = overwrite,
        progress = TRUE
      )

    if (verbose) {
      cat(jobFileContent)
    }

    jobFileContent
  }
