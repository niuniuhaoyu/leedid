# Estimator conventions

Reference: Javier Viviens, *Estimating the Intensive Margin Effect in Panel Data Settings*, arXiv:2502.08614v2 (2026), especially the two-period panel bounds and multiple-selection-source construction. The author supplies an R implementation, LeeDiD. This package implements that design in Stata/Mata.

## Selection shares

Let s(j,g,t) be the mean of source j's selection indicator in the full group-g roster at time t. The extrapolated post rate is s(j,g,0) times s(j,1-g,1)/s(j,1-g,0). For a positive monotonicity source, use the observed post rate for control and extrapolated post rate for treated; reverse these choices for a negative source. For each group, sum the selected source-specific nonselection probabilities, subtract from one, and divide by the observed joint-selection rate. This gives pi0 and pi1, the AO shares among observed units. This construction requires mutually exclusive causes and the paper's no-OC/OT-intersection restriction.

Nonpositive or undefined shares stop estimation. Shares above one are projected to one and flagged. Each selection source must be absorbing between the two periods. Therefore post-selected units also have observed baseline outcomes.

## DID bounds

Form within-unit outcome changes among post-selected units. The lower bound is the lower pi1 fraction mean of treated changes minus the upper pi0 fraction mean of control changes. The upper bound reverses tails. Fractional mass is retained at the trimming cutoff: if n*pi = k + f, retain k observations plus weight f on the next order statistic. The denominator is n*pi, without rounding the retained count.

## CiC bounds

Write A/B for treated pre/post empirical outcome distributions and C/D for control pre/post distributions, all among post-selected units. Q denotes a generalized inverse, F a CDF. At quantile q:

```
lower(q) = QB(q*pi1) - QD(FC(QA(q*pi1 + 1-pi1)) + 1-pi0)
upper(q) = QB(q*pi1 + 1-pi1) - QD(FC(QA(q*pi1)) - 1+pi0)
```

Probabilities outside [0,1] use endpoint order statistics. Empirical quantiles are inverse-ECDF (type 1); ranks within 1e-12 of an integer are snapped to that integer to prevent floating cancellation from selecting the next observation. These empirical endpoint conventions do not establish population support assumptions.

Average bounds integrate these step functions exactly. Breakpoints are 0, 1, k/(n*pi1), and (k/n-1+pi1)/pi1 in [0,1], where n is the number of selected treated units. Midpoint evaluations times interval lengths give the integral. Reporting quantiles in probs() do not control this integral.

## Inference

Resample whole units or whole user-specified clusters with replacement. Re-estimate all selection rates and bounds on every draw. Store the draws and their sample covariance. Undefined draws cause all bootstrap SEs and intervals to be withheld. A single resampling cluster is rejected when inference is requested.

For endpoints L/U and standard errors sL/sU, solve

```
Phi(c + (U-L)/max(sL,sU)) - Phi(-c) = coverage
```

and report [L-c*sL, U+c*sU]. These are Imbens-Manski pointwise parameter intervals under the required regularity, not simultaneous confidence bands or a guarantee of finite-sample coverage. Projection and weak selection support need particular attention. The software does not test the identifying assumptions.
