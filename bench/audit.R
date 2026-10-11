library(metadat)
for(n in c('dat.axfors2021','dat.hannum2020','dat.curtin2002','dat.egger2001','dat.lee2004','dat.li2007','dat.anand1999','dat.yusuf1985')) {
 d<-get(n,asNamespace('metadat'));cat('\n',n,'\n');print(head(d,4));
 for(cl in intersect(c('id','study','trial','DOI','author'),names(d))) {x<-d[[cl]];print(table(x)[table(x)>1])}
}
