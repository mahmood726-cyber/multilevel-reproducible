# Reproduction report

All findings are recomputed from results/; expected values are assertions, never substituted for measurements.

| Claim | Expected | Reproduced | Verdict |
|---|---|---|---|
| datasets_enumerated | 114 | 114 | PASS |
| datasets_used | 41 | 41 | PASS |
| datasets_excluded | 73 | 73 | PASS |
| configurations | 44 | 44 | PASS |
| effect_sizes | 8069 | 8069 | PASS |
| checks_per_configuration | 12 | 12 | PASS |
| checks | 528 | 528 | PASS |
| passed | 528 | 528 | PASS |
| before_passed | 506 | 506 | PASS |
| reml_quantities | 7 | 7 | PASS |
| share_quantities | 3 | 3 | PASS |
| exact_quantities | 2 | 2 | PASS |
| usecase_rows | 56 | 56 | PASS |
| usecase_clusters | 11 | 11 | PASS |
| max_mu | 2.3e-07 | 2.3e-07 | PASS |
| max_se | 3.1e-07 | 3.1e-07 | PASS |
| max_confidence_limits | 8.5e-07 | 8.5e-07 | PASS |
| max_sigma2Between | 5.5e-07 | 5.5e-07 | PASS |
| max_sigma2Within | 4.7e-07 | 4.7e-07 | PASS |
| max_logLik | 1.3e-10 | 1.3e-10 | PASS |
| usecase_app_mu | 0.185 | 0.185 | PASS |
| usecase_app_se | 0.085 | 0.085 | PASS |
| usecase_app_ciLo | 0.019 | 0.019 | PASS |
| usecase_app_ciHi | 0.35 | 0.35 | PASS |
| usecase_app_sigma2Between | 0.0651 | 0.0651 | PASS |
| usecase_app_sigma2Within | 0.0327 | 0.0327 | PASS |
| usecase_app_logLik | -7.959 | -7.959 | PASS |
| usecase_R_mu | 0.185 | 0.185 | PASS |
| usecase_R_se | 0.085 | 0.085 | PASS |
| usecase_R_ciLo | 0.019 | 0.019 | PASS |
| usecase_R_ciHi | 0.35 | 0.35 | PASS |
| usecase_R_sigma2Between | 0.0651 | 0.0651 | PASS |
| usecase_R_sigma2Within | 0.0327 | 0.0327 | PASS |
| usecase_R_logLik | -7.959 | -7.959 | PASS |
| usecase_mom_mu | 0.128 | 0.128 | PASS |
| maire_nlminb_logLik | -199.88753459235858 | -199.88753459235858 | PASS |
| maire_bfgs_logLik | -199.88753459234036 | -199.88753459234036 | PASS |
| maire_app_logLik | -199.8875345923403 | -199.8875345923403 | PASS |
| version_R | R version 4.6.0 (2026-04-24 ucrt) | R version 4.6.0 (2026-04-24 ucrt) | PASS |
| version_metafor | 5.2.1 | 5.2.1 | PASS |
| version_metadat | 1.6.0 | 1.6.0 | PASS |
| commit | e7355582db9c79812027cb4b47710c3f2efc7ae3 | e7355582db9c79812027cb4b47710c3f2efc7ae3 | PASS |
| pull_request | 85 | 85 | PASS |
| reml_tolerance | 1e-06 | 1e-06 | PASS |
| share_tolerance | 1e-09 | 1e-09 | PASS |
| exact_tolerance | 0 | 0 | PASS |
| bfgs_reltol | 1e-14 | 1e-14 | PASS |
| confidence_percent | 95 | 95 | PASS |
| nested_random_levels | 2 | 2 | PASS |
| model_levels_including_sampling | 3 | 3 | PASS |
| original_denominator_epsilon | 1e-10 | 1e-10 | PASS |
| corrected_faults | 2 | 2 | PASS |

Figures: 300 dpi, nominal width 170 mm, all text at least 8 pt. Each plotted point is the scalar difference for one configuration and REML quantity. Exact zeros and differences below 1e-16 are plotted at -16. The orange diamond marks dat.maire2019; the dashed line is 1e-6. Table 1 is in the same alphabetical configuration order. Several configurations stack distinct endpoints; descriptions preserve this qualification.

Seven REML comparisons, three conditional MoM share-formula checks and two exact UI contracts make twelve checks per configuration. MoM estimates and cluster-df intervals were NOT validated against R. Formula parity conditions on app MoM components. Render checks are the historical runner's Boolean rounded-value-presence contract, not an independent cell-by-cell accessibility or export test.

Numbers include all empirical manuscript claims, versions and protocol constants. Section/list numbering, bracketed citation numbers, dataset-name years, the dictated draft date and bibliographic numbering are identifiers or editorial metadata, not experimental claims. No manuscript draft is distributed. Package strings 5.2.1 and 1.6.0 are the R-reported forms of release labels 5.2-1 and 1.6-0.

Two app assets missing from the run's snapshot (a stylesheet and the tooltip glossary) were added from git at e735558; neither affects a computed value. The full archived historical numerical results remain reproducible from JSON. No full R corpus rerun or new release certification is implied by regenerating these outputs.


PASS: 52/52 paper-value assertions; 528/528 final checks; 506/528 before fixes.
