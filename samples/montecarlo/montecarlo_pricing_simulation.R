# =============
# === Setup ===
# =============

# install packages
library(devtools)
install_github("azure/razurebatch")
install_github("azure/doazureparallel")

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# generate a credentials json file
generateCredentialsConfig("credentials.json")

# set your credentials
setCredentials("credentials.json")

# generate a cluster config file
generateClusterConfig("cluster.json")

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
mean_change = 1.0011
volatility = 0.01
opening_price = 100

# define a function to simulate the movement of the stock price for one possible outcome over 5 years
simulateMovement <- function() {
  days <- 1825 # ~ 5 years
  movement <- rnorm(days, mean=mean_change, sd=volatility)
  path <- cumprod(c(opening_price, movement))
  return(path)
}

# run and plot 30 simulations
simulations <- replicate(30, simulateMovement())
matplot(simulations, type='l')

# define a new function to simulate closing prices
getClosingPrice <- function() {
  days <- 1825 # ~ 5 years
  movement <- rnorm(days, mean=mean_change, sd=volatility)
  path <- cumprod(c(opening_price, movement))
  closingPrice <- path[days]
  return(closingPrice)
}


# We will run 100 iterations where each iteration executes 100,000 simulations
opt <- list(chunkSize = 2) # optimizie runtime

start_p <- Sys.time()
closingPrices_p <- foreach(i = 1:8, .combine='c', .options.azure = opt) %dopar% {
  replicate(100000, getClosingPrice())
}
end_p <- Sys.time()

# How long did it take?
difftime(end_p, start_p, unit = "min")

# plot the 10 million closing prices in a histogram to show the distribution of outcomes
hist(closingPrices_p)

