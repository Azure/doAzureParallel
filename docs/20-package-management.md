# Package Management

The doAzureParallel package allows you to install packages to your pool in two ways:
- Installing on pool creation
- Installing per-*foreach* loop

Packages installed at the pool level benefit from only needing to be installed once per node. Each iteration of the foreach can load the library without needing to install them again. Packages installed in the foreach benefit from specifying any specific dependencies required only for that instance of the loop.

## Installing Packages on Pool Creation

Pool level packages support CRAN, GitHub and BioConductor packages. The packages are installed in a shared directory on the node. It is important to note that it is required to explicitly load any packages installed at the cluster level within the foreach loop. For example, if you installed xml2 on the cluster, you must explicityly load it before using it.

```R
foreach (i = 1:4) %dopar% {
  # Load the libraries you want to use.
  library(xml2)
  xml2::as_list(...)
}
```
You can install packages by specifying the package(s) in your JSON pool configuration file. This will then install the specified packages at the time of pool creation.

```R
{
  ...
  "rPackages": {
    "cran": ["some_cran_package_name", "some_other_cran_package_name"],
    "github": ["github_username/github_package_name", "another_github_username/another_github_package_name"],
    "bioconductor": ["IRanges"]
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
        "bioconductor": []
    },
    "commandLine": []
    }
}
```

_More information regarding github authentication tokens can be found [here](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)_

## Installing Packages per-*foreach* Loop
You can also install cran packages by using the **.packages** option in the *foreach* loop. You can also install github/bioconductor packages by using the **github** and **bioconductor" option in the *foreach* loop. Instead of installing packages during pool creation, packages (and its dependencies) can be installed before each iteration in the loop is run on your Azure cluster.

To install a single cran package:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, .packages='some_package') %dopar% { ... }
```

To install multiple cran packages:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, .packages=c('package_1', 'package_2')) %dopar% { ... }
```

To install a single github package:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, github='azure/rAzureBatch') %dopar% { ... }
```

Please do not use "https://github.com/" as prefix for the github package name above.

To install multiple github packages:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, github=c('package_1', 'package_2')) %dopar% { ... }
```

To install a single bioconductor package:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, bioconductor='some_package') %dopar% { ... }
```

To install multiple bioconductor packages:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, bioconductor=c('package_1', 'package_2')) %dopar% { ... }
```

## Installing Packages from BioConductor
The default deployment of R used in the cluster (see [Customizing the cluster](./30-customize-cluster.md) for more information) includes the Bioconductor installer by default. Simply add packages to the cluster by adding packages in the array.

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
        "github": [],
        "bioconductor": ["IRanges"]
    },
    "commandLine": []
    }
}
```

Note: Container references that are not provided by tidyverse do not support Bioconductor installs. If you choose another container, you must make sure that Biocondunctor is installed.

## Uninstalling packages
Uninstalling packages from your pool is not supported. However, you may consider rebuilding your pool.
