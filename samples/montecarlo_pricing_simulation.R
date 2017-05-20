# =============
# === Setup ===
# =============

# install packages
library(devtools)
install_github("azure/razurebatch", ref="release")
install_github("azure/doazureparallel", ref="release")

# import the doAzureParallel library and it's dependencies
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
mean_change = 1.001
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

# Run 5 million simulations with doAzureParallel - we will run 50 iterations where each iteration executes 100000 simulations
closingPrices <- foreach(i = 1:50, .combine='c') %dopar% {
  replicate(100000, getClosingPrice())
}

# plot the 5 million closing prices in a histogram to show the distribution of outcomes
hist(closingPrices)

