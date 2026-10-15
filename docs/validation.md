# Validation

Validated on macOS with Stata/MP 19 and R. Runtime use requires only Stata 16+; the comparison harness additionally needs R and dplyr. The author reference is pinned to commit `f02aac93feb2bb75ec8780a250e1ac6add9d7541` of https://github.com/JavierViviens/LeeDiD.

## Reproduce

From the package root:

```sh
git clone https://github.com/JavierViviens/LeeDiD /tmp/leedid-reference
git -C /tmp/leedid-reference checkout f02aac93feb2bb75ec8780a250e1ac6add9d7541
Rscript tests/reference.R /tmp/leedid-reference
python3 tests/run.py
```

Set the `STATA_BIN` environment variable if Stata is installed elsewhere. The runner checks Stata error codes in logs and an explicit success marker, since a successful batch process exit alone does not establish a successful do-file. Logs and generated data are excluded from Git.

## Checks

- Hand-calculated bounds, no-selection behavior, reporting-grid independence, and data validation.
- Reproducible bootstrap, covariance and CI behavior, cluster resampling, and withholding inference on undefined draws.
- Baseline nonselection denominators, two opposite selection mechanisms, string identifiers, row ordering, treatment reversal for DID, irrelevant outcomes outside selection, invalid causes and missing roster rows.
- Fractional tail trimming without input mutation, ties, empirical quantile endpoints, and limiting IM critical values.
- Explicit period filtering before roster validation and rejection of single-cluster inference.
- A 300-unit fixture plus 29 shared bootstrap samples: 14 statistics per sample (420 scalar comparisons), with maximum absolute error below 1e-10 against the stabilized comparison. IM confidence intervals agree within 1e-5, the reference solver tolerance.
- Local net-install and execution of the distributed example.

## What the R comparison establishes

The harness sources the author's selection, distribution, bound and inference functions. It uses a column named `period` to avoid a column/argument name collision in the reference selection function. It compares AO shares and quantile-bound functions; independent R fractional weighting supplies the DID comparison. Average CiC comparisons integrate the author's bound functions over all empirical breakpoints.

The unmodified R implementation uses rounded trimming counts and a reporting-quantile approximation for average CiC bounds, so this package does not claim bit-for-bit equivalence to its top-level output. The Stata implementation uses fractional mass and exact step-function integration.

Floating arithmetic at inverse-ECDF jumps can change the selected order statistic. The comparison harness preserves the original author function and makes a separate copy whose quantile operation snaps ranks within 1e-12 of an integer. It writes both raw and stabilized results to `tests/generated/raw_author_comparison.csv`. On the original fixture, the largest raw/stabilized average-bound difference was about 0.0407; this is a discontinuity issue, not a tolerance used to pass the stabilized comparison.

These checks support implementation correctness for the tested design. They are not Monte Carlo evidence of coverage, a proof of the identifying assumptions, or validation of extensions outside the documented scope.
