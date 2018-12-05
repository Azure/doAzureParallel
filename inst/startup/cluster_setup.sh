#!/bin/bash

# Entry point for the start task. It will install the docker runtime and pull down the required docker images
# Usage:
# cluster_setup.sh
set -e

apt-mark hold $(uname -r)
apt-get update
apt-get -y install python-dev python-pip
pip install psutil python-dateutil applicationinsights==0.11.3
wget --no-cache https://raw.githubusercontent.com/Azure/batch-insights/master/nodestats.py
python --version
python nodestats.py > node-stats.log 2>&1 &
apt-mark unhold $(uname -r)
