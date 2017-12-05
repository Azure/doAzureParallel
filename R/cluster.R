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
      packages <- c(installCranCommand, packages)
    }
    if (!is.null(installGithubCommand)) {
      packages <- c(installGithubCommand, packages)
    }
    if (!is.null(installBioconductorCommand)) {
      packages <- c(installBioconductorCommand, packages)
    }

    if (length(packages) == 0) {
      packages <- NULL
    }

    commandLine <- NULL

    # install docker
    dockerImage <- "rocker/tidyverse:latest"
    if (!is.null(poolConfig$containerImage)) {
      dockerImage <- poolConfig$containerImage
    }

    config$containerImage <- dockerImage
    installAndStartContainerCommand <- "cluster_setup.sh"

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
        !is.null(config$dockerAuthentication$username)) {

      username <- config$dockerAuthentication$username
      password <- config$dockerAuthentication$password
      registry <- config$dockerAuthentication$registry

      # TODO: Use --password-stdin when logging in to not show the password on the command line
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

      cat(sprintf(
        paste(
          "Cluster '%s' already exists and is being deleted.",
          "Another cluster with the same name cannot be created",
          "until it is deleted. Please wait for the cluster to be deleted",
          "or create one with a different name"
        ),
        poolConfig$name
      ),
      fill = TRUE)

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
