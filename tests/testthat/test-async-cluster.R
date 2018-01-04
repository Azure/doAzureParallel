# Run this test for users to make sure the async cluster creation features
# of doAzureParallel are still working
context("async cluster scenario test")
test_that("Async cluster scenario test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "test_cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  clusterName <- doAzureParallel::makeCluster(clusterFileName, wait = FALSE)
  while (is.null(getCluster(clusterName))) {
    cat(".")
  }
  cat("\ncluster is ready")
  cluster <- getCluster(clusterName)
  doAzureParallel::registerDoAzureParallel(cluster)

  stopCluster(cluster)
})
