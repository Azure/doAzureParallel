# Azure Limitations

doAzureParallel is built on top of Azure Batch, which starts with a few quota limitations.

## Core Count Limitation

By default, doAzureParallel users are limited to 20 dedicated cores and 100 low priorty core quotas. (Please refer to the [VM Size Table](./10-vm-sizes.md#vm-size-table) to see how many cores are in the VM size you have selected.)

Our default VM size selection is the **"Standard_F2"** that has 2 core per VM.

## Number of *foreach* Loops

By default, doAzureParallel users are limited to running 300 *foreach* loops in Azure at a time. This is because each *foreach* loops generates a *job*, of which users are by default limited to 300. To go beyond that, users need to wait for their *jobs* to complete.

## Increasing Your Quota

To increase your default quota limitations, please visit [this page](https://docs.microsoft.com/en-us/azure/batch/batch-quota-limit#increase-a-quota) for instructions.

