library(parallel) 
library(R.utils) 
library(tools) 
library(dplyr) 
library(doSNOW)



run.exe <- function(exe.in, wd.in, timeout=Inf){
  
  if(grepl("linux", R.Version()$os)){
    if(is.infinite(timeout)){
      temporary_wd=getwd()
      setwd(paste(wd.in,'/',sep=''))
      out <- system2(exe.in, args=c('cd', paste(wd.in,'/',sep='')), stdout=T)
      setwd(temporary_wd)
    }else{
      temporary_wd=getwd()
      setwd(paste(wd.in,'/',sep='')) 
      out <- system(paste0(c('timeout', paste(timeout, 's', sep=''), exe.in, 'cd', paste(wd.in,'/',sep='')), collapse=' '), intern=T, show.output.on.console=F)
      setwd(temporary_wd)
    }
    
  }else{
    options(useFancyQuotes = FALSE)
    command <- paste( 'cd', dQuote(wd.in), '& ', dQuote(exe.in) )
    out <- withTimeout(shell( command, intern=T ), timeout=timeout, onTimeout='warning')
    
    if(is.finite(timeout)){
      procs <- system('powershell -command \"get-process EPIC1102*\"', intern=T)
      if(length(procs) > 0){
        procs <- procs[procs != '' & !grepl('---', procs)]
        procs <- read.table(text=procs, header=T)
        procs <- subset(procs, CPU.s. > timeout)
        if(nrow(procs) > 0){pskill(procs$Id, SIGTERM)}
      }
    }
    
  }
  
  indices.start <- grep('RUN=', out)
  indices.end <- grep('RUN TIME', out)
  count.start <- length(indices.start)
  count.end <- length(indices.end)
  if(count.start==0){
    return(3) #failure before start of simulation
  }else if(count.end==0){
    return(2) #failure before finishing any treatments
  }else if(count.start>count.end | max(indices.end)<length(out)){
    return(1) #failure after at least one succesful treatment
  }else{
    return(0) #success
  } 
}



run.epic.parallel <- function(wd.dir, epic.dir, threads=(detectCores()-1), tmp.dir=paste(wd.dir,'/../../epic.par.tmp2',sep=''), out.ext='OUT|ACM|SUM|DHY|DPS|MFS|MPS|ANN|SOT|DTP|MCM|DCS|SCO|ACN|DCN|DWT|ACY|ACO|DSL|MWC|DGN|ABR|ATG|MSW|APS|DWC|DHS|R84|APP|RTS|DSC|DNC', timeout=Inf){
  require(dplyr)
  
  out.ext <- toupper(out.ext)
  dir <- list(wd=wd.dir, tmp=tmp.dir)
  gen <- list(threads=threads, out.ext=out.ext)
  #------------------------------------
  #read epicrun and set thread assignments
  epicrun.orig <- readLines(paste(dir$wd,'EPICRUN.DAT',sep='/'))
  read.n <- grep('xxx|XXX',epicrun.orig) - 1
  read.n <- min(read.n, length(epicrun.orig))
  gen$threads <- min(gen$threads, read.n)
  if( length(read.n) == 0 ){read.n <- grep('#',epicrun.orig) - 1}
  if( length(read.n) == 0 ){read.n <- length(epicrun.orig)}
  epicrun.orig <- data.frame(line=epicrun.orig[1:read.n])
  gen$threads <- min(gen$threads, nrow(epicrun.orig))
  epicrun.orig$thread <- rep(seq(1,gen$threads),ceiling(nrow(epicrun.orig)/gen$threads))[1:nrow(epicrun.orig)]
  #create output directory
  if(dir.exists(dir$tmp)){unlink(dir$tmp,recursive=T,force=T)}
  dir.create(dir$tmp)
  cl <- makeCluster(getOption("cl.cores", gen$threads))
  clusterExport(cl=cl, list=c('clear.epic.outputs','run.exe','dir','bind_rows','epicrun.orig','epic.dir','gen','withTimeout','timeout','pskill','SIGTERM'), envir=environment())
  out <- parLapply(cl, 1:gen$threads, function(i){
    # f <- files.cur[1]
    dir.cur <- paste(dir$tmp,'/','temp.',i,sep='')
    if(dir.exists(dir.cur)){unlink(dir.cur,recursive=T,force=T)}
    dir.create(dir.cur)
    files.cur <- list.files(dir$wd, recursive=F)
    #system(paste0("mv ", dir.wd, " ", dir.cur))
    lapply(files.cur,function(x){ file.copy(from=paste(dir$wd,x,sep='/'), to=dir.cur, recursive=T) })
    clear.epic.outputs(dir.cur)
  })
  
  #run threads, writing new epicrun for each run
  out <- parLapply(cl, 1:gen$threads, function(i){
    dir.cur <- paste(dir$tmp,'/','temp.',i,sep='')
    epicrun.cur <- subset(epicrun.orig, thread==i)
    success <- lapply(1:nrow(epicrun.cur),function(j){
      run.cur <- subset(epicrun.cur,select=c(line))[j,]
      write.table(run.cur, file=paste(dir.cur,'EPICRUN.DAT',sep='/'),col.names=F,row.names=F,quote=F)
      runname.cur <- unlist( strsplit(as.character(run.cur),'[ ]+') )[1]
      success <- run.exe(epic.dir, wd.in=dir.cur, timeout=timeout)
      return(data.frame(runname=runname.cur,success=success))
    })
    files.copy <- list.files(dir.cur,paste('.',gen$out.ext,collapse='|',sep=''))
    system(paste0("mv ", dir.cur, " ", dir$wd))
    #lapply(files.copy, function(f) file.copy(from=paste(dir.cur,f,sep='/'), to=dir$wd, overwrite=T))
    #unlink(dir.cur,recursive=T,force=T)
    feedback <- Reduce(function(x,y) rbind(x,y), success)
    feedback <- cbind(dir=dir.cur,feedback)
    return(feedback)
  })
  stopCluster(cl)
  out <- Reduce(function(x,y) rbind(x,y), out)
  write.table(out,file=paste(dir$wd,'Simulation report.txt',sep='/'),col.names=T,row.names=F,quote=F)
  if(nrow(subset(out,success>0))>0){warning(paste(nrow(subset(out,success>0)),'failures'))}
  unlink(dir$tmp,recursive=T,force=T)
  
  return(out)
}


clear.epic.outputs <- function(dir.cur='', exts=c('OUT','ACM','SUM','DHY','DPS','MFS','MPS','ANN','SOT','DTP','MCM','DCS','SCO','ACN','DCN','DWT','ACY','ACO','DSL','MWC','DGN','ABR','ATG','MSW','APS','DWC','DHS','R84','APP','RTS','DSC','51','SCN','DNC')){
  require(dplyr)
  
  files.del <- list.files(dir.cur, paste('\\.', exts, collapse='|', sep=''), full.names=T)
  df.out <- lapply(files.del, function(f){
    df.out <- file.remove(f)
    df.out <- data.frame(file=f, success=df.out, stringsAsFactors=F)
    return(df.out)
  })
  
  return(bind_rows(df.out))
}


run_EPIC = function(path, run_threads, temp_dir){
  
  gen <- list( threads=run_threads
               , epic.exe='./EPIC1102_20180607'
               , timeout=60)
  
  
  run <- run.epic.parallel(wd.dir=path, epic.dir=paste(path, gen$epic.exe, sep='/'), threads=gen$threads, tmp.dir=paste(path,'/../../',temp_dir,sep=''),  timeout=gen$timeout)
  
}

