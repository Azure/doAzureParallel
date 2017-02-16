# Package Management

The doAzureParallel package allows you to install packages to your pool in two ways:
- Installing on pool creation
- Installing per-Foreach loop

## Installing Packages on Pool Creation
You can install packages by specifying the package(s) in your JSON pool configuration file. This will then install the specified packages at the time of pool creation.

```R
{
  ...
  "rPackages": {
    "cran": {
      "source": "http://cran.us.r-project.org",
      "name": ["some_cran_package_name", "some_other_cran_package_name"]
    },
    "github": ["github_username/github_package_name", "another_github_username/another_github_package_name"]
  },
  ...
}
```

## Installing Packages per-Foreach Loop
You can also install packages by using the **.packages** option in the *foreach* loop. Instead of installing packages during pool creation, packages (and it's dependencies) can be installed before each iteration in the loop is run on your Azure cluster.

To install a single package:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, .packages='some_package') %dopar% { ... }
```

To install multiple packages:
```R
number_of_iterations <- 10
results <- foreach(i = 1:number_of_iterations, .packages=c('package_1', 'package_2')) %dopar% { ... }
```

Installing packages from github using this method is not yet supported.

## Uninstalling packages
Uninstalling packages from your pool is not supported. However, you may consider rebuilding your pool.
