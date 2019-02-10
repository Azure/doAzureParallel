context("Cluster Management Test")
test_that("Get Cluster List / Get Cluster test", {
  testthat::skip_on_travis()
  source("utility.R")

  settings <- getSettings()

  cluster <-
    doAzureParallel::makeCluster(settings$clusterConfig, wait = FALSE)

  cluster <- getCluster(cluster$poolId)
  clusterList <- getClusterList()
  filter <- list()
  filter$state <- c("active", "deleting")

  testthat::expect_true('test-pool' %in% clusterList$Id)

  clusterList <- getClusterList(filter)

  for (i in 1:length(clusterList$State)) {
    testthat::expect_true(clusterList$State[i] == 'active' ||
                          clusterList$State[i] == 'deleting')
  }
})
