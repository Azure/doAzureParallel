context("creating output files")

test_that("createOutputFile_FileProperties_Success", {
  fakeUrl <-
    "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12"

  outputFile <- createOutputFile("result.txt", fakeUrl)

  expect_equal(outputFile$filePattern, "result.txt")
  expect_equal(outputFile$uploadOptions$uploadCondition,
               "taskCompletion")
})


test_that("createOutputFile_NullValue_Success", {
  fakeUrl <-
    "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12"

  outputFile <- createOutputFile("result.txt", fakeUrl)

  expect_null(outputFile$destination$container$path)
  expect_equal(
    outputFile$destination$container$containerUrl,
    "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12"
  )
})

test_that("createOutputFile_MultipleVirtualDirectories_Success", {
  fakeUrl <-
    "https://accountname.blob.core.windows.net/outputs/foo/baz/bar?se=2017-07-31&sr=c&st=2017-07-12"

  outputFile <- createOutputFile("test-*.txt", fakeUrl)

  expect_equal(outputFile$destination$container$path, "foo/baz/bar")
  expect_equal(
    outputFile$destination$container$containerUrl,
    "https://accountname.blob.core.windows.net/outputs?se=2017-07-31&sr=c&st=2017-07-12"
  )
})
