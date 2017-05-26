AUTOSCALE_WORKDAY_FORMULA <- paste0(
  "$curTime = time();",
  "$workHours = $curTime.hour >= 8 && $curTime.hour < 18;",
  "$isWeekday = $curTime.weekday >= 1 && $curTime.weekday <= 5;",
  "$isWorkingWeekdayHour = $workHours && $isWeekday;",
  "$TargetDedicatedNodes = $isWorkingWeekdayHour ? %s:%s;")

AUTOSCALE_WEEKEND_FORMULA <- paste0(
  "$isWeekend = $curTime.weekday >= 6 && $curTime.weekday <= 7;",
  "$TargetDedicatedNodes = $isWeekend ? %s:%s;")

AUTOSCALE_MAX_CPU_FORMULA <- "$totalNodes =
  (min($CPUPercent.GetSample(TimeInterval_Minute * 10)) > 0.7) ?
  ($CurrentDedicated * 1.1) : $CurrentDedicated; $totalNodes =
  (avg($CPUPercent.GetSample(TimeInterval_Minute * 60)) < 0.2) ?
  ($CurrentDedicated * 0.9) : $totalNodes;
  $TargetDedicatedNodes = min(%s, $totalNodes)"

AUTOSCALE_QUEUE_FORMULA <- paste0(
  "$samples = $ActiveTasks.GetSamplePercent(TimeInterval_Minute * 15);",
  "$tasks = $samples < 70 ? max(0,$ActiveTasks.GetSample(1)) : max( $ActiveTasks.GetSample(1), avg($ActiveTasks.GetSample(TimeInterval_Minute * 15)));",
  "$maxTasksPerNode = %s;",
  "$round = $maxTasksPerNode - 1;",
  "$targetVMs = $tasks > 0? (($tasks + $round)/ $maxTasksPerNode) : max(0, $TargetDedicated/2) + 0.5;",
  "$TargetDedicatedNodes = max(%s, min($targetVMs, %s));",
  "$TargetLowPriorityNodes = max(%s, min($targetVMs, %s));",
  "$NodeDeallocationOption = taskcompletion;"
)

AUTOSCALE_FORMULA = list("WEEKEND" = AUTOSCALE_WEEKEND_FORMULA,
                         "WORKDAY" = AUTOSCALE_WORKDAY_FORMULA,
                         "MAX_CPU" = AUTOSCALE_MAX_CPU_FORMULA,
                         "QUEUE" = AUTOSCALE_QUEUE_FORMULA)

getAutoscaleFormula <- function(formulaName, dedicatedMin, dedicatedMax, lowPriorityMin, lowPriorityMax, maxTasksPerNode = 1){
  formulas <- names(AUTOSCALE_FORMULA)

  if(formulaName == formulas[1]){
    return(sprintf(AUTOSCALE_WEEKEND_FORMULA, dedicatedMin, dedicatedMax))
  }
  else if(formulaName == formulas[2]){
    return(sprintf(AUTOSCALE_WORKDAY_FORMULA, dedicatedMin, dedicatedMax))
  }
  else if(formulaName == formulas[3]){
    return(sprintf(AUTOSCALE_MAX_CPU_FORMULA, dedicatedMin))
  }
  else if(formulaName == formulas[4]){
    return(sprintf(AUTOSCALE_QUEUE_FORMULA, maxTasksPerNode, dedicatedMin, dedicatedMax, lowPriorityMin, lowPriorityMax))
  }
  else{
    stop("Incorrect autoscale formula: QUEUE, MAX_CPU, WEEKEND, WORKDAY")
  }
}

#' Resize an Azure cloud-enabled cluster.
#'
#' @param cluster Cluster object that was referenced in \code{makeCluster}
#' @param dedicatedMin The minimum number of dedicated nodes
#' @param dedicatedMax The maximum number of dedicated nodes
#' @param lowPriorityMin The minimum number of low priority nodes
#' @param lowPriorityMax The maximum number of low priority nodes
#' @param algorithm Current built-in autoscale formulas: QUEUE, MAX_CPU, WEEKEND, WEEKDAY
#' @param timeInterval Time interval at which to automatically adjust the pool size according to the autoscale formula
#'
#' @examples
#' \dontrun{
#' resizeCluster(cluster, dedicatedMin = 2, dedicatedMax = 6,
#'              dedicatedMin = 2, dedicatedMax = 6, algorithm = "QUEUE", timeInterval = "PT10M")
#' }
#' @export
resizeCluster <- function(cluster,
                          dedicatedMin,
                          dedicatedMax,
                          lowPriorityMin,
                          lowPriorityMax,
                          algorithm = "QUEUE",
                          timeInterval = "PT5M"){
  pool <- getPool(cluster$poolId)

  resizePool(cluster$poolId,
             autoscaleFormula = getAutoscaleFormula(algorithm, dedicatedMin, dedicatedMax, lowPriorityMin, lowPriorityMax, maxTasksPerNode = pool$maxTasksPerNode),
             autoscaleInterval = timeInterval)
}
