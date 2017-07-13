context("linux wrap commands")

test_that("single command on command line", {
  commandLine <- linuxWrapCommands("ls")

  expect_equal(commandLine, "/bin/bash -c \"set -e; set -o pipefail; ls; wait\"")
})

test_that("multiple commands on command line", {
  commands <- c("ls", "echo \"hello\"", "cp origfile newfile")
  commandLine <- linuxWrapCommands(commands)
  cat(commandLine)
  expect_equal(commandLine, "/bin/bash -c \"set -e; set -o pipefail; ls; echo \"hello\"; cp origfile newfile; wait\"")
})
