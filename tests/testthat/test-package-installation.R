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

  libPathCommand <-
    paste(
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)'",
      "-e \'.libPaths( c( \\\"/mnt/batch/tasks/shared/R/packages\\\", .libPaths()));"
    )

  expected <-
    c(
      paste(libPathCommand, "install.packages(args)\' hts lubridate tidyr")
    )

  expect_equal(poolInstallation, expected)
})

test_that("successfully create github pool package command line", {
  poolInstallation <-
    getPoolPackageInstallationCommand("github", c("Azure/doAzureParallel", "Azure/rAzureBatch"))
  expect_equal(length(poolInstallation), 2)

  libPathCommand <-
    paste(
      "Rscript -e \'args <- commandArgs(TRUE)\' -e 'options(warn=2)'",
      "-e \'.libPaths( c( \\\"/mnt/batch/tasks/shared/R/packages\\\", .libPaths()));"
    )

  expected <-
    c(
      paste(libPathCommand, "devtools::install_github(args)\' Azure/doAzureParallel Azure/rAzureBatch")
    )

  expect_equal(poolInstallation, expected)
})

test_that("successfully create bioconductor pool package command line", {
  poolInstallation <-
    getPoolPackageInstallationCommand("bioconductor", c("IRanges", "a4"))
  cat(poolInstallation)

  expected <-
    c(
      paste("Rscript /mnt/batch/tasks/startup/wd/install_bioconductor.R",
             "IRanges",
            "a4",
            sep = " ")
    )

  expect_equal(poolInstallation, expected)
})
