## Installing Custom Packages
doAzureParallel supports custom package installation in the cluster. Custom packages are R packages that cannot be hosted on Github or be built on a docker image. The recommended approach for custom packages is building them from source and uploading them to an Azure File Share.

Note: If the package requires a compilation such as apt-get installations, users will be required
to build their own containers.

### Building Package from Source in RStudio
1. Open *RStudio*
2. Go to *Build* on the navigation bar
3. Go to *Build From Source*

### Uploading Custom Package to Azure Files
For detailed steps on uploading files to Azure Files in the Portal can be found
[here](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-portal)

### Notes
1) In order to build the custom packages' dependencies, we need to untar the R packages and build them within their directories. By default, we will build custom packages in the *$AZ_BATCH_NODE_SHARED_DIR/tmp* directory. 
2) By default, the custom package cluster configuration file will install any packages that are a *.tar.gz file in the file share. If users want to specify R packages, they must change this line in the cluster configuration file.

Finds files that end with *.tar.gz in the current Azure File Share directory 
``` json
{
  ...
  "commandLine": [
    ...
    "mkdir $AZ_BATCH_NODE_STARTUP_DIR/tmp | for i in `ls $AZ_BATCH_NODE_SHARED_DIR/data/*.tar.gz | awk '{print $NF}'`; do tar -xvf $i -C $AZ_BATCH_NODE_STARTUP_DIR/tmp; done",
    ...
    ]
}
```
3) For more information on using Azure Files on Batch, follow our other [sample](./azure_files/readme.md) of using Azure Files
4) Replace your Storage Account name, endpoint and key in the cluster configuration file 
