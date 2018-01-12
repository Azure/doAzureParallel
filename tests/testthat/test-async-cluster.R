# Run this test for users to make sure the async cluster creation features
# of doAzureParallel are still working
context("async cluster scenario test")
test_that("Async cluster scenario test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)

  cluster <-
    doAzureParallel::makeCluster(clusterSetting = clusterFileName, wait = FALSE)

  cluster <- getCluster(cluster$poolId)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4) %dopar% {
      mean(1:3)
    }

  res

  testthat::expect_equal(length(res), 4)
  testthat::expect_equal(res, list(2, 2, 2, 2))

  stopCluster(cluster)
})
