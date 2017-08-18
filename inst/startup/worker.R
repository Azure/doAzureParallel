#!/usr/bin/Rscript
args <- commandArgs(trailingOnly = TRUE)

# test if there is at least one argument: if not, return an error
if (length(args) == 0) {
  stop("At least one argument must be supplied (input file).n", call. = FALSE)
} else if (length(args) == 1) {
  # default output file
  args[2] <- "out.txt"
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

batchJobPreparationDirectory <- args[1]
batchTaskWorkingDirectory <- args[2]
batchJobEnvironment <- args[3]
batchTaskEnvironment <- args[4]

setwd(batchTaskWorkingDirectory)

azbatchenv <-
  readRDS(paste0(batchJobPreparationDirectory, "/", batchJobEnvironment))
taskArgs <- readRDS(batchTaskEnvironment)

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

result <- lapply(taskArgs, function(args) {
  tryCatch({
    lapply(names(args), function(n)
      assign(n, args[[n]], pos = azbatchenv$exportenv))

    eval(azbatchenv$expr, azbatchenv$exportenv)
  },
  error = function(e) {
    print(e)
  })
})

fileResultName <- strsplit(batchTaskEnvironment, "[.]")[[1]][1]
saveRDS(result,
        file = file.path(
          batchTaskWorkingDirectory,
          paste0(fileResultName, "-result.rds")
        ))

quit(save = "yes",
     status = 0,
     runLast = FALSE)
