args <- commandArgs(trailingOnly = TRUE)

sharedPackageDirectory <- file.path(
  Sys.getenv("AZ_BATCH_NODE_SHARED_DIR"),
  "R",
  "packages")

tempDir <- file.path(
  Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"),
  "tmp")

.libPaths(c(sharedPackageDirectory, .libPaths()))

pattern <- NULL
if (length(args) > 1) {
  if (!is.null(args[2])) {
    pattern <- args[2]
  }
}

devtoolsPackage <- "devtools"
if (!require(devtoolsPackage, character.only = TRUE)) {
  install.packages(devtoolsPackage)
  require(devtoolsPackage, character.only = TRUE)
}

packageDirs <- list.files(
  path = tempDir,
  full.names = TRUE,
  recursive = FALSE)

for (i in 1:length(packageDirs)) {
  print("Package Directories")
  print(packageDirs[i])

  devtools::install(packageDirs[i],
                    args = c(
                      paste0(
                        "--library=",
                        "'",
                        sharedPackageDirectory,
                        "'")))

  print("Package Directories Completed")
}

unlink(
  tempDir,
  recursive = TRUE)
