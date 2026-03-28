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

## 本轮提交记录

- `feat: 强化在线入口页与新一轮 TODO 基线`
- `feat: 为 workbench 增加首屏使用引导`
- `feat: 改进 workbench 的空态与错误提示`
- `feat: 增强 workbench 导航与过滤可发现性`
- `docs: 同步前端页面使用说明与接口文档`
- `test: 加固前端入口与 workbench 使用回归`
