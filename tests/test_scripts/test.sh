#!/bin/bash
sudo echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" | sudo tee -a /etc/apt/sources.list

gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
gpg -a --export E084DAB9 | sudo apt-key add -

sudo apt-get update
sudo apt-get install -y r-base r-base-dev r-cran-xml libcurl4-openssl-dev
sudo apt-get install -y libssl-dev libxml2-dev openjdk-7-* libgdal-dev libproj-dev libgsl-dev xml2

Rscript
  -e "getwd();"
  -e "install.packages('devtools');"
  -e "devtools::install();"
  -e "devtools::build();"
  -e "devtools::test();"

