# Run this test for users to make sure the bioconductor package
# install feature of doAzureParallel are still working
context("bioconductor package install scenario test")
test_that("bioconductor package install Test", {
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
  bioconductor <- c('limma', 'curl', 'Rcpp')
  res <-
    foreach::foreach(
      i = 1:4,
      .packages = c('httr'),
      bioconductor = bioconductor,
      .options.azure = opt
    ) %dopar% {
      "Rcpp" %in% rownames(installed.packages())
    }

  doAzureParallel::stopCluster(cluster)

  # verify the job result is correct
  testthat::expect_equal(length(res),
                         4)

  testthat::expect_equal(res,
                         list(TRUE, TRUE, TRUE, TRUE))
})
