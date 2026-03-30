# 开发 TODO

| ID | 状态 | 目标 | 验收命令 | 提交主题 |
| --- | --- | --- | --- | --- |
| TODO-01 | 已完成 | 统一默认样例与 CLI/文档基线 | `moon test cmd/main --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- run out/simple.elf --max-steps 20` | `fix: 统一默认样例与 CLI 回归基线` |
| TODO-02 | 已完成 | 同步 workbench API 契约、测试与文档 | `moon test workbench --target native`<br>`moon test cmd/server --target native` | `fix: 同步 workbench API 契约与测试` |
| TODO-03 | 已完成 | 建立稳定 smoke 回归与 CI | 本地跑通 smoke 命令并新增 workflow | `ci: 建立稳定 smoke 回归工作流` |
| TODO-04 | 已完成 | 稳定 simulator 白盒回归 | `moon test simulator --target native` | `test: 稳定 simulator 白盒回归` |
| TODO-05 | 已完成 | 实现 RV64 默认汇编链路与显式 xlen 选项 | `moon test cmd/main --target native`<br>`moon test format`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- run out/simple.elf --max-steps 20`<br>`moon run cmd/main -- asm example/simple.s -o out/simple32.elf --xlen 32`<br>`moon run cmd/main -- run out/simple32.elf --max-steps 20` | `feat: 增加 RV64 默认汇编链路与显式 xlen 选项` |
| TODO-06 | 已完成 | 同步 RV64 默认与 RV32 兼容的文档和 smoke 基线 | `moon test cmd/main --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- run out/simple.elf --max-steps 20` | `docs: 同步 RV64 默认与 RV32 兼容的文档和 smoke 基线` |
| TODO-07 | 已完成 | 在 workbench API 暴露 xlen 并覆盖双位宽回归 | `moon test workbench --target native`<br>`moon test cmd/server --target native` | `feat: 在 workbench API 暴露 xlen 并覆盖双位宽回归` |
| TODO-08 | 已完成 | 加固 dataflow 与 decompile 回归样例 | `moon test analysis` | `test: 加固 dataflow 与 decompile 回归样例` |
| TODO-09 | 已完成 | 增加 Windows MSVC 原生校验工作流 | 新增 Windows workflow 并补使用说明 | `ci: 增加 Windows MSVC 原生校验工作流` |
| TODO-10 | 已完成 | 清理稳定性主线的低风险编译告警 | `moon test analysis`<br>`moon test decode`<br>`moon test format` | `chore: 清理稳定性主线的低风险编译告警` |
| TODO-11 | 已完成 | 强化在线入口页为 quick start 首页，并追加本轮前端 TODO 基线 | `moon test cmd/server --target native` | `feat: 强化在线入口页与新一轮 TODO 基线` |
| TODO-12 | 已完成 | 为离线/在线 workbench 增加首屏使用引导，帮助首次使用者快速上手 | `moon test workbench --target native` | `feat: 为 workbench 增加首屏使用引导` |
| TODO-13 | 已完成 | 改进 workbench 空态、错误态和截断提示，让每种状态都给出下一步操作 | `moon test workbench --target native` | `feat: 改进 workbench 的空态与错误提示` |
| TODO-14 | 已完成 | 增强函数导航、节区联动、搜索过滤和当前执行位置的可发现性 | `moon test workbench --target native` | `feat: 增强 workbench 导航与过滤可发现性` |
| TODO-15 | 已完成 | 同步 README、用户文档和 API 参考中的前端使用说明，消除页面与文档偏差 | `moon test workbench --target native`<br>`moon test cmd/main --target native` | `docs: 同步前端页面使用说明与接口文档` |
| TODO-16 | 已完成 | 加固前端入口页与 workbench 使用层回归，并在收尾时写回实际提交记录 | `moon test workbench --target native`<br>`moon test cmd/server --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- workbench out/simple.elf -o out/workbench.html` | `test: 加固前端入口与 workbench 使用回归` |
| TODO-17 | 已完成 | 统一 workbench 在线加载链路，移除旧 snapshot 前端后备实现 | `moon test workbench --target native` | `refactor: 统一 workbench 在线加载链路` |
| TODO-18 | 已完成 | 加固 online workbench 接口契约回归，防止回退到旧接口模型 | `moon test workbench --target native`<br>`moon test cmd/server --target native` | `test: 加固 online workbench 接口契约回归` |
| TODO-19 | 已完成 | 同步 workbench 主接口文档与 TODO 流程约定，消除实现/文档漂移 | `moon test workbench --target native`<br>`moon test cmd/server --target native` | `docs: 同步 workbench 主接口与 TODO 流程约定` |
| TODO-20 | 已完成 | 为 workbench 增加轨迹回放断点 | `moon test workbench --target native` | `feat: 为 workbench 增加轨迹回放断点` |
| TODO-21 | 已完成 | 为 workbench 增加状态对比视图 | `moon test workbench --target native` | `feat: 为 workbench 增加状态对比视图` |
| TODO-22 | 已完成 | 同步 workbench 断点与状态对比说明 | `moon test workbench --target native`<br>`moon test cmd/server --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- workbench out/simple.elf -o out/workbench.html` | `docs: 同步 workbench 断点与状态对比说明` |
| TODO-23 | 已完成 | 建立下一轮 TODO 基线，并对齐版本元数据与提交记录结构 | `moon test cmd/main --target native`<br>`moon run cmd/main -- version` | `chore: 建立下一轮 TODO 基线并对齐版本元数据` |
| TODO-24 | 待开始 | 为现有 ELF 主线补齐 `info/disasm/cfg/callgraph/analyze/decompile` 命令级回归，先把当前已支持能力测稳 | `moon test cmd/main --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- info out/simple.elf`<br>`moon run cmd/main -- decompile out/simple.elf` | `test: 为核心 CLI 命令补齐 ELF 回归基线` |
| TODO-25 | 待开始 | 抽取共享输入装载抽象，统一现有 ELF 与 `disasm --raw` 的入口，消除当前“半开半关”的 RAW 路径 | `moon test format`<br>`moon test cmd/main --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw`<br>`moon run cmd/main -- disasm out/simple.raw --raw --base 0x10000` | `refactor: 统一 ELF 与 RAW 输入装载抽象` |
| TODO-26 | 待开始 | 为 `info/cfg/analyze/decompile` 打通 RAW 输入闭环，统一使用共享装载抽象 | `moon test cmd/main --target native`<br>`moon run cmd/main -- info out/simple.raw --raw --base 0x10000 --xlen 64`<br>`moon run cmd/main -- cfg out/simple.raw --raw --base 0x10000 --format json`<br>`moon run cmd/main -- analyze out/simple.raw --raw --base 0x10000 --format json`<br>`moon run cmd/main -- decompile out/simple.raw --raw --base 0x10000` | `feat: 为分析命令打通 RAW 输入` |
| TODO-27 | 待开始 | 为 `simulator/run` 打通 RAW 输入，并在 RAW 缺少 ELF 元信息时提供清晰的 `base/xlen` 诊断 | `moon test simulator --target native`<br>`moon test cmd/main --target native`<br>`moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20`<br>`moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 32 --max-steps 20` | `feat: 为 run 命令增加 RAW 输入支持` |
| TODO-28 | 待开始 | 为离线 `workbench` 打通 RAW 输入，保持现有离线 HTML 交互模型不变 | `moon test workbench --target native`<br>`moon test cmd/main --target native`<br>`moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html` | `feat: 为离线 workbench 增加 RAW 输入` |
| TODO-29 | 待开始 | 明确 RAW 下 `symbols/callgraph` 的受限输出和 CLI 帮助文案，不伪造不存在的符号与函数边界 | `moon test cmd/main --target native`<br>`moon run cmd/main -- symbols out/simple.raw --raw --format json`<br>`moon run cmd/main -- callgraph out/simple.raw --raw --format json` | `docs: 明确 RAW 受限输出与 CLI 帮助文案` |
| TODO-30 | 待开始 | 同步 README、用户文档、API 文档和样例索引，形成 ELF/RAW 双路径说明 | `moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw`<br>`moon run cmd/main -- run out/simple.elf --max-steps 20`<br>`moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20`<br>`moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html` | `docs: 补齐 RAW 与 ELF 双路径样例矩阵` |
| TODO-31 | 待开始 | 扩展 Linux smoke 与 Windows supplemental check，覆盖 RAW 主路径和核心 CLI 命令矩阵 | `moon test`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw`<br>`moon run cmd/main -- info out/simple.raw --raw --base 0x10000 --xlen 64`<br>`moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20`<br>`moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html` | `ci: 扩展 smoke 覆盖 RAW 与核心命令` |
| TODO-32 | 待开始 | 编写答辩 runbook 与最终验收清单，固化 clean repo 到 CLI、离线 workbench、在线演示的完整复现顺序 | `moon test`<br>`moon run cmd/main -- asm example/file_open_read_close.s -o out/file_open_read_close.elf`<br>`moon run cmd/main -- run out/file_open_read_close.elf --trace out/file_open_read_close.trace.json`<br>`moon run cmd/main -- workbench out/simple.elf -o out/workbench.html` | `docs: 补齐答辩 runbook 与最终验收清单` |

## 执行约定

- 每完成一个 TODO，就同步更新本表状态与提交记录，并立即单独提交一个 commit。
- 所有涉及代码的 TODO，在验收前统一执行 `moon info && moon fmt`。
- 默认保留当前工作区里的 `out/workbench.html` 现状；只有某个 TODO 的验收命令明确要求重新生成并纳入提交时，才处理该产物。
- Windows 上涉及 `cmd/server --target native` 的验收，优先在 Visual Studio 2022 Developer Command Prompt / DevShell 或先执行 `vcvars64.bat` 的环境中完成。
- 如果某个 TODO 牵出在线 `/workbench` RAW 支持、ISA 扩展或新的系统调用范围，直接截断，不在本轮顺手扩大范围。

## 本轮默认假设

- 本轮不新增在线 `/workbench` 的 RAW 支持。
- 本轮不扩 ISA、特权级、CSR、JIT 或更完整文件系统语义。
- RAW 路径默认值统一为 `base=0x10000`、`xlen=64`。
- `symbols --raw` 使用空结果加说明文案；`callgraph --raw` 使用显式“不支持”结果；两者都不生成伪数据。

## 历史提交记录

- `feat: 强化在线入口页与新一轮 TODO 基线`
- `feat: 为 workbench 增加首屏使用引导`
- `feat: 改进 workbench 的空态与错误提示`
- `feat: 增强 workbench 导航与过滤可发现性`
- `docs: 同步前端页面使用说明与接口文档`
- `test: 加固前端入口与 workbench 使用回归`
- `refactor: 统一 workbench 在线加载链路`
- `test: 加固 online workbench 接口契约回归`
- `docs: 同步 workbench 主接口与 TODO 流程约定`
- `feat: 为 workbench 增加轨迹回放断点`
- `feat: 为 workbench 增加状态对比视图`
- `docs: 同步 workbench 断点与状态对比说明`

## 本轮提交记录

- `chore: 建立下一轮 TODO 基线并对齐版本元数据`
