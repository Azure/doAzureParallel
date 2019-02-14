context("linux wrap commands")

test_that("linuxWrapCommands_SingleCommand_Success", {
  commandLine <- linuxWrapCommands("ls")

  expect_equal(commandLine, "/bin/bash -c \"set -e; set -o pipefail; ls; wait\"")
})

test_that("linuxWrapCommands_MultipleCommand_Success", {
  commands <- c("ls", "echo \"hello\"", "cp origfile newfile")
  commandLine <- linuxWrapCommands(commands)

  expect_equal(commandLine, "/bin/bash -c \"set -e; set -o pipefail; ls; echo \"hello\"; cp origfile newfile; wait\"")
})
