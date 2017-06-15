context("generate cluster config")

test_that("creating a credentials file", {
  skip_on_travis()

  configFileName <- "testthat.json"

  generateCredentialsConfig(configFileName)
  config <- jsonlite::fromJSON(configFileName)

  expect_false(is.null(config$batchAccount$name))
  expect_false(is.null(config$batchAccount$key))
  expect_false(is.null(config$batchAccount$url))

  file.remove(configFileName)
})

test_that("creating a cluster file", {
  skip_on_travis()

  configFileName <- "testthat.json"

  generateClusterConfig(configFileName)
  config <- jsonlite::fromJSON(configFileName)

  expect_false(is.null(config$batchAccount$pool))
  expect_false(is.null(config$settings))
  expect_false(is.null(config$storageAccount))
  expect_equal(config$batchAccount$pool$name, "myPoolName")

  file.remove(configFileName)
})

test_that("End to end integration simple sum foreach", {
  skip_on_travis()

  configFileName <- "testthat.json"

  batchAccountName <- Sys.getenv("AZ_BATCH_ACCOUNT_NAME")
  batchAccountKey <- Sys.getenv("AZ_BATCH_ACCOUNT_KEY")
  batchAccountUrl <- Sys.getenv("AZ_BATCH_ACCOUNT_URL")

  storageAccountName <- Sys.getenv("AZ_STORAGE_ACCOUNT_NAME")
  storageAccountKey <- Sys.getenv("AZ_STORAGE_ACCOUNT_KEY")

  generateCredentialsConfig(configFileName,
                        batchAccount = batchAccountName,
                        batchKey = batchAccountKey,
                        batchUrl = batchAccountUrl,
                        storageAccount = storageAccountName,
                        storageKey = storageAccountKey)

  cluster <- makeCluster(configFileName)

  registerDoAzureParallel(cluster)

  jobId <- "job001"
  results <- foreach(i = 1:3, .options.azure = list(job = jobId)) %dopar% sum(i, 1)

  for(i in 1:length(results)){
    expect_equal(results[[i]], i + 1)
  }

  deleteContainer(jobId)
  file.remove(configFileName)
  file.remove("temp.rds")
})

test_that("End to end integration job with wait", {
  skip_on_travis()

  configFileName <- "testthat.json"

  batchAccountName <- Sys.getenv("AZ_BATCH_ACCOUNT_NAME")
  batchAccountKey <- Sys.getenv("AZ_BATCH_ACCOUNT_KEY")
  batchAccountUrl <- Sys.getenv("AZ_BATCH_ACCOUNT_URL")

  storageAccountName <- Sys.getenv("AZ_STORAGE_ACCOUNT_NAME")
  storageAccountKey <- Sys.getenv("AZ_STORAGE_ACCOUNT_KEY")

  generateCredentialsConfig(configFileName,
                        batchAccount = batchAccountName,
                        batchKey = batchAccountKey,
                        batchUrl = batchAccountUrl,
                        storageAccount = storageAccountName,
                        storageKey = storageAccountKey)

  cluster <- makeCluster(configFileName)

  registerDoAzureParallel(cluster)

  jobId <- foreach(i = 1:3, .options.azure = list(job = "testjob", wait = FALSE)) %dopar% {
    sum(i, 10)
  }

  waitForTasksToComplete(jobId, 60 * 60 * 24, tasks = 4)

  listTasksResponse <- listTask(jobId)
  # 3 tasks + merge task
  expect_equal(length(listTasksResponse$value), 4)

  getJobResponse <- getJob(jobId)
  expect_equal(getJobResponse$id, jobId)
  expect_equal(getJobResponse$onAllTasksComplete, "terminatejob")

  results <- getJobResult(jobId)
  expect_equal(length(results), 3)

  for(i in 1:length(results)){
    expect_equal(results[[i]], i + 10)
  }

  deleteContainer(jobId)
  deleteJob(jobId)
  file.remove(configFileName)
  file.remove("temp.rds")
})

test_that("End to end integration job with chunks", {
  skip_on_travis()

  configFileName <- "testthat.json"

  batchAccountName <- Sys.getenv("AZ_BATCH_ACCOUNT_NAME")
  batchAccountKey <- Sys.getenv("AZ_BATCH_ACCOUNT_KEY")
  batchAccountUrl <- Sys.getenv("AZ_BATCH_ACCOUNT_URL")

  storageAccountName <- Sys.getenv("AZ_STORAGE_ACCOUNT_NAME")
  storageAccountKey <- Sys.getenv("AZ_STORAGE_ACCOUNT_KEY")

  generateCredentialsConfig(configFileName,
                        batchAccount = batchAccountName,
                        batchKey = batchAccountKey,
                        batchUrl = batchAccountUrl,
                        storageAccount = storageAccountName,
                        storageKey = storageAccountKey)

  setCredentials("testthat.json")

  cluster <- makeCluster("cluster.json")

  registerDoAzureParallel(cluster)

  jobId <- foreach(i = 1:10, .options.azure = list(job = "chunkjob", wait = FALSE, chunkSize = 3)) %dopar% {
    c(sum(1, i), sum(2, i), sum(3, i))
  }

  waitForTasksToComplete(jobId, 60 * 60 * 24, tasks = 5)

  results <- getJobResult(jobId)
  expect_equal(length(results), 10)

  for(i in 1:length(results)){
    expect_equal(results[[i]][1], i + 1)
    expect_equal(results[[i]][2], i + 2)
    expect_equal(results[[i]][3], i + 3)
  }

  deleteContainer(jobId)
  deleteJob(jobId)
  file.remove(configFileName)
  file.remove("temp.rds")
})
