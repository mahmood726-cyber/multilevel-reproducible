import json,sys
from pathlib import Path
suffix='-patched' if len(sys.argv)>1 else ''
ref=json.loads(Path('reference.json').read_text()); app=json.loads(Path('app'+suffix+'.json').read_text());corpus=json.loads(Path('corpus.json').read_text())
stats={};failures=[]
def check(name,q,a,b,tol):
    err=abs(a-b)/(1 if q.endswith('p') else max(1,abs(b))) if isinstance(a,(int,float)) else float('inf')
    s=stats.setdefault(q,dict(checks=0,passed=0,max_difference=0,tolerance=tol,worst=None));s['checks']+=1;s['passed']+=err<=tol
    if err>s['max_difference']:s.update(max_difference=err,worst=name)
    if err>tol:failures.append(dict(dataset=name,quantity=q,app=a,reference=b,difference=err,tolerance=tol))
for name,r in ref.items():
    a=app['results'][name]
    if 'error' in r:
        check(name,'refusal',int(a['reml'] is None),1,0);continue
    for q in ('mu','se','ciLo','ciHi','sigma2Between','sigma2Within','logLik'):
        check(name,q,a['reml'][q],r['values'][q],1e-6)
    check(name,'UI_row_count',a['parsedRows'],r['rows'],0)
    if 'renderMatches' in a:check(name,'UI_REML_render',int(a['renderMatches']),1,0)
    m=a['displayedMoM']; w=[1/x['v'] for x in corpus[name]];typ=(len(w)-1)/(sum(w)-sum(x*x for x in w)/sum(w));den=m['tau2_study']+m['tau2_within']+typ
    for q,num in [('I2_study',m['tau2_study']),('I2_within',m['tau2_within']),('I2_sampling',typ)]:check(name,q+'_formula',m[q],num/den,1e-9)
    # These are explicitly MoM outputs, not REML parity assertions. Report separately.
mom={}
for name,r in ref.items():
 if 'values' not in r:continue
 a=app['results'][name]['displayedMoM'];b=r['values']
 mom[name]={q:a[q]-b[t] for q,t in [('mu','mu'),('seMu','se'),('tau2_study','sigma2Between'),('tau2_within','sigma2Within'),('I2_study','I2_study'),('I2_within','I2_within'),('I2_sampling','I2_sampling')]}
report=dict(quantities=stats,checks=sum(s['checks'] for s in stats.values()),passed=sum(s['passed'] for s in stats.values()),failures=failures,mom_minus_reml=mom,page_errors=app['pageErrors'])
Path('comparison'+suffix+'.json').write_text(json.dumps(report,indent=2),encoding='utf8')
for q,s in stats.items():print(f"{q}: {s['passed']}/{s['checks']} pass; max difference {s['max_difference']:.17g}; tolerance {s['tolerance']:g}; worst {s['worst']}")
print(f"{report['passed']}/{report['checks']} checks pass")
