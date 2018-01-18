if (requireNamespace("nycflights13", quietly = TRUE)) {
  context("hasDataSet function")

  test_that("Arguments contains data set", {
    byCarrierList <- split(nycflights13::flights, nycflights13::flights$carrier)
    it <- iterators::iter(byCarrierList)
    argsList <- as.list(it)

    hasDataSet <- hasDataSet(argsList)

    expect_equal(hasDataSet, TRUE)
  })

  test_that("Arguments does not contain data set", {
    args <- seq(1:10)
    it <- iterators::iter(args)
    argsList <- as.list(it)

    hasDataSet <- hasDataSet(argsList)

    expect_equal(hasDataSet, FALSE)
  })

}
