{smcl}
{* *! version 0.1.1 15oct2026}{...}
{hline}
{p 4 8 2}{bf:leedid} — 样本选择下的 DID 与 Changes-in-Changes 界限估计{right:version 0.1.1}
{hline}

{p 4 4 2}{it:English help / 英文帮助:} {help leedid}

{pstd}
本命令实现 Viviens (2026) 的两期面板、吸收性样本选择模型，估计处理组
始终可观测（AO）群体的平均效应界限与 CiC 分位数效应界限。
方法论文：{browse "https://arxiv.org/abs/2502.08614v2":arXiv:2502.08614v2}。
原生 Stata/Mata 实现，要求 Stata 16 及以上。

{title:语法与示例}
{phang2}{cmd:leedid wage, unit(id) time(year) treat(group) selection(observed) directions(1) pre(2020) post(2022) reps(999) seed(12345) graph}
{phang2}{cmd:leedid wage, unit(id) time(year) treat(group) selection(s1 s2) directions(1 -1) reps(999) seed(12345)}

{title:数据要求}
{pstd}
每个单位必须保留前后两行，包括结果缺失的行。treat() 是固定的 0/1 组别，
不能使用处理组与处理后时期的交互项。selection() 中每个变量表示一种选择原因：
1 表示该原因不阻止观测，0 表示该原因导致缺失。每行至多一个原因取 0；
每个原因均不得从 0 恢复为 1。所有原因均为 1 时，结果变量必须非缺失。
请勿预先删除退出样本的单位。

{pstd}
directions() 与选择变量逐一对应：1 表示处理弱提高被观测概率，-1 表示弱降低。
方向属于研究者提出的识别假设，不由样本选择率自动推断。

{title:选项}
{p 4 4 2}{cmd:unit(}{it:varname}{cmd:)} 指定单位，可使用数值或字符串标识。
{p 4 4 2}{cmd:time(}{it:varname}{cmd:)} 指定数值型时期变量。
{p 4 4 2}{cmd:treat(}{it:varname}{cmd:)} 指定固定的 0/1 处理组标识。
{p 4 4 2}{cmd:selection(}{it:varlist}{cmd:)} 列出互斥选择原因。
{p 4 4 2}{cmd:directions(}{it:numlist}{cmd:)} 为每种原因指定一个方向（1 或 -1）。
{p 4 4 2}{cmd:pre(}{it:#}{cmd:)} / {cmd:post(}{it:#}{cmd:)} 必须同时指定；省略时样本须恰有两期。
{p 4 4 2}{cmd:probs(}{it:numlist}{cmd:)} 默认 .1(.1).9，严格介于 0 和 1；平均 CiC 界限的精确积分不随报告网格改变。
{p 4 4 2}{cmd:reps(}{it:#}{cmd:)} 默认 199；0 表示只计算点估计，不能为 1。正式分析应增加重抽样次数。
{p 4 4 2}{cmd:seed(}{it:#}{cmd:)} 设置 Stata 随机种子，默认不设置。
{p 4 4 2}{cmd:level(}{it:#}{cmd:)} 默认使用 Stata 当前置信水平。
{p 4 4 2}{cmd:cluster(}{it:varname}{cmd:)} 按整群重抽样，归属须在单位内固定；默认按完整单位重抽样。推断至少需要两个群组。
{p 4 4 2}{cmd:graph} 绘制分位数界限。估计后使用 {cmd:leedid_plot} 重绘；{cmd:leedid_plot, name(}{it:name}{cmd:)} 指定图名。

{title:推断与适用范围}
{pstd}
报告的是 Imbens-Manski 逐点参数置信区间，不是同时置信带。
每次 bootstrap 都重新估计 AO 比例；只要有一次未定义，全部标准误与置信区间
就不报告，失败次数存于 e(reps_failed)。AO 比例超过 1 时投影至 1 并报告诊断；
非正或未定义时终止。边界投影可能不满足常规推断条件。

{pstd}
DID 需要 AO 群体平行趋势；CiC 需要单调潜在结果、秩分布稳定及支持条件。
选择率外推及多原因选择还需要论文的相应识别假设，数据校验不等于验证假设。
本版 CiC 实现针对连续结果，不涵盖离散结果扩展、重新进入样本、重复截面、
协变量扩展或交错处理。

{title:保存结果}
{pstd}
e(bounds) 的两行为 DID/CIC，七列为完整样本估计、下界、上界、下界标准误、
上界标准误、置信下限、置信上限。e(qtt) 第一列为分位点，其余六列含义相同。
e(b)/e(V) 保存四个平均界限及 bootstrap 协方差。端点显著性不等于效应显著性。
e(pi0)/e(pi1) 保存控制/处理组 AO 比例；e(selection) 保存各原因的选择率。
e(sample) 包括结果缺失的完整分析名册，e(N) 为行数，e(N_units) 为单位数。
完整结果列表见 {help leedid:英文帮助}。

{title:作者}
{pstd}
方法：Javier Viviens；独立 Stata 实现：Haoyu Niu。
{browse "https://github.com/niuniuhaoyu/leedid":源码、方法说明与验证记录}。
