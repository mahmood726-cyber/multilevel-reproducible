# Three-level meta-analysis in the browser: a tool validated against the R package metafor

Version 1.0.0. Creator: Mahmood Ahmad. MIT-licensed archive code.

This archive preserves the validation of allmeta's intercept-only three-level REML page at **e7355582db9c79812027cb4b47710c3f2efc7ae3** (short e735558, containing PR #85). The reference used **metafor 5.2-1**, **metadat 1.6-0**, and **R 4.6.0**. R reports the package versions as 5.2.1 and 1.6.0 in environment.json. Commit/PR provenance is supplied with the source snapshot; no remote verification was performed here.

The final run contains **114 datasets enumerated, 41 used, 73 excluded; 44 configurations and 8069 effect-size rows**. Every configuration passes twelve checks, **528/528**, compared with **506/528** before fixes. Reproduction recomputes comparisons from full-precision app and R records; it does not trust just the reported totals. The final app JSON was verified byte-identical to the final patched JSON during archive assembly.

## Corpus and model

Datasets were eligible when their package documentation identifies repeated effect sizes within a documented cluster. Repeated author surnames alone are insufficient. Effects are supplied values or transformations from metafor::escalc; missing/nonfinite effects and nonpositive variances are filtered identically. Retained row IDs and original cluster labels remain in corpus.json. Inventory, explicit inclusion/exclusion reasons, archived package help and original scripts accompany the data.

Both fits use diagonal sampling variance and `rma.mv(y, v, random = ~ 1 | cluster/id, method = "REML")`, with two nested random-effect levels and a unique effect-row ID. The browser receives sqrt(v) as its standard error. Configurations include separate outcome choices and stacked wide endpoints. Several datasets combine outcomes with different clinical meanings: numerical parity does not justify their pooled clinical interpretation. Source-imputed ghost effects in dat.bakdash2021 remain labelled in source documentation. DOI/NCT-like grouping labels are source strings, not independently verified registry claims.

## Checks and results

Relative difference is `abs(app - R) / max(1, abs(R))`. Seven REML quantities use tolerance **1e-6**: pooled estimate, standard error, both normal-distribution confidence limits, between-cluster variance, within-cluster variance, and log-likelihood. The largest differences, rounded to two significant digits, are respectively 2.3e-7, 3.1e-7, 8.5e-7 across both confidence limits, 5.5e-7, 4.7e-7 and 1.3e-10. Tables and the ledger retain full precision.

Three I² variance-share checks use **1e-9** in fraction units, conditional on the page's **method-of-moments (MoM)** components. With w=1/v, typical sampling variance is `(k-1)/(sum(w)-sum(w*w)/sum(w))`; each component is divided by the sum of both MoM heterogeneity components and this sampling variance. These are closed-form checks, not MoM-versus-R estimator comparisons. Row count and the historical rounded-value rendering contract are exact, completing twelve checks.

The denominator's former 1e-10 addition caused variance-share failures. PR #85 also corrected a chart receipt that labelled MoM results as REML. The twelve-check ledger captures numerical/UI results; it does not separately test every receipt or export path. The patch and historical report retain that distinction.

For **dat.maire2019**, nlminb gave log-likelihood **-199.88753459235858**; BFGS with relative tolerance **1e-14** gave **-199.88753459234036**, matching the app's **-199.88753459234030**. The improvement is only about **1.82e-11**. This small objective change matters for component precision: the initial reference produced three Maire numerical discrepancies. Tightened/rescaled nlminb attempts reported convergence failures; diagnose.R and the original records preserve this history. Only this reference was replaced, without widening comparison tolerances or changing the REML engine. reference-nlminb.json and comparison-initial.json are preliminary snapshots, not the final 44-configuration before-fix ledger.

The use case, **dat.konstantopoulos2011**, has **56 effects and 11 districts**. Both app and R round to estimate **0.185**, SE **0.085**, normal **95% CI 0.019 to 0.350**, between variance **0.0651**, within variance **0.0327**, and log-likelihood **-7.959**. The app's MoM estimate rounds to **0.128**.

## Validate with one command

From this archive's root, with R and the already installed `metafor` and `jsonlite` packages:

```text
Rscript validate.R
```

No Python, Node, browser, metadat installation, or network is needed for this command. Missing packages fail with a nonzero exit status; nothing is installed automatically. Set R's standard library environment variables to your existing libraries if needed. The script prints actual R/metafor versions alongside the paper version, a full comparison table for each configuration, per-quantity totals, and `N/N checks pass`. It writes `outputs/validate_R_table.csv` and exits nonzero for any failed or incomplete check.

Seven REML quantities are **recomputed in R** for each of the 44 configurations in `data/corpus.json`, against `results/app-merged-e735558.json`, at relative tolerance 1e-6. Optimizer settings match `bench/rerun_reference.R`, including Maire's BFGS exception. Three **archived MoM variance shares** are checked against a newly calculated closed form at 1e-9; the components and shares come from the archived app record. The two exact **UI checks replay archived** `parsedRows` and `renderMatches`; this command does not run a browser or certify current UI behavior. These twelve checks per configuration give 528 checks. All comparison differences use `abs(App-R)/max(1,abs(R))`; the CSV Mode column distinguishes the evidence sources. The optional R table is separately checked by `analysis/verify_archive.py`; historical Python-generated publication outputs remain byte-reproducible.

## Reproduce

With existing Python, matplotlib and Pillow:

```text
python analysis/make_outputs.py
python analysis/verify_archive.py
```

The verifier additionally requires PyYAML. See [bench/README.md](bench/README.md) for the sequence **R reference → whole-page app runner → comparison** with existing R/Node/Chrome dependencies. These output-generation commands are offline and read results/ only (plus the expected assertion file). They regenerate both tables, both PNG/TIFF figure pairs, all numerical provenance, dimensions and the reproduction report. Expected values are never used to manufacture findings.

`app/` contains the 21 files the page loads at e735558, byte-identical, with app-sha256.json. Two of them (hub/app-style.css, hub/shared/glossary.json: styling and tooltips) were missing from the run's snapshot and were added from git at e735558; they do not affect any computed value. The offline UI smoke test (`bench/ui_smoke.mjs`) passes 20/20 with no missing assets, no external requests and no page errors (results/ui-smoke.json).

## Scope and disclosure

Only intercept-only two-level-nested random-effect models are compared. There are no moderator, crossed-effect, spatial, phylogenetic or correlated-sampling-error comparisons. REML intervals use the normal distribution. The **MoM estimator, cluster-df interval and prediction interval were NOT compared with R**; neither they nor cluster-robust inference are validated here. Figure 2 concerns only the seven REML quantities. This archive task regenerates archived findings and runs a bounded offline use-case UI smoke check (20/20, results/ui-smoke.json), not the full R/browser corpus anew. No Overmind certification, deployment or release-readiness claim is made.

| Content | Static or dynamic | Evidence / transformation |
|---|---|---|
| Model, tolerances, confidence level, BFGS settings | Static protocol | Original scripts and results/protocol.json |
| Commit and PR identifiers | Static supplied provenance | Task source attribution and archived fix.patch; no network verification |
| Expected manuscript values | Static assertions | expected/paper_values.json; compared with recomputed values |
| Counts, comparison errors, tables and figure coordinates | Dynamic | results corpus, disposition, reference and app records |
| Use-case and optimizer values | Dynamic | Full-precision recorded fits; rounding only for claims |
| Figure dimensions, typography and colours | Static presentation | analysis/make_outputs.py; dimensions checked from files |
| Checksums | Dynamic integrity record | SHA-256 of supplied/assembled files; not independent scientific certification |

SOURCE_SHA256.json covers archive source files (excluding itself, generated outputs, rerun/, caches and git metadata). The app manifest additionally verifies the bytes copied from the pinned source. No manuscript drafts, machine paths or secrets are included. This tree is suitable for a future git repository; verification permits `.git`, and no git repository was initialized.

Derived from [allmeta](https://github.com/mahmood726-cyber/allmeta) and allmeta v1.2.1, DOI **10.5281/zenodo.23288388**. Links and identifiers are supplied metadata, not network-fetched evidence. Data and package documentation retain their upstream attribution in bench/docs/ and the source package citations; the MIT license covers this archive's code and does not replace upstream rights.
