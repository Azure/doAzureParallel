# Plyr

Since plyr is build on top of the doParallel interface, it can be easily extended to use in the cloud by registering doAzureParallel as it's backend.

```R
# Creating an Azure parallel backend
cluster <- makeCluster(clusterSetting = "plyr_cluster.json")

# Register your Azure parallel backend to the foreach implementation
registerDoAzureParallel(cluster)

# import plyr
library(plyr)

# For more information on plyr, https://github.com/hadley/plyr
dlply(iris, .(Species), function(x)
  lm(x$Sepal.Width ~ x$Petal.Length, data=x),
  .parallel=TRUE, .paropts = list(.packages = NULL,.export="iris"))
```
