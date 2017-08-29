# FAQ

## General

### Is doAzureParallel available on CRAN?
No. At the moment doAzureParallel is only being distributed via GitHub.

### Which version of R does doAzureParallel use?
By default, we use Microsoft R Open 3.3.

### Does doAzureParallel support a custom version of R?
No. We are looking into support for different versions of R as well as custom version of R but that is not supported today.

### How much does doAzureParallel cost?
doAzureParallel is built on top of the Azure Batch service. You are billed by the minute for each node that is assigned to your cluster. You can find more infomration on Azure Batch pricing [here](https://azure.microsoft.com/en-us/pricing/details/batch/).

### Does doAzureParallel support custom pacakge installations?
Yes. The 'command' line feature in the cluster configuration enables running custom commands on each node in the cluster before it is ready to do work. Leverage this mechanism to do any custom installations such as installing custom software or mounting network drives.

### Does doAzureParallel work with Windows-specific packages?
No. doAzureParallel is built on top of the Linux CentOS distribution and will not work with Windows-specific packages.

## Debugging and Troubleshooting

### After creating my cluster, my nodes go to a 'startTaskFailed' state. Why?
The most common case for this is that there was an issue with package installation or the custom script failed to run. To troubleshoot this you can simply download the output logs from the node.

```r
doAzureParallel::getNodeFile('tvm-123', 'stdout.txt') # snatdard log file
doAzureParallel::getNodeFile('tvm-123', 'stderr.txt') # standard error file
```

### My job never starts running. How can I troubleshoot this issue?
This is often caused by the node not being in a good state. Take a look at the state of the nodes in the cluster to see if any of there are and nodes in an error or failed state.

### Why do some packages fail with the following error?
```sh
ERROR: compilation failed for package '__PACKAGE__'
* removing '/usr/lib64/microsoft-r/3.3/lib64/R/library/__PACKAGE__'
```

This issue is due to certain compiler flags not available in the default version of R used by doAzureParallel. In order to get around this issue you can add the following commands to the command line in the cluster configuration to make sure R has the right compiler flags set.

```json
"commandLine": [
    "r_conf=/usr/lib64/microsoft-r/3.3/lib64/R/etc/Makeconf",
    "sed -i 's/CXX1X = /CXX1X = gcc/g' $r_conf",
    "sed -i 's/CXX1XFLAGS = /CXX1XFLAGS = -fpic/g' $r_conf",
    "sed -i 's/CXX1XSTD =/CXX1XSTD = -std=c++11/g' $r_conf"
    ]
```


### Why do some of my packages install an older version of the package instead of the latest?
Since doAzureParallel uses Microsoft R Open version 3.3 as the default version of R, it will automatically try to pull pacakge from [MRAN](https://mran.microsoft.com/) rather than CRAN. This is a big benefit when wanting to use a constant version of a package but does not always contain references to the latest versions. To use a specific version from CRAN or a different MRAN snapshot date, use the 'commandLine' in the cluster configuration to manually install the packages you need.