library(metafor); library(metadat)
d<-transform(dat.maire2019$dat,y=s1,v=vars1,cluster=site,id=seq_len(nrow(dat.maire2019$dat)))
options(digits=17)
for(control in list(list(),list(rel.tol=1e-10),list(rel.tol=1e-14,x.tol=1e-12,eval.max=10000,iter.max=10000),list(optimizer='optim',optmethod='BFGS',reltol=1e-14))) {
 f<-try(rma.mv(y,v,random=~1|cluster/id,data=d,method='REML',control=control),silent=TRUE)
 if(inherits(f,'try-error')){print(f);next}
 print(control);print(c(mu=coef(f),se=f$se,between=f$sigma2[1],within=f$sigma2[2],logLik=as.numeric(logLik(f))))
 if(identical(control$optimizer,'optim')) {
  w<-1/d$v;typ<-(nrow(d)-1)/(sum(w)-sum(w*w)/sum(w));den<-sum(f$sigma2)+typ
  vals<-c(mu=as.numeric(coef(f)),se=f$se,ciLo=f$ci.lb,ciHi=f$ci.ub,sigma2Between=f$sigma2[1],sigma2Within=f$sigma2[2],logLik=as.numeric(logLik(f)),z=f$zval,p=f$pval,Q=f$QE,Qp=f$QEp,I2_study=f$sigma2[1]/den,I2_within=f$sigma2[2]/den,I2_sampling=typ/den)
  writeLines(paste0('{',paste(sprintf('"%s":%.17g',names(vals),vals),collapse=','),'}'),'maire-bfgs-reference.json')
 }
}
f<-try(rma.mv(y/100,v/10000,random=~1|cluster/id,data=d,method='REML',control=list(rel.tol=1e-12)),silent=TRUE)
if(inherits(f,'try-error')){print(f);quit(status=0)}
cat('RESCALED INPUT (backtransformed)\n');print(c(mu=coef(f)*100,se=f$se*100,between=f$sigma2[1]*10000,within=f$sigma2[2]*10000,logLik=as.numeric(logLik(f))-(f$k-1)*log(100)))
write.csv(data.frame(mu=as.numeric(coef(f))*100,se=f$se*100,ciLo=f$ci.lb*100,ciHi=f$ci.ub*100,sigma2Between=f$sigma2[1]*10000,sigma2Within=f$sigma2[2]*10000,logLik=as.numeric(logLik(f))-(f$k-1)*log(100)),'maire-scaled-reference.csv',row.names=FALSE)
