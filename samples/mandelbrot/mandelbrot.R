# =================
# ===== Setup =====
# =================

# install packages
library(devtools)
install_github("azure/doazureparallel")

# import the doAzureParallel library and its dependencies
library(doAzureParallel)

# generate a credentials json file
generateCredentialsConfig("credentials.json")

# set your credentials
setCredentials("credentials.json")

# Create your cluster if not exist
cluster <- makeCluster("mandelbrot_cluster.json")

# register your parallel backend
registerDoAzureParallel(cluster)

# check that your workers are up
getDoParWorkers()

# ======================================
# ===== Compute the Mandelbrot Set =====
# ======================================

# Define Mandelbrot function
vmandelbrot <- function(xvec, y0, lim)
{
  mandelbrot <- function(x0,y0,lim)
  {
    x <- x0; y <- y0
    iter <- 0
    while (x^2 + y^2 < 4 && iter < lim)
    {
      xtemp <- x^2 - y^2 + x0
      y <- 2 * x * y + y0
      x <- xtemp
      iter <- iter + 1
    }
    iter
  }

  unlist(lapply(xvec, mandelbrot, y0=y0, lim=lim))
}

# Calculate Madelbrot
x.in <- seq(-2.0, 0.6, length.out=240)
y.in <- seq(-1.3, 1.3, length.out=240)
m <- 100
mset <- foreach(i=y.in, .combine=rbind, .options.azure = list(chunkSize=10)) %dopar% {
  vmandelbrot(x.in, i, m)
}

# Plot image
image(x.in, y.in, t(mset), col=c(rainbow(m), '#000000'), useRaster=TRUE)

