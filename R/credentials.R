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
#'  \item{"githubAuthenticationToken"}: {GitHub authentication token for pulling R
#'                                       packages from private GitHub repositories}
#'  \item{"dockerAuthentication"}: {Docker authentication for pulling Docker images
#'                                  from private Docker registries}
#'  \item{"dockerUsername"}: {Username to docker registry}
#'  \item{"dockerPassword"}: {Password to docker registry}
#'  \item{"dockerRegistry"}: {URL to docker registry}
#'
#'}
#' @return The request to the Batch service was successful.
#' @examples {
#' generateCredentialsConfig("test_config.json")
#' generateCredentialsConfig("test_config.json", batchAccount = "testbatchaccount",
#'    batchKey = "test_batch_account_key", batchUrl = "http://testbatchaccount.azure.com",
#'    storageAccount = "teststorageaccount", storageKey = "test_storage_account_key")
#' }
#' @export
generateCredentialsConfig <- function(fileName, authenticationType = c("SharedKey", "ServicePrincipal"), ...) {
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

  githubAuthenticationToken <-
    ifelse(is.null(args$githubAuthenticationToken),
           "",
           args$githubAuthenticationToken)

  dockerAuthentication <-
    ifelse(is.null(args$dockerAuthentication),
           "",
           args$dockerAuthentication)

  dockerUsername <-
    ifelse(is.null(args$dockerUsername),
           "",
           args$dockerUsername)

  dockerPassword <-
    ifelse(is.null(args$dockerPassword),
           "",
           args$dockerPassword)

  dockerRegistry <-
    ifelse(is.null(args$dockerRegistry),
           "",
           args$dockerRegistry)

  if (!file.exists(paste0(getwd(), "/", fileName))) {
    if (authenticationType == "SharedKey") {
      config <- list(
        sharedKey = list(
          batchAccount = list(name = batchAccount,
                              key = batchKey,
                              url = batchUrl),
          storageAccount = list(name = storageName,
                                key = storageKey)
        ),
        githubAuthenticationToken = githubAuthenticationToken,
        dockerAuthentication = list(username = dockerUsername,
                                    password = dockerPassword,
                                    registry = dockerRegistry)
      )
    }
    else {
      config <- list(
        servicePrincipal = list(
          tenantId = "tenant",
          clientId = "client",
          credential = "credential",
          batchUrl = "batchUrl",
          storageUrl = "storageUrl"),
        githubAuthenticationToken = githubAuthenticationToken,
        dockerAuthentication = list(username = dockerUsername,
                                    password = dockerPassword,
                                    registry = dockerRegistry)
      )
    }

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
setCredentials <- function(credentials = "az_config.json", verbose = TRUE) {
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
  } else {
    stop(sprintf(
      "credentials type is not supported: %s\n",
      class(clusterSetting)
    ))
  }

  options("az_config" = config)

  cat(strrep('=', options("width")), fill = TRUE)
  cat(sprintf("Batch Account: %s", config$batchAccount$name), fill = TRUE)
  cat(sprintf("Batch Account Url: %s", config$batchAccount$url), fill = TRUE)

  cat(sprintf("Storage Account: %s", config$storageAccount$name), fill = TRUE)
  cat(sprintf("Storage Account Url: %s", sprintf("https://%s.blob.core.windows.net",
                                                 config$storageAccount$name)),
      fill = TRUE)

  cat(strrep('=', options("width")), fill = TRUE)
  cat("Your credentials have been successfully set.", fill = TRUE)
}
