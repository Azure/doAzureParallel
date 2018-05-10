args <- commandArgs(trailingOnly = TRUE)

packages <- list.files(args[1], full.names = TRUE)
for (i in 1:length(packages)) {
  print(packages[i])
  install.packages(packages[i],
                   lib = paste0(Sys.getenv("AZ_BATCH_NODE_SHARED_DIR"),
                                "/R/packages"),
                   type = "source")
}
