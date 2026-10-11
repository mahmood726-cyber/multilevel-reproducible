# Benchmark provenance and rerun

`reference.R`, `supplement.R`, `wide.R`, `inventory.R`, `audit.R`, `diagnose.R` and `compare.py` are the original scripts, unchanged. `docs/` retains the installed metadat help used to justify cluster choices. `run-app.mjs` differs only in Playwright module resolution: use `PLAYWRIGHT_MODULE` or the installed `playwright` package. The original machine-specific module path is intentionally omitted. Use `<R_LIBS_USER>` for your own existing R library location; no local-machine path belongs in this archive. Neither scripts nor instructions install or download dependencies.

Historical discovery ran inventory, base reference, supplement and wide-endpoint scripts, then merged accepted configurations and replaced only Maire's values with the BFGS diagnostic. The supplement scripts overwrite their temporary output, so they are retained as provenance rather than represented as a single portable reconstruction of all final selection decisions. Final decisions are in `data/dataset-disposition.csv`; row-level final inputs are in `data/corpus.json`.

The new `rerun_reference.R` directly refits that final corpus, preserving metadata and using the original full-precision serializer and model settings. It requires an existing `jsonlite` installation in addition to metafor 5.2-1. Historical discovery also requires metadat 1.6-0. Reference environment: R 4.6.0. Set `R_LIBS_USER` to your existing library if required. Use existing Node, Playwright and Chrome for browser execution. Python output generation requires matplotlib and Pillow; integrity verification also uses PyYAML.

From the repository root, in order:

```text
Rscript bench/rerun_reference.R rerun
cd rerun
node ../bench/run-app.mjs ../app
cd ..
python bench/compare_rerun.py
```

The runner reads corpus.json in its working directory and writes app-patched.json for any app root other than the literal `original`. It runs the entire page, maps source cluster labels bijectively to CSV-safe labels, supplies standard errors as sqrt(v), and compares rounded values present in the second table. `compare_rerun.py` invokes the unchanged historical comparator from rerun/, then returns nonzero for incomplete checks, failures or page errors. Numerical failures are never replaced by archived values. The original comparator alone prints failures but does not return nonzero; use the wrapper for automation.

`run-app.mjs` preserves the historical file-URL navigation. A separate bounded `ui_smoke.mjs` serves the page at 127.0.0.1:8000, blocks external requests, and checks the use case without changing pinned code. It passes 20/20 (run on the host; results/ui-smoke.json). Full R/browser corpus refits were not performed in this archive task. Regenerating publication outputs reads only archived results, with no R, browser or network required:

```text
python analysis/make_outputs.py
python analysis/verify_archive.py
```

Assets: the run's snapshot lacked hub/app-style.css and hub/shared/glossary.json; both were added byte-for-byte from git at e735558. Hub navigation and optional transfers target other allmeta apps outside this single-page archive.
