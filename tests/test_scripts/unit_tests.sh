#!/bin/bash

sudo R \
  -e "getwd();" \
  -e "devtools::install();" \
  -e "devtools::build();" \
  -e "res <- devtools::test(reporter='summary');" \
  -e "df <- as.data.frame(res);" \
  -e "if(sum(df[['failed']]) > 0 || any(df[['error']])) { q(status=1) }"
