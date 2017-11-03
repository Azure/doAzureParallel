# Customizing the cluster

There are several ways to control what gets deployed to a cluster. The most flexible and powerful method is to manage the docker container image that is used to provision the cluster. By default doAzureParallel uses containers to provision the R environement. Anything within the container will be available on all nodes in the cluster. The default container used in doAzureParallel is [rocker/tidyverse:latest](https://hub.docker.com/r/rocker/tidyverse/) developed and maintained by the rocker organization.

## Modifying the default docker container

Specifying a docker container is done by updating your cluster.json file. Simply adding a reference to the docker container in the cluster.json file 'containerImage' property will cause all new clusters to deploy that container to your cluster. doAzureParallel will use the version of R specified in the container.

```json
{
  "name": "myPool",
  "vmSize": "Standard_F2",
  "maxTasksPerNode": 1,
  "poolSize": {
    "dedicatedNodes": {
      "min": 0,
      "max": 0
    },
    "lowPriorityNodes": {
      "min": 1,
      "max": 1
    },
    "autoscaleFormula": "QUEUE"
  },
  "containerImage": "rocker/tidyverse:3.4.1",
  "rPackages": {
    "cran": [],
    "github": [],
    "bioconductor": [],
    "githubAuthenticationToken": ""
  },
  "commandLine": []
}
```

Note: \_If no 'containerImage' property is set, rocker/tidyverse:latest will be used. This usually points to one of the latest versions of R.\_

### Building your own container

Building your own container gives you the flexibility to package any specific requirements, packages or data you require for running your workloads. We recommend using a debian based OS such as debian or ubuntu to build your containers and pointing to where R is in the final CMD command. For example:

```dockerfile
FROM debian:stretch
...
CMD ["/usr/bin/R"]
```

Or alternitavely,

```dockerfile
FROM ubuntu:16.04
...
CMD ["R"]
```

There is no requirement to be debian based. For consistency with other pacakges it is recommeneded though. Please note though that the container **must be based off a Linux distribution as Windows is not supported**.

### List of tested container images

The following containers were tested and cover the most common cases for end users.

Container Image | R type | Description
--- | --- | ---
[rocker/tidyverse](https://hub.docker.com/r/rocker/r-ver/) | Open source R | Tidyverse is provided by the rocker org and uses a standard version of R developed by the open soruce community. rocker/tidyverse typically keeps up with the latest releases or R quite quickly and has versions back to R 3.1
[nuest/mro](https://hub.docker.com/r/nuest/mro/) | Microsoft R Open | [Microsoft R Open](https://mran.microsoft.com/open/) is an open source SKU of R that provides out of the box support for math packages, version pacakge support with MRAN and improved performance over standard Open Source R.

* We recommend reading the details of each package before using it to make sure you understand any limitaions or requirements of using the container images.

## Running Commands when the Cluster Starts

The commandline property in the cluster configuration file allows users to prepare the nodes' environments. For example, users can perform actions such as installing applications that your foreach loop requires.

Note: Batch clusters are provisioned with Ubuntu 16.04.

Note: All commands are already run as the sudo user, so there is no need to append sudo to your command line. \_Commands may fail if you add the sudo user as part of the command.\_

Note: All commands are run on the host node, not from within the container. This provides the most flexibility but also requires a bit of understanding on how to run code from within R and how to load directories correctly. See below for exposed environement variables, directories and examples.

```json
{
  "commandLine": [
      "apt-get install -y wget",
      "apt-get install -y libcurl4-openssl-dev",
      "apt-get install -y curl"
    ]
}
```

### Environment variables for containers

The following Azure Batch environment variables are exposed into the container.

Environment Variable | Description
--- | ---
AZ\_BATCH\_NODE\_ROOT\_DIR | Root directory for all files on the node
AZ\_BATCH\_JOB\_ID | Job ID for the foreach loop
AZ\_BATCH\_TASK\_ID | Task ID for the task running the R loop instance
AZ\_BATCH\_TASK\_WORKING\_DIR | Working directory where all files for the R process are logged
AZ\_BATCH\_JOB\_PREP\_WORKING | Working directory where all files for packages in the foreach loop are logged

### Directories for containers

The following directories are mounted into the container.

Directory | Description
--- | ---
$AZ\_BATCH\_NODE\_ROOT\_DIR | Root directory for all files
$AZ\_BATCH\_NODE\_ROOT\_DIR\shared\R\packages | Shared directory where all packages are installed to by default.

### Examples

The following examples show how to configure the host node, or R package via the container.

#### Installing apt-get packages or configuring the host node

Configuring the host node is not a common operation but sometimes required. This can include installing packages, downloading data or setting up directories. The below example shows how to mount and Azure File Share to the node and expose it to the Azure Batch shared directory so it can be consumed by any R process running in the containers.

```json
{
  "commandLine": [
      "mkdir /mnt/batch/tasks/shared/fileshare",
      "mount -t cifs //<STORAGE_ACCOUNT_NAME>.file.core.windows.net/<FILE_SHARE_NAME> /mnt/batch/tasks/shared/fileshare -o vers=3.0 username=<STORAGE_ACCOUNT_NAME>,password=<STORAGE_ACCOUNT_KEY>==,dir_mode=0777,file_mode=0777,sec=ntlmssp"
    ]
}
```

Within the container, you can now access that directory using the environment variable **AZ\_BATCH\_ROOT\_DIR**, for example $AZ\_BATCH\_ROOT\_DIR\shared\fileshare
