args <- commandArgs(trailingOnly = TRUE)

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

packages <- list.files(args[1], full.names = TRUE, pattern = pattern)
for (i in 1:length(packages)) {
  devtools::install(packages[i],
                    lib = paste0(Sys.getenv("AZ_BATCH_NODE_SHARED_DIR"),
                                 "/R/packages"))
  # install.packages(packages[i],
  #                  lib = paste0(Sys.getenv("AZ_BATCH_NODE_SHARED_DIR"),
  #                               "/R/packages"),
  #                  dependencies = TRUE,
  #                  repos = "https://cloud.r-project.org",
  #                  type = "source")
}
