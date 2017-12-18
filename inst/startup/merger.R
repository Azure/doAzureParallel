#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)
status <- 0

jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")

isError <- function(x) {
  inherits(x, "simpleError") || inherits(x, "try-error")
}

batchTasksCount <- as.integer(args[1])
chunkSize <- as.integer(args[2])
errorHandling <- args[3]

batchJobId <- Sys.getenv("AZ_BATCH_JOB_ID")
batchJobPreparationDirectory <-
  Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
batchTaskWorkingDirectory <- Sys.getenv("AZ_BATCH_TASK_WORKING_DIR")
taskPackageDirectory <- paste0(batchTaskWorkingDirectory)

libPaths <- c(
  taskPackageDirectory,
  jobPrepDirectory,
  "/mnt/batch/tasks/shared/R/packages",
  .libPaths()
)

.libPaths(libPaths)

azbatchenv <-
  readRDS(paste0(batchJobPreparationDirectory, "/", batchJobId, ".rds"))

setwd(batchTaskWorkingDirectory)

for (package in azbatchenv$packages) {
  library(package, character.only = TRUE)
}

parent.env(azbatchenv$exportenv) <- globalenv()

enableCloudCombine <- azbatchenv$enableCloudCombine
cloudCombine <- azbatchenv$cloudCombine

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
    results <- vector("list", batchTasksCount)
    count <- 1

    if (errorHandling == "remove" || errorHandling == "stop") {
      files <- list.files(file.path(batchTaskWorkingDirectory,
                                    "result"),
                          full.names = TRUE)

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

      results <- foreach::foreach(i = 1:length(files), .export = c("files")) %dopar% {
        task <- readRDS(files[i])

        if (isError(task)) {
          if (errorHandling == "stop") {
            stop("Error found")
          }
          else {
            next
          }
        }

        task
      }

      results <- unlist(results, recursive = FALSE)

      saveRDS(results, file = file.path(
        batchTaskWorkingDirectory,
        paste0(batchJobId, "-merge-result.rds")
      ))
    }
    else if (errorHandling == "pass") {
      results <- foreach::foreach(i = 1:batchTasksCount,
                                  .export = c("results",
                                              "count",
                                              "batchTasksCount",
                                              "chunkSize")) %dopar% {
        taskResult <-
          file.path(
            batchTaskWorkingDirectory,
            "result",
            paste0(batchJobId, "-task", i, "-result.rds")
          )

        print(taskResult)

        if (file.exists(taskResult)) {
          task <- readRDS(taskResult)
          for (t in 1:length(task)) {
            results[count] <- task[t]
            count <- count + 1
          }

          task
        }
        else {
          result <- vector(list, length(chunkSize))
          for (t in 1:length(chunkSize)) {
            results[count] <- NA
            count <- count + 1
          }

          result
        }
      }

      results <- unlist(results, recursive = FALSE)
      saveRDS(results, file = file.path(
        batchTaskWorkingDirectory,
        paste0(batchJobId, "-merge-result.rds")
      ))
    }

    0
  },
  error = function(e) {
    print(e)
    1
  })

  parallel::stopCluster(cluster)
}

quit(save = "yes",
     status = status,
     runLast = FALSE)
