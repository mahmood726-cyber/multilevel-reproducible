# Reuse exactly the reference functions, without rerunning completed base fits.
s<-readLines('reference.R');eval(parse(text=s[seq_len(grep("^for\\(n in c\\('dat.assink",s)[1]-1)]))
add('dat.axfors2021',escalc(measure='OR',ai=hcq_arm_event,n1i=hcq_arm_total,ci=control_arm_event,n2i=control_arm_total,data=dat.axfors2021),'id','Source registry identifier groups trial arms; supplied IDs used only as cluster labels; diagonal V benchmark.')
add('dat.hannum2020',escalc(measure='PLO',xi=xi,ni=ni,data=dat.hannum2020),'DOI','Source article DOI groups olfactory loss estimates; diagonal V benchmark.')
add('dat.obrien2003',escalc(measure='PR',xi=cases,ni=total,data=dat.obrien2003),'study','Documented study ID groups BMI strata; raw proportions; intercept-only reduction of documented multilevel regression.')
savejson(refs,'reference-supplement.json');savejson(corpus,'corpus-supplement.json')
cat(length(corpus),'supplemental reference configurations written\n')
