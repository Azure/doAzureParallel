#!/bin/bash
# Entry point for the start task.
set +e
local retries=30
while [ $retries -gt 0]; do
  apt-get update
  if [$? -eq 0]; then
    break
  fi
  let retries=retries-1
  if [ $retries -eq 0]; then
    echo "ERROR: Could not update apt"
    exit 101
  fi
  sleep 5
done
echo "COMPLETED: apt updated"
set -e
  
