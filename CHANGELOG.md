# Change Log
## [0.6.1] 2017-11-13
### Added
- Support for users to use programmatically generated crdentials and cluster config

## [0.6.0] 2017-11-03
### Added
- Support for users to run custom versions of R via Docker containers
- GitHub and BioConductor support as parameters in the foreach

### Changed
- [BREAKING CHANGE] Host OS distribution is now Debian instead of CentOS
- [BREAKING CHANGE] Command line no longer updates the environment of R
- [BREAKING CHANGE] Default version of R changed from MRO 3.3.2 to latest version of CRAN R

### Fixed
- Packages installed in foreach are only present and visible to a single foreach loop and then deleted from the cluster
- Linux clients would get stuck waiting for the job to finish when using the .packages() option in the foreach loop

## [0.5.1] 2017-09-28
### Added
- Support for users to get job and job results for long running job
### Changed
- [BREAKING CHANGE] Update get job list to take state filter and return job status in a data frame

## [0.4.3] 2017-09-28
### Fixed
- Allow merge task to run on task failures

## [0.4.2] 2017-09-08
### Added
- Support for users to get files from nodes and tasks
- Documentation on debugging and troubleshooting
### Changed
- Show the job preparation status
### Fixed
- Fix pool creation when a deleting pool has the same name
- Fail faster when a broken installation happens

## [0.4.1] 2017-08-29
### Fixed
- Change github authentication token type in cluster configuration file

## [0.4.0] 2017-08-22
### Added
- Custom Scripts: Allows users to run commands on the command prompt when nodes boots up
- Output Files: Able to persistently upload files to Azure Storage after task completion
- Added cluster configuration validation at runtime
- Enable/Disable merge task from collecting all the tasks into one list
### Changed
- Enable reduce function based on chunk size
- Support backwards compatibility for older versions of the cluster configuration
- Improve R package installation using scripts instead of creating R package installation command lines on the fly
- Automatically load libraries defined in the foreach loop
### Fixed
- Paging through all tasks in `waitForTasksToComplete` function allow jobs to not fail early
- Added `::` import operators to fix NAMESPACE problems

## [0.3.0] 2017-05-22
### Added
- [BREAKING CHANGE] Two configuration files for easier debugging - credentials and cluster settings
- [BREAKING CHANGE] Added low priority virtual machine support for additional cost saving
- Added external method for setting chunk size (SetChunkSize)
- Added getJobList function to check the status of user's jobs
- Added resizeCluster function to allow users to change their autoscale formulas on the fly
