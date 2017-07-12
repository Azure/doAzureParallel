context("creating output files")

test_that("verify output file properties", {
  fakeUrl <- "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12"
  
  outputFile <- createOutputFile("result.txt", fakeUrl)
  
  expect_equal(outputFile$filePattern, "result.txt")
  expect_equal(outputFile$uploadOptions$uploadCondition, "taskCompletion")
})


test_that("create output file with null path", {
  fakeUrl <- "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12"
  
  outputFile <- createOutputFile("result.txt", fakeUrl)

  expect_null(outputFile$destination$container$path)
  expect_equal(outputFile$destination$container$containerUrl, "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12")
})

test_that("create output file with multiple virtual directories", {
  fakeUrl <- "https://accountname.blob.core.windows.net/outputs/foo/baz/bar?se=2017-07-31&sr=c&st=2017-07-12"
    
  outputFile <- createOutputFile("test-*.txt", fakeUrl)
  
  expect_equal(outputFile$destination$container$path, "foo/baz/bar")
  expect_equal(outputFile$destination$container$containerUrl, "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12")
})