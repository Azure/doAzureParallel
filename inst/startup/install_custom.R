args <- commandArgs(trailingOnly = TRUE)

pattern <- NULL
if (length(args) > 1) {
  if (!is.null(args[2])) {
    pattern <- args[2]
  }
}

packages <- list.files(args[1], full.names = TRUE, pattern = pattern)
for (i in 1:length(packages)) {
  print(packages[i])
  install.packages(packages[i],
                   lib = paste0(Sys.getenv("AZ_BATCH_NODE_SHARED_DIR"),
                                "/R/packages"),
                   dependencies = TRUE,
                   type = "source")
}
