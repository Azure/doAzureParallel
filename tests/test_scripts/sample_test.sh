#!/bin/bash
wd = "$1"
file = "$2"

sudo R \
-e "Sys.setenv(BATCH_ACCOUNT_NAME = '$BATCH_ACCOUNT_NAME')" \
-e "Sys.setenv(BATCH_ACCOUNT_KEY = '$BATCH_ACCOUNT_KEY')" \
-e "Sys.setenv(BATCH_ACCOUNT_URL = '$BATCH_ACCOUNT_URL')" \
-e "Sys.setenv(STORAGE_ACCOUNT_NAME = '$STORAGE_ACCOUNT_NAME')" \
-e "Sys.setenv(STORAGE_ACCOUNT_KEY = '$STORAGE_ACCOUNT_KEY')" \
-e "getwd();" \
-e "setwd('$wd')"
-e "source('$file')"
