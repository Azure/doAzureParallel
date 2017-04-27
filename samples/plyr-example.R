library(doAzureParallel)
library(plyr)

# Creating an Azure parallel backend
cluster <- makeCluster("credentials.json", "cluster_settings.json")

# Register your Azure parallel backend to the foreach implementation
registerDoAzureParallel(cluster)

# For more information on plyr, https://github.com/hadley/plyr
dlply(iris, .(Species), function(x)
  lm(x$Sepal.Width ~ x$Petal.Length, data=x),
  .parallel=TRUE, .paropts = list(.packages = NULL,.export="iris"))

stopCluster(cluster)
