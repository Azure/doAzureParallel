context("validating cluster config")

test_that("validating a cluster config file with null pool property", {
  clusterConfig <- "badcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)

  expect_true(is.null(config[["pool"]]))

  on.exit(file.remove(clusterConfig))
})

test_that("validating a cluster config file with bad autoscale formula property", {
  clusterConfig <- "badcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)
  config$poolSize$autoscaleFormula <- "BAD_FORMULA"

  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterConfig))

  expect_error(validation$isValidClusterConfig(clusterConfig))

  on.exit(file.remove(clusterConfig))
})


test_that("validating a cluster config file with incorrect data types", {
  clusterConfig <- "badcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)

  config$maxTasksPerNode <- "2"

  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterConfig))

  expect_error(validation$isValidClusterConfig(clusterConfig))

  on.exit(file.remove(clusterConfig))
})

test_that("validating a cluster config file with null values", {
  clusterConfig <- "nullcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)

  config$poolSize <- NULL

  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterConfig))

  expect_error(validation$isValidClusterConfig(clusterConfig))

  on.exit(file.remove(clusterConfig))
})
