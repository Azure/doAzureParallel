## doAzureParallel Guide 
This section will provide information about how Azure works, how best to take advantage of Azure, and best practices when using the doAzureParallel package.

1. **Azure Introduction** [(link)](./00-azure-introduction.md)

   Using the *Data Science Virtual Machine (DSVM)* & *Azure Batch* 

2. **Virtual Machine Sizes** [(link)](./10-vm-sizes.md)

   How do you choose the best VM type/size for your workload?

3. **Autoscale** [(link)](./11-autoscale.md)

   Automatically scale up/down your cluster to save time and/or money.

4. **Azure Limitations** [(link)](./12-quota-limitations.md)

   Learn about the limitations around the size of your cluster and the number of foreach jobs you can run in Azure.
   
4. **Package Management** [(link)](./20-package-management.md)

   Best practices for managing your R packages in code. This includes installation at the cluster or job level as well as how to use different package providers.
   
5. **Distributing your Data** [(link)](./21-distributing-data.md)

   Best practices and limitations for working with distributed data.
   
6. **Parallelizing on each VM Core** [(link)](./22-parallelizing-cores.md)

   Best practices and limitations for parallelizing your R code to each core in each VM in your pool 

7. **Persistent Storage** [(link)](./23-persistent-storage.md)

   Taking advantage of persistent storage for long-running jobs

8. **Customize Cluster** [(link)](./30-customize-cluster.md)

   Setting up your cluster to user's specific needs

9. **Long Running Job** [(link)](./31-long-running-job.md)

   Best practices for managing long running jobs

## Additional Documentation
Take a look at our [**Troubleshooting Guide**](./40-troubleshooting.md) for information on how to diagnose common issues.

Read our [**FAQ**](./42-faq.md) for known issues and common questions.
