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
      containerImage = "rocker/tidyverse:latest",
      rPackages = list(
        cran = vector(),
        github = vector(),
        bioconductor = vector()
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
#' @param clusterSetting Cluster configuration object or file name
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
    if (class(clusterSetting) == "character") {
      if (fullName) {
        poolConfig <- rjson::fromJSON(file = paste0(clusterSetting))
      }
      else {
        poolConfig <-
          rjson::fromJSON(file = paste0(getwd(), "/", clusterSetting))
      }
    } else if (class(clusterSetting) == "list") {
      poolConfig <- clusterSetting
    } else {
      stop(sprintf(
        "cluster setting type is not supported: %s\n",
        class(clusterSetting)
      ))
    }

    config <- getOption("az_config")
    if (is.null(config)) {
      stop("Credentials were not set.")
    }

    installCranCommand <- NULL
    installGithubCommand <- NULL
    installBioconductorCommand <- NULL

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

    if (!is.null(poolConfig$rPackages) &&
        !is.null(poolConfig$rPackages$bioconductor) &&
        length(poolConfig$rPackages$bioconductor) > 0) {
      installBioconductorCommand <-
        getPoolPackageInstallationCommand("bioconductor", poolConfig$rPackages$bioconductor)
    }

    packages <- c()
    if (!is.null(installCranCommand)) {
      packages <- c(packages, installCranCommand)
    }
    if (!is.null(installGithubCommand)) {
      packages <- c(packages, installGithubCommand)
    }
    if (!is.null(installBioconductorCommand)) {
      packages <- c(packages, installBioconductorCommand)
    }

    if (length(packages) == 0) {
      packages <- NULL
    }

    commandLine <- NULL

    # install docker
    dockerImage <- "rocker/tidyverse:latest"
    if (!is.null(poolConfig$containerImage) &&
        nchar(poolConfig$containerImage) > 0) {
      dockerImage <- poolConfig$containerImage
    }

    config$containerImage <- dockerImage
    installAndStartContainerCommand <- "cluster_setup.sh"

    # Note: Revert it to master once PR is approved
    dockerInstallCommand <- c(
      paste0(
        "wget https://raw.githubusercontent.com/Azure/doAzureParallel/",
        "master/inst/startup/cluster_setup.sh"
      ),
      "chmod u+x cluster_setup.sh",
      paste0(
        "wget https://raw.githubusercontent.com/Azure/doAzureParallel/",
        "master/inst/startup/install_bioconductor.R"
      ),
      "chmod u+x install_bioconductor.R",
      installAndStartContainerCommand
    )

    commandLine <- dockerInstallCommand

    # log into private registry if registry credentials were provided
    if (!is.null(config$dockerAuthentication) &&
        nchar(config$dockerAuthentication$username) > 0 &&
        nchar(config$dockerAuthentication$password) > 0 &&
        nchar(config$dockerAuthentication$registry) > 0) {

      username <- config$dockerAuthentication$username
      password <- config$dockerAuthentication$password
      registry <- config$dockerAuthentication$registry

      loginCommand <- dockerLoginCommand(username, password, registry)
      commandLine <- c(commandLine, loginCommand)
    }

    # pull docker image
    pullImageCommand <- dockerPullCommand(dockerImage)
    commandLine <- c(commandLine, pullImageCommand)

    if (!is.null(poolConfig$commandLine)) {
      commandLine <- c(commandLine, poolConfig$commandLine)
    }

    if (!is.null(packages)) {
      # install packages
      commandLine <-
        c(commandLine,
          dockerRunCommand(dockerImage, packages, NULL, FALSE, FALSE))
    }

    environmentSettings <- NULL
    if (!is.null(config$githubAuthenticationToken) &&
        config$githubAuthenticationToken != "") {
      environmentSettings <-
        list(
          list(
            name = "GITHUB_PAT",
            value = config$githubAuthenticationToken
          )
        )
    }

    if (!is.null(poolConfig[["pool"]])) {
      validation$isValidDeprecatedClusterConfig(clusterSetting)
      poolConfig <- poolConfig[["pool"]]
    }
    else {
      validation$isValidClusterConfig(clusterSetting)
    }

    tryCatch({
      validation$isValidPoolName(poolConfig$name)
    },
    error = function(e) {
      stop(paste("Invalid pool name: \n",
                 e))
    })

    response <- BatchUtilitiesOperations$addPool(
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
      message <- paste(
        "Cluster '%s' already exists and is being deleted.",
        "Another cluster with the same name cannot be created",
        "until it is deleted. Please wait for the cluster to be deleted",
        "or create one with a different name"
      )

      if (wait == TRUE) {
        pool <- rAzureBatch::getPool(poolConfig$name)

        cat(sprintf(message,
                    poolConfig$name),
            fill = TRUE)

        while (rAzureBatch::getPool(poolConfig$name)$state == "deleting") {
          cat(".")
          Sys.sleep(10)
        }

        cat("\n")

        response <- BatchUtilitiesOperations$addPool(
          pool = poolConfig,
          packages = packages,
          environmentSettings = environmentSettings,
          resourceFiles = resourceFiles,
          commandLine = commandLine
        )
      } else {
        stop(sprintf(message,
                     poolConfig$name))
      }
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
          "There is a mismatched between the requested cluster %s",
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

    if (wait) {
      if (!grepl("PoolExists", response)) {
        waitForNodesToComplete(poolConfig$name, 60000)
      }
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

#' Gets the cluster from your Azure account.
#'
#' @param clusterName The cluster configuration that was created in \code{makeCluster}
#'
#' @examples
#' \dontrun{
#' cluster <- getCluster("myCluster")
#' }
#' @export
getCluster <- function(clusterName, verbose = TRUE) {
  pool <- rAzureBatch::getPool(clusterName)

  if (!is.null(pool$code) && !is.null(pool$message)) {
    stop(sprintf("Code: %s - Message: %s", pool$code, pool$message))
  }

  if (pool$targetDedicatedNodes + pool$targetLowPriorityNodes <= 0) {
    stop("Cluster node count needs to be greater than 0.")
  }

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

  nodes <- rAzureBatch::listPoolNodes(clusterName)

  if (!is.null(nodes$value) && length(nodes$value) > 0) {
    nodesInfo <- .processNodeCount(nodes)
    nodesState <- nodesInfo$nodesState
    nodesWithFailures <- nodesInfo$nodesWithFailures

    if (verbose == TRUE) {
      cat("\nnodes:", fill = TRUE)
      cat(sprintf("\tidle:                %s", nodesState$idle), fill = TRUE)
      cat(sprintf("\tcreating:            %s", nodesState$creating), fill = TRUE)
      cat(sprintf("\tstarting:            %s", nodesState$starting), fill = TRUE)
      cat(sprintf("\twaitingforstarttask: %s", nodesState$waitingforstarttask), fill = TRUE)
      cat(sprintf("\tstarttaskfailed:     %s", nodesState$starttaskfailed), fill = TRUE)
      cat(sprintf("\tpreempted:           %s", nodesState$preempted), fill = TRUE)
      cat(sprintf("\trunning:             %s", nodesState$running), fill = TRUE)
      cat(sprintf("\tother:               %s", nodesState$other), fill = TRUE)
    }

    .showNodesFailure(nodesWithFailures)
  }

  cat("Your cluster has been registered.", fill = TRUE)

  config <- getOption("az_config")
  config$targetDedicatedNodes <- pool$targetDedicatedNodes
  config$targetLowPriorityNodes <- pool$targetLowPriorityNodes
  cat(sprintf("Dedicated Node Count: %i", pool$targetDedicatedNodes),
      fill = TRUE)
  cat(sprintf("Low Priority Node Count: %i", pool$targetLowPriorityNodes),
      fill = TRUE)

  config$poolId <- clusterName
  options("az_config" = config)
  return (config)
}

#' Get a list of clusters by state from the given filter
#'
#' @param filter A filter containing cluster state
#'
#' @examples
#' \dontrun{
#' getClusterList()
#' }
#' @export
getClusterList <- function(filter = NULL) {
  filterClause <- ""

  if (!is.null(filter)) {
    if (!is.null(filter$state)) {
      for (i in 1:length(filter$state)) {
        filterClause <-
          paste0(filterClause,
                 sprintf("state eq '%s'", filter$state[i]),
                 " or ")
      }

      filterClause <-
        substr(filterClause, 1, nchar(filterClause) - 3)
    }
  }

  pools <-
    rAzureBatch::listPools(
      query = list(
        "$filter" = filterClause,
        "$select" = paste0("id,state,allocationState,vmSize,currentDedicatedNodes,",
                    "targetDedicatedNodes,currentLowPriorityNodes,targetLowPriorityNodes")
      )
    )

  count <- length(pools$value)
  id <- character(count)
  state <- character(count)
  allocationState <- character(count)
  vmSize <- integer(count)
  currentDedicatedNodes <- integer(count)
  targetDedicatedNodes <- integer(count)
  currentLowPriorityNodes <- integer(count)
  targetLowPriorityNodes <- integer(count)

  if (count > 0) {
    if (is.null(pools$value[[1]]$id)) {
      stop(pools$value)
    }
    for (j in 1:length(pools$value)) {
      id[j] <- pools$value[[j]]$id
      state[j] <- pools$value[[j]]$state
      allocationState[j] <- pools$value[[j]]$allocationState
      vmSize[j] <- pools$value[[j]]$vmSize
      currentDedicatedNodes[j] <- pools$value[[j]]$currentDedicatedNodes
      targetDedicatedNodes[j] <- pools$value[[j]]$targetDedicatedNodes
      currentLowPriorityNodes[j] <- pools$value[[j]]$currentLowPriorityNodes
      targetLowPriorityNodes[j] <- pools$value[[j]]$targetLowPriorityNodes
    }
  }

  return (
    data.frame(
      Id = id,
      State = state,
      AllocationState = allocationState,
      VmSize = vmSize,
      CurrentDedicatedNodes = currentDedicatedNodes,
      targetDedicatedNodes = targetDedicatedNodes,
      currentLowPriorityNodes = currentLowPriorityNodes,
      targetLowPriorityNodes = targetLowPriorityNodes
    )
  )
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

  print(sprintf("Your %s cluster is being deleted.", cluster$poolId))
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
