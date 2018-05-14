## doAzureParallel Guide 
This section will provide information about how Azure works, how best to take advantage of Azure, and best practices when using the doAzureParallel package.

1. **Azure Introduction** [(link)](./00-azure-introduction.md)

   Using the *Data Science Virtual Machine (DSVM)* & *Azure Batch*

2. **Getting Started** [(link)](./02-getting-started.md)

    Using the *Getting Started* to create credentials
  
  i. **Cluster and Credentials Objects** [(link)](./33-programmatically-generate-config.md)
   
    Generate credentials and cluster configuration objects at runtime programmatically
   
  ii. **National Cloud Support** [(link)](./34-national-clouds.md)
  
    How to run workload in Azure national clouds

3. **Customize Cluster** [(link)](./30-customize-cluster.md)

    Setting up your cluster to user's specific needs

  i. **Virtual Machine Sizes** [(link)](./10-vm-sizes.md)
  
      How do you choose the best VM type/size for your workload?

  ii. **Autoscale** [(link)](./11-autoscale.md)
  
      Automatically scale up/down your cluster to save time and/or money.
  
  iii. **Building Containers** [(link)](./32-building-containers.md)
    
      Creating your own Docker containers for reproducibility

4. **Managing Cluster** [(link)](./33-clusters.md)

    Managing your cluster's lifespan

5. **Customize Job**

    Setting up your job to user's specific needs
    
  i. **Asynchronous Jobs** [(link)](./31-long-running-job.md)

      Best practices for managing long running jobs
  
  ii. **Foreach Azure Options** [(link)](./)
  
      Use Azure package-defined foreach options to improve performance and user experience
  
  iii. **Error Handling** 
      
      How Azure handles errors in your Foreach loop? 
    
6. **Package Management** [(link)](./20-package-management.md)

   Best practices for managing your R packages in code. This includes installation at the cluster or job level as well as how to use different package providers.

7. **Storage Management**

  i. **Distributing your Data** [(link)](./21-distributing-data.md)

    Best practices and limitations for working with distributed data.

  ii. **Persistent Storage** [(link)](./23-persistent-storage.md)

    Taking advantage of persistent storage for long-running jobs
   
  iii. **Accessing Azure Storage through R** [(link)](./23-persistent-storage.md)

    Manage your Azure Storage files via R 

8. **Performance Tuning** [(link)](./50-performance-tuning.md)

    Best practices on optimizing your Foreach loop

9. **Debugging and Troubleshooting** [(link)](./40-troubleshooting.md)

    Best practices on diagnosing common issues

10. **Azure Limitations** [(link)](./12-quota-limitations.md)

    Learn about the limitations around the size of your cluster and the number of foreach jobs you can run in Azure.
   
## Additional Documentation
Read our [**FAQ**](./42-faq.md) for known issues and common questions.
