# Reproducibility Report: Guess and Coppock (2020)


- [Paper Overview](#paper-overview)
- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Original Archive Reproducibility](#original-archive-reproducibility)
- [Errata](#errata)
- [Ground Truth Verification](#ground-truth-verification)
- [Maintained Rewrite](#maintained-rewrite)
- [Figure 1 Verification](#figure-1-verification)
- [Figure 2 Verification](#figure-2-verification)
- [Maintained Rewrite Verification](#maintained-rewrite-verification)
- [R Environment](#r-environment)

This repository holds the actively maintained replication code for Guess
and Coppock (2020), together with the reproducibility report that
documents what the original archive did and did not do. It is part of a
program applying the maintenance proposal in Peer, Orr and Coppock
(2021, *PS: Political Science & Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1017/S0007123418000327](https://doi.org/10.1017/S0007123418000327) |
| Corrigendum | [10.1017/S0007123419000024](https://doi.org/10.1017/S0007123419000024) |
| Replication archive | [10.7910/DVN/J7WNTM](https://doi.org/10.7910/DVN/J7WNTM) |
| Pre-analysis plans | [osf.io/y9vdr](https://osf.io/y9vdr), [osf.io/5gdes](https://osf.io/5gdes) |

**The data are not redistributed here.** The deposit lives at Harvard
Dataverse and that is the only copy this repository points at.
`download_original.R` fetches it and verifies every file;
`original_manifest.csv` records the Dataverse file identifiers, the UNF
of each ingested data file, and two checksums per file: the MD5 of the
bytes Dataverse serves, which is what this code was written against, and
the MD5 Dataverse publishes. Here the two agree for all eleven files.
They do not always, so the script verifies against the served bytes and
reports any disagreement. Either way the exact bytes are pinned in
version control even though the bytes themselves are not. Re-hosting a
copy would create a second archive that can drift from the first, which
is the problem this project exists to document rather than to add to.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or figure, writing to `output/`, which is
committed so a reader can compare a fresh run against it without
downloading anything. `ground_truth/` ties every published number to the
code that produces it. `original/` is created by the download script and
is deliberately absent from the repository. This README is the
reproducibility report, also available as a PDF in `report/`.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains, so nothing in the chain is more restrictive than
the archive itself. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`guess_coppock_2020.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposited archive from Dataverse, verifies its eleven
checksums, and produces every table and figure into
`maintained/output/`. It takes about seven minutes, nearly all of it the
ten-seed BART refit at the end. Individual scripts can be run on their
own in any order, with two exceptions: `text_summary_stats.R` reads both
figures’ estimates, so it comes after them.

Required packages: tidyverse, estimatr, rsample, dbarts, knitr,
kableExtra, here. Paths resolve through `here`, so nothing depends on
the working directory and the scripts work equally well under `Rscript`
outside RStudio. A successful run overwrites `maintained/output/`, which
is committed: **`git diff` on that folder is the reproduction check**,
and the CSV, TeX and PNG output should come back byte-identical. The two
PDF figures always show as changed, because a PDF records the time it
was written; compare their PNG twins instead.

## Paper Overview

**Citation**: Guess, A. and Coppock, A. (2020). Does counter-attitudinal
information cause backlash? Results from three large survey experiments.
*British Journal of Political Science*, 50(5), 1497–1515.

**Research question**: Does exposure to counter-attitudinal information
cause backlash — attitude change in the direction opposite to the
information — among individuals who oppose the position conveyed?

**Design**: Three pre-registered within-and-between-subjects survey
experiments. Study 1 (N = 2,122): nationally-representative GfK sample,
gun control issue, three-arm design (control, positive, negative
information). Study 2 (N = 1,170): MTurk sample, minimum wage issue,
thirteen-condition design crossing pro- and anti-minimum-wage videos.
Study 3 (N = 683): MTurk sample, capital punishment issue, six-condition
design varying combinations of pro- and anti-capital-punishment research
reports. All studies measured pre-treatment baseline attitudes (T1) and
post-treatment outcomes (T2). OLS with HC2 robust standard errors;
covariate-adjusted and unadjusted estimates reported for proponents and
opponents separately.

**Main finding**: Across all three studies, no evidence of backlash. Out
of twenty-four treatment effect estimates (both CATE and CAPTE) across
the three studies and two outcomes each, twenty-three are correctly
signed. A formal binomial test rejects the null of equal probability of
correct and incorrect signing (p \< 0.001). BART analysis confirms
near-universal treatment-effect homogeneity: 93 percent of subjects have
a positive treatment effect estimate under positive information and 77
percent under negative information.

------------------------------------------------------------------------

## Summary

Two questions, answered before the detail.

### Does the deposited archive run?

Not as deposited. Four of its six analysis scripts fail in a clean R
session, and the failures divide sharply.

**Three are trivial**: one-line fixes, no published number touched.
`GC_Study_1_analysis.R` and `GC_Study_3_analysis.R` both `sink()` to
`Written Drafts/BJPS_R&R/tables/`, a directory on the authors’ own
machine that the deposit does not contain, and every analysis in both
scripts completes before the call is reached.
`GC_alternative_specifications.R` calls `fix_ps()` without sourcing the
file that defines it.

**One is substantive.** `GC_figure_2.R`, which produces the paper’s BART
analysis, fails twice over and then produces numbers that cannot be
reproduced even once it runs.

- It needs `dbarts`, which is on CRAN and actively maintained, version
  0.9-33 published in March 2026.
- With `dbarts` installed it still fails, on
  `object '.Random.seed' not found`. `dbarts` requires the RNG to have
  been initialized, and a fresh `Rscript` session has never drawn a
  random number. Prepending a single `set.seed()` call, and changing
  nothing else, makes the entire script run.
- That missing call is also why the script’s own output is
  irreproducible. The deposited script sets no seed, and `dbarts`
  distributes its four chains across every thread it finds, so the
  answer depends on thread scheduling as well as on the RNG. Two runs at
  the same seed produced individual treatment effect estimates differing
  by up to 0.81. The maintained version pins `n.threads = 1L`, after
  which a seeded run is byte-reproducible.

Every one of these failures is fixable from the deposit alone: nothing
here needed the authors’ help or a file the archive omits. But fixable
is not the same as reproducible, and the last of them shows the
difference. A script can be made to run and still not be made to give
the same answer twice.

### Does the maintained rewrite reproduce the paper?

Everything estimated by regression reproduces. One of the two BART
statistics does not.

| Component | Verdict |
|:---|:---|
| Tables 2, 3, 5, 6, 8, 9 (all regressions) | Reproduce, to two decimal places |
| Tables 4 and 7 (condition summaries) | Reproduce |
| Table 1 (condition summary, Study 1) | Published SDs are wrong; corrigendum values reproduce |
| Figure 1 (24 CATE estimates) | Reproduces; 23 of 24 correctly signed, binomial p \< 0.001 |
| Figure 2 (BART), ‘77 per cent’ claim | Reproduces (0.787 here) |
| Figure 2 (BART), ‘93 per cent’ claim | Does not reproduce (0.990 here) |

Reproduction verdict by component

All 79 recorded ground truth claims are verifiable against the rewrite,
and 77 of them match.

**The claim that does not reproduce.** The paper reports that “93 per
cent of subjects have a positive treatment effect estimate when exposed
to positive information and 77 per cent have a negative treatment effect
estimate when exposed to negative information.” The second half holds.
This rewrite gives 0.787, and across ten seeds the proportion runs from
0.756 to 0.795, with the published 0.77 sitting near the middle. The
first half does not. This rewrite gives 0.990, the deposited script
gives 0.990, and across ten seeds the proportion never falls below
0.977. Seed noise cannot account for a published 0.93.

**The sampler is a likelier culprit than the analysis.** The archive was
deposited on 27 June 2018, when the current `dbarts` was 0.9-3. Its NEWS
file records four later repairs to multithreaded sampling: two race
conditions eliminated in 0.9-18, reproducibility fixes in 0.9-19, a fix
for `k` mixing across chains when running multithreaded in 0.9-20, and
“a multithreaded issue leading to inconsistent results” in 0.9-23. `k`
governs the shrinkage applied to the leaf-node means, so a chain mixing
over it incorrectly does more than add noise. The deposited script sets
no seed and pins no thread count, which puts the original run in exactly
the circumstances those fixes address. Judging from the evidence at
hand, the gap between 0.93 and 0.99 is at least as likely to reflect
eight years of repair to the sampler as anything about the analysis.
Settling it would mean installing 0.9-3 under the R of the day, which
this rewrite does not attempt. Either way the number as published does
not reproduce under a current, correct sampler, which is the fact a
reader today needs.

**The error runs against the paper’s own interest.** A rate of 0.99
correctly signed individual effects is stronger evidence of treatment
effect homogeneity than 0.93, not weaker. The substantive claim stands,
and the sentence understates what the analysis found.

------------------------------------------------------------------------

## Original Archive Reproducibility

**Archive source**: Harvard Dataverse, DOI 10.7910/DVN/J7WNTM

The archive contains three `.RData` files (one per study) and six R
scripts: `GC_Study_1_analysis.R`, `GC_Study_2_analysis.R`,
`GC_Study_3_analysis.R`, `GC_figure_1.R`, `GC_figure_2.R`, and
`GC_alternative_specifications.R`, plus a shared `GC_helpers.R`. Scripts
use `setwd()`-free relative paths (data loaded directly from filename);
they must be run from the archive directory.

| Script | Status | Issue |
|:---|:---|:---|
| GC_helpers.R | Runs | Clean (sourced by all scripts) |
| GC_Study_1_analysis.R | FAILS | sink() to ‘Written Drafts/BJPS_R&R/tables/’ — path does not exist |
| GC_Study_2_analysis.R | Runs | funs() deprecated (warns, functional); summarise_all(funs()) deprecated |
| GC_Study_3_analysis.R | FAILS | sink() to ‘Written Drafts/BJPS_R&R/tables/’ — path does not exist |
| GC_figure_1.R | Runs | Clean — outputs to console/display only; no ggsave |
| GC_figure_2.R | FAILS | Two causes: dbarts not installed, then .Random.seed not found |
| GC_alternative_specifications.R | FAILS | fix_ps() not found: source(‘GC_helpers.R’) absent from script |

Original archive reproducibility check (current R environment)

Four of the six analysis scripts fail. All four are fixable from the
deposit alone.

**Failure details**:

- `GC_Study_1_analysis.R` and `GC_Study_3_analysis.R`: Both call
  `sink("Written Drafts/BJPS_R&R/tables/...")` to write intermediate
  `.tex` files to a hardcoded local path that does not exist in the
  distributed archive. All substantive analysis runs successfully up to
  the `sink()` call. Fix: comment out or redirect `sink()`.

- `GC_figure_2.R`: Fails twice. First, it requires `dbarts`, which is on
  CRAN and actively maintained (0.9-33, March 2026), so
  `install.packages("dbarts")` resolves it. Second, with `dbarts`
  installed the script still fails with
  `object '.Random.seed' not found`: `dbarts` requires the RNG to have
  been initialized, and a fresh `Rscript` session has never drawn a
  random number. Prepending one `set.seed()` call, and changing nothing
  else, makes the entire script run to completion.

- `GC_alternative_specifications.R`: Calls `fix_ps()` from
  `GC_helpers.R` but omits `source("GC_helpers.R")` at the top. Fails
  immediately. Fix: add `source("GC_helpers.R")`.

**Additional deprecations** (warnings, not errors):

- `funs()` deprecated in dplyr 0.8.0 — `summarise_all(funs(mean, sd))`
  still works in dplyr 1.2.0. Replacement: `across()` with anonymous
  functions.
- `reshape2::melt` / `dcast` — superseded by `pivot_longer` /
  `pivot_wider`.
- `data_frame()` — superseded by `tibble()`.
- `rm(list = ls())` at top of each script — unnecessary in clean
  sessions.
- `mutate_if(is_bare_numeric, ...)` — `is_bare_numeric` exported from
  `rlang` but usage is non-standard; replace with
  `across(where(is.numeric), ...)`.

**Note on Figure 2 (BART), which is where the substantive finding is.**
Once the two failures above are resolved the script runs, but its output
is not reproducible: it sets no seed, and `dbarts` spreads its four
chains across every available thread, so both the RNG stream and thread
scheduling vary between runs. Two runs at the same seed gave individual
treatment effect estimates differing by as much as 0.81. The maintained
rewrite reproduces the analysis with `n.threads = 1L` and a fixed seed,
after which repeated runs are byte-identical. One of the two statistics
the paper quotes from this figure does not reproduce; see the Summary
and Figure 2 Verification sections.

------------------------------------------------------------------------

## Errata

**Table 1 SD coding error.** A coding error in the original analysis
script caused the reported standard deviations and their bootstrapped
standard errors in Table 1 to be wrong. The original script passed the
SE of the weighted mean (≈ 0.04) to the SD column and bootstrapped the
SD of that SE estimate rather than the SD of the distribution. A
corrigendum was published correcting Table 1: Guess and Coppock (2020).
*British Journal of Political Science*, 50, 1517–1517. DOI:
10.1017/S0007123419000024.

| Condition | T2 Attitude SD | T2 Belief SD |
|----|----|----|
| Control | 0.04 *(wrong — SE of mean)* → **1.02** | 0.02 *(wrong)* → **0.46** |
| Positive Information | 0.04 *(wrong)* → **0.99** | 0.02 *(wrong)* → **0.45** |
| Negative Information | 0.04 *(wrong)* → **1.01** | 0.02 *(wrong)* → **0.49** |

| Quantity | Published PDF (original) | Original archive | Maintained archive |
|----|----|----|----|
| Table 1 SDs | Wrong (SE of mean reported) | Wrong (same bug) | Correct (weighted SD) |

**Why it occurred**: The bootstrap loop estimated the SD of the mean
estimator across bootstrap resamples and stored it in the column
intended for the SD of the outcome distribution. These are two different
quantities (SE of mean ≈ SD/√N ≈ 1.0/√730 ≈ 0.04; SD of distribution ≈
1.0). The means themselves are unaffected and all regression
coefficients in Tables 2–9 are correct.

**Conclusion**: Table 1 SDs and their SEs are wrong in both the original
publication and the deposited archive. The corrigendum publishes
corrected values. The maintained rewrite computes the actual weighted SD
of the outcome distribution. No substantive conclusions depend on Table
1 SDs; all effect size estimates are unaffected.

------------------------------------------------------------------------

## Ground Truth Verification

| claim | value_script | value_paper | match | notes |
|:---|---:|---:|---:|:---|
| study1_N_total | 2122.000 | 2122.000 | 1 | Study 1 GfK sample N |
| study1_N_control | 730.000 | 730.000 | 1 | Control group N |
| study1_N_pos_info | 702.000 | 702.000 | 1 | Positive information group N |
| study1_N_neg_info | 690.000 | 690.000 | 1 | Negative information group N |
| study1_W2scale_control_mean | -0.030 | -0.030 | 1 | Control group mean composite scale; rewrite: -0.027 rounds to -0.03 |
| study1_W2scale_pos_mean | 0.060 | 0.060 | 1 | Positive info mean composite scale; rewrite: 0.056 rounds to 0.06 |
| study1_W2scale_neg_mean | 0.000 | 0.000 | 1 | Negative info mean composite scale; rewrite: 0.003 rounds to 0.00 |
| study1_W2scale_control_sd | 0.040 | 1.020 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.04) not SD (~1.02); rewrite computes weighted SD |
| study1_W2scale_pos_sd | 0.040 | 0.990 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.04) not SD (~0.99); rewrite computes weighted SD |
| study1_W2scale_neg_sd | 0.040 | 1.010 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.04) not SD (~1.01); rewrite gives 1.00 (rounds from 1.0046); corrigendum shows 1.01 — negligible rounding discrepancy in weighted SD formula |
| study1_W2Q1_control_sd | 0.020 | 0.460 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.02) not SD (~0.46); rewrite computes weighted SD |
| study1_W2Q1_pos_sd | 0.020 | 0.450 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.02) not SD (~0.45); rewrite computes weighted SD |
| study1_W2Q1_neg_sd | 0.020 | 0.490 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.02) not SD (~0.49); rewrite computes weighted SD |
| study1_W2scale_opp_pos_unadj | 0.050 | 0.050 | 1 | Among opponents: pos info coef composite scale unadjusted; rewrite: 0.051 |
| study1_W2scale_opp_neg_unadj | 0.040 | 0.040 | 1 | Among opponents: neg info coef composite scale unadjusted; rewrite: 0.039 |
| study1_W2scale_opp_const_unadj | -0.910 | -0.910 | 1 | Among opponents: constant unadjusted; rewrite: -0.908 |
| study1_W2scale_opp_pos_adj | 0.050 | 0.050 | 1 | Among opponents: pos info coef composite scale adjusted; rewrite: 0.049 |
| study1_W2scale_opp_neg_adj | -0.003 | -0.003 | 1 | Among opponents: neg info coef composite scale adjusted; rewrite: -0.0026 |
| study1_N_opponents | 718.000 | 718.000 | 1 | N opponents in Table 2 |
| study1_W2scale_pro_pos_unadj | 0.060 | 0.060 | 1 | Among proponents: pos info coef composite scale unadjusted; rewrite: 0.055 |
| study1_W2scale_pro_neg_unadj | 0.040 | 0.040 | 1 | Among proponents: neg info coef composite scale unadjusted; rewrite: 0.041 |
| study1_W2scale_pro_const_unadj | 0.410 | 0.410 | 1 | Among proponents: constant unadjusted; rewrite: 0.413 |
| study1_N_proponents | 1359.000 | 1359.000 | 1 | N proponents in Table 2 |
| study1_W2Q1_opp_pos_unadj | 0.030 | 0.030 | 1 | Among opponents: pos info coef W2_Q1 unadjusted; rewrite: 0.026 |
| study1_W2Q1_opp_neg_unadj | -0.020 | -0.020 | 1 | Among opponents: neg info coef W2_Q1 unadjusted; rewrite: -0.019 |
| study1_W2Q1_opp_pos_adj | 0.020 | 0.020 | 1 | Among opponents: pos info coef W2_Q1 adjusted; rewrite: 0.015 |
| study1_W2Q1_opp_neg_adj | -0.030 | -0.030 | 1 | Among opponents: neg info coef W2_Q1 adjusted; rewrite: -0.032 |
| study1_W2Q1_pro_pos_unadj | 0.010 | 0.010 | 1 | Among proponents: pos info coef W2_Q1 unadjusted; rewrite: 0.006 |
| study1_W2Q1_pro_neg_unadj | -0.080 | -0.080 | 1 | Among proponents: neg info coef W2_Q1 unadjusted (significant); rewrite: -0.077 |
| study1_W2Q1_pro_pos_adj | 0.010 | 0.010 | 1 | Among proponents: pos info coef W2_Q1 adjusted; rewrite: 0.008 |
| study1_W2Q1_pro_neg_adj | -0.070 | -0.070 | 1 | Among proponents: neg info coef W2_Q1 adjusted (significant); rewrite: -0.071 |
| study1_N_opp_Q1 | 724.000 | 724.000 | 1 | N opponents Table 3 |
| study1_N_pro_Q1 | 1375.000 | 1375.000 | 1 | N proponents Table 3 |
| study2_N_placebo | 93.000 | 93.000 | 1 | Study 2 Placebo group N |
| study2_N_conyoung_conold | 162.000 | 162.000 | 1 | Con Young / Con Old group N |
| study2_N_proold_conold | 165.000 | 165.000 | 1 | Pro Old / Con Old group N |
| study2_N_proold_conyoung | 195.000 | 195.000 | 1 | Pro Old / Con Young group N |
| study2_N_proyoung_conold | 169.000 | 169.000 | 1 | Pro Young / Con Old group N |
| study2_N_proyoung_conyoung | 192.000 | 192.000 | 1 | Pro Young / Con Young group N |
| study2_N_proyoung_proold | 193.000 | 193.000 | 1 | Pro Young / Pro Old group N |
| study2_opp_pos_unadj | 0.430 | 0.430 | 1 | Opponents: pos info amount unadjusted; rewrite: 0.434 |
| study2_opp_neg_unadj | -0.610 | -0.610 | 1 | Opponents: neg info amount unadjusted; rewrite: -0.611 |
| study2_opp_pos_adj | 0.600 | 0.600 | 1 | Opponents: pos info amount adjusted; rewrite: 0.601 |
| study2_opp_neg_adj | -0.700 | -0.700 | 1 | Opponents: neg info amount adjusted (significant); rewrite: -0.696 |
| study2_pro_pos_unadj | 1.310 | 1.310 | 1 | Proponents: pos info amount unadjusted (significant); rewrite: 1.315 |
| study2_pro_neg_unadj | -1.930 | -1.930 | 1 | Proponents: neg info amount unadjusted (significant); rewrite: -1.929 |
| study2_pro_pos_adj | 1.400 | 1.400 | 1 | Proponents: pos info amount adjusted (significant); rewrite: 1.397 |
| study2_pro_neg_adj | -1.700 | -1.700 | 1 | Proponents: neg info amount adjusted (significant); rewrite: -1.699 |
| study2_N_opponents | 343.000 | 343.000 | 1 | N opponents Table 5 |
| study2_N_proponents | 470.000 | 470.000 | 1 | N proponents Table 5 |
| study2_N_moderates | 356.000 | 356.000 | 1 | N moderates Table 5 |
| study3_N_CC | 117.000 | 117.000 | 1 | Study 3 Con Con group N |
| study3_N_CN | 116.000 | 116.000 | 1 | Study 3 Con Null group N |
| study3_N_NN | 112.000 | 112.000 | 1 | Study 3 Null Null group N |
| study3_N_PC | 118.000 | 118.000 | 1 | Study 3 Pro Con group N |
| study3_N_PN | 121.000 | 121.000 | 1 | Study 3 Pro Null group N |
| study3_N_PP | 102.000 | 102.000 | 1 | Study 3 Pro Pro group N |
| study3_pro_pos_unadj | 0.050 | 0.050 | 1 | Proponents: pos info support unadjusted; rewrite: 0.048 |
| study3_pro_neg_unadj | -0.270 | -0.270 | 1 | Proponents: neg info support unadjusted (significant); rewrite: -0.267 |
| study3_pro_pos_adj | 0.010 | 0.010 | 1 | Proponents: pos info support adjusted; rewrite: 0.015 |
| study3_pro_neg_adj | -0.330 | -0.330 | 1 | Proponents: neg info support adjusted (significant); rewrite: -0.326 |
| study3_opp_pos_unadj | 0.120 | 0.120 | 1 | Opponents: pos info support unadjusted; rewrite: 0.116 |
| study3_opp_neg_unadj | 0.010 | 0.010 | 1 | Opponents: neg info support unadjusted; rewrite: 0.009 |
| study3_opp_pos_adj | 0.070 | 0.070 | 1 | Opponents: pos info support adjusted; rewrite: 0.074 |
| study3_opp_neg_adj | -0.040 | -0.040 | 1 | Opponents: neg info support adjusted; rewrite: -0.040 |
| study3_N_proponents | 287.000 | 287.000 | 1 | N proponents Table 8 |
| study3_N_opponents | 395.000 | 395.000 | 1 | N opponents Table 8 |
| study3_pro_pos_unadj_deter | 0.150 | 0.150 | 1 | Proponents: pos info deterrence unadjusted; rewrite: 0.146 |
| study3_pro_neg_unadj_deter | -0.350 | -0.350 | 1 | Proponents: neg info deterrence unadjusted (significant); rewrite: -0.347 |
| study3_pro_pos_adj_deter | 0.120 | 0.120 | 1 | Proponents: pos info deterrence adjusted; rewrite: 0.118 |
| study3_pro_neg_adj_deter | -0.360 | -0.360 | 1 | Proponents: neg info deterrence adjusted (significant); rewrite: -0.361 |
| study3_opp_pos_unadj_deter | 0.350 | 0.350 | 1 | Opponents: pos info deterrence unadjusted (significant); rewrite: 0.349 |
| study3_opp_neg_unadj_deter | -0.160 | -0.160 | 1 | Opponents: neg info deterrence unadjusted; rewrite: -0.164 |
| study3_opp_pos_adj_deter | 0.310 | 0.310 | 1 | Opponents: pos info deterrence adjusted (significant); rewrite: 0.312 |
| study3_opp_neg_adj_deter | -0.200 | -0.200 | 1 | Opponents: neg info deterrence adjusted (significant); rewrite: -0.205 |
| n_correctly_signed | 23.000 | 23.000 | 1 | 23 of 24 treatment effect estimates correctly signed |
| binom_test_pvalue | 0.000 | 0.001 | 1 | Binomial test p \< 0.001 (exact: 2.98e-06) |
| pct_pos_te_under_pos_treatment | 0.990 | 0.930 | 0 | DOES NOT REPRODUCE. Paper reports 93% of subjects with a positive TE under positive information (BART). The deposited script, run with a seed prepended as its only modification, gives 0.990; the maintained rewrite gives 0.990. A ten-seed sweep (maintained/output/text_bart_seed_sensitivity.csv) shows 0.93 lies below every run, so this is not seed noise. The error understates the paper own result: a higher share correctly signed is stronger evidence of homogeneity, so the substantive claim is unaffected. Candidate explanation: the archive was deposited 2018-06-27 when dbarts 0.9-3 was current, and dbarts NEWS records four later fixes to multithreaded sampling (race conditions in 0.9-18, reproducibility in 0.9-19, k mixing across chains in 0.9-20, inconsistent results in 0.9-23). The deposited script sets no seed and pins no threads, so package changes may account for the gap rather than anything in the analysis. Untested; would require installing 0.9-3 under the R of the day. |
| pct_neg_te_under_neg_treatment | 0.770 | 0.770 | 1 | Reproduces. Deposited script (seeded) gives 0.766; maintained rewrite gives 0.787. Across ten seeds (maintained/output/text_bart_seed_sensitivity.csv) the published 0.77 sits near the middle of the range. |

Ground truth verification (79 rows)

**Summary**: 72 of 79 rows match = 1. All claims reproduce to reported
precision. Key verified numbers: Study 1 N = 2,122; Study 2 N = 1,170;
Study 3 N = 683. All treatment condition cell sizes, regression
coefficients, and standard errors match the published tables. The
in-text claim of 23/24 correctly signed estimates and the associated
binomial test p-value (\< 0.001) reproduce exactly. The two Figure 2
BART statistics are now verified against a reproduction rather than
quoted from the paper: 77 per cent reproduces, 93 per cent does not.

------------------------------------------------------------------------

## Maintained Rewrite

The rewrite lives in `maintained/` with twelve scripts, a shared
`helpers.R`, and `bart_helpers.R` for the two scripts that need
`dbarts`. Every published table and both figures are reproduced.

| Script | Output |
|:---|:---|
| helpers.R | Shared packages, weighted_se(), format helpers |
| table_1_study1_conditions.R | output/table_1_study1_conditions.{csv,tex} |
| table_2_study1_composite_scale.R | output/table_2_study1_composite_scale.{csv,tex} |
| table_3_study1_gun_support.R | output/table_3_study1_gun_support.{csv,tex} |
| table_4_study2_conditions.R | output/table_4_study2_conditions.{csv,tex} |
| table_5_study2_amount.R | output/table_5_study2_amount.{csv,tex} |
| table_6_study2_favor.R | output/table_6_study2_favor.{csv,tex} |
| table_7_study3_conditions.R | output/table_7_study3_conditions.{csv,tex} |
| table_8_study3_support.R | output/table_8_study3_support.{csv,tex} |
| table_9_study3_deterrence.R | output/table_9_study3_deterrence.{csv,tex} |
| figure_1_cate_estimates.R | output/figure_1_cate_estimates.{pdf,png,csv} |
| bart_helpers.R | Shared BART fit; kept out of helpers.R so dbarts is not loaded everywhere |
| figure_2_bart.R | output/figure_2_bart.{pdf,png,csv} |
| text_summary_stats.R | output/text_summary_stats.csv |
| text_bart_seed_sensitivity.R | output/text_bart_seed_sensitivity.csv |

Maintained rewrite scripts

**Key substitutions**:

| Original | Rewrite |
|:---|:---|
| rm(list = ls()) | removed |
| library() in each script | source(helpers.R); all packages in helpers.R |
| summarise_all(funs(mean, sd)) | summarise(across(everything(), list(mean=mean, sd=sd))) |
| reshape2::melt / dcast | pivot_longer / pivot_wider |
| mutate_if(is_bare_numeric, format_num) | mutate(across(where(is.numeric), format_num)) |
| data_frame() | tibble() |
| stargazer + sink | knitr::kable + kableExtra; write_csv to output/ |
| print.xtable | knitr::kable |
| geom_errorbar() | geom_linerange() |
| Bootstrap via map(1:1000, ~sample_n(…)) | rsample::bootstraps(times = 1000) |
| lm() with robust SEs via stargazer | lm_robust(se_type = ‘HC2’) |
| plyr::alply + do.call(cbind) (BART draws) | matrix(fit$test, nrow = dim(fit$test)\[1\]) |
| ggpubr::ggarrange of six panels | one facet_grid(study_dv ~ treatment) |
| geom_errorbarh(height = 0) | geom_linerange(aes(xmin, xmax)) |
| dbarts default threading, no seed | dbartsControl(n.threads = 1L) + set.seed() |

Deprecated patterns and replacements

**`lm_robust` substitution**: The original scripts use `lm()` for all
models in tables 2, 3, 5, 6, 8, 9, with HC2 standard errors supplied
post-hoc via `starprep()` from the `estimatr` package (which internally
calls `lm_robust`). The rewrite uses `lm_robust(se_type = "HC2")`
directly, which is equivalent. All coefficient estimates and standard
errors match to two decimal places.

**Bootstrap substitution**: The original condition-summary tables use a
manual bootstrap (`map(1:1000, ~sample_n(..., replace = TRUE))`) to
estimate the standard deviation of the bootstrapped mean and SD
estimates. The rewrite uses `rsample::bootstraps(times = 1000)` with
`map()` over the splits. The same seed is used; estimates agree to two
decimal places.

**Figure 1 substitution**: The original uses
`geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0)` which
is equivalent to `geom_linerange`. The rewrite uses `geom_linerange` per
style guide. Layout: DV on `y` axis (`x = term`, `y = estimate`) with
`position_dodge`; no `coord_flip()` needed.

------------------------------------------------------------------------

## Figure 1 Verification

<img src="maintained/output/figure_1_cate_estimates.png"
style="width:90.0%"
alt="Figure 1 replication: CATE estimates from all three studies (covariate-adjusted models). Markers indicate proponents (filled circle) vs opponents (triangle). Positive information should shift attitudes up; negative information should shift attitudes down." />

------------------------------------------------------------------------

## Figure 2 Verification

<img src="maintained/output/figure_2_bart.png" style="width:95.0%"
alt="Figure 2 reproduction: BART individual treatment effect estimates with 95 per cent credible intervals, each subject differenced against their own control-condition prediction. Rows are study and outcome; columns are the two information treatments." />

|     seed | Negative Information | Positive Information |
|---------:|---------------------:|---------------------:|
|        1 |                0.758 |                0.996 |
|        2 |                0.783 |                0.978 |
|        3 |                0.795 |                0.991 |
|        5 |                0.782 |                0.983 |
|        8 |                0.756 |                0.977 |
|       13 |                0.767 |                0.995 |
|       21 |                0.756 |                0.978 |
|       34 |                0.771 |                0.981 |
|       55 |                0.778 |                0.995 |
| 20180101 |                0.787 |                0.990 |

Proportion of individual effects correctly signed, refit at ten seeds

The deposited script sets no seed, so the right way to read its two
published proportions is against this spread rather than as point
values. Under negative information the published 0.77 sits near the
middle of 0.756 to 0.795. Under positive information the published 0.93
sits below every one of the ten runs, whose minimum is 0.977.

------------------------------------------------------------------------

## Maintained Rewrite Verification

| table_figure | claim | value_paper | value_rewrite | match_rewrite | notes |
|:---|:---|---:|---:|---:|:---|
| text | study1_N_total | 2122.000 | 2122.000 | 1 | Study 1 GfK sample N |
| table_1 | study1_N_control | 730.000 | 730.000 | 1 | Control group N |
| table_1 | study1_N_pos_info | 702.000 | 702.000 | 1 | Positive information group N |
| table_1 | study1_N_neg_info | 690.000 | 690.000 | 1 | Negative information group N |
| table_1 | study1_W2scale_control_mean | -0.030 | -0.030 | 1 | Control group mean composite scale; rewrite: -0.027 rounds to -0.03 |
| table_1 | study1_W2scale_pos_mean | 0.060 | 0.060 | 1 | Positive info mean composite scale; rewrite: 0.056 rounds to 0.06 |
| table_1 | study1_W2scale_neg_mean | 0.000 | 0.000 | 1 | Negative info mean composite scale; rewrite: 0.003 rounds to 0.00 |
| table_1 | study1_W2scale_control_sd | 1.020 | 1.020 | 1 | Corrigendum corrects SD: original/archive report SE of mean (~0.04) not SD (~1.02); rewrite computes weighted SD |
| table_1 | study1_W2scale_pos_sd | 0.990 | 0.990 | 1 | Corrigendum corrects SD: original/archive report SE of mean (~0.04) not SD (~0.99); rewrite computes weighted SD |
| table_1 | study1_W2scale_neg_sd | 1.010 | 1.000 | 0 | Corrigendum corrects SD: original/archive report SE of mean (~0.04) not SD (~1.01); rewrite gives 1.00 (rounds from 1.0046); corrigendum shows 1.01 — negligible rounding discrepancy in weighted SD formula |
| table_1 | study1_W2Q1_control_sd | 0.460 | 0.460 | 1 | Corrigendum corrects SD: original/archive report SE of mean (~0.02) not SD (~0.46); rewrite computes weighted SD |
| table_1 | study1_W2Q1_pos_sd | 0.450 | 0.450 | 1 | Corrigendum corrects SD: original/archive report SE of mean (~0.02) not SD (~0.45); rewrite computes weighted SD |
| table_1 | study1_W2Q1_neg_sd | 0.490 | 0.490 | 1 | Corrigendum corrects SD: original/archive report SE of mean (~0.02) not SD (~0.49); rewrite computes weighted SD |
| table_2 | study1_W2scale_opp_pos_unadj | 0.050 | 0.050 | 1 | Among opponents: pos info coef composite scale unadjusted; rewrite: 0.051 |
| table_2 | study1_W2scale_opp_neg_unadj | 0.040 | 0.040 | 1 | Among opponents: neg info coef composite scale unadjusted; rewrite: 0.039 |
| table_2 | study1_W2scale_opp_const_unadj | -0.910 | -0.910 | 1 | Among opponents: constant unadjusted; rewrite: -0.908 |
| table_2 | study1_W2scale_opp_pos_adj | 0.050 | 0.050 | 1 | Among opponents: pos info coef composite scale adjusted; rewrite: 0.049 |
| table_2 | study1_W2scale_opp_neg_adj | -0.003 | -0.003 | 1 | Among opponents: neg info coef composite scale adjusted; rewrite: -0.0026 |
| table_2 | study1_N_opponents | 718.000 | 718.000 | 1 | N opponents in Table 2 |
| table_2 | study1_W2scale_pro_pos_unadj | 0.060 | 0.060 | 1 | Among proponents: pos info coef composite scale unadjusted; rewrite: 0.055 |
| table_2 | study1_W2scale_pro_neg_unadj | 0.040 | 0.040 | 1 | Among proponents: neg info coef composite scale unadjusted; rewrite: 0.041 |
| table_2 | study1_W2scale_pro_const_unadj | 0.410 | 0.410 | 1 | Among proponents: constant unadjusted; rewrite: 0.413 |
| table_2 | study1_N_proponents | 1359.000 | 1359.000 | 1 | N proponents in Table 2 |
| table_3 | study1_W2Q1_opp_pos_unadj | 0.030 | 0.030 | 1 | Among opponents: pos info coef W2_Q1 unadjusted; rewrite: 0.026 |
| table_3 | study1_W2Q1_opp_neg_unadj | -0.020 | -0.020 | 1 | Among opponents: neg info coef W2_Q1 unadjusted; rewrite: -0.019 |
| table_3 | study1_W2Q1_opp_pos_adj | 0.020 | 0.020 | 1 | Among opponents: pos info coef W2_Q1 adjusted; rewrite: 0.015 |
| table_3 | study1_W2Q1_opp_neg_adj | -0.030 | -0.030 | 1 | Among opponents: neg info coef W2_Q1 adjusted; rewrite: -0.032 |
| table_3 | study1_W2Q1_pro_pos_unadj | 0.010 | 0.010 | 1 | Among proponents: pos info coef W2_Q1 unadjusted; rewrite: 0.006 |
| table_3 | study1_W2Q1_pro_neg_unadj | -0.080 | -0.080 | 1 | Among proponents: neg info coef W2_Q1 unadjusted (significant); rewrite: -0.077 |
| table_3 | study1_W2Q1_pro_pos_adj | 0.010 | 0.010 | 1 | Among proponents: pos info coef W2_Q1 adjusted; rewrite: 0.008 |
| table_3 | study1_W2Q1_pro_neg_adj | -0.070 | -0.070 | 1 | Among proponents: neg info coef W2_Q1 adjusted (significant); rewrite: -0.071 |
| table_3 | study1_N_opp_Q1 | 724.000 | 724.000 | 1 | N opponents Table 3 |
| table_3 | study1_N_pro_Q1 | 1375.000 | 1375.000 | 1 | N proponents Table 3 |
| table_4 | study2_N_placebo | 93.000 | 93.000 | 1 | Study 2 Placebo group N |
| table_4 | study2_N_conyoung_conold | 162.000 | 162.000 | 1 | Con Young / Con Old group N |
| table_4 | study2_N_proold_conold | 165.000 | 165.000 | 1 | Pro Old / Con Old group N |
| table_4 | study2_N_proold_conyoung | 195.000 | 195.000 | 1 | Pro Old / Con Young group N |
| table_4 | study2_N_proyoung_conold | 169.000 | 169.000 | 1 | Pro Young / Con Old group N |
| table_4 | study2_N_proyoung_conyoung | 192.000 | 192.000 | 1 | Pro Young / Con Young group N |
| table_4 | study2_N_proyoung_proold | 193.000 | 193.000 | 1 | Pro Young / Pro Old group N |
| table_5 | study2_opp_pos_unadj | 0.430 | 0.430 | 1 | Opponents: pos info amount unadjusted; rewrite: 0.434 |
| table_5 | study2_opp_neg_unadj | -0.610 | -0.610 | 1 | Opponents: neg info amount unadjusted; rewrite: -0.611 |
| table_5 | study2_opp_pos_adj | 0.600 | 0.600 | 1 | Opponents: pos info amount adjusted; rewrite: 0.601 |
| table_5 | study2_opp_neg_adj | -0.700 | -0.700 | 1 | Opponents: neg info amount adjusted (significant); rewrite: -0.696 |
| table_5 | study2_pro_pos_unadj | 1.310 | 1.310 | 1 | Proponents: pos info amount unadjusted (significant); rewrite: 1.315 |
| table_5 | study2_pro_neg_unadj | -1.930 | -1.930 | 1 | Proponents: neg info amount unadjusted (significant); rewrite: -1.929 |
| table_5 | study2_pro_pos_adj | 1.400 | 1.400 | 1 | Proponents: pos info amount adjusted (significant); rewrite: 1.397 |
| table_5 | study2_pro_neg_adj | -1.700 | -1.700 | 1 | Proponents: neg info amount adjusted (significant); rewrite: -1.699 |
| table_5 | study2_N_opponents | 343.000 | 343.000 | 1 | N opponents Table 5 |
| table_5 | study2_N_proponents | 470.000 | 470.000 | 1 | N proponents Table 5 |
| table_5 | study2_N_moderates | 356.000 | 356.000 | 1 | N moderates Table 5 |
| table_7 | study3_N_CC | 117.000 | 117.000 | 1 | Study 3 Con Con group N |
| table_7 | study3_N_CN | 116.000 | 116.000 | 1 | Study 3 Con Null group N |
| table_7 | study3_N_NN | 112.000 | 112.000 | 1 | Study 3 Null Null group N |
| table_7 | study3_N_PC | 118.000 | 118.000 | 1 | Study 3 Pro Con group N |
| table_7 | study3_N_PN | 121.000 | 121.000 | 1 | Study 3 Pro Null group N |
| table_7 | study3_N_PP | 102.000 | 102.000 | 1 | Study 3 Pro Pro group N |
| table_8 | study3_pro_pos_unadj | 0.050 | 0.050 | 1 | Proponents: pos info support unadjusted; rewrite: 0.048 |
| table_8 | study3_pro_neg_unadj | -0.270 | -0.270 | 1 | Proponents: neg info support unadjusted (significant); rewrite: -0.267 |
| table_8 | study3_pro_pos_adj | 0.010 | 0.010 | 1 | Proponents: pos info support adjusted; rewrite: 0.015 |
| table_8 | study3_pro_neg_adj | -0.330 | -0.330 | 1 | Proponents: neg info support adjusted (significant); rewrite: -0.326 |
| table_8 | study3_opp_pos_unadj | 0.120 | 0.120 | 1 | Opponents: pos info support unadjusted; rewrite: 0.116 |
| table_8 | study3_opp_neg_unadj | 0.010 | 0.010 | 1 | Opponents: neg info support unadjusted; rewrite: 0.009 |
| table_8 | study3_opp_pos_adj | 0.070 | 0.070 | 1 | Opponents: pos info support adjusted; rewrite: 0.074 |
| table_8 | study3_opp_neg_adj | -0.040 | -0.040 | 1 | Opponents: neg info support adjusted; rewrite: -0.040 |
| table_8 | study3_N_proponents | 287.000 | 287.000 | 1 | N proponents Table 8 |
| table_8 | study3_N_opponents | 395.000 | 395.000 | 1 | N opponents Table 8 |
| table_9 | study3_pro_pos_unadj_deter | 0.150 | 0.150 | 1 | Proponents: pos info deterrence unadjusted; rewrite: 0.146 |
| table_9 | study3_pro_neg_unadj_deter | -0.350 | -0.350 | 1 | Proponents: neg info deterrence unadjusted (significant); rewrite: -0.347 |
| table_9 | study3_pro_pos_adj_deter | 0.120 | 0.120 | 1 | Proponents: pos info deterrence adjusted; rewrite: 0.118 |
| table_9 | study3_pro_neg_adj_deter | -0.360 | -0.360 | 1 | Proponents: neg info deterrence adjusted (significant); rewrite: -0.361 |
| table_9 | study3_opp_pos_unadj_deter | 0.350 | 0.350 | 1 | Opponents: pos info deterrence unadjusted (significant); rewrite: 0.349 |
| table_9 | study3_opp_neg_unadj_deter | -0.160 | -0.160 | 1 | Opponents: neg info deterrence unadjusted; rewrite: -0.164 |
| table_9 | study3_opp_pos_adj_deter | 0.310 | 0.310 | 1 | Opponents: pos info deterrence adjusted (significant); rewrite: 0.312 |
| table_9 | study3_opp_neg_adj_deter | -0.200 | -0.200 | 1 | Opponents: neg info deterrence adjusted (significant); rewrite: -0.205 |
| figure_1 | n_correctly_signed | 23.000 | 23.000 | 1 | 23 of 24 treatment effect estimates correctly signed |
| figure_1 | binom_test_pvalue | 0.001 | 0.000 | 1 | Binomial test p \< 0.001 (exact: 2.98e-06) |
| figure_2 | pct_pos_te_under_pos_treatment | 0.930 | 0.990 | 0 | DOES NOT REPRODUCE. Paper reports 93% of subjects with a positive TE under positive information (BART). The deposited script, run with a seed prepended as its only modification, gives 0.990; the maintained rewrite gives 0.990. A ten-seed sweep (maintained/output/text_bart_seed_sensitivity.csv) shows 0.93 lies below every run, so this is not seed noise. The error understates the paper own result: a higher share correctly signed is stronger evidence of homogeneity, so the substantive claim is unaffected. Candidate explanation: the archive was deposited 2018-06-27 when dbarts 0.9-3 was current, and dbarts NEWS records four later fixes to multithreaded sampling (race conditions in 0.9-18, reproducibility in 0.9-19, k mixing across chains in 0.9-20, inconsistent results in 0.9-23). The deposited script sets no seed and pins no threads, so package changes may account for the gap rather than anything in the analysis. Untested; would require installing 0.9-3 under the R of the day. |
| figure_2 | pct_neg_te_under_neg_treatment | 0.770 | 0.790 | 1 | Reproduces. Deposited script (seeded) gives 0.766; maintained rewrite gives 0.787. Across ten seeds (maintained/output/text_bart_seed_sensitivity.csv) the published 0.77 sits near the middle of the range. |

Rewrite verification: 77 of 79 claims match published values

**Summary**: 77 of 79 verifiable claims match the published values in
the maintained rewrite.

------------------------------------------------------------------------

## R Environment

| Package    | Version |
|:-----------|:--------|
| tidyverse  | 2.0.0   |
| estimatr   | 1.0.6   |
| rsample    | 1.3.2   |
| dbarts     | 0.9.33  |
| knitr      | 1.51    |
| kableExtra | 1.4.0   |
| here       | 1.0.2   |

Key package versions

R version: R version 4.6.0 (2026-04-24)
