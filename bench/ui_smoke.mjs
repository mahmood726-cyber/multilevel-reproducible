// Bounded offline use-case UI contract, no downloads, pinned files unchanged.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const appRoot=path.join(root,'app');
const checks=[]; const errors=[]; const missing=[]; const external=[];
const server=http.createServer((req,res)=>{
  const target=path.resolve(appRoot,'.'+decodeURIComponent(new URL(req.url,'http://127.0.0.1:8000').pathname));
  if(!target.startsWith(appRoot+path.sep)){res.writeHead(403);res.end();return;}
  if(!fs.existsSync(target)||!fs.statSync(target).isFile()) {missing.push(path.relative(appRoot,target).replaceAll('\\','/'));res.writeHead(404);res.end();return;}
  res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.css':'text/css','.json':'application/json'})[path.extname(target)]||'application/octet-stream');
  res.end(fs.readFileSync(target));
});
let browser;
const watchdog=setTimeout(()=>{console.error('FAIL: UI smoke timed out');process.exit(1);},60000);
try {
  await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(8000,'127.0.0.1',resolve);});
  browser=await chromium.launch({channel:'chrome',headless:true,args:['--disable-background-networking','--disable-component-update','--no-first-run']});
  const context=await browser.newContext({serviceWorkers:'block'});
  await context.route('**/*',route=>{
    if(new URL(route.request().url()).origin==='http://127.0.0.1:8000')return route.continue();
    external.push(route.request().url());return route.abort();
  });
  const page=await context.newPage();page.setDefaultTimeout(15000);
  page.on('pageerror',e=>errors.push(String(e)));
  await page.goto('http://127.0.0.1:8000/multilevel-ma/index.html');
  await page.waitForFunction(()=>typeof window.__almReml==='function');
  const name='dat.konstantopoulos2011';
  const corpus=JSON.parse(fs.readFileSync(path.join(root,'data/corpus.json'),'utf8'));
  const reference=JSON.parse(fs.readFileSync(path.join(root,'results/reference.json'),'utf8'))[name];
  const observed=await page.evaluate(rows=>{
    const ids=[...new Set(rows.map(r=>r.cluster))];
    document.getElementById('src').value=rows.map(r=>['cluster_'+ids.indexOf(r.cluster),r.y,Math.sqrt(r.v),'row_'+r.id].join(',')).join('\n');
    document.getElementById('btn-run').click();
    return {reml:window.__almReml(),mom:window._almLastMlma(),rows:document.querySelectorAll('#body tr').length-1,summary:document.getElementById('summary').innerText,caption:document.querySelector('#summary table caption').textContent};
  },corpus[name]);
  checks.push({name:'parsed rows',pass:observed.rows===reference.rows});
  checks.push({name:'MoM label',pass:observed.caption==='Method of moments (MoM)'});
  for(const q of ['mu','se','ciLo','ciHi','sigma2Between','sigma2Within','logLik']) {
    const diff=Math.abs(observed.reml[q]-reference.values[q])/Math.max(1,Math.abs(reference.values[q]));
    checks.push({name:q,pass:Number.isFinite(diff)&&diff<=1e-6,difference:diff});
    checks.push({name:'render '+q,pass:observed.summary.includes(observed.reml[q].toFixed(q.startsWith('sigma')?4:3))});
  }
  checks.push({name:'MoM use-case value',pass:observed.mom.mu.toFixed(3)==='0.128'});
  checks.push({name:'no page errors',pass:errors.length===0});
  checks.push({name:'no external page requests',pass:external.length===0});
  checks.push({name:'no missing local assets',pass:[...new Set(missing)].filter(x=>x!=='favicon.ico').length===0});
  fs.mkdirSync(path.join(root,'results'),{recursive:true});
  fs.writeFileSync(path.join(root,'results/ui-smoke.json'),JSON.stringify({dataset:name,browser:browser.version(),checks,errors,missing:[...new Set(missing)],external,observed},null,2)+'\n');
  if(checks.some(c=>!c.pass))throw new Error('UI contract failure');
  console.log(`UI PASS: ${checks.length}/${checks.length} checks.`);
} finally {
  clearTimeout(watchdog);
  if(browser)await browser.close();
  await new Promise(resolve=>server.close(resolve));
}
