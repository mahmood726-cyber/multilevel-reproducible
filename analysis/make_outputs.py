"""Rebuild publication outputs using results/ only. Expected claims are assertions."""
import argparse
import csv
import json
import math
from collections import defaultdict
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REML = ('mu', 'se', 'ciLo', 'ciHi', 'sigma2Between', 'sigma2Within', 'logLik')
SHARES = ('I2_study_formula', 'I2_within_formula', 'I2_sampling_formula')
QUANTITIES = REML + ('UI_row_count', 'UI_REML_render') + SHARES

def read(p):
    return json.loads(p.read_text(encoding='utf-8'))

def dump(p, value):
    p.write_text(json.dumps(value, indent=2, ensure_ascii=False, allow_nan=False)+'\n', encoding='utf-8')

def csvread(p):
    with p.open(encoding='utf-8', newline='') as f: return list(csv.DictReader(f))

def csvwrite(p, fields, rows):
    with p.open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(rows)

def compare(ref, app, corpus):
    assert set(ref) == set(app['results']) == set(corpus), 'Configuration sets differ'
    assert app['pageErrors'] == [], 'Page errors in archived run'
    rows = []
    def check(name, q, a, b, tol):
        assert isinstance(a, (float, int)) and isinstance(b, (float, int))
        assert math.isfinite(a) and math.isfinite(b), (name, q, 'nonfinite')
        diff = abs(a-b)/max(1, abs(b))
        rows.append(dict(configuration=name, quantity=q, app=a, reference=b, difference=diff, tolerance=tol, passed=diff <= tol))
    for name, r in ref.items():
        a = app['results'][name]; c = corpus[name]
        assert 'values' in r and a['reml'] is not None, name
        assert r['rows'] == len(c) and r['clusters'] == len({x['cluster'] for x in c}), name
        assert len({x['id'] for x in c}) == len(c), name
        assert all(math.isfinite(x['y']) and math.isfinite(x['v']) and x['v'] > 0 for x in c), name
        for q in REML: check(name, q, a['reml'][q], r['values'][q], 1e-6)
        check(name, 'UI_row_count', a['parsedRows'], r['rows'], 0)
        assert type(a['renderMatches']) is bool
        check(name, 'UI_REML_render', int(a['renderMatches']), 1, 0)
        m = a['displayedMoM']; w = [1/x['v'] for x in c]
        typ = (len(w)-1)/(sum(w)-sum(x*x for x in w)/sum(w))
        den = m['tau2_study'] + m['tau2_within'] + typ
        assert den > 0 and math.isfinite(den)
        for q, num in [('I2_study',m['tau2_study']),('I2_within',m['tau2_within']),('I2_sampling',typ)]:
            check(name, q+'_formula', m[q], num/den, 1e-9)
    return rows

def summarize(rows):
    out = {}
    for r in rows:
        s = out.setdefault(r['quantity'], dict(checks=0, passed=0, max_difference=0, tolerance=r['tolerance'], worst=None))
        s['checks'] += 1; s['passed'] += r['passed']
        if r['difference'] > s['max_difference']: s.update(max_difference=r['difference'], worst=r['configuration'])
    return out

def figures(out, rows, n):
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':8,'axes.titlesize':9,'axes.labelsize':8,'xtick.labelsize':8,'ytick.labelsize':8,'legend.fontsize':8})
    fig, axs = plt.subplots(4, 2, figsize=(170/25.4, 8.8), sharey=True)
    labels = ['Pooled estimate','Standard error','CI lower limit','CI upper limit','Between-cluster variance','Within-cluster variance','REML log-likelihood']
    for ax,q,label in zip(axs.flat, REML, labels):
        group = sorted((r for r in rows if r['quantity']==q), key=lambda r:r['configuration'])
        for i,r in enumerate(group, 1):
            maire = r['configuration'] == 'dat.maire2019'
            ax.scatter(i, math.log10(max(r['difference'],1e-16)), s=32 if maire else 10, marker='D' if maire else 'o', color='#bc552c' if maire else '#24658a', alpha=1 if maire else .7, zorder=3)
        ax.axhline(math.log10(group[0]['tolerance']), color='#555', ls='--', lw=1)
        ax.set_title(label); ax.set_xlim(0, len(group)+1); ax.set_ylim(-16.6,-5.2)
        ax.set_xticks([1,11,22,33,len(group)]); ax.set_yticks([-16,-12,-9,-6]); ax.grid(axis='y',alpha=.2)
        ax.set_xlabel('Configuration (alphabetical order)'); ax.set_ylabel('log10 relative difference')
    ax=axs.flat[-1]; ax.axis('off')
    ax.text(0,1,'App versus metafor\nEach dot: one configuration\nBlue circle: other configurations\nOrange diamond: dat.maire2019\nDashed line: tolerance = 10⁻⁶\nDifference = |app − R| / max(1, |R|)\nZeros / <10⁻¹⁶ plotted at −16\nAll seven quantities pass.\nAlphabetical order: Table 1.',va='top',fontsize=8,linespacing=1.3)
    fig.suptitle('Agreement of three-level REML estimates',fontsize=11)
    fig.tight_layout(rect=(0,0,1,.97)); savefig(fig,out,'figure2_agreement'); plt.close(fig)
    fig=plt.figure(figsize=(170/25.4,3.65))
    value=lambda k:n[k]['value']
    boxes=[('Problem','Several effect sizes\nfrom one study\nrequire modelling\nof dependence.'),('Tool','allmeta fits\nthree-level REML\noffline in\nthe browser.'),('Validation',f'{value("datasets_used")} datasets\n{value("effect_sizes")} effect sizes\nAgainst R package\nmetafor.'),('Result',f'{value("passed")} of {value("checks")}\nchecks pass;\n{value("configurations")} configurations')]
    for i,(head,body) in enumerate(boxes):
        x=.02+i*.245
        fig.patches.append(FancyBboxPatch((x,.25),.22,.52,boxstyle='round,pad=0.008',transform=fig.transFigure,facecolor=['#f4ece8','#e8f0f7','#eaf4ec','#fdf6e3'][i],edgecolor='#999'))
        fig.text(x+.11,.70,head,ha='center',weight='bold',fontsize=10)
        fig.text(x+.11,.49,body,ha='center',va='center',fontsize=8,linespacing=1.6)
    fig.text(.5,.89,'Three-level meta-analysis in the browser',ha='center',fontsize=11,weight='bold')
    fig.text(.5,.13,'Intercept-only nested models; normal-distribution REML intervals.',ha='center',fontsize=8)
    fig.text(.5,.07,'Method-of-moments estimates and intervals were not compared with R.',ha='center',fontsize=8)
    savefig(fig,out,'visual_abstract'); plt.close(fig)

def savefig(fig,out,name):
    for ext in ('png','tif'): fig.savefig(out/f'{name}.{ext}', dpi=300)

def build(results, out, expected):
    out.mkdir(parents=True, exist_ok=True)
    ref=read(results/'reference.json');app=read(results/'app-merged-e735558.json');old=read(results/'app.json');corpus=read(results/'corpus.json')
    rows=compare(ref,app,corpus);before=compare(ref,old,corpus)
    stats=summarize(rows);oldstats=summarize(before)
    for s,filename in [(stats,'comparison-patched.json'),(oldstats,'comparison.json')]:
        ledger=read(results/filename)
        assert s==ledger['quantities'], f'Recomputed quantities differ from {filename}'
        assert sum(v['checks'] for v in s.values())==ledger['checks']
        assert sum(v['passed'] for v in s.values())==ledger['passed']
    byconfig=defaultdict(list)
    for row in rows:byconfig[row['configuration']].append(row)
    table1=[]
    for name in sorted(ref):
        r=ref[name];rr=byconfig[name]
        table1.append(dict(dataset=r['dataset'],configuration=name,outcome_label=name.split('/',1)[1] if '/' in name else '',cluster_variable=r['cluster'],effect_sizes=r['rows'],clusters=r['clusters'],largest_relative_difference=max(x['difference'] for x in rr if x['quantity'] in REML),checks_passed=sum(x['passed'] for x in rr),checks=len(rr),all_within='yes' if all(x['passed'] for x in rr) else 'no',configuration_description=r['reason']))
    csvwrite(out/'table1_by_dataset.csv',list(table1[0]),table1)
    table2=[dict(quantity=q,checks=stats[q]['checks'],passed=stats[q]['passed'],largest_difference=stats[q]['max_difference'],tolerance=stats[q]['tolerance'],passed_before_fixes=oldstats[q]['passed']) for q in QUANTITIES]
    table2.append(dict(quantity='TOTAL',checks=len(rows),passed=sum(r['passed'] for r in rows),largest_difference='',tolerance='quantity-specific',passed_before_fixes=sum(r['passed'] for r in before)))
    csvwrite(out/'table2_by_quantity.csv',list(table2[0]),table2)
    dump(out/'check_ledger.json',rows); dump(out/'before_check_ledger.json',before)
    disposition=csvread(results/'dataset-disposition.csv');inventory=csvread(results/'inventory.csv')
    assert {r['dataset'] for r in disposition}=={r['dataset'] for r in inventory}
    assert {r['dataset'] for r in disposition if r['status']=='used'}=={r['dataset'] for r in ref.values()}
    n={}
    def add(key,value,source,transformation='identity',kind='measured'):
        n[key]=dict(value=value,source=source,transformation=transformation,kind=kind)
    add('datasets_enumerated',len(inventory),'inventory.csv','count rows')
    for label,status in [('used','used'),('excluded','excluded')]:add('datasets_'+label,sum(r['status']==status for r in disposition),'dataset-disposition.csv:status','count '+status)
    add('configurations',len(ref),'reference.json','count configurations')
    add('effect_sizes',sum(r['rows'] for r in ref.values()),'reference.json:*.rows','sum across configurations; not unique participants')
    counts={len(rr) for rr in byconfig.values()};assert len(counts)==1
    add('checks_per_configuration',counts.pop(),'recomputed ledger','count checks per configuration')
    for key,rr,field in [('checks',rows,None),('passed',rows,'passed'),('before_passed',before,'passed')]:add(key,len(rr) if field is None else sum(r[field] for r in rr),'reference.json + '+('app.json' if rr is before else 'app-merged-e735558.json')+' + corpus.json','recompute comparison')
    for key,group in [('reml_quantities',REML),('share_quantities',SHARES),('exact_quantities',('UI_row_count','UI_REML_render'))]:add(key,len(group),'comparison-patched.json:quantities','count named quantity group')
    for q in REML:add('max_'+q,stats[q]['max_difference'],'reference.json:*.values.'+q+' + app-merged-e735558.json:results.*.reml.'+q,'max |app-R|/max(1,|R|)')
    add('max_confidence_limits',max(stats[q]['max_difference'] for q in ['ciLo','ciHi']),'reference.json + app-merged-e735558.json:ciLo,ciHi','max across both confidence limits')
    name='dat.konstantopoulos2011'
    for q in ['rows','clusters']:add('usecase_'+q,ref[name][q],'reference.json:'+name+'.'+q)
    for source,values in [('app',app['results'][name]['reml']),('R',ref[name]['values'])]:
        for q in REML:add('usecase_'+source+'_'+q,values[q],('app-merged-e735558.json:results.'+name+'.reml.' if source=='app' else 'reference.json:'+name+'.values.')+q)
    add('usecase_mom_mu',app['results'][name]['displayedMoM']['mu'],'app-merged-e735558.json:results.'+name+'.displayedMoM.mu')
    maire='dat.maire2019';bfgs=read(results/'maire-bfgs-reference.json');nl=read(results/'reference-nlminb.json')
    assert ref[maire]['values']==bfgs
    for key,val,src in [('nlminb',nl[maire]['values']['logLik'],'reference-nlminb.json:'+maire+'.values.logLik'),('bfgs',bfgs['logLik'],'maire-bfgs-reference.json:logLik'),('app',app['results'][maire]['reml']['logLik'],'app-merged-e735558.json:results.'+maire+'.reml.logLik')]:add('maire_'+key+'_logLik',val,src)
    add('maire_logLik_improvement',bfgs['logLik']-nl[maire]['values']['logLik'],'maire-bfgs-reference.json + reference-nlminb.json','BFGS minus nlminb logLik')
    env=read(results/'environment.json')
    for k in ['R','metafor','metadat']:add('version_'+k,env[k],'environment.json:'+k,kind='source metadata')
    assert env['datasets']==len(inventory) and env['used']==n['datasets_used']['value'] and env['configurations']==len(ref)
    protocol=read(results/'protocol.json')
    for k,v in protocol.items():
        if k!='sources':add(k,v,'protocol.json:'+k,'declared protocol/source metadata; evidence links in protocol.json:sources',kind='static')
    dump(out/'numbers.json',n)
    figures(out,rows,n)
    sizes={}
    for p in sorted(out.iterdir()):
        if p.suffix in ['.png','.tif']:
            with Image.open(p) as im:sizes[p.name]=dict(width_pixels=im.width,height_pixels=im.height,dpi=[float(d) for d in im.info['dpi']])
    dump(out/'sizes.json',sizes)
    notes='''Figures: 300 dpi, nominal width 170 mm, all text at least 8 pt. Each plotted point is the scalar difference for one configuration and REML quantity. Exact zeros and differences below 1e-16 are plotted at -16. The orange diamond marks dat.maire2019; the dashed line is 1e-6. Table 1 is in the same alphabetical configuration order. Several configurations stack distinct endpoints; descriptions preserve this qualification.\n\nSeven REML comparisons, three conditional MoM share-formula checks and two exact UI contracts make twelve checks per configuration. MoM estimates and cluster-df intervals were NOT validated against R. Formula parity conditions on app MoM components. Render checks are the historical runner's Boolean rounded-value-presence contract, not an independent cell-by-cell accessibility or export test.\n\nNumbers include all empirical manuscript claims, versions and protocol constants. Section/list numbering, bracketed citation numbers, dataset-name years, the dictated draft date and bibliographic numbering are identifiers or editorial metadata, not experimental claims. No manuscript draft is distributed. Package strings 5.2.1 and 1.6.0 are the R-reported forms of release labels 5.2-1 and 1.6-0.\n\nTwo app assets missing from the run's snapshot (a stylesheet and the tooltip glossary) were added from git at e735558; neither affects a computed value. The full archived historical numerical results remain reproducible from JSON. No full R corpus rerun or new release certification is implied by regenerating these outputs.\n'''
    (out/'notes.md').write_text(notes,encoding='utf-8')
    report=['# Reproduction report','','All findings are recomputed from results/; expected values are assertions, never substituted for measurements.','','| Claim | Expected | Reproduced | Verdict |','|---|---|---|---|']
    passed=0
    for k,e in expected.items():
        actual=n[k]['value'] if k in n else None
        if actual is not None and 'digits' in e:actual=round(actual,e['digits'])
        if actual is not None and 'significant' in e:actual=float(format(actual,f'.{e["significant"]}g'))
        ok=actual==e['value'];passed+=ok
        report.append(f'| {k} | {e["value"]} | {actual} | {"PASS" if ok else "FAIL"} |')
    final=f'{"PASS" if passed==len(expected) else "FAIL"}: {passed}/{len(expected)} paper-value assertions; {sum(r["passed"] for r in rows)}/{len(rows)} final checks; {sum(r["passed"] for r in before)}/{len(before)} before fixes.'
    report += ['',notes,'',final]
    (out/'reproduction_report.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
    print(final)
    return 0 if passed==len(expected) and all(r['passed'] for r in rows) else 1

def main():
    p=argparse.ArgumentParser();p.add_argument('--results',type=Path,default=ROOT/'results');p.add_argument('--outputs',type=Path,default=ROOT/'outputs');p.add_argument('--expected',type=Path,default=ROOT/'expected/paper_values.json');a=p.parse_args()
    return build(a.results,a.outputs,read(a.expected))

if __name__=='__main__':raise SystemExit(main())
