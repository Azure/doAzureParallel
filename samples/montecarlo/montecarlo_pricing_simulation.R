# =============
# === Setup ===
# =============

# install packages
library(devtools)
#install_github("azure/razurebatch")
install_github("azure/doazureparallel")

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# generate a credentials json file
generateCredentialsConfig("credentials.template.json")

# generate a cluster config file
generateClusterConfig("cluster.template.json")

# set your credentials
setCredentials("credentials.json")

# Create your cluster if not exist
cluster <- makeCluster("cluster.json")

# register your parallel backend
registerDoAzureParallel(cluster)

# check that your workers are up
getDoParWorkers()

# ======================================
# === Monte Carlo Pricing Simulation ===
# ======================================

# set the parameters for the monte carlo simulation
mean_change = 1.001
volatility = 0.01
opening_price = 100

# define a new function to simulate closing prices
getClosingPrice <- function() {
  days <- 1825 # ~ 5 years
  movement <- rnorm(days, mean=mean_change, sd=volatility)
  path <- cumprod(c(opening_price, movement))
  closingPrice <- path[days]
  return(closingPrice)
}

start_s <- Sys.time()
# Run 10,000 simulations in series
closingPrices_s <- foreach(i = 1:10, .combine='c') %do% {
  replicate(1000, getClosingPrice())
}
end_s <- Sys.time()

# plot the 50 closing prices in a histogram to show the distribution of outcomes
hist(closingPrices_s)

# How long did it take?
difftime(end_s, start_s)

# Estimate runtime for 10 million (linear approximation)
1000 * difftime(end_s, start_s, unit = "min")

# Run 10 million simulations with doAzureParallel

# We will run 100 iterations where each iteration executes 100,000 simulations
opt <- list(chunkSize = 2) # optimizie runtime. Chunking allows us to run multiple iterations on a single instance of R.

start_p <- Sys.time()
closingPrices_p <- foreach(i = 1:100, .combine='c', .options.azure = opt) %dopar% {
  replicate(100000, getClosingPrice())
}
end_p <- Sys.time()

# How long did it take?
difftime(end_p, start_p, unit = "min")

# plot the 10 million closing prices in a histogram to show the distribution of outcomes
hist(closingPrices_p)
