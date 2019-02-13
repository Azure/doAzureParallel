context("validating cluster config")

test_that("generateClusterConfig_NullPoolValue_Success", {
  clusterConfig <- "badcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)

  expect_true(is.null(config[["pool"]]))

  on.exit(file.remove(clusterConfig))
})

test_that("generateClusterConfig_BadAutoscaleFormula_Failed", {
  clusterConfig <- "badcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)
  config$poolSize$autoscaleFormula <- "BAD_FORMULA"

  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterConfig))

  expect_error(validation$isValidClusterConfig(clusterConfig))

  on.exit(file.remove(clusterConfig))
})


test_that("generateClusterConfig_InvalidDataTypes_Failed", {
  clusterConfig <- "badcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)

  config$maxTasksPerNode <- "2"

  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterConfig))

  expect_error(validation$isValidClusterConfig(clusterConfig))

  on.exit(file.remove(clusterConfig))
})

test_that("generateClusterConfig_NullValues_Failed", {
  clusterConfig <- "nullcluster.json"

  generateClusterConfig(clusterConfig)
  config <- jsonlite::fromJSON(clusterConfig)

  config$poolSize <- NULL

  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterConfig))

  expect_error(validation$isValidClusterConfig(clusterConfig))

  on.exit(file.remove(clusterConfig))
})
