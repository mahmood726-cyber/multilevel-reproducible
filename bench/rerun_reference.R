# Refit the archived final corpus; no data discovery or network access.
# Requires existing metafor and jsonlite installations. Run from repository root.
library(metafor)
library(jsonlite)
stopifnot(as.character(packageVersion('metafor')) == '5.2.1')
args <- commandArgs(trailingOnly=TRUE)
dest <- if(length(args)) args[1] else 'rerun'
dir.create(dest, recursive=TRUE, showWarnings=FALSE)
corpus <- fromJSON('data/corpus.json', simplifyVector=FALSE)
metadata <- fromJSON('results/reference.json', simplifyVector=FALSE)
helper <- readLines('bench/reference.R', warn=FALSE)
# Reuse the historical full-precision JSON serializer, without running discovery.
eval(parse(text=helper[seq_len(grep('^inventory<-',helper)[1]-1)]))
out <- list()
for(name in names(corpus)) {
  d <- do.call(rbind,lapply(corpus[[name]],as.data.frame,stringsAsFactors=FALSE))
  control <- if(name == 'dat.maire2019') list(optimizer='optim',optmethod='BFGS',reltol=1e-14) else list(rel.tol=1e-10)
  warnings <- character()
  fit <- withCallingHandlers(rma.mv(y,v,random=~1|cluster/id,data=d,method='REML',sparse=name!='dat.maire2019',control=control),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
  w<-1/d$v;typ<-(nrow(d)-1)/(sum(w)-sum(w*w)/sum(w));den<-sum(fit$sigma2)+typ
  vals<-list(mu=as.numeric(coef(fit)),se=as.numeric(fit$se),ciLo=as.numeric(fit$ci.lb),ciHi=as.numeric(fit$ci.ub),sigma2Between=fit$sigma2[1],sigma2Within=fit$sigma2[2],logLik=as.numeric(logLik(fit)),z=as.numeric(fit$zval),p=as.numeric(fit$pval),Q=fit$QE,Qp=fit$QEp,I2_study=fit$sigma2[1]/den,I2_within=fit$sigma2[2]/den,I2_sampling=typ/den)
  entry<-metadata[[name]];entry$values<-vals;entry$warnings<-as.list(warnings)
  stopifnot(entry$rows==nrow(d),entry$clusters==length(unique(d$cluster)))
  out[[name]]<-entry
  cat(name,'OK\n')
}
savejson(out,file.path(dest,'reference.json'))
file.copy('data/corpus.json',file.path(dest,'corpus.json'),overwrite=TRUE)
cat(length(out),'reference configurations refitted\n')
