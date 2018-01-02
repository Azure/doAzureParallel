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
  it <- azbatchenv$it
  accumulator <- makeAccum(it)
  print(it)
  print(accumulator)
  parallel::clusterExport(cluster, "libPaths")
  parallel::clusterExport(cluster, "it")
  parallel::clusterExport(cluster, "accumulator")
  parallel::clusterEvalQ(cluster, .libPaths(libPaths))

  doParallel::registerDoParallel(cluster)

  status <- tryCatch({
    count <- 1

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


    #registerDoSEQ()
    foreach::foreach(i = 1:batchTasksCount, .export = c("it",
                                                        "batchTaskWorkingDirectory",
                                                        "batchJobId",
                                                        "chunkSize",
                                                        "errorHandling",
                                                        "accumulator",
                                                        "isError"
                                                        ), .packages = c('foreach')) %dopar% {
     taskFileName <-
           file.path(
             batchTaskWorkingDirectory,
             "result",
             paste0(batchJobId, "-task", i, "-result.rds")
           )

     task <- tryCatch({
       readRDS(taskFileName)
     }, error = function(e) {
       e
     })

     n <- as.numeric(names(task))

     print(task)
     print(n)

     tryCatch(accumulator(task, n),
              error = function(e) {
                cat("error calling combine function:\n", file=stderr())
                print(e)
              })
    }

    # results <- foreach::foreach(i = 1:batchTasksCount, .export = c("batchTaskWorkingDirectory",
    #                                                                "batchJobId",
    #                                                                 "chunkSize",
    #                                                                "errorHandling",
    #                                                                "isError")) %dopar% {
    #
    #   taskFileName <-
    #     file.path(
    #       batchTaskWorkingDirectory,
    #       "result",
    #       paste0(batchJobId, "-task", i, "-result.rds")
    #     )
    #   task <- tryCatch({
    #     readRDS(taskFileName)
    #   }, error = function(e) {
    #     e
    #   })
    #
    #   if (isError(task)) {
    #     if (errorHandling == "stop") {
    #       stop("Error found: ", task)
    #     }
    #     else if (errorHandling == "pass") {
    #       result <- vector("list", length(chunkSize))
    #       for (t in 1:length(chunkSize)) {
    #         result[[t]] <- NA
    #       }
    #
    #       result
    #       next
    #     }
    #     else if (errorHandling == "remove"){
    #       next
    #     }
    #     else {
    #       stop("Unknown error handling: ", errorHandling)
    #     }
    #   }
    #
    #   result <- vector("list", length(task))
    #   for (t in 1:length(task)) {
    #     if (isError(task[[t]]) && errorHandling == "stop") {
    #       stop("Error found: ", task[[t]])
    #     }
    #     else {
    #       result[[t]] <- task[[t]]
    #     }
    #   }
    #
    #   result
    # }

    # results <- unlist(results, recursive = FALSE)

    0
  },
  error = function(e) {
    traceback()
    print(e)
    1
  })

  parallel::stopCluster(cluster)

  errorValue <- foreach::getErrorValue(it)
  errorIndex <- foreach::getErrorIndex(it)

  print(it)

  if (identical(errorHandling, "stop") && !is.null(errorValue)) {
    msg <- sprintf("task %d failed - \"%s\"", errorIndex,
                   conditionMessage(errorValue))
    stop(simpleError(msg, call = expr))
  } else {
    results <- foreach::getResult(it)
  }

  saveRDS(results, file = file.path(
    batchTaskWorkingDirectory,
    paste0(batchJobId, "-merge-result.rds")
  ))
}

quit(save = "yes",
     status = status,
     runLast = FALSE)
