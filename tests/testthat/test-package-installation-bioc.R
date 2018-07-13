# Run this test for users to make sure the bioconductor package
# install feature of doAzureParallel are still working
context("bioconductor package install scenario test")
test_that("job single bioconductor package install Test", {
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

  opt <- list(wait = TRUE)
  '%dopar%' <- foreach::'%dopar%'
  bioconductor <- 'AMOUNTAIN'
  res <-
    foreach::foreach(
      i = 1:4,
      bioconductor = bioconductor,
      .options.azure = opt
    ) %dopar% {
      "AMOUNTAIN" %in% rownames(installed.packages())
    }

  # verify the job result is correct
  testthat::expect_equal(length(res),
                         4)

  testthat::expect_equal(res,
                         list(TRUE, TRUE, TRUE, TRUE))
})

test_that("job multiple bioconductor package install Test", {
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

  opt <- list(wait = TRUE)
  '%dopar%' <- foreach::'%dopar%'
  bioconductor <- c('AgiMicroRna', 'biobroom', 'BiocParallel')
  res <-
    foreach::foreach(i = 1:4,
                     bioconductor = bioconductor,
                     .options.azure = opt) %dopar% {
      c("AgiMicroRna" %in% rownames(installed.packages()),
      "biobroom" %in% rownames(installed.packages()),
      "BiocParallel" %in% rownames(installed.packages()))
    }

  # verify the job result is correct
  testthat::expect_equal(length(res),
                         4)

  testthat::expect_equal(res,
                         list(
                           c(TRUE, TRUE, TRUE),
                           c(TRUE, TRUE, TRUE),
                           c(TRUE, TRUE, TRUE),
                           c(TRUE, TRUE, TRUE)))
})

test_that("pool multiple bioconductor package install Test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  config <- jsonlite::fromJSON(clusterFileName)
  config$name <- "bioconductorPackages1"
  config$poolSize$dedicatedNodes$min <- 0
  config$poolSize$dedicatedNodes$max <- 0
  config$poolSize$lowPriorityNodes$min <- 1
  config$poolSize$lowPriorityNodes$max <- 1
  config$rPackages$bioconductor <- c('AgiMicroRna', 'biobroom', 'BiocParallel')
  configJson <- jsonlite::toJSON(config, auto_unbox = TRUE, pretty = TRUE)
  write(configJson, file = paste0(getwd(), "/", clusterFileName))

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:2) %dopar% {
      c("AgiMicroRna" %in% rownames(installed.packages()),
        "biobroom" %in% rownames(installed.packages()),
        "BiocParallel" %in% rownames(installed.packages()))
    }

  # verify the job result is correct
  testthat::expect_equal(length(res),
                         2)

  testthat::expect_equal(res,
                         list(
                           c(TRUE, TRUE, TRUE),
                           c(TRUE, TRUE, TRUE)))
})
