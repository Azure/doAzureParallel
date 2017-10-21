# Run this test for users to make sure the core features
# of doAzureParallel are still working
context("live scenario test")
test_that("Scenario Test", {
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "test_cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4, .packages = c("stringr")) %dopar% {
      library(xml2)
      library(rAzureBatch)
      mean(1:3)
    }

  res

  doAzureParallel::stopCluster(cluster)

})

test_that("Chunksize Test", {
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:10, .options.azure = list(chunkSize = 3)) %dopar% {
      i
    }

  doAzureParallel::stopCluster(cluster)

  testthat::expect_equal(length(res),
                         10)

  for (i in 1:10) {
    testthat::expect_equal(res[[i]],
                           i)
  }
})
