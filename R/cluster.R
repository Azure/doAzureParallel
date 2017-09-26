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

#' Creates a configuration file for the user's cluster setup.
#'
#' @param fileName Cluster settings file name
#' @return The request to the Batch service was successful.
#' @examples {
#' generateClusterConfig("test_config.json")
#' generateClusterConfig("test_config.json")
#' }
#'
#' @export
generateClusterConfig <- function(fileName) {
  if (!file.exists(fileName) ||
      !file.exists(paste0(getwd(), "/", fileName))) {
    config <- list(
      name = "myPoolName",
      vmSize = "Standard_D2_v2",
      maxTasksPerNode = 1,
      poolSize = list(
        dedicatedNodes = list(min = 3,
                              max = 3),
        lowPriorityNodes = list(min = 3,
                                max = 3),
        autoscaleFormula = "QUEUE"
      ),
      rPackages = list(
        cran = vector(),
        github = vector(),
        githubAuthenticationToken = ""
      ),
      commandLine = vector()
    )

    configJson <-
      jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
    write(configJson, file = paste0(getwd(), "/", fileName))

    print(
      sprintf(
        "A cluster settings has been generated %s. Please enter your cluster specification.",
        paste0(getwd(), "/", fileName)
      )
    )
    print(
      "Note: To maximize all CPU cores, set the maxTasksPerNode property up to 4x the number of cores for the VM size."
    )
  }
}

#' Creates an Azure cloud-enabled cluster.
#'
#' @param clusterSetting Cluster configuration's file name
#' @param fullName A boolean flag for checking the file full name
#' @param wait A boolean flag to wait for all nodes to boot up
#' @param resourceFiles A list of files that Batch will download to the compute node before running the command line
#'
#' @return The request to the Batch service was successful.
#' @examples
#' \dontrun{
#' cluster <- makeCluster("cluster_config.json", fullName = TRUE, wait = TRUE)
#' }
#' @export
makeCluster <-
  function(clusterSetting = "cluster_settings.json",
           fullName = FALSE,
           wait = TRUE,
           resourceFiles = list()) {
    if (fullName) {
      poolConfig <- rjson::fromJSON(file = paste0(clusterSetting))
    }
    else {
      poolConfig <-
        rjson::fromJSON(file = paste0(getwd(), "/", clusterSetting))
    }

    config <- getOption("az_config")
    if (is.null(config)) {
      stop("Credentials were not set.")
    }

    installCranCommand <- NULL
    installGithubCommand <- NULL

    if (!is.null(poolConfig$rPackages) &&
        !is.null(poolConfig$rPackages$cran) &&
        length(poolConfig$rPackages$cran) > 0) {
      installCranCommand <-
        getPoolPackageInstallationCommand("cran", poolConfig$rPackages$cran)
    }

    if (!is.null(poolConfig$rPackages) &&
        !is.null(poolConfig$rPackages$github) &&
        length(poolConfig$rPackages$github) > 0) {
      installGithubCommand <-
        getPoolPackageInstallationCommand("github", poolConfig$rPackages$github)
    }

    packages <- NULL
    if (!is.null(installCranCommand)) {
      packages <- installCranCommand
    }

    if (!is.null(installGithubCommand) && is.null(packages)) {
      packages <- installGithubCommand
    }
    else if (!is.null(installGithubCommand) && !is.null(packages)) {
      packages <- c(installCranCommand, installGithubCommand)
    }

    commandLine <- NULL

    # install docker and create docker container
    docker_image = "r_base:3.4.1"
    if (!is.null(poolConfig$containerImage)) {
      docker_image = poolConfig$containerImage
    }
    
    install_and_start_container_command = paste0("cluster_setup.sh ", docker_image, "
                                                 'docker run --rm --name r-version -v /mnt/batch/tasks:/batch
                                                  -e DOCKER_WORKING_DIR=/batch/startup/wd", 
                                                 docker_image, " R --version'")
    container_install_command <- c(
      "wget https://raw.githubusercontent.com/Azure/doAzureParallel/feature/container/R/cluster_setup.sh",
      "chmod u+x cluster_setup.sh",
      install_and_start_container_command)

    if (!is.null(poolConfig$commandLine)) {
      commandLine <- c(container_install_command, poolConfig$commandLine)
    }

    environmentSettings <- NULL
    if (!is.null(poolConfig$rPackages) &&
        !is.null(poolConfig$rPackages$githubAuthenticationToken) &&
        poolConfig$rPackages$githubAuthenticationToken != "") {
      environmentSettings <-
        list(
          list(
            name = "GITHUB_PAT",
            value = poolConfig$rPackages$githubAuthenticationToken
          )
        )
    }

    if (!is.null(poolConfig[["pool"]])) {
      validateDeprecatedClusterConfig(clusterSetting)
      poolConfig <- poolConfig[["pool"]]
    }
    else {
      validateClusterConfig(clusterSetting)
    }

    response <- .addPool(
      pool = poolConfig,
      packages = packages,
      environmentSettings = environmentSettings,
      resourceFiles = resourceFiles,
      commandLine = commandLine
    )

    if (grepl("AuthenticationFailed", response)) {
      stop("Check your credentials and try again.")
    }

    if (grepl("PoolBeingDeleted", response)) {
      pool <- rAzureBatch::getPool(poolConfig$name)

      cat(
        sprintf(
          paste("Cluster '%s' already exists and is being deleted.",
                "Another cluster with the same name cannot be created",
                "until it is deleted. Please wait for the cluster to be deleted",
                "or create one with a different name"),
          poolConfig$name
        ),
        fill = TRUE
      )

      while (areShallowEqual(rAzureBatch::getPool(poolConfig$name)$state,
                      "deleting")) {
        cat(".")
        Sys.sleep(10)
      }

      cat("\n")

      response <- .addPool(
        pool = poolConfig,
        packages = packages,
        environmentSettings = environmentSettings,
        resourceFiles = resourceFiles,
        commandLine = commandLine
      )
    }

    pool <- rAzureBatch::getPool(poolConfig$name)

    if (grepl("PoolExists", response)) {
      cat(
        sprintf(
          "The specified cluster '%s' already exists. Cluster '%s' will be used.",
          pool$id,
          pool$id
        ),
        fill = TRUE
      )

      clusterNodeMismatchWarning <-
        paste(
          "There is a mismatched between the projected cluster %s",
          "nodes min/max '%s'/'%s' and the existing cluster %s nodes '%s'.",
          "Use the 'resizeCluster' function to get the correct amount",
          "of workers."
        )

      if (!(
        poolConfig$poolSize$dedicatedNodes$min <= pool$targetDedicatedNodes &&
        pool$targetDedicatedNodes <= poolConfig$poolSize$dedicatedNodes$max
      )) {
        dedicatedLabel <- "dedicated"
        warning(
          sprintf(
            clusterNodeMismatchWarning,
            dedicatedLabel,
            poolConfig$poolSize$dedicatedNodes$min,
            poolConfig$poolSize$dedicatedNodes$max,
            dedicatedLabel,
            pool$targetDedicatedNodes
          )
        )
      }

      if (!(
        poolConfig$poolSize$lowPriorityNodes$min <= pool$targetLowPriorityNodes &&
        pool$targetLowPriorityNodes <= poolConfig$poolSize$lowPriorityNodes$max
      )) {
        lowPriorityLabel <- "low priority"

        warning(
          sprintf(
            clusterNodeMismatchWarning,
            lowPriorityLabel,
            poolConfig$poolSize$lowPriorityNodes$min,
            poolConfig$poolSize$lowPriorityNodes$max,
            lowPriorityLabel,
            pool$targetLowPriorityNodes
          )
        )
      }
    }

    if (wait && !grepl("PoolExists", response)) {
      waitForNodesToComplete(poolConfig$name, 60000)
    }

    cat("Your cluster has been registered.", fill = TRUE)
    cat(sprintf("Dedicated Node Count: %i", pool$targetDedicatedNodes),
        fill = TRUE)
    cat(sprintf("Low Priority Node Count: %i", pool$targetLowPriorityNodes),
        fill = TRUE)

    config$poolId <- poolConfig$name
    options("az_config" = config)
    return(getOption("az_config"))
  }

#' Deletes the cluster from your Azure account.
#'
#' @param cluster The cluster configuration that was created in \code{makeCluster}
#'
#' @examples
#' \dontrun{
#' clusterConfiguration <- makeCluster("cluster_settings.json")
#' stopCluster(clusterConfiguration)
#' }
#' @export
stopCluster <- function(cluster) {
  rAzureBatch::deletePool(cluster$poolId)

  print(sprintf("Your %s cluster has been destroyed.", cluster$poolId))
}

#' Set azure credentials to R session.
#'
#' @param fileName The cluster configuration that was created in \code{makeCluster}
#'
#' @export
setCredentials <- function(fileName = "az_config.json") {
  if (file.exists(fileName)) {
    config <- rjson::fromJSON(file = paste0(fileName))
  }
  else{
    config <- rjson::fromJSON(file = paste0(getwd(), "/", fileName))
  }

  options("az_config" = config)
  print("Your azure credentials have been set.")
}

getPoolWorkers <- function(poolId, ...) {
  args <- list(...)
  raw <- !is.null(args$RAW)

  nodes <- rAzureBatch::listPoolNodes(poolId)

  if (length(nodes$value) > 0) {
    for (i in 1:length(nodes$value)) {
      print(
        sprintf(
          "Node: %s - %s - %s",
          nodes$value[[i]]$id,
          nodes$value[[i]]$state,
          nodes$value[[i]]$ipAddress
        )
      )
    }
  }
  else{
    print("There are currently no nodes in the pool.")
  }

  if (raw) {
    return(nodes)
  }
}
