# run_EPIC
R scripts for running EPIC model following SEIMF.

# Background
running_EPIC_helper() function runs the EPIC software in in multi-core session. Each process creates temporary folder where all computation is performed and output is created. The output files are then transferred back to the original folder and temporary folders are deleted. 

# How To Use
Follow the run_EPICs_Example.R for running the EPIC simulations for desired models, dates, crops etc. 
