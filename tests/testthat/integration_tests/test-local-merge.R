# Run this test for users to make sure the local result merge feature
# of doAzureParallel are still working
context("merge job result locally test")
test_that("merge job result locally test", {
  testthat::skip_on_travis()
  testthat::skip("Skipping merge job locally")
  source("utility.R")
  settings <- getSettings()

  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  setChunkSize(2)
  '%dopar%' <- foreach::'%dopar%'
  jobId <-
    foreach::foreach(
      i = 1:11,
      .errorhandling = "pass",
      .options.azure = list(
        enableCloudCombine = FALSE,
        wait = FALSE
      )
    ) %dopar% {
      i
    }

  res <- getJobResult(jobId)

  testthat::expect_equal(length(res),
                         10)

  for (i in 1:10) {
    testthat::expect_equal(res[[i]],
                           i)
  }
})

test_that("merge job result locally test", {
  testthat::skip_on_travis()
  testthat::skip("Skipping merge job locally")
  source("utility.R")
  settings <- getSettings()

  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  setChunkSize(2)
  '%dopar%' <- foreach::'%dopar%'
  jobId <-
    foreach::foreach(
      i = 1:11,
      .errorhandling = "pass",
      .options.azure = list(
        enableCloudCombine = FALSE,
        wait = FALSE
      )
    ) %dopar% {
      i
    }

  res <- getJobResult(jobId)

  testthat::expect_equal(length(res),
                         10)

  for (i in 1:10) {
    testthat::expect_equal(res[[i]],
                           i)
  }
})
