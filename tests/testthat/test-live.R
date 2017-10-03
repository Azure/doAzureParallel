# Run this test for users to make sure the core features
# of doAzureParallel are still working
context("live scenario test")
test_that("Scenario Test", {
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "test_cluster.json"

  #doAzureParallel::generateCredentialsConfig(credentialsFileName)
  #doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <- doAzureParallel::makeCluster(clusterFileName)
  doAzureParallel::registerDoAzureParallel(cluster)

  #cluster
  
  '%dopar%' <- foreach::'%dopar%'
  res <- foreach::foreach(i = 1:4, .packages = c("stringr")) %dopar% {
    library(xml2)
    library(rAzureBatch)
    mean(1:3)
  }

  res
  
  # doAzureParallel::stopCluster(cluster)
  # 
  # testthat::expect_equal(length(res),
  #                        4)
  # 
  # testthat::expect_equal(res,
  #                        list(2, 2, 2, 2))
})''

dockerOptions <- "-e V=$V "
cleanCommands <- c("rbase:3.4.1 R --version", "alfpark/blobxfer blobxfer --download")
actions <- paste(paste0("docker run ", dockerOptions), cleanCommands, sep="")
commandLine <-
  sprintf("/bin/bash -c \"set -e; set -o pipefail; %s wait\"",
          paste0(paste(
            actions, sep = " ", collapse = "; "
          ), ";"))

commandLine
