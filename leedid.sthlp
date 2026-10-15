{smcl}
{* *! version 0.1.0 15oct2026}{...}
{title:leedid — Selection-adjusted DID and Changes-in-Changes bounds}

{title:Syntax}
{p 8 12 2}
{cmd:leedid} {it:outcome} {ifin}, {cmd:unit(}{it:id}{cmd:)}
{cmd:time(}{it:period}{cmd:)} {cmd:treat(}{it:group}{cmd:)}
{cmd:selection(}{it:varlist}{cmd:)} {cmd:directions(}{it:numlist}{cmd:)}
[{cmd:pre(}{it:#}{cmd:)} {cmd:post(}{it:#}{cmd:)}
{cmd:probs(}{it:numlist}{cmd:)} {cmd:reps(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)} {cmd:level(}{it:#}{cmd:)}
{cmd:cluster(}{it:varname}{cmd:)} {cmd:graph}]

{title:Description}
{pstd}
Implements the two-period absorbing-selection panel design in Javier Viviens,
Estimating the Intensive Margin Effect in Panel Data Settings (2026),
{browse "https://arxiv.org/abs/2502.08614v2":arXiv:2502.08614v2}.
Reports DID and CiC average bounds and CiC quantile bounds for treated
always-observed units. Stata 16 or newer is required.

{title:Data requirements}
{pstd}
Keep two roster rows per unit, including rows with unobserved outcomes.
The group is a fixed binary assignment, not a group-by-post interaction.
Each selection variable equals 1 when its cause does not prevent observation,
and 0 otherwise. At most one source may equal 0 on a row. Each source must be
absorbing (no 0-to-1 transition). The outcome must be observed whenever all
sources equal 1. Deleting attrited units changes the estimand.

{pstd}
Each direction must be 1 (treatment weakly increases selection) or -1
(treatment weakly decreases selection), in selection-variable order.
These are user-supplied identification assumptions.

{title:Options}
{pstd}
{cmd:pre()} and {cmd:post()} select the two periods. Supply both or neither;
without them the sample must contain exactly two distinct periods.

{pstd}
{cmd:probs()} specifies reporting quantiles strictly between 0 and 1;
default .1(.1).9. Average CiC bounds use exact empirical integration and do not
depend on this reporting grid.

{pstd}
{cmd:reps()} sets bootstrap replications, default 199. Use 0 for estimates only;
1 is invalid. {cmd:seed()} sets Stata's RNG seed. {cmd:level()} sets coverage,
defaulting to Stata's current confidence level.

{pstd}
{cmd:cluster()} resamples entire clusters; membership must be fixed within unit.
Without it, entire units are resampled. Inference requires at least two clusters.
AO shares are re-estimated in every draw. Any undefined draw withholds all
bootstrap SEs and confidence intervals; inspect {cmd:e(reps_failed)}.

{pstd}
{cmd:graph} draws quantile bounds. {cmd:leedid_plot} redraws them after estimation.
The confidence intervals are Imbens-Manski pointwise parameter intervals,
not simultaneous bands. Small numbers of replications are useful for testing;
use more for substantive inference.

{title:Assumptions and limits}
{pstd}
DID requires AO-stratum parallel trends. CiC requires its monotone latent-outcome
model, rank-distribution stability and support conditions. Both use the paper's
selection-rate extrapolation assumptions; multiple causes additionally require
source-specific monotonicity and no overlap of OC/OT strata.
The command checks data structure, not identification assumptions.

{pstd}
CiC implements the continuous-outcome estimator. Discrete-outcome extensions,
re-entry, repeated cross sections, covariates and staggered adoption are outside
this release. AO shares above one are projected to one and flagged; nonpositive
or undefined shares cause an error. Boundary projection can be nonregular.

{title:Stored results}
{pstd}
{cmd:e(bounds)}: rows DID/CIC; columns complete_case, lower, upper, se_lower,
se_upper, ci_lower, ci_upper.
{cmd:e(qtt)}: quantile, lower, upper, se_lower, se_upper, ci_lower, ci_upper.
{cmd:e(b)} and {cmd:e(V)}: four average endpoints and bootstrap covariance when
available. Endpoint p-values are not tests of the partially identified effect.

{pstd}
{cmd:e(pi0)}, {cmd:e(pi1)}: AO shares among observed control/treated units.
{cmd:e(selection)}: source index, group, baseline rate, post rate, counterfactual rate.
{cmd:e(N)} counts roster rows; {cmd:e(N_units)} counts units;
{cmd:e(N_control)}, {cmd:e(N_treated)} count complete cases;
{cmd:e(N_clusters)} counts resampling clusters. {cmd:e(sample)} retains the full roster.

{pstd}
{cmd:e(boot)} stores average-bound draws. {cmd:e(boot_qtt)} stores all lower-quantile
then upper-quantile draws. {cmd:e(reps_success)}, {cmd:e(reps_failed)},
{cmd:e(projected)}, {cmd:e(boot_projected)} report diagnostics.

{title:Example}
{phang2}{cmd:leedid wage, unit(id) time(year) treat(group) selection(observed) directions(1) pre(2020) post(2022) reps(999) seed(12345) graph}
{phang2}{cmd:net get leedid, from("https://raw.githubusercontent.com/niuniuhaoyu/leedid/main/") replace}
{phang2}{cmd:do leedid_example.do}
{pstd}The simulated example clears the current data.

{title:Author and references}
{pstd}Method: Javier Viviens. Independent Stata implementation: Haoyu Niu.
{browse "https://github.com/niuniuhaoyu/leedid":Source, methods and validation}.
The author's R implementation is {browse "https://github.com/JavierViviens/LeeDiD":LeeDiD}.
See also {help leedid_zh:Chinese help}.
