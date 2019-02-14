context("Unit Tests")
if (requireNamespace("nycflights13", quietly = TRUE)) {
  test_that("hasDataSet Test - Contains Data", {
    byCarrierList <- split(nycflights13::flights, nycflights13::flights$carrier)
    it <- iterators::iter(byCarrierList)
    argsList <- as.list(it)

    hasDataSet <- hasDataSet(argsList)

    expect_equal(hasDataSet, TRUE)
  })

  test_that("hasDataSet Test - Contains no Data Set", {
    args <- seq(1:10)
    it <- iterators::iter(args)
    argsList <- as.list(it)

    hasDataSet <- hasDataSet(argsList)

    expect_equal(hasDataSet, FALSE)
  })
}
