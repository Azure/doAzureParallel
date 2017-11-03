Validators <- R6::R6Class(
  "Validators",
  lock_objects = TRUE,
  public = list(
    isValidStorageContainerName = function(storageContainerName) {
      if (!grepl("^([a-z]|[0-9]|[-]){3,64}$", storageContainerName)) {
        stop(paste("Storage Container names can contain only lowercase letters, numbers,",
                   "and the dash (-) character. Names must be 3 through 64 characters long."))
      }
    },
    isValidPoolName = function(poolName) {
      if (!grepl("^([a-zA-Z0-9]|[-]|[_]){1,64}$", poolName)) {
        stop(paste("The pool name can contain any combination of alphanumeric characters",
                   "including hyphens and underscores, and cannot contain more",
                   "than 64 characters."))
      }
    },
    isValidJobName = function(jobName) {
      if (!grepl("^([a-zA-Z0-9]|[-]|[_]){1,64}$", jobName)) {
        stop(paste("The job name can contain any combination of alphanumeric characters",
                   "including hyphens and underscores, and cannot contain more",
                   "than 64 characters."))
      }
    }
  )
)

`Validators` <- Validators$new()
