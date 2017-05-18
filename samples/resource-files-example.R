library(doAzureParallel)

setCredentials("credentials.json")
setVerbose(TRUE)

storageAccountName <- "STORAGE_ACCOUNT_NAME"
inputsContainer <- "inputs"
outputsContainer <- "outputs"

# Creating containers
createContainer(inputsContainer)
createContainer(outputsContainer)

# Generating sas token for blob uploads and downloads
inputSas <- constructSas("r", "c", inputsContainer)
outputSas <- constructSas("w", "c", outputsContainer)

# Using the NYC taxi datasets, http://www.nyc.gov/html/tlc/html/about/trip_record_data.shtml
uploadChunk(inputsContainer, "yellow_tripdata_2016-01.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-02.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-03.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-04.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-05.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-06.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-07.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-08.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-09.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-10.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-11.csv", parallelThreads = 6)
uploadChunk(inputsContainer, "yellow_tripdata_2016-12.csv", parallelThreads = 6)

azure_files <- list(
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-01.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-02.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-03.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-04.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-05.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-06.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-07.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-08.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-09.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-10.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-11.csv", inputSas),
  generateResourceFile(storageAccountName, inputsContainer, "yellow_tripdata_2016-12.csv", inputSas)
)

localSeqExecution <- function(months) {
  print("local")

  results <- foreach(i = 1:months, .packages = c("data.table", "ggplot2", "rAzureBatch")) %do% {
    # Will update the docs to illustrate our temporary way of reading files
    fileDirectory <- getwd()

    colsToKeep <- c("pickup_longitude", "pickup_latitude", "dropoff_longitude", "dropoff_latitude", "tip_amount", "trip_distance")
    if(i > 9){
      file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-", i, ".csv"), select = colsToKeep)
    }
    else {
      file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-0", i, ".csv"), select = colsToKeep)
    }

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

    NULL
  }
}

localParExecution <- function(months) {
  print("doParallel")
  library(doParallel)
  cl<-parallel::makeCluster(4, outfile = "log.txt")
  registerDoParallel(cl)

  results <- foreach(i = 1:months, .packages = c("data.table", "ggplot2", "rAzureBatch")) %dopar% {
    # Will update the docs to illustrate our temporary way of reading files
    fileDirectory <- getwd()

    colsToKeep <- c("pickup_longitude", "pickup_latitude", "dropoff_longitude", "dropoff_latitude", "tip_amount", "trip_distance")
    if(i > 9){
      file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-", i, ".csv"), select = colsToKeep)
    }
    else {
      file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-0", i, ".csv"), select = colsToKeep)
    }

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

    NULL
  }
}

azureExecution <- function(months) {
  print("azureExecution")
  library(doAzureParallel)

  setCredentials("credentials.json")
  setVerbose(TRUE)

  storageAccountName <- "doazureparalleltest"
  inputsContainer <- "inputs"
  outputsContainer <- "outputs"

  # Generating sas token for blob uploads
  inputSas <- constructSas("r", "c", inputsContainer)
  outputSas <- constructSas("w", "c", outputsContainer)

  # add the parameter 'resourceFiles'
  startTime <- Sys.time()
  cluster <- doAzureParallel::makeCluster("cluster_settings.json", resourceFiles = azure_files)
  endTime <- Sys.time()

  # when the cluster is provisioned, register the cluster as your parallel backend
  registerDoAzureParallel(cluster)

  results <- foreach(i = 1:months, .packages = c("data.table", "ggplot2", "rAzureBatch")) %dopar% {
    # Will update the docs to illustrate our temporary way of reading files
    fileDirectory <- paste0(Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"), "/wd")

    colsToKeep <- c("pickup_longitude", "pickup_latitude", "dropoff_longitude", "dropoff_latitude", "tip_amount", "trip_distance")
    if(i > 9){
      file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-", i, ".csv"), select = colsToKeep)
    }
    else {
      file <- fread(paste0(fileDirectory, "/yellow_tripdata_2016-0", i, ".csv"), select = colsToKeep)
    }
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
}

library(microbenchmark)
op <- microbenchmark(
  doAzureParallel=azureExecution(6),
  doLocal = localSeqExecution(6),
  doParallel = localParExecution(6),
  times=2L)

