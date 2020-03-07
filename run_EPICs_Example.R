#####################################################################
# This is a example Run for EPICs.
# This script calls the run_EPICs() function for given inputs.  
# User can make the modification based on  case in hand.
# ###################################################################



#Import the standard libs as required. 
library(parallel)
library(rgdal)
library(raster)
library(reshape2)
library(sp)

#Import any user-defined libraries if required. 
source("Path/to/User Defined lib")

#Define threads 
run_threads = 39


#Its better to keep log of EPIC runs in some file. 
log_filename = "log_file.txt"
log_outpath = "path/to/log_file"
if (!dir.exists(log_outpath)){
  dir.create(log_outpath, recursive = TRUE)  
}


#You can run EPICs for multiple models, years, months, types of crops if you like.
models = c("Model 1", "Model 2")
years = c("2013", "2014")
months = c("08", "09")
crop_types = c("corn", "soy")

#If you are using weather model (or any other model for that matter), you can choose ensembles if any. 
ensemble_range = 1 : 20


#Run the simulations in the order preffered.
for (model in models){
  for (year in years){
    for(month in months){
      for (ensemble in ensemble_range){
        for(crop_type in crop_types){
          
          #Measure the time for each run.
          start_time = Sys.time()
          
          #Produce the folder name where Each EPIC .exe is situated.
          #Foldername might be the combination of model name, year, month, ensemble, crop_type etc.
          foldername = paste0('/path/to/EPIC EXE/') 
          
          #Path to each foldername.
          #Path might be the combination of model name, year, month, ensemble, crop_type etc.
          path = paste0('Path/upto/folder/',foldername,'/')
          
          #Temp directory name preffered for each EPIC Run.
          #Temp directory might be the combination of model name, year, month, ensemble, crop_type etc.
          temp_dir = paste0("final_gsapp6_temp_", foldername)
          
          
          #Call the run_EPIC function based on all the inputs.
          run_EPIC(path, run_threads, temp_dir)
          
          #Once the run is performed, Make a log in logfile.
          f = file(paste0(log_outpath,log_filename), open = 'a')
          text = paste0("Successfully completed one more simulation!")
          writeLines(text, f)
          close(f)
        }  
      }  
    }    
  }  
}



f = file(paste0(log_outpath,log_filename), open = 'a')
text = "All simulations are complete!"
writeLines(text, f)
close(f)
