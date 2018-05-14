## doAzureParallel Guide 
This section will provide information about how Azure works, how best to take advantage of Azure, and best practices when using the doAzureParallel package.

1. **Azure Introduction** [(link)](./00-azure-introduction.md)

   Using the *Data Science Virtual Machine (DSVM)* & *Azure Batch*

2. **Getting Started** [(link)](./02-getting-started.md)

   Using the *Getting Started* to create credentials
  
  a.
  
  b. **Programmatically** [(link)](./33-programmatically-generate-config.md)
   Generate credentials and cluster config at runtime programmatically
   
  c. **National Cloud Support** [(link)](./34-national-clouds.md)

   How to run workload in Azure national clouds

3. **Customize Cluster** [(link)](./30-customize-cluster.md)

    Setting up your cluster to user's specific needs
  a. **Virtual Machine Sizes** [(link)](./10-vm-sizes.md)
    How do you choose the best VM type/size for your workload?
  b. **Autoscale** [(link)](./11-autoscale.md)
    Automatically scale up/down your cluster to save time and/or money.
  c. **Building Containers** [(link)](./32-building-containers.md)

4. **Managing Cluster** [(link)](./33-clusters.md)

    Setting up your cluster to user's specific needs
    
    a. Setting up your cluster to user's specific needs

6. **Package Management** [(link)](./20-package-management.md)

   Best practices for managing your R packages in code. This includes installation at the cluster or job level as well as how to use different package providers.

7. **Storage Management** [(link)](./31-long-running-job.md)

  a. **Distributing your Data** [(link)](./21-distributing-data.md)

   Best practices and limitations for working with distributed data.

  b. **Persistent Storage** [(link)](./23-persistent-storage.md)

   Taking advantage of persistent storage for long-running jobs
   
  c. **Accessing Azure Storage through R** [(link)](./23-persistent-storage.md)

   Taking advantage of persistent storage for long-running jobs

8. **Performance Tuning** [(link)](./30-customize-cluster.md)

    Setting up your cluster to user's specific needs
    
  a. **Parallelizing on each VM Core** [(link)](./22-parallelizing-cores.md)
    Best practices and limitations for parallelizing your R code to each core in each VM in your pool
  b. 

9. **Asynchronous Jobs** [(link)](./31-long-running-job.md)

    Best practices for managing long running jobs

10. **Debugging and Troubleshooting** [(link)](./40-troubleshooting.md)

    Best practices on diagnosing common issues

5. **Azure Limitations** [(link)](./12-quota-limitations.md)

   Learn about the limitations around the size of your cluster and the number of foreach jobs you can run in Azure.
   
## Additional Documentation
Read our [**FAQ**](./42-faq.md) for known issues and common questions.
