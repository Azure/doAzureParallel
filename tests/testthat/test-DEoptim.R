# Run this test for users to make sure the DEoptim support feature
# of doAzureParallel are still working
context("DEoptim integration test")
test_that("DEoptim integration test", {
  testthat::skip("DEoptim integration test")
  testthat::skip_on_travis()
  credentialsFileName <- "credentials.json"
  clusterFileName <- "cluster.json"

  doAzureParallel::generateCredentialsConfig(credentialsFileName)
  doAzureParallel::generateClusterConfig(clusterFileName)

  # set your credentials
  doAzureParallel::setCredentials(credentialsFileName)
  cluster <-
    doAzureParallel::makeCluster(clusterFileName, wait = FALSE)
  doAzureParallel::registerDoAzureParallel(cluster)
  setChunkSize(1)

  # install.packages("quantmod")
  # install.packages("DEoptim")
  # install.packages("PerformanceAnalytics")
  # install.packages("PortfolioAnalytics")
  library(quantmod)
  library(DEoptim)
  tickers <- c(
    "VNO",
    "VMC",
    "WMT",
    "DIS",
    "DIS",
    "CHK",
    "WFC",
    "WDC",
    "WY",
    "WHR",
    "WMB",
    "WEC",
    "XEL",
    "XRX",
    "XLNX",
    "ZION",
    "MMM",
    "ABT",
    "ADBE",
    "AMD",
    "AET",
    "AFL",
    "APD",
    "RAD",
    "AA",
    "AGN",
    "GE",
    "MO",
    "AEP",
    "AXP",
    "AIG",
    "AMGN",
    "APC",
    "ADI",
    "AON",
    "APA",
    "AAPL",
    "AMAT",
    "ADM",
    "T",
    "ADSK",
    "ADP",
    "AZO",
    "AVY",
    "AVP",
    "AMD",
    "BLL",
    "BAC",
    "BK",
    "GS",
    "BAX",
    "BBT",
    "BDX",
    "BMS",
    "BBY",
    "BIG",
    "HRB",
    "JCP",
    "BA",
    "BMY",
    "CA",
    "COG",
    "CPB",
    "CAH",
    "CCL",
    "CAT",
    "CELG",
    "CNP",
    "CTL",
    "WFC",
    "CERN",
    "SCHW",
    "CVX",
    "CB",
    "CI",
    "CINF",
    "CTAS",
    "CSCO",
    "C",
    "CLF",
    "CLX",
    "CMS",
    "KO",
    "CCE",
    "CL",
    "CMCSA",
    "CMA",
    "JPM",
    "CAG",
    "NOK",
    "ED",
    "ORCL",
    "GLW",
    "COST",
    "MSFT",
    "CSX",
    "CMI",
    "CVS",
    "DHR",
    "DE"
  )
  getSymbols(tickers, from = "2000-12-01", to = "2010-12-31")
  P <- NULL
  seltickers <- NULL
  for (ticker in tickers) {
    tmp <- Cl(to.monthly(eval(parse(text = ticker))))
    if (is.null(P)) {
      timeP <- time(tmp)
    }
    if (any(time(tmp) != timeP))
      next
    else
      P <- cbind(P, as.numeric(tmp))
    seltickers <- c(seltickers , ticker)
  }
  P = xts(P, order.by = timeP)
  colnames(P) <- seltickers
  R <- diff(log(P))
  R <- R[-1, ]
  dim(R)
  mu <- colMeans(R)
  sigma <- cov(R)

  obj <- function(w, mu, sigma) {
    library(PerformanceAnalytics)
    if (sum(w) == 0) {
      w <- w + 1e-2
    }
    w <- w / sum(w)
    CVaR <- ES(
      weights = w,
      method = "gaussian",
      portfolio_method = "component",
      mu = mu,
      sigma = sigma
    )
    tmp1 <- CVaR$ES
    tmp2 <- max(CVaR$pct_contrib_ES - 0.05, 0)
    out <- tmp1 + 1e3 * tmp2
    return(out)
  }

  N <- ncol(R)
  minw <- 0
  maxw <- 1
  lower <- rep(minw, N)
  upper <- rep(maxw, N)

  library("PortfolioAnalytics")
  eps <- 0.025
  weight_seq <-
    generatesequence(
      min = minw,
      max = maxw,
      by = .001,
      rounding = 3
    )
  rpconstraint <- constraint(
    assets = N,
    min_sum = (1 - eps),
    max_sum = (1 + eps),
    min = lower,
    max = upper,
    weight_seq = weight_seq
  )
  #assuming equal weighted seed portfolio
  set.seed(1234)
  rp <-
    random_portfolios_v1(rpconstraints = rpconstraint, permutations = N * 10)

  rp <- rp / rowSums(rp)

  options <- list(wait = TRUE, autoDeleteJob = FALSE)
  #options <- list(wait = FALSE, autoDeleteJob = FALSE)
  foreachArgs <-
    list(
      #.packages = c('DEoptim', 'PerformanceAnalytics'),
      .options.azure = options
    )
  controlDE <-
    list(
      reltol = .000001,
      steptol = 150,
      itermax = 5000,
      trace = 250,
      NP = as.numeric(nrow(rp)),
      initialpop = rp,
      foreachArgs = foreachArgs,
      parallelType = 2
    )
  set.seed(1234)
  start <- Sys.time()
  out <-
    DEoptim(
      fn = obj,
      lower = lower,
      upper = upper,
      control = controlDE,
      mu,
      sigma
    )
  stoptime <- Sys.time()
})
