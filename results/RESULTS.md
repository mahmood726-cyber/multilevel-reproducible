# Job 7: multilevel meta-analysis validation


Source commit: `39f172b00233d072bdce5cfe4c7137f79167708a`. Source files were read-only; SHA-256 equality with local original copies was verified. No repository, index, workbook, push, or deployment changes were made.

Enumerated **114** metadat datasets; used **41**, excluded **73**. Ran **44** REML configurations on **8069** effect rows. Original: **506/528 checks pass**. Patched local copy: **528/528 checks pass**.

These totals include numerical REML parity, conditional MoM I²-formula checks, row counts and rendered-value contracts. They are not a claim that the MoM estimator equals REML or that all clinical models are appropriate.

## Methods and provenance

Environment: R version 4.6.0 (2026-04-24 ucrt); metafor 5.2.1; metadat 1.6.0; Chrome 154.0.8037.93. Node and Python were invoked from PATH.

Reference: rma.mv(y, v, random = ~1|cluster/id, method='REML', sparse=TRUE), intercept only, test='z'. Each retained row has its own nested id. Full-precision JSON uses sprintf('%.17g'). The app receives exactly corpus.json values, with SE=sqrt(v); CSV-safe cluster labels are bijective recodings of the stored source identifiers. Invalid/missing effects and nonpositive variances are excluded identically before either fit; reference.json records omitted source row indices.

The corpus comes exclusively from installed metadat data and metafor::escalc. Local package help is archived in docs/. No data were simulated or downloaded. Source-imputed ghost effects in dat.bakdash2021 remain explicitly source-imputed. NCT/DOI fields are copied from source records as grouping labels, not asserted as independently verified registry claims.

Inventory.csv records columns and repeated values for every dataset. Dataset-disposition.csv records every final inclusion/exclusion. Repeated author surnames alone do not establish nesting: dat.egger2001, dat.lee2004, and dat.li2007 were removed after their unique trial IDs and help descriptions were checked. Wide binary endpoints were explicitly stacked in wide.R; their grand effects are numerical benchmarks, not clinical conclusions.

## What the page actually computes

The inline fit() in multilevel-ma/index.html:161-285 is an iterated method-of-moments calculation. Its values populate the first table, forest, JSON export, and pooled-result transfer. The separate displayed REML table calls unchanged shared/multilevel-reml.js at index.html:318 and retains that fit in __almReml(). Browser execution used the whole page and shipped dependencies, without extracting or reimplementing the estimator.

Seven REML quantities are compared: mu, SE, both normal confidence limits, both variance components, and REML log-likelihood. z, p, Q and Q p-values are retained in reference.json but are not exposed by this page, so they have no fabricated app comparisons. ML, moderator coefficients, variance-component CIs, and a REML test='t' configuration are not offered.

The displayed I² shares belong to MoM, not the REML table. For the intercept-only model, typical sampling variance is (k-1)/(sum(w)-sum(w²)/sum(w)), w=1/v; each share is its variance divided by the sum of typical sampling variance and both heterogeneity components. These closed-form checks condition on the page's MoM components. R REML-based shares are also saved, and comparison JSON records MoM-minus-REML differences without treating distinct estimators as interchangeable.

The page also labels a residual-scale interval HKSJ and uses cluster df J-1. This is not metafor's rma.mv(test='t') or a cluster-robust fit. Its calibration and the prediction interval are not certified by this parity study. The original footer incorrectly said only a 1.96 interval without HK was shown; the patch describes the actual separate intervals.

## Tolerances

Error = abs(app-reference)/max(1,abs(reference)); p-values, if compared, use absolute error. All seven iterative REML quantities use 1e-6, including variance components; no 1e-4 relaxation was needed. Conditional I² shares use 1e-9 in fraction units (not percentage points). Row-count and rendering contracts are exact.

## Per-quantity results

| Quantity | Original pass/checks | Patched pass/checks | Original maximum error | Patched maximum error | Tolerance |
|---|---:|---:|---:|---:|---:|
| mu | 44/44 | 44/44 | 2.3390059139538621e-07 | 2.3390059139538621e-07 | 1e-06 |
| se | 44/44 | 44/44 | 3.1423260604679371e-07 | 3.1423260604679371e-07 | 1e-06 |
| ciLo | 44/44 | 44/44 | 3.8198399923694559e-07 | 3.8198399923694559e-07 | 1e-06 |
| ciHi | 44/44 | 44/44 | 8.4978518211098475e-07 | 8.4978518211098475e-07 | 1e-06 |
| sigma2Between | 44/44 | 44/44 | 5.5463724172796769e-07 | 5.5463724172796769e-07 | 1e-06 |
| sigma2Within | 44/44 | 44/44 | 4.6890289739920377e-07 | 4.6890289739920377e-07 | 1e-06 |
| logLik | 44/44 | 44/44 | 1.3277410384479676e-10 | 1.3277410384479676e-10 | 1e-06 |
| UI_row_count | 44/44 | 44/44 | 0 | 0 | 0 |
| UI_REML_render | 44/44 | 44/44 | 0 | 0 | 0 |
| I2_study_formula | 38/44 | 44/44 | 1.0026213459468636e-07 | 7.2164496600635175e-16 | 1e-09 |
| I2_within_formula | 37/44 | 44/44 | 9.8416135102530333e-09 | 3.8857805861880479e-16 | 1e-09 |
| I2_sampling_formula | 35/44 | 44/44 | 3.8018934667150006e-09 | 1.1657341758564144e-15 | 1e-09 |

## Failures, diagnosis, and patch

1. **I² denominator bias:** index.html:260 adds 1e-10 to the total variance. This prevents exact decomposition and causes the closed-form failures, especially at small variance scales. fix.patch removes this additive constant. Positive finite sampling variances and k>=3 imply a positive typical variance on the tested domain.

2. **Method mislabel:** index.html:475 calls the chart receipt REML even though its results are _lastResults from MoM. The patch names the receipt method correctly, adds an explicit MoM caption, and corrects the stale interval description. The numerical REML engine is unchanged.

3. **Reference optimizer precision:** the preliminary 37-configuration run had 385/407 passing checks, including three numerical discrepancies on dat.maire2019. nlminb reported logLik=-199.88753459235858; independent BFGS (reltol=1e-14) reached -199.88753459234036, agreeing with the app's -199.88753459234030. The stricter nlminb and rescaled-input attempts refused convergence (code 1), recorded by diagnose.R. The final reference uses BFGS for this dataset only. reference-nlminb.json and comparison-initial.json preserve the initial evidence; maire-bfgs-reference.json stores the replacement at full precision. This is reference refinement, not an app-engine fix or tolerance widening.

All final reference configurations returned estimates. No both-refuse cases were counted as passes. Original numerical I² failures remain visible; only the local patched copy resolves them. No fix was applied to allmeta.

## Verbatim final console lines

```text
44/44 browser configurations run; 0 page errors
506/528 checks pass
44/44 browser configurations run; 0 page errors
528/528 checks pass
```

Full per-quantity console output is in comparison-console.txt and comparison-patched-console.txt. The preliminary console count was 385/407 checks pass; the count grew when rendering contracts and wide-endpoint datasets were added.

## Commands executed and reproduction

Run from this job folder. R_LIBS_USER was set to the library directory specified in ../codex_common.md. No packages were installed and no web requests were made. Inspection commands included Get-Content/rg, Get-Command Rscript,node,python, source git rev-parse HEAD, and git status (the job folder is not a git repository). The computational commands were:

```text
Rscript inventory.R
Rscript reference.R
Rscript audit.R
Copy-Item corpus.json corpus-base.json
Copy-Item reference.json reference-base.json
Rscript supplement.R
python merge.py
node run-app.mjs
python compare.py
Rscript diagnose.R
python finalize-reference.py
python make-patch.py
node run-app.mjs patched
python compare.py patched
Copy-Item corpus.json corpus-base.json
Copy-Item reference.json reference-base.json
Rscript wide.R
python merge.py
node run-app.mjs
node run-app.mjs patched
python report.py
```

diagnose.R was run three times while adding error capture and preserving the successful BFGS reference; stricter/scaled nlminb attempts were bounded and not silently substituted. One attempted Python -c script-writing command failed because Windows stripped quotes; the script was then written with UTF-8-no-BOM WriteAllText and executed successfully. The failed command session was stopped before the final merge. The source snapshot was copied into original/ and make-patch.py creates patched/ and the unified diff.

For a clean full replay use replay.py, which orders the same scripts and preserves each reference stage. For checking existing artifacts, python report.py reruns comparison and artifact consistency checks without refitting.

## Static versus dynamic disclosure

| Item | Static or dynamic | Basis |
|---|---|---|
| Dataset choices, grouping variables, transformation recipes | Static analysis specification | Package schemas and help; explicit in R scripts and tables below |
| Input effects, variances, identifiers | Dynamic source reads | Installed metadat records; escalc where required |
| R reference values and app results | Dynamic computation | Actual R and headless Chrome runs |
| Tolerances and 95% confidence level | Static test contract | Task instructions and shipped app |
| Counts, maxima, report tables and source hashes | Dynamic | Computed from saved artifacts by report.py |

## Configuration and nesting register

| Configuration | Rows | Clusters | Cluster variable and rationale |
|---|---:|---:|---|
| dat.assink2016 | 100 | 17 | study: Documented study groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.konstantopoulos2011 | 56 | 11 | district: Documented district groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.berkey1998 | 10 | 5 | trial: Documented trial groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.berkey1998r | 10 | 5 | trial: Documented trial groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.kalaian1996 | 67 | 47 | study: Documented study groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.knapp2017 | 66 | 31 | study: Documented study groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.tannersmith2016 | 113 | 17 | studyid: Documented studyid groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.riley2003 | 98 | 81 | study: Documented study groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.mccurdy2020 | 1653 | 126 | article: Documented article groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.lehmann2018 | 81 | 41 | Full_Citation: Documented Full_Citation groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.begg1989 | 20 | 16 | study: Documented study groups supplied effect estimates; diagonal sampling V; row id is nested effect. |
| dat.bakdash2021 | 678 | 79 | SampleID: Documented experiment identifier; supplied z correlations include source-imputed ghost results, not generated here. |
| dat.cohen1981 | 20 | 16 | study: Documented study identifier; Fisher z correlations from escalc; diagonal V. |
| dat.craft2003 | 54 | 10 | study: Documented study identifier; Fisher z correlations from escalc; diagonal V. |
| dat.crede2010 | 97 | 68 | studyid: Documented study identifier; Fisher z correlations from escalc; diagonal V. |
| dat.white2020 | 186 | 41 | study_id: Documented study identifier; Fisher z correlations from escalc; diagonal V. |
| dat.demir2022 | 33 | 26 | studyid: Study identifier groups reliability estimates; ABT transformation from package example. |
| dat.bornmann2007 | 66 | 21 | study: Study reference groups award comparisons; log odds ratios per help example. |
| dat.bourassa1996 | 54 | 47 | study: Combined-sex samples within studies per package example; avoids overlapping subgroup rows. |
| dat.curtis1998 | 102 | 29 | paper: Paper groups plant experiments; log response ratios. |
| dat.besson2016 | 389 | 46 | study_ID: Documented study ID groups comparisons; SMD from reported means and SE times sqrt(n); raw experimental direction, diagonal V. |
| dat.anand1999 | 34 | 31 | study: Repeated documented study/trial identifier; log OR; diagonal V; numerical validation not a clinical pooled estimand. |
| dat.yusuf1985 | 118 | 61 | id: Repeated documented study/trial identifier; log OR; diagonal V; numerical validation not a clinical pooled estimand. |
| dat.hartmannboyce2018 | 136 | 133 | study: Study groups nicotine comparisons; log OR; shared-control covariance omitted in both fits. |
| dat.landenberger2005 | 58 | 54 | study: Study identifier groups CBT comparisons; log OR. |
| dat.lim2014/m_o_size | 357 | 220 | article: Documented article/study groups correlations; two-level reduction excludes phylogenetic random effects. |
| dat.lim2014/m_o_fecundity | 517 | 289 | article: Documented article/study groups correlations; two-level reduction excludes phylogenetic random effects. |
| dat.lim2014/o_o_unadj | 170 | 125 | article: Documented article/study groups correlations; two-level reduction excludes phylogenetic random effects. |
| dat.lim2014/o_o_adj | 185 | 85 | article: Documented article/study groups correlations; two-level reduction excludes phylogenetic random effects. |
| dat.moura2021/dat | 1828 | 457 | study.id: Documented article/study groups correlations; two-level reduction excludes phylogenetic random effects. |
| dat.maire2019 | 35 | 11 | site: Stations within sites; supplied s1 and vars1; two-level reduction excludes spatial correlation. |
| dat.anker2025 | 12 | 6 | study: Disjoint male/female log risk ratios within trials; excludes overlapping overall estimate. |
| dat.ishak2007 | 82 | 46 | study: Repeated timepoint effects within studies; diagonal V benchmark excludes temporal sampling covariance. |
| dat.dagostino1998 | 34 | 9 | study: Continuous outcomes within study; SMD; missing continuous summaries excluded. |
| dat.axfors2021 | 33 | 28 | id: Source registry identifier groups trial arms; supplied IDs used only as cluster labels; diagonal V benchmark. |
| dat.hannum2020 | 35 | 34 | DOI: Source article DOI groups olfactory loss estimates; diagonal V benchmark. |
| dat.obrien2003 | 43 | 13 | study: Documented study ID groups BMI strata; raw proportions; intercept-only reduction of documented multilevel regression. |
| dat.cannon2006 | 24 | 4 | cluster: Wide endpoints stacked within source trial ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |
| dat.fine1993 | 66 | 17 | cluster: Wide endpoints stacked within source study ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |
| dat.chiarito2020 | 32 | 9 | cluster: Wide endpoints stacked within source study ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |
| dat.karner2014 | 128 | 22 | cluster: Wide endpoints stacked within source study ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |
| dat.nissen2007 | 84 | 42 | cluster: Wide endpoints stacked within source study ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |
| dat.collins1985a | 71 | 27 | cluster: Wide endpoints stacked within source id ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |
| dat.collins1985b | 34 | 9 | cluster: Wide endpoints stacked within source id ; log OR; overlapping/different endpoints, numerical benchmark only, not a clinical grand effect. |

## Excluded datasets

Every remaining inventory entry is listed here; exclusion is from this intercept-only nested-effect validation, not a claim that the dataset cannot support any meta-analysis.

| Dataset | Reason |
|---|---|
| dat.aloe2013 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.baker2009 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.bangertdrowns2004 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.bartos2023 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.baskerville2012 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.bassler2004 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.bauer2002 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.bcg | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.bonett2010 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.colditz1994 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.crisafulli2020 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.curtin2002 | One mean difference per crossover study; author repetition across distinct publications does not establish nesting. |
| dat.damico2009 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.debruin2009 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.dogliotti2014 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.dong2013 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.dorn2007 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.dumouchel1994 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.egger2001 | Unique trial id; repeated study field is first author surname, not evidence of shared trial. |
| dat.feng2019 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.franchini2012 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.frank2008 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.furukawa2003 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.gibson2002 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.graves2010 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.greb2008 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.greenland1992 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.gurusamy2011 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.hackshaw1998 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.hahn2001 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.hart1999 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.hasselblad1998 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.higgins2008 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.hine1989 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.huber2000 | Individual participant counts, not effect-size rows. |
| dat.kearon1998 | Diagnostic accuracy tables with threshold/test structure; bivariate model unsupported. |
| dat.laopaiboon2015 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.lau1992 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.lee2004 | Unique trial id; repeated study field is first author surname, not evidence of shared trial. |
| dat.li2007 | Unique trial id; repeated study field is first author surname, not evidence of shared trial. |
| dat.linde2005 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.linde2015 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.linde2016 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.lloyd2010 | DAS and HAQ on different scales; common intercept not meaningful. |
| dat.lopez2019 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.mcdaniel1994 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.meeker2017 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.metap | List of separate univariate meta-analyses, not nested effects. |
| dat.michael2013 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.molloy2014 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.moore1998 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.nakagawa2007 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.nielweise2007 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.nielweise2008 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.normand1999 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.pagliaro1992 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.pignon2000 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.poole2003 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.pritz1997 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.quan2000 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.raudenbush1985 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.rivera2025 | Diagnostic accuracy metrics; bivariate test structure unsupported. |
| dat.roever2022 | Dose-arm data require dose model, unsupported. |
| dat.senn2013 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.spooner2002 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.steurer2006 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.stowe2010 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.thompson1999 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.tian2009 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |
| dat.ursino2021 | Dose-arm data require dose model, unsupported. |
| dat.vanhowe1999 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.viechtbauer2021 | No documented repeated study-level effect-size structure in supplied table; repeated covariates/authors alone are not cluster evidence. |
| dat.woods2010 | Arm-based network/different-treatment data; no common supplied contrast estimand for intercept-only nested-effect app; network covariance/treatment moderators not supported. |

## Boundaries

Additional random effects (phylogeny, spatial structure, crossed outcomes) and correlated sampling errors are deliberately absent from both benchmark fits. Some included datasets combine outcomes with different clinical meanings; their numerical parity is not an endorsement of a pooled interpretation. Coverage includes every package inventory entry with an explicit decision, but not every possible outcome transformation or subgroup analysis. All checks validate this pinned code and corpus, not universal accuracy or release readiness. No Overmind certification was attempted.

## Run warnings and final checks

R reported locale-initialization warnings for LC_COLLATE, LC_CTYPE, LC_MONETARY, and LC_TIME. The Besson SMD transformation warned about unusually large SMD values; its SE-to-SD conversion was checked against the package help. These warnings are retained in reference-console.txt; fit-specific warnings are in reference.json. The final unified diff passed git apply --check --directory=original fix.patch. No global browser cleanup was used.
