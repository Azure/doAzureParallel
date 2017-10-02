# Package Management

The doAzureParallel package allows you to install packages to your pool in two ways:
- Installing on pool creation
- Installing per-*foreach* loop

## Installing Packages on Pool Creation
You can install packages by specifying the package(s) in your JSON pool configuration file. This will then install the specified packages at the time of pool creation.

```R
{
  ...
  "rPackages": {
    "cran": ["some_cran_package_name", "some_other_cran_package_name"],
    "github": ["github_username/github_package_name", "another_github_username/another_github_package_name"]
  },
  ...
}
```

## Installing packages from a private GitHub repository

Clusters can be configured to install packages from a private GitHub repository by setting the __githubAuthenticationToken__ property. If this property is blank only public repositories can be used. If a token is added then public and the private github repo can be used together.

When the cluster is created the token is passed in as an environment variable called GITHUB\_PAT on start-up which lasts the life of the cluster and is looked up whenever devtools::install_github is called.

```json
{
    {
    "name": <your pool name>,
    "vmSize": <your pool VM size name>,
    "maxTasksPerNode": <num tasks to allocate to each node>,
    "poolSize": {
        "dedicatedNodes": {
            "min": 2,
            "max": 2
        },
        "lowPriorityNodes": {
            "min": 1,
            "max": 10
        },
        "autoscaleFormula": "QUEUE"
    },
    "rPackages": {
        "cran": [],
        "github": ["<project/some_private_repository>"],
        "githubAuthenticationToken": "<github_authentication_token>"
    },
    "commandLine": []
    }
}
```

_More information regarding github authentication tokens can be found [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)_

## Installing Packages per-*foreach* Loop
You can also install packages by using the **.packages** option in the *foreach* loop. Instead of installing packages during pool creation, packages (and it's dependencies) can be installed before each iteration in the loop is run on your Azure cluster.

To install a single package:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, .packages='some_package') %dopar% { ... }
```

To install multiple packages:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, .packages=c('package_1', 'package_2')) %dopar% { ... }
```

Installing packages from github using this method is not yet supported.

## Installing Packages from BioConductor
Currently there is no native support for Bioconductor package installation, but it can be achieved by installing the packages directly in your environment or using the 'commandLine' feature in the cluster configuration. We recommend using the 'commandLine' to install the base BioConductor package and then install additional packages either through the 'commandLine' as well, or directly in your code.

### Installing BioConductor using the 'commandLine'

We recommend using the [script provided in the samples](../samples/package_management/bioc_setup.sh) section of this project which will install the required pre-requisites for BioConductor as well as BioConductor itself.

In the example below, the script will install BioConductor and install the GenomeInfoDB package. Simply update your cluster configuration commandLine as follows:
```json
"commandLine": [
        "wget https://raw.githubusercontent.com/Azure/doAzureParallel/master/samples/package_management/bioc_setup.sh",
        "chmod u+x ./bioc_setup.sh",
        "./bioc_setup.sh",
        "Rscript -e 'library(BiocInstaller);biocLite(\\\"GenomeInfoDb\\\");'"]
```

Installing bioconductor packages 'on the fly' is not supported, and should be specified and installed during the cluster creation. Note that the \\\" characters are required to correctly escaple the quotes in the command line.

A [working sample](../samples/package_management/bioconductor_cluster.json) can be found in the samples directory.

### Installing additional packages in your code

If you have already configured BioConductor at the cluster level, you should have access to biocLite in your code. Within your foreach loop add the call to biocLite to install the packages:

```r
results <- foreach(i = 1:number_of_iterations) %dopar% { 
    library(BiocInstaller)
    biocLite(c('GenomicsFeatures', 'AnnotationDbi'))
    ...
    }
```

## Uninstalling packages
Uninstalling packages from your pool is not supported. However, you may consider rebuilding your pool.
