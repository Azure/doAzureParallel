# Change Log
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
