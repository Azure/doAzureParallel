# Using Azure Files

Azure files is an easy and convenient way to share files and folders across all of the nodes in your doAzureParallel cluster.

This samples shows how to update the cluster configuration to create a new mount drive on each node and mount an Azure File share. More information on creating and managing Azure Files can be found [here](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share). We also recommend [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/) as a great desktop application to manage the data on your Azure File shares from your local machine.

**IMPORTANT** The cluster configuration files requires code to setup the file share. The exact command string to mount the drive can be found [here](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-portal#connect-to-file-share) but remember to _remove_ the 'sudo' part of the command. All custom commands in a cluster are automatically run with elevated permissions and adding sudo will cause an error at node setup time.

**IMPORTANT** Since all of your processes are run within a container in the node, the number of directories mounted on the container are limited. Currently, only /mnt/batch/tasks is mounted into the container, so when you mount a drive it must be under that path. For example /mnt/batch/tasks/my/file/share. Note that any new directories under /mnt/batch/tasks __must first be created__ before mounting. Please see the provided sample_cluster.json as an example.

**IMPORTANT** Mounting Azure Files on non-azure machines has limited support. This service should be used for creating a shared files system in your doAzureParallel cluster. For managing files from your local machine we recommend [Azure Storage Explorer](https://azure.microsoft.com/en-us/features/storage-explorer/)

For large data sets or large traffic applications be sure to review the Azure Files [scalability and performance targets](https://docs.microsoft.com/en-us/azure/storage/common/storage-scalability-targets#scalability-targets-for-blobs-queues-tables-and-files).

For very large data sets we recommend using Azure Blobs. You can learn more in the [persistent storage](../../docs/23-persistent-storage.md) and [distrubuted data](../../docs/21-distributing-data.md) docs.
