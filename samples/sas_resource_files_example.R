library(doAzureParallel)

setCredentials("credentials.json")
setVerbose(TRUE)

storageAccountName <- "mystorageaccount"
inputContainerName <- "datasets"

# Generate a sas token with the createSasToken function
writeSasToken <- createSasToken(permission = "w", path = "c", inputContainerName)
readSasToken <- createSasToken(permission = "r", path = "c", inputContainerName)

# Upload blobs with a write sasToken
uploadBlob(inputContainerName,
           fileDirectory = "1989.csv",
           sasToken = writeSasToken,
           accountName = storageAccountName)

uploadBlob(inputContainerName,
           fileDirectory = "1990.csv",
           sasToken = writeSasToken,
           accountName = storageAccountName)

csvFileUrl1 <- createBlobUrl(storageAccountName = storageAccountName,
              containerName = inputContainerName,
              sasToken = readSasToken,
              fileName = "1989.csv")

csvFileUrl2 <- createBlobUrl(storageAccountName = storageAccountName,
                             containerName = inputContainerName,
                             sasToken = readSasToken,
                             fileName = "1990.csv")

azure_files = list(
  createResourceFile(url = csvFileUrl1, fileName = "1989.csv"),
  createResourceFile(url = csvFileUrl2, fileName = "1990.csv")
)

cluster <- makeCluster("cluster_settings.json", resourceFiles = azure_files)

registerDoAzureParallel(cluster)

# To get access to your azure resource files, user needs to use the special
# environment variable to get the directory
listFiles <- foreach(i = 1989:1990, .combine='c') %dopar% {
  fileDirectory <- paste0(Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"), "/wd")
  return(list.files(fileDirectory))
}

stopCluster(cluster)
