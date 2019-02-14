# Run this test for users to make sure the autodeletejob feature
# of doAzureParallel is still working
context("auto delete job scenario test")
test_that("auto delete job as foreach option test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  # use autoDeleteJob flag to keep the job and its result
  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:10,
                     .options.azure = list(autoDeleteJob = FALSE)) %dopar% {
      i
    }

  testthat::expect_equal(length(res),
                         10)

  for (i in 1:10) {
    testthat::expect_equal(res[[i]],
                           i)
  }

  # find the job id from the output of above command and call
  # deleteJob(jobId) when you no longer need the job and its result
})

test_that("auto delete job as global setting test", {
  testthat::skip("Live test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  # set autoDeleteJob flag to FALSE to keep the job and its result
  setAutoDeleteJob(FALSE)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:10) %dopar% {
                       i
                     }

  testthat::expect_equal(length(res),
                         10)

  for (i in 1:10) {
    testthat::expect_equal(res[[i]],
                           i)
  }

  # find the job id from the output of above command and call
  # deleteJob(jobId) when you no longer need the job and its result
})
