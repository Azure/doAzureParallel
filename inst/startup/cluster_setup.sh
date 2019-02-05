#!/bin/bash
wget https://github.com/Azure/batch-insights/releases/download/go-beta.1/batch-insight
chmod +x batch-insights
./batch-insights > node-stats.log &
