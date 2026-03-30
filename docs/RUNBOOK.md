# Demo Runbook

## 目标

这份 runbook 用于答辩、录屏和最终验收，目标是把一次完整复现固定为同一条顺序：

1. 从 clean repo 起步
2. 跑完整测试
3. 验证 CLI 主路径
4. 演示 syscall/trace
5. 生成离线 workbench
6. 启动在线 workbench

本轮范围保持不变：

- 在线 `/workbench` 继续只演示 ELF 输入，不纳入 RAW 在线支持
- RAW 主路径已经纳入 smoke，见 `docs/TESTING.md`
- 最终答辩主线仍以 `example/simple.s` 和 `example/file_open_read_close.s` 为主

## 环境准备

- MoonBit CLI 已安装，并且 `~/.moon/bin` 已加入 `PATH`
- Windows 上如需跑 `cmd/server --target native`，请使用 Visual Studio 2022 Developer Command Prompt / DevShell，或先执行 `vcvars64.bat`
- 仓库根目录为当前工作目录

如果 `out/` 不存在，先创建：

```bash
mkdir -p out
```

## Step 1: Clean Repo 起点

先确认当前工作区没有混入未提交改动；如果有本地实验文件，请先自行区分。

```bash
git status --short
```

预期：

- clean repo 时输出为空
- `out/` 下的临时产物不应作为仓库基线提交

## Step 2: 完整测试基线

先把全量测试跑通，再进入演示链路：

```bash
~/.moon/bin/moon test
```

预期：

- 所有测试通过
- 当前基线应为 `Total tests: 461, passed: 461, failed: 0.`

## Step 3: CLI 主路径演示

先生成默认 ELF，再演示基础运行：

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf
~/.moon/bin/moon run cmd/main -- info out/simple.elf
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20
```

观察点：

- `asm` 成功生成 `out/simple.elf`
- `info` 显示 ELF / RISC-V / RV64 信息
- `run` 在 20 步内结束，并停在 `ebreak`

如果需要补一句本轮范围说明，可以直接说明：

- 默认演示 ELF 为 RV64
- RAW 路径已经支持 `info/cfg/analyze/decompile/run/离线 workbench`
- 在线 workbench 仍然只展示 ELF 输入

## Step 4: Syscall / Trace 演示

用文件 I/O 样例展示 syscall 和 trace 产物：

```bash
~/.moon/bin/moon run cmd/main -- asm example/file_open_read_close.s -o out/file_open_read_close.elf
~/.moon/bin/moon run cmd/main -- run out/file_open_read_close.elf --trace out/file_open_read_close.trace.json
```

观察点：

- 成功生成 `out/file_open_read_close.elf`
- 成功生成 `out/file_open_read_close.trace.json`
- trace 中能看到文件相关 syscall 事件，适合用作“执行器 + syscall 语义”答辩材料

## Step 5: 离线 Workbench 演示

离线 workbench 适合录屏、提交材料和没有 server 的现场：

```bash
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
```

观察点：

- 成功生成 `out/workbench.html`
- 本地打开 HTML 后，可查看反汇编、CFG、寄存器、trace、memory writes、syscalls/output
- 这条路径不依赖在线服务，适合做兜底演示

## Step 6: 在线 Workbench 演示

在线演示前，确认 `out/simple.elf` 已经生成。随后启动服务：

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

浏览器访问顺序：

1. `http://127.0.0.1:18080/`
2. 点击 `Open Online Workbench`
3. 或直接打开 `http://127.0.0.1:18080/workbench?file=out/simple.elf`

现场观察点：

- 首页能说明在线/离线两条入口
- `/workbench` 首屏包含 `How to use`
- `Reset / Prev / Next / Play` 正常工作
- 函数切换、搜索过滤、`Follow PC`、trace 与寄存器联动正常

## 最终验收清单

按下面顺序逐项勾完，即可视为本轮答辩和最终验收材料准备完成：

- `git status --short` 为 clean repo，或本地临时改动已明确隔离
- `~/.moon/bin/moon test` 全量通过
- `out/simple.elf` 可由 `example/simple.s` 重新生成
- `~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20` 可稳定完成
- `out/file_open_read_close.elf` 与 `out/file_open_read_close.trace.json` 成功生成
- `out/workbench.html` 成功生成并可本地打开
- 在线 `cmd/server --target native` 能启动，首页与 `/workbench?file=out/simple.elf` 可访问
- 如被问到 RAW 支持范围，可说明：CLI 与离线 workbench 已支持，在线 `/workbench` 不在本轮范围

## 最小复现命令组

如果现场时间很紧，可以直接按这组命令执行：

```bash
git status --short
mkdir -p out
~/.moon/bin/moon test
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20
~/.moon/bin/moon run cmd/main -- asm example/file_open_read_close.s -o out/file_open_read_close.elf
~/.moon/bin/moon run cmd/main -- run out/file_open_read_close.elf --trace out/file_open_read_close.trace.json
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```
