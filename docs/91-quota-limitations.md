# Azure Limitations

doAzureParallel is built on top of Azure Batch, which starts with a few quota limitations.

## Core Count Limitation

By default, doAzureParallel users are limited to 20 cores in total. (Please refer to the [VM Size Table](./10-vm-sizes.md#vm-size-table) to see how many cores are in the VM size you have selected.)

Our default VM size selection is the **"Standard_F2"** that has 2 core per VM. With this VM size, users are limited to a 10-node pool.

## Number of *foreach* Loops

By default, doAzureParallel users are limited to running 20 *foreach* loops in Azure at a time. This is because each *foreach* loops generates a *job*, of which users are by default limited to 20.

## Increasing Your Core and Job Quota

To increase your default quota limitations, please visit [this page](https://docs.microsoft.com/en-us/azure/batch/batch-quota-limit#increase-a-quota) for instructions.

