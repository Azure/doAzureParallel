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

if (length(args) < 1) {
  stop("Given arguments were not passed,",
       "install_custom.R file_share_directory pattern")
}

directory <- args[1]

devtoolsPackage <- "devtools"
if (!require(devtoolsPackage, character.only = TRUE)) {
  install.packages(devtoolsPackage)
  require(devtoolsPackage, character.only = TRUE)
}

packageDirs <- list.files(
  path = directory,
  pattern = pattern,
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
