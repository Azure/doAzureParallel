#!/bin/bash

sudo R \
  -e "Sys.setenv(BATCH_ACCOUNT_NAME = '$BATCH_ACCOUNT_NAME')" \
  -e "Sys.setenv(BATCH_ACCOUNT_KEY = '$BATCH_ACCOUNT_KEY')" \
  -e "Sys.setenv(BATCH_ACCOUNT_URL = '$BATCH_ACCOUNT_URL')" \
  -e "Sys.setenv(STORAGE_ACCOUNT_NAME = '$STORAGE_ACCOUNT_NAME')" \
  -e "Sys.setenv(STORAGE_ACCOUNT_KEY = '$STORAGE_ACCOUNT_KEY')" \
  -e "getwd();" \
  -e "install.packages(c('devtools', 'remotes', 'testthat', 'roxygen2'));" \
  -e "devtools::install();" \
  -e "devtools::build();" \
  -e "res <- devtools::test(reporter='summary');" \
  -e "df <- as.data.frame(res);" \
  -e "if(sum(df[['failed']]) > 0 || any(df[['error']])) { q(status=1) }"
