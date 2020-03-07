#.libPaths( c( .libPaths(), "/gpfs/data1/cmongp/pranav/EPIC_SubX_Simulations/libs/") )
library(parallel)
source("/gpfs/data1/cmongp/pranav/EPIC_SubX_Simulations/scripts/imporved_EPIC/running_EPIC_helper.R")
source("/gpfs/data1/cmongp/pranav/EPIC_SubX_Simulations/scripts/helper_functions_v2.R")
library(rgdal)
library(raster)
library(reshape2)
library(sp)
#library(filesstrings)
#library(ff)


models = c("GEOS_V2p1")

years = c("2013", "2014")
months = c("08", "09")
crop_types = c("base_2012_nirr_corn")


log_filename = "gsapp1_corn_GEOS_nirr.txt"
run_threads = 39
log_outpath = "/gpfs/data1/cmongp/pranav/EPIC_SubX_Simulations/new_simulations/logs/nirr_corn_log/"
if (!dir.exists(log_outpath)){
  dir.create(log_outpath, recursive = TRUE)  
}

counter = 4

for (model in models){
  
  for (year in years){
    
      
    for(month in months){
      
      initialization_date = get_initialization_date_2(model, year, month)  
      
      if(year == "2013" && month == "08"){
        ensemble_range = 4
      }
      else{
        ensemble_range = 1:4
      }
      
      for (ensemble in ensemble_range){
        
        for(crop_type in crop_types){
          
          start_time = Sys.time()
          print(paste0("Starting with model: ", model, " ensemble: ", ensemble, " year: ", year, " month: ", month, " crop_type: ", crop_type))
          foldername = paste0(crop_type, '_', initialization_date, '_', ensemble)
          path = paste0('/gpfs/data1/cmongp/pranav/EPIC_SubX_Simulations/new_simulations/', model,'/EPIC_runs/',foldername,'/')
          temp_dir = paste0("final_gsapp6_temp_", foldername)
          run_EPIC(path, run_threads, temp_dir)
          f = file(paste0(log_outpath,log_filename), open = 'a')
          text = paste0(counter, ". Completed model: ", model, " ensemble: ", ensemble, " year: ", year, " month: ", month, " crop_type: ", crop_type, " at ", Sys.time(), " Total time taken : ", Sys.time() - start_time)
          writeLines(text, f)
          close(f)
          counter = counter + 1
        }  
      }  
    }    
    
    
    
  }  
}



f = file(paste0(log_outpath,log_filename), open = 'a')
text = "All simulations are complete!"
writeLines(text, f)
close(f)
