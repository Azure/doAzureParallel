# Using package management

doAzureParallel supports installing packages at either the cluster level or during the execution of the foreach loop. Packages installed at the cluster level benefit from only needing to be installed once per node. Each iteration of the foreach can load the library without needing to install them again. Packages installed in the foreach benefit from specifying any specific dependencies required only for that instance of the loop.

## Cluster level packages

Cluster level packages support CRAN, GitHub and BioConductor packages. The packages are installed in a shared directory on the node. It is important to note that it is required to explicitly load any packages installed at the cluster level within the foreach loop. For example, if you installed xml2 on the cluster, you must explicityly load it before using it.

```R
foreach (i = 1:4) %dopar% {
  # Load the libraries you want to use.
  library(xml2)
  xml2::as_list(...)
}
```

### CRAN

CRAN packages can be insatlled on the cluster by adding them to the collection of _cran_ packages in the cluster specification. 

```json
"rPackages": {
    "cran": ["package1", "package2", "..."],
    "github": [],
    "bioconductor": []
  }
```

### GitHub

GitHub packages can be insatlled on the cluster by adding them to the collection of _github_ packages in the cluster specification. 

```json
"rPackages": {
    "cran": [],
    "github": ["repo1/name1", "repo1/name2", "repo2/name1", "..."],
    "bioconductor": []
  }
```

**NOTE** When using packages from a private GitHub repository, you must add your GitHub authentication token to your credentials.json file.

### BioConductor

Installing bioconductor packages is now supported via the cluster configuration. Simply add the list of packages you want to have installed in the cluster configuration file and they will get automatically applied

```json
"rPackages": {
    "cran": [],
    "github": [],
    "bioconductor": ["IRanges", "GenomeInofDb"]
  }
```

**IMPORTANT** doAzureParallel uses the rocker/tidyverse Docker images by default, which comes with BioConductor pre-installed. If you use a different container image, make sure that bioconductor is installed on it.


## Foreach level packages

Foreach level packages currently only support CRAN packages. Unlike cluster level pacakges, when specifying packages on the foreach loop, packages will be automatically installed _and loaded_ for use.

### CRAN

```R
foreach(i = 1:4, .packages = c("xml2")) %dopar% {
  # xml2 is automatically loaded an can be used without calling library(xml2)
  xml2::as_list(...)
}
```
