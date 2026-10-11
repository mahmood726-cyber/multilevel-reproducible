import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const root=process.argv[2]||'original';
const browser=await chromium.launch({channel:'chrome',headless:true});
const page=await browser.newPage();
const errors=[]; page.on('pageerror',e=>errors.push(String(e)));
await page.goto(pathToFileURL(path.resolve(root,'multilevel-ma/index.html')).href);
await page.waitForFunction(()=>typeof window.__almReml==='function');
const corpus=JSON.parse(fs.readFileSync('corpus.json','utf8')), out={};
for(const [name,rows] of Object.entries(corpus)) {
 const r=await page.evaluate(rows=>{
  // Map source cluster identifiers bijectively to CSV-safe labels; preserve memberships.
  const ids=[...new Set(rows.map(r=>r.cluster))];
  document.getElementById('src').value=rows.map(r=>['cluster_'+ids.indexOf(r.cluster),r.y,Math.sqrt(r.v),'row_'+r.id].join(',')).join('\n');
  document.getElementById('btn-run').click();
  const reml=window.__almReml(),table=document.querySelectorAll('#summary table')[1];
  const checks=table && [reml.mu.toFixed(3),reml.se.toFixed(3),reml.ciLo.toFixed(3),reml.ciHi.toFixed(3),reml.sigma2Between.toFixed(4),reml.sigma2Within.toFixed(4),reml.logLik.toFixed(3)].every(s=>table.innerText.includes(s));
  return {reml,displayedMoM:window._almLastMlma(),summary:document.getElementById('summary').innerText,parsedRows:document.querySelectorAll('#body tr').length-1,renderMatches:!!checks,momCaption:document.querySelector('#summary table caption')?.textContent||null};
 },rows);
 out[name]=r;
 console.log(name, r.parsedRows===rows.length?'UI rows PASS':'UI rows FAIL');
}
fs.writeFileSync(root==='original'?'app.json':'app-patched.json',JSON.stringify({results:out,pageErrors:errors,browser:browser.version()},null,2));
await browser.close();
console.log(`${Object.keys(out).length}/${Object.keys(corpus).length} browser configurations run; ${errors.length} page errors`);
