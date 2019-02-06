#!/bin/bash
sudo echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" | sudo tee -a /etc/apt/sources.list

gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -

sudo apt-get update
sudo apt-get install -y r-base r-base-dev libcurl4-openssl-dev
sudo apt-get install -y libssl-dev libxml2-dev libgdal-dev libproj-dev libgsl-dev

sudo R \
  -e "getwd();" \
  -e "install.packages(c('devtools', 'remotes', 'testthat', 'roxygen2'));" \
  -e "devtools::install();" \
  -e "devtools::build();"
