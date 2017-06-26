library(doAzureParallel)

setCredentials("credentials.json")
setVerbose(TRUE)

storageAccountName <- "mystorageaccount"
inputContainerName <- "datasets"

# Generate a sas token with the createSasToken function
writeSasToken <- rAzureBatch::createSasToken(permission = "w", sr = "c", inputContainerName)
readSasToken <- rAzureBatch::createSasToken(permission = "r", sr = "c", inputContainerName)

# Upload blobs with a write sasToken
rAzureBatch::uploadBlob(inputContainerName,
           fileDirectory = "1989.csv",
           sasToken = writeSasToken,
           accountName = storageAccountName)

rAzureBatch::uploadBlob(inputContainerName,
           fileDirectory = "1990.csv",
           sasToken = writeSasToken,
           accountName = storageAccountName)

csvFileUrl1 <- rAzureBatch::createBlobUrl(storageAccount = storageAccountName,
              containerName = inputContainerName,
              sasToken = readSasToken,
              fileName = "1989.csv")

csvFileUrl2 <- rAzureBatch::createBlobUrl(storageAccount = storageAccountName,
                             containerName = inputContainerName,
                             sasToken = readSasToken,
                             fileName = "1990.csv")

azure_files = list(
  rAzureBatch::createResourceFile(url = csvFileUrl1, fileName = "1989.csv"),
  rAzureBatch::createResourceFile(url = csvFileUrl2, fileName = "1990.csv")
)

cluster <- doAzureParallel::makeCluster("cluster_settings.json", resourceFiles = azure_files)

registerDoAzureParallel(cluster)

# To get access to your azure resource files, user needs to use the special
# environment variable to get the directory
listFiles <- foreach(i = 1989:1990, .combine = 'c') %dopar% {
  fileDirectory <- paste0(Sys.getenv("AZ_BATCH_NODE_STARTUP_DIR"), "/wd")
  return(list.files(fileDirectory))
}

stopCluster(cluster)
