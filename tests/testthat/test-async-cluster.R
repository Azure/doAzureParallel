# Run this test for users to make sure the async cluster creation features
# of doAzureParallel are still working
context("Cluster Management Test")
test_that("Async cluster scenario test", {
  testthat::skip_on_travis()
  source("utility.R")

  settings <- getSettings()

  # set your credentials
  doAzureParallel::setCredentials(settings$credentials)

  cluster <-
    doAzureParallel::makeCluster(settings$clusterConfig, wait = FALSE)

  cluster <- getCluster(cluster$poolId)
  getClusterList()
  filter <- list()
  filter$state <- c("active", "deleting")

  getClusterList(filter)

  doAzureParallel::stopCluster(cluster)
})
