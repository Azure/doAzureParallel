#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
.libPaths(c(jobPrepDirectory, "/mnt/batch/tasks/shared/R/packages", .libPaths()))

# test if there is at least one argument: if not, return an error
if (length(args) == 0) {
  stop("At least one argument must be supplied (input file).n", call. = FALSE)
} else if (length(args) == 1) {
  # default output file
  args[2] <- "out.txt"
}

batchJobPreparationDirectory <- args[1]
batchTaskWorkingDirectory <- args[2]
batchJobId <- args[3]

n <- args[4]
numOfTasks <- args[5]

azbatchenv <-
  readRDS(paste0(batchJobPreparationDirectory, "/", batchJobId, ".rds"))

for (package in azbatchenv$packages) {
  library(package, character.only = TRUE)
}
parent.env(azbatchenv$exportenv) <- globalenv()

enableCloudCombine <- azbatchenv$enableCloudCombine
cloudCombine <- azbatchenv$cloudCombine

if (typeof(cloudCombine) == "list" && enableCloudCombine) {
  results <- vector("list", numOfTasks)
  count <- 1
  tryCatch({
    for (i in 1:n) {
      taskResult <-
        file.path(
          batchTaskWorkingDirectory,
          "result",
          paste0(batchJobId, "-task", i, "-result.rds")
        )

      task <- readRDS(taskResult)

      for (t in 1:length(task)) {
        results[count] <- task[t]
        count <- count + 1
      }
    }

    saveRDS(results, file = file.path(
      batchTaskWorkingDirectory,
      paste0(batchJobId, "-merge-result.rds")
    ))
  },
  error = function(e) {
    print(e)
  })
} else {
  # Work needs to be done for utilizing custom merge functions
}

quit(save = "yes",
     status = 0,
     runLast = FALSE)
