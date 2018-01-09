#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)
workerErrorStatus <- 0

startIndex <- as.integer(args[1])
endIndex <- as.integer(args[2])
isDataSet <- as.logical(as.integer(args[3]))

jobPrepDirectory <- Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
.libPaths(c(
  jobPrepDirectory,
  "/mnt/batch/tasks/shared/R/packages",
  .libPaths()
))

getparentenv <- function(pkgname) {
  parenv <- NULL

  # if anything goes wrong, print the error object and return
  # the global environment
  tryCatch({
    # pkgname is NULL in many cases, as when the foreach loop
    # is executed interactively or in an R script
    if (is.character(pkgname)) {
      # load the specified package
      if (require(pkgname, character.only = TRUE)) {
        # search for any function in the package
        pkgenv <- as.environment(paste0("package:", pkgname))
        for (sym in ls(pkgenv)) {
          fun <- get(sym, pkgenv, inherits = FALSE)
          if (is.function(fun)) {
            env <- environment(fun)
            if (is.environment(env)) {
              parenv <- env
              break
            }
          }
        }
        if (is.null(parenv)) {
          stop("loaded ", pkgname, ", but parent search failed", call. = FALSE)
        }
        else {
          message("loaded ", pkgname, " and set parent environment")
        }
      }
    }
  },
  error = function(e) {
    cat(sprintf(
      "Error getting parent environment: %s\n",
      conditionMessage(e)
    ))
  })

  # return the global environment by default
  if (is.null(parenv))
    globalenv()
  else
    parenv
}

batchJobId <- Sys.getenv("AZ_BATCH_JOB_ID")
batchTaskId <- Sys.getenv("AZ_BATCH_TASK_ID")
batchJobPreparationDirectory <-
  Sys.getenv("AZ_BATCH_JOB_PREP_WORKING_DIR")
batchTaskWorkingDirectory <- Sys.getenv("AZ_BATCH_TASK_WORKING_DIR")

batchJobEnvironment <- paste0(batchJobId, ".rds")
batchTaskEnvironment <- paste0(batchTaskId, ".rds")

setwd(batchTaskWorkingDirectory)

azbatchenv <-
  readRDS(paste0(batchJobPreparationDirectory, "/", batchJobEnvironment))

tryCatch({
  print("Data Set Boolean: ")

  print(isDataSet)
  print(typeof(isDataSet))
  if (isDataSet) {
    argsList <- readRDS(batchTaskEnvironment)
  } else {
    argsList <- azbatchenv$argsList
    argsList <- argsList[startIndex:endIndex]
  }

  print(argsList)
},
error = function(e){
  print(e)
})

for (package in azbatchenv$packages) {
  library(package, character.only = TRUE)
}

ls(azbatchenv)
parent.env(azbatchenv$exportenv) <- getparentenv(azbatchenv$pkgName)

azbatchenv$pkgName
sessionInfo()
if (!is.null(azbatchenv$inputs)) {
  options("az_config" = list(container = azbatchenv$inputs))
}

result <- lapply(argsList, function(args) {
  tryCatch({
    lapply(names(args), function(n)
      assign(n, args[[n]], pos = azbatchenv$exportenv))

    eval(azbatchenv$expr, azbatchenv$exportenv)
  },
  error = function(e) {
    workerErrorStatus <<- 1
    print(e)
    traceback()

    e
  })
})

if (!is.null(azbatchenv$gather) && length(argsList) > 1) {
  result <- Reduce(azbatchenv$gather, result)
}

saveRDS(result,
        file = file.path(
          batchTaskWorkingDirectory,
          paste0(batchTaskId, "-result.rds")
        ))

cat(paste0("Error Code: ", workerErrorStatus), fill = TRUE)

quit(save = "yes",
     status = workerErrorStatus,
     runLast = FALSE)
