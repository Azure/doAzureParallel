# Mandelbrot

Calculating the Mandelbrot set is an embarassingly parallel problem that can easily be done using doAzureParallel. This sample shows how to set up a simple cluster of two nodes, generate the Mandelbrot set and render an image of it on the screen.

Also included in this directory is a notebook with a benchmark sample to show the performance difference of large Mandelbrot computations on your local workstation vs using doAzureParallel. This is a good sample to use if you would like to test out different VM sizes, maxTasksPerNode or chunk size settings to try to optimize your cluster.
