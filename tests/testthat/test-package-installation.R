context("package installation")
test_that("successfully create cran job package command line", {
  jobInstallation <-
    getJobPackageInstallationCommand("cran", c("hts", "lubridate", "tidyr", "dplyr"))
  expect_equal(
    jobInstallation,
    "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_cran.R hts lubridate tidyr dplyr"
  )
})

test_that("successfully create github job package command line", {
  jobInstallation <-
    getJobPackageInstallationCommand("github", c("Azure/doAzureParallel", "Azure/rAzureBatch"))
  expect_equal(
    jobInstallation,
    "Rscript $AZ_BATCH_JOB_PREP_WORKING_DIR/install_github.R Azure/doAzureParallel Azure/rAzureBatch"
  )
})

test_that("successfully create cran pool package command line", {
  poolInstallation <-
    getPoolPackageInstallationCommand("cran", c("hts", "lubridate", "tidyr"))
  expect_equal(length(poolInstallation), 3)
  expected <-
    c(
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)' -e \'install.packages(args[1])\' hts",
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)' -e \'install.packages(args[1])\' lubridate",
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)' -e \'install.packages(args[1])\' tidyr"
    )

  expect_equal(poolInstallation, expected)
})

test_that("successfully create github pool package command line", {
  poolInstallation <-
    getPoolPackageInstallationCommand("github", c("Azure/doAzureParallel", "Azure/rAzureBatch"))
  expect_equal(length(poolInstallation), 2)

  expected <-
    c(
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)' -e \'devtools::install_github(args[1])\' Azure/doAzureParallel",
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)' -e \'devtools::install_github(args[1])\' Azure/rAzureBatch"
    )

  expect_equal(poolInstallation, expected)
})
