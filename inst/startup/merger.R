#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)
status <- 0

isError <- function(x) {
  inherits(x, "simpleError") || inherits(x, "try-error")
}

getSimpleErrorMessage <- function(e) {
  print(e$message)
  e$message
}

getSimpleErrorCall <- function(e) {
  deparse(e$call)
}

batchTasksCount <- as.integer(args[1])
chunkSize <- as.integer(args[2])
errorHandling <- args[3]
cat(chunkSize, fill = TRUE)
cat(batchTasksCount, fill = TRUE)

batchJobId <- Sys.getenv("AZ_BATCH_JOB_ID")
batchJobPreparationDirectory <-
  Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
batchTaskWorkingDirectory <- Sys.getenv("AZ_BATCH_TASK_WORKING_DIR")

azbatchenv <-
  readRDS(paste0(batchJobPreparationDirectory, "/", batchJobId, ".rds"))

setwd(batchTaskWorkingDirectory)

for (package in azbatchenv$packages) {
  library(package, character.only = TRUE)
}

parent.env(azbatchenv$exportenv) <- globalenv()
sessionInfo()

enableCloudCombine <- azbatchenv$enableCloudCombine
cloudCombine <- azbatchenv$cloudCombine

if (typeof(cloudCombine) == "list" && enableCloudCombine) {
  results <- vector("list", batchTasksCount * chunkSize)
  count <- 1

  status <- tryCatch({
    if (errorHandling == "remove" || errorHandling == "stop") {
      files <- list.files(file.path(batchTaskWorkingDirectory,
                                    "result"),
                          full.names = TRUE)

      if (errorHandling == "stop" && length(files) != batchTasksCount) {
        stop("Issues with file upload")
      }

      results <- vector("list", length(files) * chunkSize)

      for (i in 1:length(files)) {
        task <- readRDS(files[i])

        if (isError(task)) {
          if (errorHandling == "stop") {
            stop("Error found")
          }
          else {
            next
          }
        }

        for (t in 1:length(chunkSize)) {
          results[count] <- task[t]
          count <- count + 1
        }
      }

      saveRDS(results, file = file.path(
        batchTaskWorkingDirectory,
        paste0(batchJobId, "-merge-result.rds")
      ))
    }
    else if (errorHandling == "pass") {
      for (i in 1:batchTasksCount) {
        taskResult <-
          file.path(
            batchTaskWorkingDirectory,
            "result",
            paste0(batchJobId, "-task", i, "-result.rds")
          )

        if (file.exists(taskResult)) {
          task <- readRDS(taskResult)
          for (t in 1:length(chunkSize)) {
            results[count] <- task[t]
            count <- count + 1
          }
        }
        else {
          for (t in 1:length(chunkSize)) {
            results[count] <- NA
            count <- count + 1
          }
        }
      }

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
} else {
  # Work needs to be done for utilizing custom merge functions
}

quit(save = "yes",
     status = status,
     runLast = FALSE)
