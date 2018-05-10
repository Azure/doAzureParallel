args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 2) {
  if (is.null(args[2])) {
    pattern = NULL
  }
  else {
    pattern = args[2]
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
