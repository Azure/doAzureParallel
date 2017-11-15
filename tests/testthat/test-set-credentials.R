# Run this test for users to make sure the set credentials from json or R object features
# of doAzureParallel are still working
context("set credentials from R object scenario test")
test_that("set credentials/cluster config programmatically scenario test", {
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
  doAzureParallel::setCredentials(credentials)

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
      "cran" = list(),
      "github" = list(),
      "bioconductor" = list(),
      "githubAuthenticationToken" = ""
    ),
    "commandLine" = list()
  )

  source("R\\validationUtilities.R") #import validation R6 object
  source("R\\autoscale.R") #import autoscaleFormula
  validation$isValidClusterConfig(clusterConfig)
})

test_that("set credentials/cluster config from Json file scenario test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()

  credentialsFileName <- "credentials.json"
  clusterFileName <- "test_cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)

  source("R\\validationUtilities.R") #import validation R6 object
  source("R\\autoscale.R") #import autoscaleFormula
  validation$isValidClusterConfig(clusterFileName)
})
