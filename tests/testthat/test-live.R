# Run this test for users to make sure the core features
# of doAzureParallel are still working
context("live scenario test")
test_that("Basic scenario test", {
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
    foreach::foreach(i = 1:4) %dopar% {
      i
    }

  res

  testthat::expect_equal(length(res), 4)
  testthat::expect_equal(res, list(2, 2, 2, 2))
})

# Run this test for users to make sure the core features
# of doAzureParallel are still working
context("basic code test")
test_that("Basic Test 2", {
  testthat::skip_on_travis()

  credentials <- list(
    "sharedKey" = list(
      "batchAccount" = list(
        "name" = Sys.getenv("BATCH_ACCOUNT_NAME"),
        "key" = Sys.getenv("BATCH_ACCOUNT_KEY"),
        "url" = Sys.getenv("BATCH_ACCOUNT_URL")
      ),
      "storageAccount" = list(
        "name" = Sys.getenv("STORAGE_ACCOUNT_NAME"),
        "key" = Sys.getenv("STORAGE_ACCOUNT_KEY"),
        "endpointSuffix" = "core.windows.net"
      )
    ),
    "githubAuthenticationToken" = "",
    "dockerAuthentication" = list("username" = "",
                                  "password" = "",
                                  "registry" = "")
  )

  # set your credentials
  doAzureParallel::setCredentials(credentials)

  clusterConfig <- list(
    "name" = "test-pool",
    "vmSize" = "Standard_D2_v2",
    "maxTasksPerNode" = 1,
    "poolSize" = list(
      "dedicatedNodes" = list(
        "min" = 0,
        "max" = 0
      ),
      "lowPriorityNodes" = list(
        "min" = 1,
        "max" = 1
      ),
      "autoscaleFormula" = "QUEUE"
    ),
    "containerImage" = "rocker/tidyverse:latest",
    "rPackages" = list(
      "cran" = list(),
      "github" = list(),
      "bioconductor" = list()
    ),
    "commandLine" = list()
  )

  cluster <- doAzureParallel::makeCluster(clusterConfig)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4) %dopar% {
      i
    }

  res

  testthat::expect_equal(length(res), 4)
  testthat::expect_equal(unname(res), list(1, 2, 3, 4))
})


test_that("Chunksize Test", {
  testthat::skip("Live test")
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
    foreach::foreach(i = 1:10,
                     .options.azure = list(chunkSize = 3)) %dopar% {
      i
    }

  testthat::expect_equal(length(res),
                         10)

  for (i in 1:10) {
    testthat::expect_equal(res[[i]],
                           i)
  }
})
