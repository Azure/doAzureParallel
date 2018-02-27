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
          batchAccountResourceId = "batchAccountResourceId",
          storageAccountResourceId = "storageAccountResourceId"),
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

  batchServiceClient <- makeBatchClient(config)
  storageServiceClient <- makeStorageClient(config)

  config$batchClient <- batchServiceClient
  config$storageClient <- storageServiceClient
  options("az_config" = config)

  cat(strrep('=', options("width")), fill = TRUE)
  if (!is.null(config$sharedKey)) {
    printSharedKeyInformation(config$sharedKey)
  }
  else if (!is.null(config$servicePrincipal)) {
    cat(sprintf("Tenant Id: %s",
                config$servicePrincipal$tenantId), fill = TRUE)
    cat(sprintf("Client Id: %s",
                config$servicePrincipal$clientId),fill = TRUE)
    cat(sprintf("Client Secret: %s",
                rep(config$servicePrincipal$clientSecret)), fill = TRUE)
    cat(sprintf("Batch Account Resource Id: %s",
                config$servicePrincipal$batchAccountResourceId), fill = TRUE)
    cat(sprintf("Storage Account Resource Id: %s",
                config$servicePrincipal$storageAccountResourceId), fill = TRUE)
  }
  else {
    printSharedKeyInformation(config)
  }

  cat(strrep('=', options("width")), fill = TRUE)
  if (!is.null(config$batchAccountName) &&
      !is.null(config$storageAccount) &&
      packageVersion("doAzureParallel") != '0.6.2') {
    warning("Old version of credentials file: Generate new credentials file.")
  }

  cat("Your credentials have been successfully set.", fill = TRUE)
}

makeBatchClient <- function(config) {
  batchCredentials <- NULL

  # Set up SharedKeyCredentials
  if (!is.null(config$sharedKey) ||
      !is.null(config$batchAccount) && !is.null(config$storageAccount)) {
    credentials <- config
    if (!is.null(config$sharedKey)) {
      credentials <- config$sharedKey
    }

    batchCredentials <- rAzureBatch::SharedKeyCredentials$new(
      name = credentials$batchAccountName,
      key = credentials$batchAccountKey
    )

    baseUrl <- config$batchAccountUrl
  }
  # Set up ServicePrincipalCredentials
  else {
    info <-
      getAccountInformation(config$servicePrincipal$batchAccountResourceId)

    batchCredentials <- rAzureBatch::ServicePrincipalCredentials$new(
      tenantId = config$servicePrincipal$tenantId,
      clientId = config$servicePrincipal$clientId,
      clientSecrets = config$servicePrincipal$credential
    )

    azureContext <- AzureSMR::createAzureContext(
      tenantID = config$servicePrincipal$tenantId,
      clientID = config$servicePrincipal$clientId,
      authKey = config$servicePrincipal$credential
    )

    batchAccountInfo <- AzureSMR::azureGetBatchAccount(
      azureContext,
      batchAccount = info$account,
      resourceGroup = info$resourceGroup,
      subscriptionID = info$subscriptionId
    )

    baseUrl <- sprintf("https://%s/",
                       batchAccountInfo$properties$accountEndpoint)
  }

  rAzureBatch::BatchServiceClient$new(
    url = baseUrl,
    authentication = batchCredentials
  )
}

makeStorageClient <- function(config) {
  if (!is.null(config$sharedKey) ||
      !is.null(config$storageAccount)) {
    credentials <- config
    if (!is.null(config$sharedKey)) {
      credentials <- config$sharedKey
    }

    storageCredentials <- rAzureBatch::SharedKeyCredentials$new(
      name = credentials$storageAccountName,
      key = credentials$storageAccountKey
    )
  }
  # Set up ServicePrincipalCredentials
  else {
    info <-
      getAccountInformation(config$servicePrincipal$storageAccountResourceId)

    azureContext <- AzureSMR::createAzureContext(
      tenantID = config$servicePrincipal$tenantId,
      clientID = config$servicePrincipal$clientId,
      authKey = config$servicePrincipal$credential
    )

    primaryKey <- AzureSMR::azureSAGetKey(
      azureContext,
      storageAccount = info$account,
      resourceGroup =  info$resourceGroup,
      subscriptionID = info$subscriptionId
    )

    storageCredentials <- rAzureBatch::SharedKeyCredentials$new(
      name = info$account,
      key = primaryKey
    )
  }

  rAzureBatch::StorageServiceClient$new(
    authentication = storageCredentials
  )
}

getConfiguration <- function(){
  return(options("az_config"))
}
