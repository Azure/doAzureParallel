# Autoscale

The doAzureParallel package lets you autoscale your cluster in several ways, letting you save both time and money by automatically adjusting the number of nodes in your cluster to fit your job's demands.

This package pre-defines a few autoscale options (or *autoscale formulas*) that you can choose from and use in your JSON configuration file.

The options are:
 - "QUEUE"
 - "QUEUE_AND_RUNNING"
 - "WORKDAY"
 - "WEEKEND"
 - "MAX_CPU"

*See more [below](./11-autoscale.md#autoscale-formulas) to learn how each of these settings work.*

When configuring your autoscale formula, you also need to set the mininum number of nodes and the maximum number of nodes for both low priority VMs and dedicated VMs. Each autoscale formula will use these as parameters to set it's upper and lower bound limits for pool size. 

By default, doAzureParallel uses autoscale and uses the QUEUE autoscale formula. This can be easily configured:

```javascript
{
  ...  
  "poolSize": {
    "dedicatedNodes": {
        "min": 2,
        "max": 2
    },
    "lowPriorityNodes": { 
        "min": 1,
        "max": 10
    },
    "autoscaleFormula": "QUEUE"
  },
  ...
}
```

## Autoscale Formulas:

For five autoscale settings are can be selected for different scenarios:

| Autoscale Formula | Description | 
| ----------------- |:----------- |
| QUEUE | This formula will scale up and down the pool size based on the amount of work in the queue |
| QUEUE_AND_RUNNING | This formula will scale up and down the pool size based on the amount of running tasks and active tasks in the queue  |
| WORKDAY | This formula  will adjust your pool size based on the day/time of the week. If it's a weekday, during working hours (8am - 6pm), the pool size will increase to maximum size (maxNodes). Otherwise it will default to the minimum size (minNodes). |
| WEEKEND | This formula  will adjust your pool size based on the day/time of the week. At the beginning of the weekend (Saturday), the pool size will increase to maximum size (maxNodes). At the end of Sunday, the pool will shrink down to the minimum size (minNodes). | 
| MAX_CPU | This formula will adjust your pool size based on the minimum average CPU usage during the last 10 minutes - if the minimum average CPU usage was above 70%, the cluster size will increase 1.1X times. | 

## When to use Autoscale

Autoscaling can be used in various scenarios when using the doAzureParallel package. 

### Time-based scaling

For time-based autoscaling adjustments, you would want to autoscale your pool in anticipation of incoming work. If you know that you want your cluster ready during the workday, you can select the WORKDAY formula and expect your clster to be ready when you get in for work, or expect your cluster to automatically shut down after work hours.

### Task-based scaling

In contrast, task-based autoscaling adjustments are ideal for when you don't have a pre-defined schedule for running work, and simply want your cluster to scale up or scale down according to your task queue. 

A good example for this is when you want to execute long-running jobs: you can kick off a long-running foreach loops at the end of the day without worrying about having to shut down your cluster when the work is done. With Task-based scaling (QUEUE), the cluster will automatically decrease in size until the minNode property is met. This way you don't have to worry about monitoring your job and manually shutting down your cluster.

To take advantage of this, you will also need to understand how to retreive the results of your foreach loop from storage. See [here](./23-persistent-storage.md) to learn more about it.

## Static Clusters

If you do not want your cluster to autoscale, you can simply set the property min-nodes equal to max-nodes for both low priority and dedicated VMs. For example, if you wanted a static cluster of 10 nodes, 3 dedicated and 7 low priority, you can configure your cluster this way:

```javascript
{
  ...  
  "poolSize": {
    "dedicatedNodes": {
        "min": 3,
        "max": 3
    },
    "lowPriorityNodes": { 
        "min": 7,
        "max": 7
    },
    "autoscaleFormula": "QUEUE"
  },
  ...
}
```

---

doAzureParallel's autoscale comes from Azure Batch's autoscaling capabilities. To learn more about it, you can visit the [Azure Batch auto-scaling documentation](https://docs.microsoft.com/en-us/azure/batch/batch-automatic-scaling).

