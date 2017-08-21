#!/usr/bin/Rscript
args = commandArgs(trailingOnly = TRUE)

# test if there is at least one argument: if not, return an error
if (length(args) == 0) {
  stop("At least one argument must be supplied (input file).n", call. = FALSE)
} else if (length(args) == 1) {
  # default output file
  args[2] = "out.txt"
}

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
        pkgenv <- as.environment(paste0('package:', pkgname))
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
          stop('loaded ', pkgname, ', but parent search failed', call. = FALSE)
        } else {
          message('loaded ', pkgname, ' and set parent environment')
        }
      }
    }
  },
  error = function(e) {
    cat(sprintf('Error getting parent environment: %s\n',
                conditionMessage(e)))
  })

  # return the global environment by default
  if (is.null(parenv)) globalenv() else parenv
}

AZ_BATCH_JOB_PREP_DIR <- args[1]
AZ_BATCH_TASK_WORKING_DIR <- args[2]
AZ_BATCH_JOB_ENV <- args[3]
AZ_BATCH_TASK_ENV <- args[4]

setwd(AZ_BATCH_TASK_WORKING_DIR)

azbatchenv <- readRDS(paste0(AZ_BATCH_JOB_PREP_DIR, "/", AZ_BATCH_JOB_ENV))
taskArgs <- readRDS(AZ_BATCH_TASK_ENV)

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

result <- lapply(taskArgs, function(args){
  tryCatch({
    lapply(names(args), function(n)
      assign(n, args[[n]], pos = azbatchenv$exportenv))

    eval(azbatchenv$expr, azbatchenv$exportenv)
  }, error = function(e) {
    print(e)
  })
})

names(result) <- names(taskArgs)

print("Result")
result

finalResult <- result
if (!is.null(azbatchenv$gather)) {
  finalResult <- Reduce(azbatchenv$gather, result)
}

file_result_name <- strsplit(AZ_BATCH_TASK_ENV, "[.]")[[1]][1]
saveRDS(finalResult, file = paste0(AZ_BATCH_TASK_WORKING_DIR, "/", file_result_name, "-result.rds"))

quit(save = "yes", status = 0, runLast = FALSE)
