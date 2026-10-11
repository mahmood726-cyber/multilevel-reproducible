# Wide repeated endpoints: diagonal-V numerical benchmarks only.
s<-readLines('reference.R');eval(parse(text=s[seq_len(grep("^for\\(n in c\\('dat.assink",s)[1]-1)]))
wide<-function(name,cl,ai,ci,n1,n2) {
 d<-getd(name);z<-do.call(rbind,lapply(seq_along(ai),function(i)data.frame(cluster=d[[cl]],endpoint=i,ai=d[[ai[i]]],ci=d[[ci[i]]],n1i=d[[rep(n1,length.out=length(ai))[i]]],n2i=d[[rep(n2,length.out=length(ai))[i]]])))
 add(name,escalc(measure='OR',ai=ai,ci=ci,n1i=n1i,n2i=n2i,data=z),'cluster',paste('Wide endpoints stacked within source',cl,'; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect.'))
}
wide('dat.cannon2006','trial',paste0('ep',1:6,'t'),paste0('ep',1:6,'c'),'nt','nc')
wide('dat.fine1993','study',paste0('e',1:4,'i'),paste0('c',1:4,'i'),'nei','nci')
wide('dat.chiarito2020','study',paste0('p2y12.',c('mi','stroke','death','vdeath')),paste0('aspirin.',c('mi','stroke','death','vdeath')),'p2y12.total','aspirin.total')
wide('dat.karner2014','study',paste0('tiotropium.',c('exa','sexa','hospi','deaths','sae','dropout')),paste0('placebo.',c('exa','sexa','hospi','deaths','sae','dropout')),'tiotropium.total','placebo.total')
wide('dat.nissen2007','study',c('treat.infarction','treat.death'),c('cont.infarction','cont.death'),'treat.total','cont.total')
wide('dat.collins1985a','id',paste0(c('b','o','d'),'.xti'),paste0(c('b','o','d'),'.xci'),'nti','nci')
wide('dat.collins1985b','id',paste0(c('pre','ped','stb','ned'),'.xti'),paste0(c('pre','ped','stb','ned'),'.xci'),c('pre.nti',rep('fup.nti',3)),c('pre.nci',rep('fup.nci',3)))
savejson(refs,'reference-supplement.json');savejson(corpus,'corpus-supplement.json')
cat(length(corpus),'wide-endpoint reference configurations written\n')
