# leedid — selection-adjusted DID and Changes-in-Changes for Stata

[简体中文](README_zh.md) · [Methods](docs/methods.md) · [Validation](docs/validation.md)

Native Stata/Mata implementation of Javier Viviens's **Estimating the Intensive Margin Effect in Panel Data Settings**, [arXiv:2502.08614v2](https://arxiv.org/abs/2502.08614v2), February 2026. The original 2025 draft was titled *Difference-in-Differences and Changes-in-Changes with Sample Selection*.

Version **0.1.0**. Stata **16+**, no external runtime or package dependencies. Tested on Stata/MP 19. Method: **Javier Viviens**. Stata implementation: **Haoyu Niu**. This is an independent implementation, not an author-endorsed release.

## What it estimates

When treatment changes whether an outcome is observed (employment and wages, for example), complete-case DID may not identify the desired effect. `leedid` estimates **lower and upper bounds** on average treatment effects for the treated **always-observed (AO)** stratum. It reports both DID and CiC average bounds, CiC quantile bounds, and complete-case comparison estimates.

Features:

- One or more mutually exclusive selection causes, with explicit monotonicity directions.
- Full-roster selection denominators, including baseline and post-period nonselection.
- Fractional-mass DID trimming and exact integration of empirical CiC bounds.
- Unit or whole-cluster bootstrap that re-estimates AO shares on every draw.
- Imbens–Manski **pointwise parameter confidence intervals**, distinct from identified intervals and simultaneous confidence bands.
- Quantile plots and stored results for further analysis.

## Install

```stata
net install leedid, from("https://raw.githubusercontent.com/niuniuhaoyu/leedid/main/") replace
help leedid
help leedid_zh
```

## Data and usage

Supply a **full two-period roster**, one row per unit and period, even when the outcome is missing. `treat()` is the fixed group assignment (0 or 1), not the time-varying treatment indicator. A selection source is 0 when that cause prevents observation, 1 otherwise. With several causes, at most one can be 0 per row. Do not code unmeasured causes as zero. Sources must be absorbing across the chosen periods; re-entry and switching failure causes are not supported by this release.

```stata
* One selection source; treatment weakly increases selection.
leedid wage, unit(id) time(year) treat(treated) selection(observed) ///
    directions(1) pre(2020) post(2022) reps(999) seed(12345) graph

* Two mutually exclusive causes with opposite monotonicity assumptions.
leedid wage, unit(id) time(year) treat(treated) ///
    selection(not_unemployed not_attrited) directions(1 -1) ///
    pre(2020) post(2022) probs(.1(.1).9) reps(999) seed(12345)

* Cluster-level sampling dependence.
leedid wage, unit(id) time(year) treat(treated) selection(observed) ///
    directions(1) pre(2020) post(2022) cluster(region) reps(999) seed(12345)

leedid_plot
matrix list e(bounds)
matrix list e(qtt)
```

`directions(1)` assumes treatment weakly increases selection; `-1` assumes it weakly decreases selection. With multiple sources, the signs correspond to the `selection()` order. They are **substantive assumptions**, not conclusions from observed selection rates.

| Option | Default / meaning |
|---|---|
| `pre()` / `post()` | Inferred only if the sample has exactly two distinct periods; otherwise supply both |
| `probs()` | `.1(.1).9`; display quantiles strictly between 0 and 1 |
| `reps()` | 199; use 0 for estimates only; 1 is invalid |
| `seed()` | Unset; a supplied nonnegative integer sets Stata's RNG seed |
| `level()` | Stata's current confidence level (normally 95) |
| `cluster()` | Defaults to resampling whole units; cluster membership must be fixed within unit |
| `graph` | Draw CiC quantile bounds and available pointwise intervals |

For a simulated example (clears the current data):

```stata
net get leedid, from("https://raw.githubusercontent.com/niuniuhaoyu/leedid/main/") replace
do leedid_example.do
```

## Assumptions and scope

The implemented design is two-period panel data with absorbing, mutually exclusive selection causes. DID requires parallel trends for the AO stratum; CiC instead requires its monotone latent-outcome model, rank-distribution stability, and support conditions. Selection-rate extrapolation requires the paper's selection model. Multiple causes additionally require source-specific monotonicity and the no-OC/OT-intersection restriction. These are identification assumptions, not established by the command's data checks.

The CiC routine implements the paper's **continuous-outcome** estimator. Handling repeated empirical values numerically does not establish identification for binary/count/mixed outcomes. This release does not implement the paper's separate discrete-outcome, re-entry, repeated-cross-section, or covariate extensions, or staggered adoption. Keep the full baseline roster; restricting to complete cases before calling the command changes the selection estimand.

If estimated AO shares exceed one, they are projected to one and reported via `e(projected)`. Nonpositive or undefined shares stop estimation. Projection indicates a boundary/assumption issue; inspect the rates and signs. Bootstrap inference relies on regularity and adequate independent sampling units; boundary projection can be nonregular. Any undefined bootstrap draw causes **all bootstrap SEs/CIs to be withheld**, with the failed-draw count reported. The command never silently computes inference conditional on successful draws.

## Stored results

- `e(bounds)`: rows DID, CIC; columns complete-case estimate, lower bound, upper bound, SE of each bound, lower/upper pointwise parameter CI.
- `e(qtt)`: quantile, lower/upper CiC bound, bound SEs, pointwise parameter CI.
- `e(b)`, `e(V)`: four average-bound estimates and their bootstrap covariance (when available). Endpoint p-values are not tests of the partially identified effect.
- `e(selection)`: source index, group, baseline rate, observed post rate, counterfactual rate. Source order is `e(selection_vars)`.
- `e(pi0)`, `e(pi1)`: AO shares among observed control/treated units.
- `e(N_units)`, `e(N_control)`, `e(N_treated)`, `e(N_clusters)`: roster units, complete-case units per arm, resampling clusters.
- `e(sample)`: full analysis roster, including missing outcomes; `e(N)` counts roster rows.
- `e(boot)`: bootstrap average-bound draws; `e(boot_qtt)`: all lower-quantile draws followed by upper-quantile draws in `e(qtt)` order.
- `e(reps_success)`, `e(reps_failed)`, `e(projected)`, `e(boot_projected)`: diagnostics.

## Validation and reference implementation

The author provides an [R package, LeeDiD](https://github.com/JavierViviens/LeeDiD). Our verification pins commit `f02aac93feb2bb75ec8780a250e1ac6add9d7541`. We compare selection shares and quantile-bound functions, use independent fractional trimming, and integrate the author's quantile functions over all empirical breakpoints. Inverse-CDF boundary arithmetic is stabilized explicitly in the comparison harness; raw results are retained separately. **This is not a claim of bit-for-bit equivalence to the unmodified R package.** Details and reproducible commands are in [validation](docs/validation.md).

## Citation and license

Cite Viviens for the method and Niu for this implementation. See [CITATION.cff](CITATION.cff). MIT license; the R reference has its own MIT license and is not bundled in the installed Stata package.
