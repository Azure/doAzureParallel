#!/usr/bin/Rscript
args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = "out.txt"
}

AZ_BATCH_JOB_PREP_DIR <- args[1]
AZ_BATCH_TASK_WORKING_DIR <- args[2]
AZ_BATCH_JOB_ID <- args[3]

N <- args[4]
numOfTasks <- args[5]

azbatchenv <- readRDS(paste0(AZ_BATCH_JOB_PREP_DIR, "/", AZ_BATCH_JOB_ID, ".rds"))

for(package in azbatchenv$packages){
  library(package, character.only = TRUE)
}
parent.env(azbatchenv$exportenv) <- globalenv()

enableCloudCombine <- azbatchenv$enableCloudCombine
cloudCombine <- azbatchenv$cloudCombine

if(typeof(cloudCombine) == "list" && enableCloudCombine){
  results <- vector("list", numOfTasks)
  count <- 1
  tryCatch({
    for(i in 1:N){
      task_result <- paste0(AZ_BATCH_TASK_WORKING_DIR, "/result/", AZ_BATCH_JOB_ID, "-task", i, "-result.rds")
      task <- readRDS(task_result)
      
      for(t in 1 : length(task)){
        results[count] <- task[t]
        count <- count + 1
      }
    }
    
    saveRDS(results, file = paste0(AZ_BATCH_TASK_WORKING_DIR, "/", paste0(AZ_BATCH_JOB_ID, "-merge-result.rds")))
  }, error = function(e) {
    print(e)
  })
} else {
  # Work needs to be done for utilizing custom merge functions
}

quit(save = "yes", status = 0, runLast = FALSE)
