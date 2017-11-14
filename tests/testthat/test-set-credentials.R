# Run this test for users to make sure the set credentials from R object features
# of doAzureParallel are still working
context("set credentials from R object scenario test")
test_that("Basic scenario test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  
  # set your credentials
  credentials <- list(
    "batchAccount" = list(
      "name" = "batchaccountname",
      "key" = "batchaccountkey",
      "url" = "https://batchaccountname.region.batch.azure.com"
    ),
    "storageAccount" = list("name" = "storageaccountname",
                            "key" = "storageaccountkey")
  )
  doAzureParallel::setCredentialsObject(credentials)
  
  # set cluster config
  clusterConfig <- list(
    "name" = "clustername",
    "vmSize" = "Standard_D2_v2",
    "maxTasksPerNode" = 1,
    "poolSize" = list(
      "dedicatedNodes" = list("min" = 0,
                              "max" = 0),
      "lowPriorityNodes" = list("min" = 1,
                                "max" = 1),
      "autoscaleFormula" = "QUEUE"
    ),
    "containerImage" = "rocker/tidyverse:latest",
    "rPackages" = list(
      "cran" = c(),
      "github" = c(),
      "bioconductor" = c(),
      "githubAuthenticationToken" = c()
    ),
    "commandLine" = c()
  )
  
  cluster <- doAzureParallel::makeClusterObject(clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)
  
  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4) %dopar% {
      mean(1:3)
    }
  
  res
  
  testthat::expect_equal(length(res), 4)
  testthat::expect_equal(res, list(2, 2, 2, 2))
})
