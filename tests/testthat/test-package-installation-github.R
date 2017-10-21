# Run this test for users to make sure the github package
# install feature of doAzureParallel are still working
context("github package install scenario test")
test_that("github package install Test", {
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  opt <- list(wait = TRUE)
  '%dopar%' <- foreach::'%dopar%'
  github <- c('azure/rAzureBatch', 'azure/doAzureParallel')
  res <-
    foreach::foreach(
      i = 1:4,
      .packages = c('httr'),
      github = github,
      .options.azure = opt
    ) %dopar% {
      "doAzureParallel" %in% rownames(installed.packages())
    }

  doAzureParallel::stopCluster(cluster)

  # verify the job result is correct
  testthat::expect_equal(length(res),
                         4)

  testthat::expect_equal(res,
                         list(TRUE, TRUE, TRUE, TRUE))
})
