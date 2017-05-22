library(doAzureParallel)

setCredentials("credentials.json")
setVerbose(TRUE)

# This step will upload the results within the foreach loop to azure storage
# First, replace the "mystorageaccount" with your storage account.
# We will create an output container named "nyc-taxi-graphs", then
# create an write-only permission SAS token to upload the graph from a VM in Azure
storageAccountName <- "mystorageaccount"
outputsContainer <- "nyc-taxi-graphs"
createContainer(outputsContainer)
outputSas <- createSasToken("w", "c", outputsContainer)

# Using the NYC taxi datasets, http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml
# We will upload the files to your pool of VMs, using resource files
azureStorageUrl <- "http://playdatastore.blob.core.windows.net/nyc-taxi-dataset"
azure_files <- list(
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-01.csv"), fileName = "yellow_tripdata_2016-01.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-02.csv"), fileName = "yellow_tripdata_2016-02.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-03.csv"), fileName = "yellow_tripdata_2016-03.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-04.csv"), fileName = "yellow_tripdata_2016-04.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-05.csv"), fileName = "yellow_tripdata_2016-05.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-06.csv"), fileName = "yellow_tripdata_2016-06.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-07.csv"), fileName = "yellow_tripdata_2016-07.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-08.csv"), fileName = "yellow_tripdata_2016-08.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-09.csv"), fileName = "yellow_tripdata_2016-09.csv")
)

# add the parameter 'resourceFiles'
cluster <- makeCluster("cluster_settings.json", resourceFiles = azure_files)

# when the cluster is provisioned, register the cluster as your parallel backend
registerDoAzureParallel(cluster)

results <- foreach(i = 1:9, .packages = c("data.table", "ggplot2", "rAzureBatch")) %dopar% {
  # Will update the docs to illustrate our temporary way of reading files
  fileDirectory <- paste0(Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"), "/wd")

  colsToKeep <- c("pickup_longitude", "pickup_latitude", "dropoff_longitude", "dropoff_latitude", "tip_amount", "trip_distance")

  file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-0", i, ".csv"), select = colsToKeep)

  min_lat <- 40.5774
  max_lat <- 40.9176
  min_long <- -74.15
  max_long <- -73.7004

  plot <- ggplot(file, aes(x=pickup_longitude, y=pickup_latitude)) +
    geom_point(size=0.06) +
    scale_x_continuous(limits=c(min_long, max_long)) +
    scale_y_continuous(limits=c(min_lat, max_lat)) +
    scale_color_gradient(low="#CCCCCC", high="#8E44AD", trans="log") +
    labs(title = paste0("Map of NYC, Plotted Using Locations Of All Yellow Taxi Pickups in ", i, " month"))

  image <- paste0("nyc-taxi-", i, ".png")
  ggsave(image)

  uploadBlob(containerName = outputsContainer,
             image,
             sasToken = outputSas,
             accountName = storageAccountName)
  NULL
}
