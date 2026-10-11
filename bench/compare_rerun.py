"""Run the unchanged historical comparator, then fail closed on any discrepancy."""
import json
from pathlib import Path
import subprocess
import sys

root=Path(__file__).resolve().parents[1]
dest=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else root/'rerun'
subprocess.run([sys.executable,str(root/'bench/compare.py'),'patched'],cwd=dest,check=True)
report=json.loads((dest/'comparison-patched.json').read_text(encoding='utf-8'))
if report['checks']!=528 or report['passed']!=528 or report['page_errors']:
    raise SystemExit('FAIL: rerun did not reproduce 528 passing checks without page errors')
print('RERUN PASS: 528/528 checks; no page errors.')
