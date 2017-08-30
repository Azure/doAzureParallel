#' Get node log files from Azure Storage. By default, this operation will print the files on screen.
#'
#' @param cluster The cluster object
#' @param nodeId Id of the node
#' @param type The type of logs the user wants: "stdout" or "stderr"
#' @param verbose Flag for printing log files onto console
#'
#' @param ... Further named parameters
#' \itemize{
#'  \item{"localPath"}: { Path to save file to }
#'  \item{"overwrite"}: { Will only overwrite existing localPath }
#'}
#'
#' @examples
#' stdoutText <- getClusterLogs(cluster, "tvm-1170471534_1-20170829t072146z", type = "stdout", verbose = FALSE)
#' getClusterLogs(cluster, "tvm-1170471534_2-20170829t072146z", type = "stderr", localPath = "abc.txt", overwrite = TRUE)
#' @export
getClusterLogs <-
  function(cluster,
           nodeId,
           type = c("stdout", "stderr"),
           verbose = TRUE,
           overwrite = FALSE,
           localPath = NULL) {
    filePathString <- "startup/%s.txt"

    filePath <- switch(type,
                       "stdout" = {
                         sprintf(filePathString, type)
                       },
                       "stderr" = {
                         sprintf(filePathString, type)
                       },
                       stop(sprintf("Incorrect File Path Type: %s", type)))

    nodeFileContent <- rAzureBatch::getNodeFile(
      cluster$poolId,
      nodeId,
      filePath,
      content = "text",
      write = write,
      progress = TRUE,
      localPath = localPath,
      overwrite = overwrite
    )

    if (verbose) {
      cat(nodeFileContent)
    }

    nodeFileContent
  }

#' Get job log files from Azure Storage. By default, this operation will print the files on screen.
#'
#' @param jobId Id of the foreach job
#' @param taskId Id of the task
#' @param type Type of logs: rlogs, stdout, or stderr
#' @param verbose Flag for printing the log files onto console
#' @param ... Further named parameters
#' \itemize{
#'  \item{"localPath"}: { Path to save file to }
#'  \item{"overwrite"}: { Will only overwrite existing localPath }
#'}
#'
#' @examples
#' stdoutFile <- getJobLogs("job20170822055031", "job20170822055031-task1", type = "stdout")
#' getJobLogs("job20170822055031", "job20170822055031-task1", type = "rlogs", localPath = "hello.txt")
#' @export
getJobLogs <-
  function(jobId,
           taskId,
           type = c("rlogs", "stdout", "stderr"),
           verbose = TRUE,
           overwrite = FALSE,
           localPath = NULL) {
    blobPathString <- "%s/%s.txt"

    blobPath <- switch(
      type,
      "rlogs" = {
        sprintf(blobPathString, "logs", taskId)
      },
      "stdout" = {
        sprintf(blobPathString, type, paste0(taskId, "-", type))
      },
      "stderr" = {
        sprintf(blobPathString, type, paste0(taskId, "-", type))
      },
      stop(
        sprintf("Incorrect Blob Path Type: %s - Use rlogs, stdout, or stderr ", type)
      )
    )

    jobFileContent <-
      rAzureBatch::downloadBlob(
        jobId,
        blobPath,
        content = "text",
        localDest = localPath,
        overwrite = overwrite,
        progress = TRUE
      )

    if (verbose) {
      cat(jobFileContent)
    }

    jobFileContent
  }
