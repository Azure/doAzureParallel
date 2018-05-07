## doAzureParallel Guide 
This section will provide information about how Azure works, how best to take advantage of Azure, and best practices when using the doAzureParallel package.

1. **Azure Introduction** [(link)](./00-azure-introduction.md)

   Using the *Data Science Virtual Machine (DSVM)* & *Azure Batch*

2. **Getting Started** [(link)](./02-getting-started.md)

   Using the *Getting Started* to create credentials 

3. **Virtual Machine Sizes** [(link)](./10-vm-sizes.md)

   How do you choose the best VM type/size for your workload?

4. **Autoscale** [(link)](./11-autoscale.md)

   Automatically scale up/down your cluster to save time and/or money.

5. **Azure Limitations** [(link)](./12-quota-limitations.md)

   Learn about the limitations around the size of your cluster and the number of foreach jobs you can run in Azure.
   
6. **Package Management** [(link)](./20-package-management.md)

   Best practices for managing your R packages in code. This includes installation at the cluster or job level as well as how to use different package providers.
   
7. **Distributing your Data** [(link)](./21-distributing-data.md)

   Best practices and limitations for working with distributed data.
   
8. **Parallelizing on each VM Core** [(link)](./22-parallelizing-cores.md)

   Best practices and limitations for parallelizing your R code to each core in each VM in your pool 

9. **Persistent Storage** [(link)](./23-persistent-storage.md)

   Taking advantage of persistent storage for long-running jobs

10. **Customize Cluster** [(link)](./30-customize-cluster.md)

   Setting up your cluster to user's specific needs

11. **Long Running Job** [(link)](./31-long-running-job.md)

   Best practices for managing long running jobs

12. **Programmatically generated config** [(link)](./33-programmatically-generate-config.md)

   Generate credentials and cluster config at runtime programmatically

13. **National Cloud configuration" [(link)](./34-national-clouds.md)

   How to run workload in Azure national clouds

## Additional Documentation
Take a look at our [**Troubleshooting Guide**](./40-troubleshooting.md) for information on how to diagnose common issues.

Read our [**FAQ**](./42-faq.md) for known issues and common questions.
