#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)
status <- 0

jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")

isError <- function(x) {
  return(inherits(x, "simpleError") || inherits(x, "try-error"))
}

batchTasksCount <- as.integer(args[1])
chunkSize <- as.integer(args[2])
errorHandling <- args[3]

batchJobId <- Sys.getenv("AZ_BATCH_JOB_ID")
batchTaskId <- Sys.getenv("AZ_BATCH_TASK_ID")
batchJobPreparationDirectory <-
  Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
batchTaskWorkingDirectory <- Sys.getenv("AZ_BATCH_TASK_WORKING_DIR")
taskPackageDirectory <- paste0(batchTaskWorkingDirectory)
clusterPackageDirectory <- file.path(Sys.getenv("AZ_BATCH_NODE_SHARED_DIR"),
                                     "R",
                                     "packages")

libPaths <- c(
  taskPackageDirectory,
  jobPrepDirectory,
  clusterPackageDirectory,
  .libPaths()
)

.libPaths(libPaths)

azbatchenv <-
  readRDS(paste0(batchJobPreparationDirectory, "/", batchJobId, ".rds"))

setwd(batchTaskWorkingDirectory)

parent.env(azbatchenv$exportenv) <- globalenv()

enableCloudCombine <- azbatchenv$enableCloudCombine
cloudCombine <- azbatchenv$cloudCombine
localCombine <- azbatchenv$localCombine
isListCombineFunction <- identical(function(a, ...) c(a, list(...)),
                                   localCombine, ignore.environment = TRUE)

if (typeof(cloudCombine) == "list" && enableCloudCombine) {
  if (!require("doParallel", character.only = TRUE)) {
    install.packages(c("doParallel"), repos = "http://cran.us.r-project.org")
    require("doParallel", character.only = TRUE)
    library("doParallel")
  }

  sessionInfo()
  cluster <- parallel::makeCluster(parallel::detectCores(), outfile = "doParallel.txt")
  parallel::clusterExport(cluster, "libPaths")
  parallel::clusterEvalQ(cluster, .libPaths(libPaths))

  doParallel::registerDoParallel(cluster)

  status <- tryCatch({
    count <- 1

    files <- list.files(file.path(batchTaskWorkingDirectory,
                                  "results"),
                        full.names = TRUE)

    files <- files[order(as.numeric(gsub("[^0-9]", "", files)))]

    if (errorHandling == "stop" &&
        length(files) != batchTasksCount) {
      stop(
        paste(
          "Error handling is set to 'stop' and there are missing results due to",
          "task failures. If this is not the correct behavior, change the errorHandling",
          "property to 'pass' or 'remove' in the foreach object.",
          "For more information on troubleshooting, check",
          "https://github.com/Azure/doAzureParallel/blob/master/docs/40-troubleshooting.md"
        )
      )
    }

    results <- foreach::foreach(i = 1:length(files), .export = c("batchTaskWorkingDirectory",
                                                                 "batchJobId",
                                                                 "chunkSize",
                                                                 "errorHandling",
                                                                 "isError")) %do% {
      task <- tryCatch({
        readRDS(files[i])
      }, error = function(e) {
        e
      })

      if (isError(task)) {
        if (errorHandling == "stop") {
          stop("Error found: ", task)
        }
        else if (errorHandling == "pass") {
          result <- lapply(1:length(chunkSize), function(x){
            NA
          })

          result
          next
        }
        else if (errorHandling == "remove"
                 && isListCombineFunction) {
          next
        }
        else {
          stop("Unknown error handling: ", errorHandling)
        }
      }

      if (errorHandling == "stop") {
        errors <- Filter(function(x) isError(x), task)

        if (length(errors) > 0) {
          stop("Error found: ", errors)
        }
      }

      if (errorHandling == "remove"
          && isListCombineFunction) {
        return(Filter(function(x) !isError(x), task))
      }

      return(task)
    }

    results <- unlist(results, recursive = FALSE)

    saveRDS(results, file = file.path(
      batchTaskWorkingDirectory,
      paste0(batchTaskId, "-result.rds")
    ))

    0
  },
  error = function(e) {
    traceback()
    print(e)
    1
  })

  parallel::stopCluster(cluster)
}

quit(save = "yes",
     status = status,
     runLast = FALSE)
