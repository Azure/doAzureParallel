# Using Azure Files

Azure files is an easy and convenient way to share files and folders across all of the nodes in your doAzureParallel cluster.

This samples shows how to update the cluster configuration to create a new mount drive on each node and mount an Azure File share. More information on creating and managing Azure Files can be found [here](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share).

**IMPORTANT** The cluster configuration files requires code to setup the file share. The exact command string to mount the drive can be found [here](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-portal#connect-to-file-share) but remember to _remove_ the 'sudo' part of the command. All custom commands in a cluster are automatically run with elevated permissions and adding sudo will cause an error at node setup time.

For large data sets or large traffic applications be sure to review the Azure Files [scalability and performance targets](https://docs.microsoft.com/en-us/azure/storage/common/storage-scalability-targets#scalability-targets-for-blobs-queues-tables-and-files).

For very large data sets we recommend using Azure Blobs. You can learn more in the [persistent storage](../../docs/23-persistent-storage.md) and [distrubuted data](../../docs/21-distributing-data.md) docs.