#' List storage containers from Azure Storage.
#'
#' @param prefix Filters the results to return only containers
#' whose name begins with the specified prefix.
#'
#' @examples
#' \dontrun{
#' containers <- listStorageContainers()
#' View(containers)
#' }
#' @export
listStorageContainers <- function(prefix = "") {
  xmlResponse <-
    rAzureBatch::listContainers(prefix, content = "parsed")

  name <- getXmlValues(xmlResponse, ".//Container/Name")
  lastModified <-
    getXmlValues(xmlResponse, ".//Container/Properties/Last-Modified")
  publicAccess <-
    getXmlValues(xmlResponse, ".//Container/Properties/PublicAccess")
  leaseState <-
    getXmlValues(xmlResponse, ".//Container/Properties/LeaseState")

  data.frame(
    Name = name,
    PublicAccess = publicAccess,
    LeaseState = leaseState,
    LastModified = lastModified
  )
}

#' Delete a storage container from Azure Storage
#'
#' @param container The name of the container
#'
#' @export
deleteStorageContainer <- function(container) {
  response <-
    rAzureBatch::deleteContainer(container, content = "response")

  if (response$status_code == 202) {
    cat(sprintf("Your storage container '%s' has been deleted.", container),
        fill = TRUE)
  } else if (response$status_code == 404) {
    cat(sprintf("storage container '%s' does not exist.", container),
        fill = TRUE)
  }

  response
}

#' List storage files from Azure storage.
#'
#' @param container The cluster object
#' @param prefix Id of the node
#'
#' @examples
#' \dontrun{
#' files <- listStorageFiles("job001")
#' View(files)
#' }
#' @export
listStorageFiles <- function(container, prefix = "", ...) {
  xmlResponse <-
    rAzureBatch::listBlobs(container, prefix, content = "parsed", ...)

  filePath <- getXmlValues(xmlResponse, ".//Blob/Name")

  lastModified <-
    getXmlValues(xmlResponse, ".//Blob/Properties/Last-Modified")

  contentLength <-
    getXmlValues(xmlResponse, ".//Blob/Properties/Content-Length")

  contentType <-
    getXmlValues(xmlResponse, ".//Blob/Properties/Content-Type")

  leaseState <-
    getXmlValues(xmlResponse, ".//Blob/Properties/LeaseState")

  storageFiles <- data.frame(
    FilePath = filePath,
    ContentLength = contentLength,
    ContentType = contentType,
    LeaseState = leaseState,
    LastModified = lastModified
  )

  attr(storageFiles, "containerName") <- container

  storageFiles
}

#' Get a storage file from Azure Storage. By default, this operation will print the files on screen.
#'
#' @param container The name of the container
#' @param blobPath The path of the blob
#' @param ... Optional parameters
#' \itemize{
#'  \item{"downloadPath"}: { Path to save file to }
#'  \item{"overwrite"}: { Will only overwrite existing localPath }
#'  \item{"verbose"}: { Show verbose messages }
#'}
#' @examples
#' \dontrun{
#' stdoutText <- getStorageFile(testContainer, "logs/stdout.txt")
#' }
#' @export
getStorageFile <-
  function(container,
           blobPath,
           downloadPath = NULL,
           overwrite = FALSE,
           verbose = TRUE,
           ...) {
    jobFileContent <- rAzureBatch::downloadBlob(
      container,
      blobPath,
      downloadPath = downloadPath,
      overwrite = overwrite,
      progress = TRUE,
      ...
    )

    jobFileContent
  }

#' Delete a storage file from a container.
#'
#' @param container The name of container
#' @param blobPath The file path of the blob
#'
#' @export
deleteStorageFile <- function(container, blobPath, ...) {
  response <-
    rAzureBatch::deleteBlob(container, blobPath, content = "response", ...)

  if (response$status_code == 202) {
    cat(
      sprintf(
        "Your blob '%s' from container '%s' has been deleted.",
        blobPath,
        container
      ),
      fill = TRUE
    )
  }

  response
}
