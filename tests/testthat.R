# In order to run the test properly, a preconfigured pool named myPoolName needs to be created
# User must set environments for the credentials:
# Sys.setenv("AZ_BATCH_ACCOUNT_NAME" = "YOUR_BATCH_ACCOUNT_NAME",
#            "AZ_BATCH_ACCOUNT_KEY"="YOUR_ACCOUNT_KEY",
#            "AZ_BATCH_ACCOUNT_URL"="http://defaultaccount.azure.com",
#            "AZ_STORAGE_ACCOUNT_NAME"="YOUR_STORAGE_ACCOUNT_NAME_EXAMPLE",
#            "AZ_STORAGE_ACCOUNT_KEY"="YOUR_STORAGE_ACCOUNT_KEY")

library(testthat)
library(doAzureParallel)

test_check("doAzureParallel")
