#!/bin/bash

apt-get -y update
apt-get -y install libcurl4-openssl-dev
apt-get -y install libssl-dev

mkdir -p /mnt/batch/tasks/shared/R/packages