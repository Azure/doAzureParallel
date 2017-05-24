# =======================================
# === Setup / Install and Credentials ===
# =======================================

# install packages from github
library(devtools)
install_github("azure/razurebatch")
install_github("azure/doazureparallel")

# import packages
library(doAzureParallel)

# create credentials config files
generateCredentialsConfig("credentials.json")

# set azure credentials
setCredentials("credentials.json")

# ===================================================
# === Setting up your cluster with resource files ===
# ===================================================

# Now we will use resource-files to upload our dataset onto each node of our cluster.
# Currently, our data is stored in Azure Blob in an account called 'playdatastore', 
#   in a public container called "nyc-taxi-dataset". To get this dataset onto each node, 
#   we will create a resouceFile object for each blob - we will then use the resourceFile
#   when building the cluster so that each node in the cluster knows to download these files
#   after the node is provisioned.
# Using the NYC taxi datasets, http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml
azureStorageUrl <- "http://playdatastore.blob.core.windows.net/nyc-taxi-dataset"
resource_files <- list(
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-01.csv"), fileName = "yellow_tripdata_2016-01.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-02.csv"), fileName = "yellow_tripdata_2016-02.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-03.csv"), fileName = "yellow_tripdata_2016-03.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-04.csv"), fileName = "yellow_tripdata_2016-04.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-05.csv"), fileName = "yellow_tripdata_2016-05.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-06.csv"), fileName = "yellow_tripdata_2016-06.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-07.csv"), fileName = "yellow_tripdata_2016-07.csv"),
  createResourceFile(url = paste0(azureStorageUrl, "/yellow_tripdata_2016-08.csv"), fileName = "yellow_tripdata_2016-08.csv")
)

# add the parameter 'resourceFiles' to download files to nodes
cluster <- makeCluster("cluster_settings.json", resourceFiles = resource_files)

# when the cluster is provisioned, register the cluster as your parallel backend
registerDoAzureParallel(cluster)


# ======================================================
# === Setting up storage account to write results to ===
# ======================================================

# Setup storage location to write your results to:
# This step will allow your to upload your results from within your doAzureParallel foreach loop:
# 
#   1. Replace the "mystorageaccount" with the name of the storage account you wish to write your results to.
#   2. Create an output container named "nyc-taxi-graphs" to store your results in
#   3. Create a SasToken that allows us to write ("w") to the container
#   4. Notice the parameter 'path = "c"' in the createSasToken method, this 
#      simply means that the token is created for that entire container in storage
# 
storageAccountName <- "mystorageaccount"
outputsContainer <- "nyc-taxi-graphs"
createContainer(outputsContainer)
outputSas <- createSasToken(permission = "w", path = "c", outputsContainer)

# =======================================================
# === Foreach with resourceFiles & writing to storage ===
# =======================================================

results <- foreach(i = 1:8, .packages = c("data.table", "ggplot2", "rAzureBatch")) %dopar% {
  
  # To get access to your azure resource files, user needs to use the special
  # environment variable to get the directory
  fileDirectory <- paste0(Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"), "/wd")

  # columns to keep for the datafram
  colsToKeep <- c("pickup_longitude", "pickup_latitude", "dropoff_longitude", "dropoff_latitude", "tip_amount", "trip_distance")

  # read in data from CSV that was downloaded from the resource file
  file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-0", i, ".csv"), select = colsToKeep)

  # set the coordinates for the bounds of the plot
  min_lat <- 40.5774
  max_lat <- 40.9176
  min_long <- -74.15
  max_long <- -73.7004

  # compute intensive plotting
  plot <- ggplot(file, aes(x=pickup_longitude, y=pickup_latitude)) +
    geom_point(size=0.06) +
    scale_x_continuous(limits=c(min_long, max_long)) +
    scale_y_continuous(limits=c(min_lat, max_lat)) +
    scale_color_gradient(low="#CCCCCC", high="#8E44AD", trans="log") +
    labs(title = paste0("Map of NYC, Plotted Using Locations Of All Yellow Taxi Pickups in ", i, " month"))

  # build image from plot
  image <- paste0("nyc-taxi-", i, ".png")
  ggsave(image)

  # save image to the storage account using the Sas token we created above
  uploadBlob(containerName = outputsContainer,
             image,
             sasToken = outputSas,
             accountName = storageAccountName)
  NULL
}

# deprovision your cluster after your work is complete
stopCluster(cluster)
