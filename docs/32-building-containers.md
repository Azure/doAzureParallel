# Building Docker Containers for doAzureParallel

As of version v0.6.0 doAzureParallel runs all workloads within a Docker container. This has several benefits including consistent immutable runtime, custom R version, environment and packages and improved testing before deploying to doAzureParallel

The documentation below builds on top of the standard Docker documentation. It is highly recommended you read up on Docker [documentation](https://docs.docker.com/), specifically their [getting started guide](https://docs.docker.com/get-started/).

Prerequisites
- Install Docker [instructions](https://docs.docker.com/engine/installation/)

## Use cases
These are some of the common use cases for builing your own images in Docker.

### Custom version of R
If you have your own R runtime, or want to use something other than the default version of R that doAzureParallel uses, you can easily point to an existing Docker image or build one yourself. This allows for the flexibility to use any R version you need without being subjected to what defaults are used by this toolkit.

### Custom packages pre-built into your environment
Installing packages is often complex and involved and takes a few tries to get right. Using docker you can make sure that your images are built correctly on your local machine without needing to try building and rebuilding doAzureParallel clusters trying to get it right. This also means that you can pull in your own custom packages and guarantee that the version of the package inside the container will never change and your runs will always produce the same results.


### Improved cluster provisioning reliability and start up time
One issue with installing packages is that they can take time to load and install, and are subject to potential issues with repository access and network reliability. By pre-packaging everything into your container, you can guarantee that everything is already built and available and will be loaded correctly in the doAzureParallel cluster.

## Building your own container image
Building container images may seem a bit difficult to begin with, but they are really no harder than running commands in your command line. The following sections will go through how to build a container image that will install a few R packages and their operating system dependencies.

In the following example we will create an image that installs the popular web based packages jsonlite and httr. This example simply uses an image provided by the RStudio team 'r-ver' and installs a few packages into it. The benefit of using the r-ver package is that it has already done all the hard work of getting R installed, so all we need to do in add the packages we want to use and we should be good to go.

NOTE: Rocker has [several great R container images](https://github.com/rocker-org/rocker/wiki) available on Docker Hub. Take a quick look through them to see if any of them suit your needs.

Create a Dockerfile in a direcotry called 'demo'. Notice the Dockerfile has no extension.

```sh
mkdir demo
touch demo/Dockerfile
```

Open up the Dockerfile with your favorite editor and paste in the following code.

```Dockerfile
# Use rocker/r-ver as the base image
# This will inherit everyhing that was installed into base image already
# Documented at https://hub.docker.com/r/rocker/r-ver/~/dockerfile/
FROM rocker/r-ver

# Install any dependencies required for the R packages
RUN  apt-get update \
  && apt-get install -y --no-install-recommends \
  libxml2-dev


# Install the R Packages from CRAN
RUN Rscript -e 'install.packages(c(jsonlite, httr), dependecies = TRUE)'
```

Finally save the file and build the docker image.

```sh
# docker build takes the directory which contains the Dockerfile as the input
# -t is used to tag or name the image
docker build demo -t demo/custom-r-ver
```

Once the docker image is built locally, you can list it by running the below command.
```sh
docker images
```

And you should see the following

```sh
REPOSITORY           TAG                 IMAGE ID            CREATED             SIZE
demo/custom-r-ver    latest              55aefec47200        14 seconds ago      709MB
rocker/r-ver         latest              503e3df4e322        21 hours ago        578MB
```

rocker/r-ver is the image that was downloaded to build the demo/custom-r-ver.

## Testing your image

Once you have your images built, you can run it locally to test it out.

```sh
docker run --rm -it demo/custom-r-ver R
```

This will open up a conole version of R. To make sure the packages are insalled correctly, load them into the R session.

```sh
> library(httr)
> library(jsonlite)
> sessionInfo()
```

The output will show that these packages are now available to use

```sh
R version 3.4.2 (2017-09-28)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Debian GNU/Linux 9 (stretch)

Matrix products: default
BLAS: /usr/lib/openblas-base/libblas.so.3
LAPACK: /usr/lib/libopenblasp-r0.2.19.so

locale:
 [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
 [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=C             
 [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] jsonlite_1.5 httr_1.3.1  

loaded via a namespace (and not attached):
[1] compiler_3.4.2 R6_2.2.2
```

## Testing your image for doAzureParallel (advanced)

doAzureParallel will run your container and load in specific direcotories and environement varialbles.

We run the container as follows:
```sh
docker run --rm \
    -v $AZ_BATCH_NODE_ROOT_DIR:$AZ_BATCH_NODE_ROOT_DIR \
    -e AZ_BATCH_NODE_ROOT_DIR=$AZ_BATCH_NODE_ROOT_DIR \
    -e AZ_BATCH_NODE_STARTUP_DIR=$AZ_BATCH_NODE_STARTUP_DIR \
    -e AZ_BATCH_TASK_ID=$AZ_BATCH_TASK_ID \
    -e AZ_BATCH_JOB_ID=$AZ_BATCH_JOB_ID \
    -e AZ_BATCH_TASK_WORKING_DIR=$AZ_BATCH_TASK_WORKING_DIR \
    -e AZ_BATCH_JOB_PREP_WORKING_DIR=$AZ_BATCH_JOB_PREP_WORKING_DIR
```

All files downloaded with resource files will be available at $AZ\_BATCH\_NODE\_STARTUP\_DIR/wd.

You can use these values to set up your local environment to look like it is running on a Batch node.

## Deploying your images to Docker Hub

Once you are happy with your image, you can publish it to docker hub

```sh
docker login
...
docker push <username>/custom-r-ver
```

## Referencing your image in your cluster.json file

```json
{
  "name": "demo",
  "vmSize": "Standard_F2",
  "maxTasksPerNode": 2,
  "poolSize": {
  "dedicatedNodes": {
    "min": 0,
    "max": 0
  },
  "lowPriorityNodes": {
    "min": 2,
    "max": 2
  },
    "autoscaleFormula": "QUEUE"
  },
  "containerImage": "<username>/custom-r-ver",
  "rPackages": {
    "cran": [],
    "github": [],
    "bioconductor": []
  },
  "commandLine": []
}
```

## Using private Docker Hub repositories

This is currently not supported in doAzureParallel.