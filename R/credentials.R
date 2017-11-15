#' Creates a credentials file for rAzureBatch package authentication
#'
#' @param fileName Credentials file name
#' @param ... Further named parameters
#' \itemize{
#'  \item{"batchAccount"}: {Batch account name for Batch Service authentication.}
#'  \item{"batchKey"}: {Batch account key for signing REST signatures.}
#'  \item{"batchUrl"}: {Batch service url for account.}
#'  \item{"storageAccount"}: {Storage account for storing output results.}
#'  \item{"storageKey"}: {Storage account key for storage service authentication.}
#'}
#' @return The request to the Batch service was successful.
#' @examples {
#' generateCredentialsConfig("test_config.json")
#' generateCredentialsConfig("test_config.json", batchAccount = "testbatchaccount",
#'    batchKey = "test_batch_account_key", batchUrl = "http://testbatchaccount.azure.com",
#'    storageAccount = "teststorageaccount", storageKey = "test_storage_account_key")
#' }
#' @export
generateCredentialsConfig <- function(fileName, ...) {
  args <- list(...)

  batchAccount <-
    ifelse(is.null(args$batchAccount),
           "batch_account_name",
           args$batchAccount)
  batchKey <-
    ifelse(is.null(args$batchKey), "batch_account_key", args$batchKey)
  batchUrl <-
    ifelse(is.null(args$batchUrl), "batch_account_url", args$batchUrl)

  storageName <-
    ifelse(is.null(args$storageAccount),
           "storage_account_name",
           args$storageAccount)
  storageKey <-
    ifelse(is.null(args$storageKey),
           "storage_account_key",
           args$storageKey)

  if (!file.exists(paste0(getwd(), "/", fileName))) {
    config <- list(
      batchAccount = list(
        name = batchAccount,
        key = batchKey,
        url = batchUrl
      ),
      storageAccount = list(name = storageName,
                            key = storageKey)
    )

    configJson <-
      jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
    write(configJson, file = paste0(getwd(), "/", fileName))

    print(
      sprintf(
        "A config file has been generated %s. Please enter your Batch credentials.",
        paste0(getwd(), "/", fileName)
      )
    )
  }
}

#' Set azure credentials to R session from credentials object or json file.
#'
#' @param credentials The credentials object or json file
#'
#' @export
setCredentials <- function(credentials = "az_config.json") {
  if (class(credentials) == "character") {
    fileName <- credentials
    if (file.exists(fileName)) {
      config <- rjson::fromJSON(file = paste0(fileName))
    }
    else{
      config <- rjson::fromJSON(file = paste0(getwd(), "/", fileName))
    }
  } else if (class(credentials) == "list") {
    config <- credentials
    generateCredentialsConfig(
      "az_config.json",
      batchAccount = config$batchAccount$name,
      batchKey = config$batchAccount$key,
      batchUrl = config$batchAccount$url,
      storageAccount = config$storageAccount$name,
      storageKey = config$storageAccount$key
    )
  } else {
    stop(sprintf(
      "credentials type is not supported: %s\n",
      class(clusterSetting)
    ))
  }

  options("az_config" = config)
  print("Your azure credentials have been set.")
}
