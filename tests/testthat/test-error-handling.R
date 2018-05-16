context("error handling test")
test_that("Remove error handling with combine test", {
  testthat::skip_on_travis()
  source("utility.R")
  settings <- getSettings()

  # set your credentials
  doAzureParallel::setCredentials(settings$credentials)

  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:5, .errorhandling = "remove", .combine = "c") %dopar% {
      if (i == 3 || i == 4) {
        fail
      }

      sqrt(i)
    }

  res

  testthat::expect_equal(length(res), 2)
})

test_that("Remove error handling test", {
  testthat::skip_on_travis()

  settings <- getSettings()

  # set your credentials
  doAzureParallel::setCredentials(settings$credentials)

  settings$clusterConfig$poolId <- "error-handling-test"
  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:5, .errorhandling = "remove") %dopar% {
      if (i == 3 || i == 4) {
        randomObject
      }

      i
    }

  res <- unname(res)

  testthat::expect_equal(res, list(1, 2, 5))
})

test_that("Pass error handling test", {
  testthat::skip_on_travis()

  settings <- getSettings()

  # set your credentials
  doAzureParallel::setCredentials(settings$credentials)

  settings$clusterConfig$poolId <- "error-handling-test"
  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4, .errorhandling = "pass") %dopar% {
      if (i == 2) {
        randomObject
      }

      i
    }

  res

  testthat::expect_equal(length(res), 4)
  testthat::expect_true(class(res[[2]])[1] == "simpleError")
})

test_that("Stop error handling test", {
  testthat::skip_on_travis()

  settings <- getSettings()

  # set your credentials
  doAzureParallel::setCredentials(settings$credentials)

  settings$clusterConfig$poolId <- "error-handling-test"
  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'

  testthat::expect_error(
    res <-
      foreach::foreach(i = 1:4, .errorhandling = "stop") %dopar% {
        if (i == 2) {
          randomObject
        }

        i
      }
  )

  doAzureParallel::stopCluster(cluster)
})
