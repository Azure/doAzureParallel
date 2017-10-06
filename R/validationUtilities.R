validateClusterConfig <- function(clusterFilePath) {
  if (file.exists(clusterFilePath)) {
    pool <- rjson::fromJSON(file = clusterFilePath)
  }
  else{
    pool <- rjson::fromJSON(file = file.path(getwd(), clusterFilePath))
  }
  
  if (is.null(pool$poolSize)) {
    stop("Missing poolSize entry")
  }
  
  if (is.null(pool$poolSize$dedicatedNodes)) {
    stop("Missing dedicatedNodes entry")
  }
  
  if (is.null(pool$poolSize$lowPriorityNodes)) {
    stop("Missing lowPriorityNodes entry")
  }
  
  if (is.null(pool$poolSize$autoscaleFormula)) {
    stop("Missing autoscaleFormula entry")
  }
  
  if (is.null(pool$poolSize$dedicatedNodes$min)) {
    stop("Missing dedicatedNodes$min entry")
  }
  
  if (is.null(pool$poolSize$dedicatedNodes$max)) {
    stop("Missing dedicatedNodes$max entry")
  }
  
  if (is.null(pool$poolSize$lowPriorityNodes$min)) {
    stop("Missing lowPriorityNodes$min entry")
  }
  
  if (is.null(pool$poolSize$lowPriorityNodes$max)) {
    stop("Missing lowPriorityNodes$max entry")
  }
  
  stopifnot(is.character(pool$name))
  stopifnot(is.character(pool$vmSize))
  stopifnot(is.character(pool$poolSize$autoscaleFormula))
  stopifnot(pool$poolSize$autoscaleFormula %in% names(autoscaleFormula))
  
  stopifnot(pool$poolSize$dedicatedNodes$min <= pool$poolSize$dedicatedNodes$max)
  stopifnot(pool$poolSize$lowPriorityNodes$min <= pool$poolSize$lowPriorityNodes$max)
  stopifnot(pool$maxTasksPerNode >= 1)
  
  stopifnot(is.double(pool$poolSize$dedicatedNodes$min))
  stopifnot(is.double(pool$poolSize$dedicatedNodes$max))
  stopifnot(is.double(pool$poolSize$lowPriorityNodes$min))
  stopifnot(is.double(pool$poolSize$lowPriorityNodes$max))
  stopifnot(is.double(pool$maxTasksPerNode))
  
  TRUE
}

# Validating cluster configuration files below doAzureParallel version 0.3.2
validateDeprecatedClusterConfig <- function(clusterFilePath) {
  if (file.exists(clusterFilePath)) {
    poolConfig <- rjson::fromJSON(file = clusterFilePath)
  }
  else{
    poolConfig <-
      rjson::fromJSON(file = file.path(getwd(), clusterFilePath))
  }
  
  if (is.null(poolConfig$pool$poolSize)) {
    stop("Missing poolSize entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$dedicatedNodes)) {
    stop("Missing dedicatedNodes entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$lowPriorityNodes)) {
    stop("Missing lowPriorityNodes entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$autoscaleFormula)) {
    stop("Missing autoscaleFormula entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$dedicatedNodes$min)) {
    stop("Missing dedicatedNodes$min entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$dedicatedNodes$max)) {
    stop("Missing dedicatedNodes$max entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$lowPriorityNodes$min)) {
    stop("Missing lowPriorityNodes$min entry")
  }
  
  if (is.null(poolConfig$pool$poolSize$lowPriorityNodes$max)) {
    stop("Missing lowPriorityNodes$max entry")
  }
  
  stopifnot(is.character(poolConfig$pool$name))
  stopifnot(is.character(poolConfig$pool$vmSize))
  stopifnot(is.character(poolConfig$pool$poolSize$autoscaleFormula))
  stopifnot(poolConfig$pool$poolSize$autoscaleFormula %in% names(autoscaleFormula))
  
  stopifnot(
    poolConfig$pool$poolSize$dedicatedNodes$min <= poolConfig$pool$poolSize$dedicatedNodes$max
  )
  stopifnot(
    poolConfig$pool$poolSize$lowPriorityNodes$min <= poolConfig$pool$poolSize$lowPriorityNodes$max
  )
  stopifnot(poolConfig$pool$maxTasksPerNode >= 1)
  
  stopifnot(is.double(poolConfig$pool$poolSize$dedicatedNodes$min))
  stopifnot(is.double(poolConfig$pool$poolSize$dedicatedNodes$max))
  stopifnot(is.double(poolConfig$pool$poolSize$lowPriorityNodes$min))
  stopifnot(is.double(poolConfig$pool$poolSize$lowPriorityNodes$max))
  stopifnot(is.double(poolConfig$pool$maxTasksPerNode))
  
  TRUE
}
