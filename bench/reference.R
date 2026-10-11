library(metafor); library(metadat)
options(warn=1)
json <- function(x) {
 if(is.null(x)) return('null')
 if(is.data.frame(x)) return(paste0('[',paste(vapply(seq_len(nrow(x)),function(i)json(as.list(x[i,,drop=FALSE])),''),collapse=','),']'))
 if(is.list(x)) { vals<-vapply(x,json,''); if(!is.null(names(x))) return(paste0('{',paste(paste0(vapply(names(x),json,''),':',vals),collapse=','),'}'));return(paste0('[',paste(vals,collapse=','),']')) }
 if(length(x)>1) return(paste0('[',paste(vapply(as.list(x),json,''),collapse=','),']'))
 if(length(x)==0||is.na(x)) return('null')
 if(is.character(x)) return(paste0('"',gsub('\n','\\n',gsub('"','\\"',gsub('\\','\\\\',x,fixed=TRUE),fixed=TRUE),fixed=TRUE),'"'))
 if(is.logical(x)) return(if(x)'true' else 'false')
 if(!is.finite(x)) return('null'); sprintf('%.17g',x)
}
savejson<-function(x,f)writeLines(json(x),f,useBytes=TRUE)
inventory<-read.csv('inventory.csv'); inventory$status<-'excluded';inventory$reason<-'No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence.'
corpus<-list(); refs<-list(); decisions<-list()
add<-function(name,d,cluster,reason,config=name) {
 stopifnot(all(c(cluster,'yi','vi')%in%names(d)))
 keep<-is.finite(d$yi)&is.finite(d$vi)&d$vi>0&!is.na(d[[cluster]])
 z<-data.frame(cluster=as.character(d[[cluster]][keep]),id=which(keep),y=d$yi[keep],v=d$vi[keep])
 if(nrow(z)<3||length(unique(z$cluster))<2||!anyDuplicated(z$cluster)) {decisions[[config]]<<-list(dataset=name,status='excluded configuration',reason='No identifiable repeated nesting after finite positive-variance filtering');return()}
 inventory$status[inventory$dataset==name]<<-'used';inventory$reason[inventory$dataset==name]<<-reason
 corpus[[config]]<<-z
 warnings<-character(); fit<-tryCatch(withCallingHandlers(rma.mv(y,v,random=~1|cluster/id,data=z,method='REML',sparse=TRUE,control=list(rel.tol=1e-10)),warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')}),error=function(e)e)
 meta<-list(dataset=name,cluster=cluster,reason=reason,original_rows=nrow(d),rows=nrow(z),omitted_rows=which(!keep),clusters=length(unique(z$cluster)),warnings=as.list(warnings))
 if(inherits(fit,'error')) refs[[config]]<<-c(meta,list(error=conditionMessage(fit))) else {
 w<-1/z$v;typ<-(nrow(z)-1)/(sum(w)-sum(w*w)/sum(w));den<-sum(fit$sigma2)+typ
 vals<-list(mu=as.numeric(coef(fit)),se=as.numeric(fit$se),ciLo=as.numeric(fit$ci.lb),ciHi=as.numeric(fit$ci.ub),sigma2Between=fit$sigma2[1],sigma2Within=fit$sigma2[2],logLik=as.numeric(logLik(fit)),z=as.numeric(fit$zval),p=as.numeric(fit$pval),Q=fit$QE,Qp=fit$QEp,I2_study=fit$sigma2[1]/den,I2_within=fit$sigma2[2]/den,I2_sampling=typ/den)
 refs[[config]]<<-c(meta,list(values=vals))
 }
 cat(config, nrow(z),'rows',if(inherits(fit,'error'))'REFUSED' else 'OK','\n');flush.console()
 savejson(corpus,'corpus.json');savejson(refs,'reference.json')
}
getd<-function(n)get(n,asNamespace('metadat'))
for(n in c('dat.assink2016','dat.konstantopoulos2011','dat.berkey1998','dat.berkey1998r','dat.kalaian1996','dat.knapp2017','dat.tannersmith2016','dat.riley2003','dat.mccurdy2020','dat.lehmann2018','dat.begg1989')) {
 cl<-switch(n,dat.konstantopoulos2011='district',dat.berkey1998='trial',dat.berkey1998r='trial',dat.tannersmith2016='studyid',dat.mccurdy2020='article',dat.lehmann2018='Full_Citation','study')
 add(n,getd(n),cl,paste('Documented',cl,'groups supplied effect estimates; diagonal sampling V; row id is nested effect.'))
}
add('dat.bakdash2021',transform(dat.bakdash2021,yi=es.z,vi=vi.z),'SampleID','Documented experiment identifier; supplied z correlations include source-imputed ghost results, not generated here.')
for(n in c('dat.cohen1981','dat.craft2003','dat.crede2010','dat.white2020')) {
 d<-getd(n);if(n=='dat.white2020'){d$ri<-d$r;d$ni<-d$n}
 d<-escalc(measure='ZCOR',ri=ri,ni=ni,data=d)
 cl<-switch(n,dat.crede2010='studyid',dat.white2020='study_id','study')
 add(n,d,cl,'Documented study identifier; Fisher z correlations from escalc; diagonal V.')
}
add('dat.demir2022',escalc(measure='ABT',ai=alpha,ni=n,mi=items,data=dat.demir2022),'studyid','Study identifier groups reliability estimates; ABT transformation from package example.')
add('dat.bornmann2007',escalc(measure='OR',ai=waward,n1i=wtotal,ci=maward,n2i=mtotal,data=dat.bornmann2007),'study','Study reference groups award comparisons; log odds ratios per help example.')
add('dat.bourassa1996',subset(escalc(measure='OR',ai=lh.le,bi=lh.re,ci=rh.le,di=rh.re,add=.5,to='all',data=dat.bourassa1996),sex=='combined'),'study','Combined-sex samples within studies per package example; avoids overlapping subgroup rows.')
add('dat.curtis1998',escalc(measure='ROM',m1i=m1i,sd1i=sd1i,n1i=n1i,m2i=m2i,sd2i=sd2i,n2i=n2i,data=dat.curtis1998),'paper','Paper groups plant experiments; log response ratios.')
d<-dat.besson2016;d$sd_e<-d$exp_se*sqrt(d$exp_n);d$sd_c<-d$con_se*sqrt(d$con_n)
d<-escalc(measure='SMD',m1i=exp_mean,m2i=con_mean,sd1i=sd_e,sd2i=sd_c,n1i=exp_n,n2i=con_n,data=d)
add('dat.besson2016',d,'study_ID','Documented study ID groups comparisons; SMD from reported means and SE times sqrt(n); raw experimental direction, diagonal V.')
for(n in c('dat.anand1999','dat.egger2001','dat.lee2004','dat.li2007','dat.yusuf1985')) add(n,escalc(measure='OR',ai=ai,n1i=n1i,ci=ci,n2i=n2i,data=getd(n)),if(n=='dat.yusuf1985')'id' else 'study','Repeated documented study/trial identifier; log OR; diagonal V; numerical validation not a clinical pooled estimand.')
add('dat.hartmannboyce2018',escalc(measure='OR',ai=x.nrt,n1i=n.nrt,ci=x.ctrl,n2i=n.ctrl,data=dat.hartmannboyce2018),'study','Study groups nicotine comparisons; log OR; shared-control covariance omitted in both fits.')
add('dat.landenberger2005',escalc(measure='OR',ai=n.cbt.rec,bi=n.cbt.non,ci=n.ctrl.rec,di=n.ctrl.non,data=dat.landenberger2005),'study','Study identifier groups CBT comparisons; log OR.')
for(n in c('dat.lim2014','dat.moura2021')) {
 obj<-getd(n);for(part in names(obj)) {d<-obj[[part]];if(is.data.frame(d)&&all(c('ri','ni')%in%names(d)))add(n,escalc(measure='ZCOR',ri=ri,ni=ni,data=d),if(n=='dat.lim2014')'article' else 'study.id','Documented article/study groups correlations; two-level reduction excludes phylogenetic random effects.',paste(n,part,sep='/'))}
}
add('dat.maire2019',transform(dat.maire2019$dat,yi=s1,vi=vars1),'site','Stations within sites; supplied s1 and vars1; two-level reduction excludes spatial correlation.')
d<-dat.anker2025;d<-rbind(data.frame(study=d$study,yi=d$female.logrr,vi=d$female.se^2),data.frame(study=d$study,yi=d$male.logrr,vi=d$male.se^2));add('dat.anker2025',d,'study','Disjoint male/female log risk ratios within trials; excludes overlapping overall estimate.')
d<-dat.ishak2007;d<-do.call(rbind,lapply(1:4,function(i)data.frame(study=d$study,yi=d[[paste0('y',i,'i')]],vi=d[[paste0('v',i,'i')]])));add('dat.ishak2007',d,'study','Repeated timepoint effects within studies; diagonal V benchmark excludes temporal sampling covariance.')
for(n in c('dat.dagostino1998')) {d<-getd(n);add(n,escalc(measure='SMD',m1i=mt,sd1i=sdt,n1i=nt,m2i=mc,sd2i=sdc,n2i=nc,data=d),'study','Continuous outcomes within study; SMD; missing continuous summaries excluded.')}
network<-c('dat.baker2009','dat.dogliotti2014','dat.dong2013','dat.franchini2012','dat.gurusamy2011','dat.hasselblad1998','dat.linde2015','dat.linde2016','dat.lopez2019','dat.pagliaro1992','dat.senn2013','dat.stowe2010','dat.woods2010','dat.tian2009')
inventory$reason[inventory$dataset%in%network]<-'Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported.'
other<-c(dat.huber2000='Individual participant counts, not effect-size rows.',dat.metap='List of separate univariate meta-analyses, not nested effects.',dat.kearon1998='Diagnostic accuracy tables with threshold/test structure; bivariate model unsupported.',dat.rivera2025='Diagnostic accuracy metrics; bivariate test structure unsupported.',dat.roever2022='Dose-arm data require dose model, unsupported.',dat.ursino2021='Dose-arm data require dose model, unsupported.',dat.obrien2003='BMI-category single-arm proportions, not common treatment contrasts; dose model unsupported.',dat.curtin2002='Different paired designs and missing within-study correlations; valid SE transformation not assumed.',dat.cannon2006='Nested/overlapping endpoints with different definitions; no common effect outcome selected.',dat.chiarito2020='Multiple distinct clinical endpoints; no common repeated outcome selected.',dat.fine1993='Overlapping binary endpoints; no common repeated outcome selected.',dat.karner2014='Distinct clinical endpoints and measurement scales; no common repeated outcome selected.',dat.lloyd2010='DAS and HAQ on different scales; common intercept not meaningful.',dat.collins1985a='Distinct mortality endpoints and trial strata; no common repeated outcome selected.',dat.collins1985b='Distinct perinatal endpoints; no common repeated outcome selected.',dat.nissen2007='Distinct infarction and mortality endpoints; no common repeated outcome selected.')
for(n in names(other))inventory$reason[inventory$dataset==n]<-other[[n]]
write.csv(inventory,'dataset-disposition.csv',row.names=FALSE)
savejson(decisions,'excluded-configurations.json')
savejson(list(R=R.version.string,metafor=as.character(packageVersion('metafor')),metadat=as.character(packageVersion('metadat')),datasets=nrow(inventory),used=sum(inventory$status=='used'),configurations=length(corpus)),'environment.json')
cat(length(corpus),'reference configurations written\n')
