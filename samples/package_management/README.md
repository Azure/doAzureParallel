# Using package management

## BioConductor

Currently, Bioconductor is not natively supported in doAzureParallel but enabling it only requires updating the cluster configuration. In the Bioconductor sample you can simply create a cluster using the bioconductor_cluster.json file and a cluster will be set up ready to go.

Within your foreach loop, simply reference the Bioconductor library before running your algorithms.

```R
# Load the bioconductor libraries you want to use.
library(BiocInstaller)
```

**IMPORTANT:** Using Bioconductor in doAzureParallel requires updating the default version of R on the nodes. The cluster setup scrips will download and install [Microsoft R Open version 3.4.0](https://mran.microsoft.com/download/) which is compatible with Bioconductor 3.4.