context("foreach options test")
test_that("chunksize", {
  testthat::skip_on_travis()
  source("utility.R")
  settings <- getSettings()

  # set your credentials
  doAzureParallel::setCredentials(settings$credentials)

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

  doAzureParallel::stopCluster(cluster)
})
