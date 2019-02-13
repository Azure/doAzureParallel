#!/bin/bash

sudo R \
  -e "getwd();" \
  -e "devtools::install();" \
  -e "devtools::build();" \
  -e "devtools::load_all();" \
  -e "res <- testthat::test_dir('../testthat/unit_tests', reporter='summary');" \
  -e "df <- as.data.frame(res);" \
  -e "if(sum(df[['failed']]) > 0 || any(df[['error']])) { q(status=1) }"
