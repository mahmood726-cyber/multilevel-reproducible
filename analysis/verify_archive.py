"""Verify hashes, regenerated outputs, tables, image pixels, metadata and scope."""
import hashlib
import json
from pathlib import Path
import re
import tempfile

from PIL import Image
import yaml
from make_outputs import ROOT, build, csvread, read

EXCLUDED_PARTS={'.git','__pycache__','node_modules','rerun','outputs'}

def source_files():
    return sorted(p for p in ROOT.rglob('*') if p.is_file() and not any(x in EXCLUDED_PARTS or x.startswith('.verify-') for x in p.relative_to(ROOT).parts) and p.name not in {'SOURCE_SHA256.json','PROGRESS.md'})

def main():
    manifest=read(ROOT/'SOURCE_SHA256.json')
    actual={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in source_files()}
    assert actual==manifest, 'Source hash or source inventory mismatch'
    app=read(ROOT/'app/app-sha256.json')
    assert set(app)=={p.relative_to(ROOT/'app').as_posix() for p in (ROOT/'app').rglob('*') if p.is_file() and p.name!='app-sha256.json'}
    for name,want in app.items():assert hashlib.sha256((ROOT/'app'/name).read_bytes()).hexdigest()==want,name
    for p in source_files():
        if p.suffix.lower() in {'.json','.js','.mjs','.py','.r','.md','.csv','.txt','.html','.cff','.patch','.css'}:
            raw=p.read_bytes();assert not raw.startswith(b'\xef\xbb\xbf'),f'UTF-8 BOM: {p.name}'
            text=raw.decode('utf-8')
            assert not re.search(r'\b[A-Za-z]:[\\/](?:Users|Projects|claude-temp|E156|ProjectIndex)[\\/]',text),f'Machine path: {p.name}'
    assert not any(p.name in {'paper.md','paper_v2_dictated_text.md'} for p in source_files())
    page=ROOT/'app/multilevel-ma/index.html';missing=[]
    for name in re.findall(r'(?:src|href)="([^"]+)"',page.read_text(encoding='utf-8')):
        if name.startswith('../') and name.endswith(('.js','.css')):
            target=(page.parent/name).resolve()
            assert target.is_relative_to(ROOT/'app')
            if not target.is_file():missing.append(target.relative_to(ROOT/'app').as_posix())
    disclosed=read(ROOT/'results/asset-availability.json')['missing_local_assets']
    assert missing==disclosed==[], 'Unreported asset gap'
    for n in ['corpus.json','dataset-disposition.csv','inventory.csv']:assert (ROOT/'data'/n).read_bytes()==(ROOT/'results'/n).read_bytes(),n
    table1=csvread(ROOT/'outputs/table1_by_dataset.csv');table2=csvread(ROOT/'outputs/table2_by_quantity.csv')
    assert len(table1)==44 and len({r['dataset'] for r in table1})==41
    assert sum(int(r['effect_sizes']) for r in table1)==8069
    assert all(r['all_within']=='yes' and int(r['checks_passed'])==int(r['checks'])==12 for r in table1)
    total=table2[-1];assert total['quantity']=='TOTAL' and len(table2)==13
    for col,want in [('checks',528),('passed',528),('passed_before_fixes',506)]:assert int(total[col])==sum(int(r[col]) for r in table2[:-1])==want
    expected=read(ROOT/'expected/paper_values.json')
    # Compare all generated files, including full ledgers, claims, reports and images.
    with tempfile.TemporaryDirectory(prefix='.verify-',dir=ROOT) as temp:
        tmp=Path(temp)
        assert build(ROOT/'results',tmp,expected)==0
        assert {p.name for p in tmp.iterdir()}=={p.name for p in (ROOT/'outputs').iterdir() if p.is_file()}
        for p in tmp.iterdir():assert p.read_bytes()==(ROOT/'outputs'/p.name).read_bytes(),f'Output not reproducible: {p.name}'
    sizes=read(ROOT/'outputs/sizes.json')
    assert set(sizes)=={stem+'.'+ext for stem in ['figure2_agreement','visual_abstract'] for ext in ['png','tif']}
    for name,info in sizes.items():
        with Image.open(ROOT/'outputs'/name) as im:
            assert (im.width,im.height)==(info['width_pixels'],info['height_pixels'])
            assert abs(im.width/300*25.4-170)<.1
            assert all(abs(float(v)-300)<.001 for v in im.info['dpi'])
            assert [float(v) for v in im.info['dpi']]==info['dpi']
    for stem in ['figure2_agreement','visual_abstract']:
        with Image.open(ROOT/'outputs'/f'{stem}.png') as a,Image.open(ROOT/'outputs'/f'{stem}.tif') as b:assert a.convert('RGB').tobytes()==b.convert('RGB').tobytes()
    title='Three-level meta-analysis in the browser: a tool validated against the R package metafor'
    z=read(ROOT/'.zenodo.json');cff=yaml.safe_load((ROOT/'CITATION.cff').read_text(encoding='utf-8'))
    assert z['title']==cff['title']==title
    assert z['creators']==[{'name':'Ahmad, Mahmood'}]
    assert cff['authors']==[{'family-names':'Ahmad','given-names':'Mahmood'}]
    assert z['license']==cff['license']=='MIT' and z['version']==cff['version']=='1.0.0'
    assert {(r['identifier'],r['relation']) for r in z['related_identifiers']}=={('https://github.com/mahmood726-cyber/allmeta','isDerivedFrom'),('10.5281/zenodo.23288388','isDerivedFrom')}
    assert any(r.get('doi')=='10.5281/zenodo.23288388' and r.get('version')=='1.2.1' and r.get('notes')=='isDerivedFrom' for r in cff['references'])
    assert (ROOT/'.gitattributes').read_text().strip()=='* -text'
    ui=read(ROOT/'results/ui-smoke-status.json')
    assert ui['status']=='pass' and ui['checks']=='20/20'
    print(f'ARCHIVE PASS: {len(app)} app hashes; {len(manifest)} source hashes; 44 table rows; 528/528 final checks; reproducible outputs and paired image pixels verified; no missing app assets; UI smoke 20/20 recorded.')

if __name__=='__main__':main()
