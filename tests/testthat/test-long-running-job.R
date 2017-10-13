# Run this test for users to make sure the long running job feature
# of doAzureParallel are still working
context("long running job scenario test")
test_that("Long Running Job Test", {
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  #options <- list(wait = FALSE, job = 'myjob')
  options <- list(wait = FALSE)
  '%dopar%' <- foreach::'%dopar%'
  jobId <-
    foreach::foreach(
      i = 1:4,
      .packages = c('httr'),
      .errorhandling = "stop",
      .options.azure = options
    ) %dopar% {
      mean(1:3)
    }

  job <- getJob(jobId)

  # get active/running job list
  filter <- filter <- list()
  filter$state <- c("active", "completed")
  getJobList(filter)

  # get job list for all jobs
  getJobList()

  # wait 2 minutes for job to finish
  Sys.sleep(120)

  # get job result
  jobResult <- getJobResult(jobId)

  doAzureParallel::stopCluster(cluster)

  # verify the job result is correct
  testthat::expect_equal(length(jobResult),
                         4)

  testthat::expect_equal(jobResult,
                         list(2, 2, 2, 2))

  # delete the job
  rAzureBatch::deleteJob(jobId)
})
