context("Integration Test")

# Run this test for users to make sure the core features
# of doAzureParallel are still working
test_that("simple foreach 1 to 4", {
  testthat::skip_on_travis()
  source("utility.R")
  settings <- getSettings()
  doAzureParallel::registerDoAzureParallel(cluster)

  '%dopar%' <- foreach::'%dopar%'
  res <-
    foreach::foreach(i = 1:4) %dopar% {
      i
    }

  res <- unname(res)

  testthat::expect_equal(length(res), 4)
  testthat::expect_equal(res, list(1, 2, 3, 4))
})
