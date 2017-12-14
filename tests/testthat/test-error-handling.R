context("error handling test")
test_that("Pass error handling test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4, .errorhandling = "remove") %dopar% {
      if (i == 3 || i == 4) {
        randomObject
      }

      i
    }

  res

  testthat::expect_equal(length(res), 2)
})

test_that("Pass error handling test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
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
