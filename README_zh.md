# leedid

[English](README.md) | [简体中文](README_zh.md)

**Stata 样本选择下的 DID 与 Changes-in-Changes 界限估计**

[![Stata 16+](https://img.shields.io/badge/Stata-16%2B-blue.svg)](https://www.stata.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-green.svg)](CHANGELOG.md)

本包用 Stata/Mata 原生实现 Javier Viviens 的 *Estimating the Intensive Margin Effect in Panel Data Settings*（[arXiv:2502.08614v2，2026 年 2 月](https://arxiv.org/abs/2502.08614v2)）。2025 年初稿题为 *Difference-in-Differences and Changes-in-Changes with Sample Selection*。

版本 **0.1.1**，要求 Stata **16+**，不依赖 R、Python 或其他 Stata 包。实际测试环境为 Stata/MP 19。方法作者：**Javier Viviens**；Stata 实现：**Haoyu Niu**。本包为独立的 Stata 实现。

## 用途

政策既影响就业，也影响工资，而未就业者没有可观察工资。此时仅对有工资的人做 DID，可能混入样本选择的影响。本包估计处理组中“两种处理状态下均可观察”的人群（Always Observed，AO）的处理效应界限。

输出包括 DID/CiC 平均效应的上下界、CiC 分位数效应上下界、完整案例的对照估计、选择比例诊断，以及单位或聚类 bootstrap 的标准误和 Imbens–Manski 逐点参数置信区间。

## 安装

```stata
net install leedid, from("https://raw.githubusercontent.com/niuniuhaoyu/leedid/main/") replace
help leedid_zh
```

## 数据要求与示例

必须保留完整的两期单位名册。失访者仍需保留对应行，其结果变量可以缺失，但选择指标必须已知。`treat()` 是固定的处理组标识，取 0/1；不要传入处理组与政策后时期的交互项。

每个选择指标的 0 表示该原因使结果不可观察，1 表示未因该原因退出。多个退出原因必须互斥：同一行最多一个指标为 0。不知道某原因是否发生时，不能随意填 0。首版支持吸收式退出，不支持重新进入或在退出原因间切换。

```stata
* 假定处理对可观察性为弱正向影响。
leedid wage, unit(id) time(year) treat(treated) selection(observed) ///
    directions(1) pre(2020) post(2022) reps(999) seed(12345) graph

* 两类互斥退出原因；对可观察性的处理影响分别假定为正、负。
leedid wage, unit(id) time(year) treat(treated) ///
    selection(not_unemployed not_attrited) directions(1 -1) ///
    pre(2020) post(2022) reps(999) seed(12345)

matrix list e(bounds)
matrix list e(qtt)
leedid_plot
```

`directions()` 按选择变量顺序填写：1 表示处理弱增加可观察性，-1 表示弱减少。方向来自研究假设，不由样本中处理组与控制组的选择率差异自动决定。

- `pre()` / `post()`：恰好两期时自动识别；多期数据须同时指定。
- `probs()`：默认 `.1(.1).9`，仅改变分位数展示网格，不改变平均效应界限。
- `reps()`：默认 199，0 表示只估计点界限；正式分析可用 999 或更多。
- `cluster()`：指定整群重抽样；默认按完整单位重抽样。
- `level()`：使用 Stata 当前置信水平，通常为 95。
- `seed()`：设置随机种子，会改变 Stata 的随机数状态。

## 解释与支持范围

上下界构成估计的识别区间，不是置信区间。置信区间另计入抽样不确定性。图上的区间是**逐点参数置信区间，不是全曲线同时置信带**；上下界系数的常规 p 值也不能替代部分识别效应的检验。

DID 要求 AO 人群的平行趋势；CiC 使用单调潜在结果模型、潜在秩分布稳定及支持集条件。选择率外推和多原因退出还需要论文的选择模型、来源特定单调性以及 no-OC/OT-intersection 条件。数据校验不能证明这些识别假设成立。

本版本实现两期面板、吸收式互斥选择原因和连续结果 CiC 估计。不含离散结果的专门识别扩展、重新进入、重复截面、协变量调整或分批处理。不要先删掉结果缺失的样本再调用，否则选择率的分母和目标人群会改变。

估计 AO 比例超过 1 时会投影到 1 并提示；比例非正或无法计算时停止估计。边界投影可能导致非正规推断，应检查假设和选择率。每次 bootstrap 都重新估计选择比例。如果任何一次重抽样无法识别，本包保留点界限并报告失败次数，但不输出基于“仅成功样本”的标准误和置信区间。

## 返回结果

`e(bounds)` 两行分别为 DID 和 CiC，七列依次为完整案例估计、下界、上界、两界标准误、参数置信区间两端。`e(qtt)` 为分位数及对应的界限和推断。

`e(pi0)` / `e(pi1)` 为两组 AO 比例；`e(selection)` 为各来源选择率诊断；`e(sample)` 包括结果缺失的名册行；`e(N_units)` 是名册单位数，`e(N_control)` / `e(N_treated)` 是完整案例单位数。bootstrap 结果见 `e(boot)`、`e(boot_qtt)`，失败与投影见 `e(reps_failed)`、`e(projected)`、`e(boot_projected)`。

## 验证

作者已有 [R 包 LeeDiD](https://github.com/JavierViviens/LeeDiD)。本包以固定版本对照选择比例、分位数界限和置信区间，并独立校验分数质量修剪、平均界限积分和重抽样结果。R 对照脚本明确处理经验逆分布的浮点边界，并保留原始结果作比较；不能把结果表述成“未经修改的 R 包逐位一致”。完整说明见 [验证记录](docs/validation.md)。

## 复现示例

在仓库根目录运行（示例会清空当前数据）：

```stata
do examples/leedid_example.do
do examples/make_figure.do
```

- `examples/leedid_simdata.do` 生成 `data/leedid_sim.dta`。
- `examples/leedid_example.do` 生成数据并运行估计。
- `examples/make_figure.do` 保存 `examples/leedid_figure.png`。
- `tests/reference.R` 提供 R 对照，详见 [验证记录](docs/validation.md)。

通过 Stata 安装的用户也可获取独立的一键示例：

```stata
net get leedid, from("https://raw.githubusercontent.com/niuniuhaoyu/leedid/main/") replace
do leedid_example.do
```

方法细节见 [方法说明](docs/methods.md)，版本变动见 [更新日志](CHANGELOG.md)。

## 引用

方法与软件分别引用：

```bibtex
@misc{viviens2026intensive,
  title  = {Estimating the Intensive Margin Effect in Panel Data Settings},
  author = {Viviens, Javier},
  year   = {2026},
  note   = {arXiv:2502.08614v2},
  url    = {https://arxiv.org/abs/2502.08614v2}
}

@software{niu2026leedid,
  title   = {leedid: Selection-adjusted DID and Changes-in-Changes bounds for Stata},
  author  = {Niu, Haoyu},
  year    = {2026},
  version = {0.1.1},
  url     = {https://github.com/niuniuhaoyu/leedid}
}
```

另见 [CITATION.cff](CITATION.cff)。

## 许可证

[MIT](LICENSE)

---

[English](README.md) | [简体中文](README_zh.md)
