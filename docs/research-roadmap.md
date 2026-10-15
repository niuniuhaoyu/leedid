# Stata 方法包选题记录

更新：2026-10-15。用户决定先完整实现第 3 项，并推送 GitHub。

| 顺序 | 方向 | 文献与参照 | 状态 |
|---|---|---|---|
| 1 | 样本构成变化 DID | Sant’Anna–Xu；https://github.com/pedrohcgs/comp_did | 待做 |
| 2 | 链式 DID | Bellégo–Benatia–Dortet-Bernadet, JoE 2025；https://github.com/joelcuerrier/cdid | 待做 |
| 3 | 样本选择下 DID / CiC 界限 | Viviens，arXiv:2502.08614，2025 初稿 / 2026 v2；https://github.com/JavierViviens/LeeDiD | 本次实施 |
| 4 | FETWFE | Faletto；https://github.com/gregfaletto/fetwfePackage | 待做 |

已有包的后续：contdid 的精确 CCK 自适应推断；ddd 的第一阶段不确定性、聚合与 GMM 协方差。

创新定位：方法属于原作者，当前项目贡献是 Stata 原生实现、验证、诊断及文档。2026-10-15 对 Viviens / LeeDiD / Stata / ado / RePEc 的检索未发现直接对应的 Stata 包，不能据此宣称绝对首创。经典 leebounds 已存在，但实现 Lee (2009)，与本项目不同。
