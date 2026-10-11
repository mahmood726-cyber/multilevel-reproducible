library(metadat)
ds <- sort(unique(data(package='metadat')$results[,'Item']))
dir.create('docs',showWarnings=FALSE)
out <- lapply(ds,function(n) {
 e<-new.env(); data(list=n,package='metadat',envir=e); d<-e[[n]]
 h<-tryCatch(paste(capture.output(tools::Rd2txt(utils:::.getHelpFile(help(n,package='metadat')))),collapse='\n'),error=function(e)'')
 writeLines(h,file.path('docs',paste0(n,'.txt')))
 if(!is.data.frame(d)) return(data.frame(dataset=n,n=length(d),columns=class(d),repeated='non-data-frame'))
 rep<-names(d)[vapply(d,function(x)is.atomic(x)&&length(unique(x[!is.na(x)]))>1&&length(unique(x[!is.na(x)]))<sum(!is.na(x)),logical(1))]
 data.frame(dataset=n,n=nrow(d),columns=paste(names(d),collapse=';'),repeated=paste(rep,collapse=';'))
})
write.csv(do.call(rbind,out),'inventory.csv',row.names=FALSE)
cat(length(ds),'datasets inventoried\n')
