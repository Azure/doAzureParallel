## Samples
This list of samples in this section highlights various usecases for doAzureParallel. 

If you would like to see more samples, please reach out to [razurebatch@microsoft.com](mailto:razurebatch@microsoft.com).


1. **Monte Carlo Pricing Simulation** [(link)](./montecarlo/montecarlo_pricing_simulation.R)

   The sample walks you through a monte carlo pricing simulation. It illustrates a simple way to use doAzureParallel to parallelize your simuluation-based workloads.

2. **Grid Search with Cross Validation using Caret** [(link)](./caret/caret_example.R)

   The code walks through how to off-load computationally expensive parameter-tuning work to Azure. The parameter tuning is handled by a package called Caret, which uses doAzureParallel as a parallel backend to distibute work to.

   This sample uses the built-in email dataset to evaluate whether or not an email is spam. Using Caret, the code runs through random search using a 10-fold cross validation with 10 repeats. The classification algorithm used in the sample if Random Forest ('rf'), and each run is evaluated for ROC. Using doAzureParallel to create the backend, caret is able to distribute work to Azure and significantly speed up the work.

3. **Mandelbrot Simulation Benchmark** [(link)](./mandelbrot/mandelbrot_performance_test.ipynb)

   This sample uses doAzureParallel to compute the mandelbrot set. The code benchmarks the difference in performance for running local and running on a doAzureParallel cluster size of 10, 20, 40, and 80 cores. 

4. **Using Resource Files to Move Your Data** [(link)](./resource_files/resource_files_example.R)

   This sample illustrates how you can easily pull in data to your cluster directly from blob storage using *resource files*  and then how to write back to blob storage after the job is done. 
   
   In this case, we use the 2016 NY Taxi Dataset where each node in Azure pulls data down from a different month of the dataset to work on, and then uploads the results back to another location in storage.

   The sample also has code that runs through this process locally (both single core and multi-core) to do a benchmark against running the work with doAzureParallel.

5. **Using Sas Tokens for Private Blobs** [(link)](./resource_files/sas_resource_files_example.R)

   This sample walks through using private blobs. The code shows your how to create a Sas token to use when uploading files to your private blob, and then how to use resource files to move your private dataset into your doAzureParallel cluster to execute on.

6. **Distributed ETL with plyr** [(link)](./plyr/plyr_example.R)

   This short sample shows you how you can perform distributed ETL jobs with plyr on top of doAzureParallel's parallel backend.

7. **Using Azure Files** [(link)](./azure_files/readme.md)

   A quick introduction to setting up a distributed file system with Azure Files across all nodes in the cluster
