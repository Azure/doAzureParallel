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
#'    storageAccount = "teststorageaccount", storageKey = "test_storage_account_key",
#'    storageEndpointSuffix = "core.windows.net")
#' supported storage account endpoint suffix: core.windows.net (default),
#'    core.chinacloudapi.cn, core.cloudapi.de, core.usgovcloudapi.net, etc.
#' }
#' @export
generateCredentialsConfig <- function(fileName, authenticationType = "SharedKey", ...) {
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

  storageEndpointSuffix <-
    ifelse(is.null(args$storageEndpointSuffix),
           "core.windows.net",
           args$storageEndpointSuffix)

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
    authenticationType <- tolower(authenticationType)
    if (authenticationType == "sharedkey") {
      config <- list(
        sharedKey = list(
          batchAccount = list(name = batchAccount,
                              key = batchKey,
                              url = batchUrl),
          storageAccount = list(name = storageName,
                                key = storageKey,
                                endpointSuffix = storageEndpointSuffix)
        ),
        githubAuthenticationToken = githubAuthenticationToken,
        dockerAuthentication = list(username = dockerUsername,
                                    password = dockerPassword,
                                    registry = dockerRegistry)
      )
    }
    else if (authenticationType == "serviceprincipal") {
      config <- list(
        servicePrincipal = list(
          tenantId = "tenant",
          clientId = "client",
          credential = "credential",
          batchAccountResourceId = "batchAccountResourceId",
          storageAccountResourceId = "storageAccountResourceId",
          storageEndpointSuffix = storageEndpointSuffix),
        githubAuthenticationToken = githubAuthenticationToken,
        dockerAuthentication = list(username = dockerUsername,
                                    password = dockerPassword,
                                    registry = dockerRegistry)
      )
    }
    else {
      stop(sprintf("Incorrect authentication type: %s. Use 'SharedKey' or 'ServicePrincipal'",
                   authenticationType))
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
#' @param verbose Enable verbose messaging on setting credentials
#' @param environment The type of Azure Environment that your account is located
#'
#' @export
setCredentials <- function(credentials = "az_config.json",
                           verbose = TRUE,
                           environment = "Azure") {
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

  environment <- tolower(environment)
  if (environment == "azureusgov") {
    aadUrl <- "https://login.microsoftonline.us/"
    armUrl <- "https://management.usgovcloudapi.net/"
    batchUrl <- "https://batch.core.usgovcloudapi.net/"
  }
  else if (environment == "azurechina") {
    aadUrl <- "https://login.chinacloudapi.cn/"
    armUrl <- "https://management.chinacloudapi.cn/"
    batchUrl <- "https://batch.chinacloudapi.cn/"
  }
  else if (environment == "azuregermany"){
    aadUrl <- "https://login.microsoftonline.de/"
    armUrl <- "https://management.microsoftazure.de/"
    batchUrl <- "https://batch.microsoftazure.de/"
  }
  else {
    aadUrl <- "https://login.microsoftonline.com/"
    armUrl <- "https://management.azure.com/"
    batchUrl <- "https://batch.core.windows.net/"
  }

  config$azureEnvironment <- list(type = environment,
                                  aadUrl = aadUrl,
                                  armUrl = armUrl,
                                  batchUrl = batchUrl)

  batchServiceClient <- makeBatchClient(config)
  storageServiceClient <- makeStorageClient(config)

  config$batchClient <- batchServiceClient
  config$storageClient <- storageServiceClient

  cat(strrep('=', options("width")), fill = TRUE)
  if (!is.null(config$sharedKey)) {
    printSharedKeyInformation(config$sharedKey)

    config$endpointSuffix <- config$sharedKey$storageAccount$endpointSuffix
  }
  else if (!is.null(config$servicePrincipal)) {
    cat(sprintf("Batch Account Resource Id: %s",
                config$servicePrincipal$batchAccountResourceId), fill = TRUE)
    cat(sprintf("Storage Account Resource Id: %s",
                config$servicePrincipal$storageAccountResourceId), fill = TRUE)

    config$endpointSuffix <- config$servicePrincipal$storageEndpointSuffix
  }
  else {
    printSharedKeyInformation(config)
  }

  if (is.null(config$endpointSuffix)) {
    config$endpointSuffix <- "core.windows.net"
  }

  options("az_config" = config)
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
      name = credentials$batchAccount$name,
      key = credentials$batchAccount$key
    )

    baseUrl <- credentials$batchAccount$url
  }
  # Set up ServicePrincipalCredentials
  else {
    info <-
      getAccountInformation(config$servicePrincipal$batchAccountResourceId)

    batchCredentials <- rAzureBatch::ServicePrincipalCredentials$new(
      tenantId = config$servicePrincipal$tenantId,
      clientId = config$servicePrincipal$clientId,
      clientSecrets = config$servicePrincipal$credential,
      resource = config$azureEnvironment$batchUrl,
      aadUrl = config$azureEnvironment$aadUrl
    )

    servicePrincipal <- rAzureBatch::ServicePrincipalCredentials$new(
      tenantId = config$servicePrincipal$tenantId,
      clientId = config$servicePrincipal$clientId,
      clientSecrets = config$servicePrincipal$credential,
      resource = config$azureEnvironment$armUrl,
      aadUrl = config$azureEnvironment$aadUrl
    )

    batchAccountInfo <- rAzureBatch::getBatchAccount(
      batchAccount = info$account,
      resourceGroup = info$resourceGroup,
      subscriptionId = info$subscriptionId,
      servicePrincipal = servicePrincipal,
      verbose = TRUE
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
      name = credentials$storageAccount$name,
      key = credentials$storageAccount$key
    )

    endpointSuffix <- credentials$storageAccount$endpointSuffix
    if (is.null(endpointSuffix)) {
      endpointSuffix <- "core.windows.net"
    }

    baseUrl <- sprintf("https://%s.blob.%s",
                       credentials$storageAccount$name,
                       endpointSuffix)
  }
  # Set up ServicePrincipalCredentials
  else {
    info <-
      getAccountInformation(config$servicePrincipal$storageAccountResourceId)

    endpointSuffix <- config$servicePrincipal$storageEndpointSuffix
    if (is.null(endpointSuffix)) {
      endpointSuffix <- "core.windows.net"
    }

    servicePrincipal <- rAzureBatch::ServicePrincipalCredentials$new(
      tenantId = config$servicePrincipal$tenantId,
      clientId = config$servicePrincipal$clientId,
      clientSecrets = config$servicePrincipal$credential,
      resource = config$azureEnvironment$armUrl,
      aadUrl = config$azureEnvironment$aadUrl
    )

    storageKeys <- rAzureBatch::getStorageKeys(
      storageAccount = info$account,
      resourceGroup =  info$resourceGroup,
      subscriptionId = info$subscriptionId,
      servicePrincipal = servicePrincipal,
      verbose = TRUE
    )

    storageCredentials <- rAzureBatch::SharedKeyCredentials$new(
      name = info$account,
      key = storageKeys$keys[[1]]$value
    )

    baseUrl <- sprintf("https://%s.blob.%s",
                       info$account,
                       endpointSuffix)
  }

  rAzureBatch::StorageServiceClient$new(
    authentication = storageCredentials,
    url = baseUrl
  )
}

getConfiguration <- function(){
  config <- options("az_config")
  return(config$az_config)
}
