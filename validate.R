# Refit archived inputs using installed packages only; never install or download.
main <- function() {
  for (pkg in c('metafor', 'jsonlite')) {
    if (!requireNamespace(pkg, quietly=TRUE)) stop('Required installed package missing: ', pkg)
  }
  cat(R.version.string, '\n')
  cat('metafor ', as.character(utils::packageVersion('metafor')), '; paper 5.2-1\n', sep='')
  cat('Recomputed: seven REML quantities per configuration.\n')
  cat('Replayed: archived MoM shares checked against their closed form; archived row count and renderMatches (no browser run).\n')
  corpus <- jsonlite::fromJSON('data/corpus.json', simplifyVector=FALSE)
  app <- jsonlite::fromJSON('results/app-merged-e735558.json', simplifyVector=FALSE)
  stopifnot(length(corpus)==44L, setequal(names(corpus), names(app$results)), length(app$pageErrors)==0L)
  keys <- c('mu','se','ciLo','ciHi','sigma2Between','sigma2Within','logLik')
  table <- list()
  check <- function(name, quantity, a, r, tol, mode) {
    valid <- is.numeric(a) && length(a)==1L && is.finite(a) && is.numeric(r) && length(r)==1L && is.finite(r)
    difference <- if(valid) abs(a-r)/max(1,abs(r)) else Inf
    table[[length(table)+1L]] <<- data.frame(configuration=name,quantity=quantity,
      App=if(valid) a else NA_real_,R=if(valid) r else NA_real_,Difference=difference,
      Tolerance=tol,Result=if(difference<=tol) 'PASS' else 'FAIL',Mode=mode)
  }
  for (name in names(corpus)) {
    d <- do.call(rbind, lapply(corpus[[name]], as.data.frame, stringsAsFactors=FALSE))
    stopifnot(all(c('y','v','cluster','id') %in% names(d)), all(is.finite(d$y)), all(is.finite(d$v)), all(d$v>0), !anyNA(d$cluster), !anyDuplicated(d$id))
    a <- app$results[[name]]
    control <- if(name=='dat.maire2019') list(optimizer='optim',optmethod='BFGS',reltol=1e-14) else list(rel.tol=1e-10)
    f <- tryCatch(metafor::rma.mv(y,v,random=~1|cluster/id,data=d,method='REML',sparse=name!='dat.maire2019',control=control),error=function(e) {cat('FIT ERROR ',name,': ',conditionMessage(e),'\n',sep=''); NULL})
    values <- if(is.null(f)) setNames(rep(NA_real_,7L),keys) else c(mu=as.numeric(coef(f)),se=as.numeric(f$se),ciLo=as.numeric(f$ci.lb),ciHi=as.numeric(f$ci.ub),sigma2Between=f$sigma2[1],sigma2Within=f$sigma2[2],logLik=as.numeric(logLik(f)))
    start <- length(table)+1L
    for(q in keys) check(name,q,a$reml[[q]],values[[q]],1e-6,'recomputed R REML')
    m <- a$displayedMoM
    w <- 1/d$v; typical <- (length(w)-1)/(sum(w)-sum(w*w)/sum(w))
    denom <- m$tau2_study+m$tau2_within+typical
    shares <- c(I2_study=m$tau2_study/denom,I2_within=m$tau2_within/denom,I2_sampling=typical/denom)
    for(q in names(shares)) check(name,paste0(q,'_formula'),m[[q]],shares[[q]],1e-9,'archived MoM versus closed form')
    check(name,'UI_row_count',a$parsedRows,as.numeric(nrow(d)),0,'archived browser row count')
    check(name,'UI_REML_render',if(is.logical(a$renderMatches) && length(a$renderMatches)==1L) as.numeric(a$renderMatches) else NA_real_,1,0,'archived browser rendering')
    cat('\n',name,'\n',sep='')
    print(do.call(rbind,table[start:length(table)])[,c('quantity','App','R','Difference','Tolerance','Result')],row.names=FALSE,digits=17)
  }
  result <- do.call(rbind,table)
  dir.create('outputs',showWarnings=FALSE)
  write.csv(result,'outputs/validate_R_table.csv',row.names=FALSE,na='NA')
  cat('\nPer-quantity totals:\n')
  for(q in unique(result$quantity)) {
    rows <- result[result$quantity==q,]
    cat(sprintf('%s: %d/%d pass; max difference %.17g; tolerance %g\n',q,sum(rows$Result=='PASS'),nrow(rows),max(rows$Difference),rows$Tolerance[1]))
  }
  passed <- sum(result$Result=='PASS')
  cat(sprintf('%d/%d checks pass\n',passed,nrow(result)))
  if(nrow(result)!=528L || passed!=528L) return(1L)
  0L
}
status <- tryCatch(main(),error=function(e) {cat('Validation failed: ',conditionMessage(e),'\n',sep='',file=stderr());1L})
quit(save='no',status=status)
