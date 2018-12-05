#!/usr/bin/env bash
refresh_package_index() {
    set +e
    local retries=30
    while [ $retries -gt 0 ]; do
        apt-get update
        if [ $? -eq 0 ]; then
            break
        fi
        let retries=retries-1
        if [ $retries -eq 0 ]; then
            echo "ERROR: Could not update package index"
            exit 101
        fi
        sleep 1
    done
    set -e
}

install_package() {
    set +e
    local package=$1
    local retries=30
    while [ $retries -gt 0 ]; do
        apt-get install -y -q -o Dpkg::Options::="--force-confnew" --no-install-recommends $package
        if [ $? -eq 0 ]; then
            break
        fi
        let retries=retries-1
        if [ $retries -eq 0 ]; then
            echo "ERROR: Could not install packages: $package"
            exit 101
        else
            # make sure apt-get update to latest index
            apt-get update
        fi
        sleep 1
    done
    set -e
}

set -e

# hold kernel update to preserve the nvidia driver, bootstrap will unhold the kernel if run on non-nvidia VM
apt-mark hold $(uname -r)
refresh_package_index
install_package python-dev python-pip
install_package python-pip
pip install psutil python-dateutil applicationinsights==0.11.3
wget --no-cache https://raw.githubusercontent.com/Azure/batch-insights/master/nodestats.py
python --version
python nodestats.py > node-stats.log 2>&1 &
apt-mark unhold $(uname -r)
