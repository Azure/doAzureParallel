# Running Commands when the Cluster Starts

The commandline property in the cluster configuration file allows users to prepare the nodes' environments. For example, users can perform actions such as installing applications that your foreach loop requires.

Note: Batch clusters are run with Centos-OS Azure DSVMs.

Note: All commands are already run as the sudo user, so there is no need to append sudo to your command line. _Commands may fail if you add the sudo user as part of the command._

```javascript
{
  ...
  "commandLine": [
      "yum install -y gdal gdal-devel",
      "yum install -y proj-devel",
      "yum install -y proj-nad",
      "yum install -y proj-epsg"
    ]
}
```
