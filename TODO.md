# 开发 TODO

| ID | 状态 | 目标 | 验收命令 | 提交主题 |
| --- | --- | --- | --- | --- |
| TODO-01 | 已完成 | 统一默认样例与 CLI/文档基线 | `moon test cmd/main --target native`<br>`moon run cmd/main -- asm example/simple.s -o out/simple.elf`<br>`moon run cmd/main -- run out/simple.elf --max-steps 20` | `fix: 统一默认样例与 CLI 回归基线` |
| TODO-02 | 已完成 | 同步 workbench API 契约、测试与文档 | `moon test workbench --target native`<br>`moon test cmd/server --target native` | `fix: 同步 workbench API 契约与测试` |
| TODO-03 | 已完成 | 建立稳定 smoke 回归与 CI | 本地跑通 smoke 命令并新增 workflow | `ci: 建立稳定 smoke 回归工作流` |
| TODO-04 | 已完成 | 稳定 simulator 白盒回归 | `moon test simulator --target native` | `test: 稳定 simulator 白盒回归` |
