context("Integration Test")

# Run this test for users to make sure the core features
# of doAzureParallel are still working
test_that("simple foreach 1 to 4", {
  testthat::skip_on_travis()
  source("utility.R")
  settings <- getSettings()
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4) %dopar% {
      i
    }

  res <- unname(res)

  testthat::expect_equal(length(res), 4)
  testthat::expect_equal(res, list(1, 2, 3, 4))
})

context("Foreach Options Integration Test")
test_that("chunksize", {
  testthat::skip_on_travis()
  source("utility.R")
  settings <- getSettings()

  cluster <- doAzureParallel::makeCluster(settings$clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:10,
                     .options.azure = list(chunkSize = 3)) %dopar% {
                       i
                     }

  testthat::expect_equal(length(res),
                         10)

  for (index in 1:10) {
    testthat::expect_equal(res[[index]],
                           index)
  }

  res <-
    foreach::foreach(i = 1:2,
                     .options.azure = list(chunkSize = 2)) %dopar% {
                       i
                     }

  testthat::expect_equal(length(res),
                         2)

  for (index in 1:2) {
    testthat::expect_equal(res[[index]],
                           index)
  }
})
