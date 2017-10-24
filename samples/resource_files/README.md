# Resource Files

The following two samples show how to use resource files to move data onto and off of the nodes in doAzureParallel. Good data movement techniques, especially for large data, are critical to get your code running quickly and in a scalable fashion.

## Resource Files example

The resource files example is a good starting point on how to manage your files in the cloud and use them in your doAzureParallel cluster. The doAzureParallel package exposes Azure Storage methods to allow you to create, upload and download files from cloud storage.

This samples shows how to work with the well known large data set for the NYC Yellow Taxi Cab data set. It partitions the data set into monthly sets and then iterates over each month individually to create a map of all the pick up locations in NYC. The final result is then again uploaded to cloud storage as an image, and can be downloaded using any standard tools or viewed in a browser.

NOTE: _This sample may cause the cluster to take a bit of time to set up because it needs to download a large amount of data on each node._
