# MoonRV Lab / rvkit

MoonBit 编写的 RISC-V 二进制分析与执行实验项目。当前仓库已经具备静态分析、默认 RV64 演示链路、显式 RV32 兼容装配入口、RAW 输入闭环、8 项 syscall、离线 workbench 和在线 `/workbench` 工作台，可直接用于演示、回归和项目验收。

## 当前范围

- 静态分析:
  `asm`、`disasm`、`info`、`symbols`、`cfg`、`callgraph`、`analyze`、`decompile`
- 执行能力:
  `run`、断点、trace JSON、按 ELF 位宽装载执行（默认 RV64，显式兼容 RV32）、RAW `base/xlen` 显式装载、`exit/read/write/openat/close/lseek/fstat/brk/ioctl`
- 展示能力:
  离线单文件 `workbench`，在线 `/workbench`，主接口 `/api/workbench/overview` / `/api/workbench/function`，以及兼容接口 `/api/snapshot` / `/api/stream`

RAW 支持范围补充:

- 已支持: `disasm/info/cfg/analyze/decompile/run/离线 workbench`
- 受限输出: `symbols --raw` 返回空符号表说明；`callgraph --raw` 返回显式“不支持”
- 当前不包含: 在线 `/workbench` 的 RAW 输入

## 快速开始

```bash
# 自动化回归
~/.moon/bin/moon test

# 先汇编默认演示源码
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf

# 运行默认 RV64 演示 ELF
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20

# 同一份源码导出 RAW 并显式执行
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw
~/.moon/bin/moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20

# 断点执行
~/.moon/bin/moon run cmd/main -- run out/simple.elf --break 0x10010

# 导出 trace JSON
~/.moon/bin/moon run cmd/main -- run out/simple.elf --trace out/trace.json

# 生成离线 workbench
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
~/.moon/bin/moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html

# 显式生成 RV32 兼容 ELF
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple32.elf --xlen 32
~/.moon/bin/moon run cmd/main -- run out/simple32.elf --max-steps 20
```

## 前端使用路径

- 离线路径:
  `~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html`
  作用: 生成单文件 HTML，适合录屏、提交材料和不依赖 server 的演示。
  RAW 等价命令:
  `~/.moon/bin/moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html`
- 在线路径:
  `~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080`
  作用: 启动首页 `/` 与在线 `/workbench`。当前在线路径仍以 ELF 为主，不包含 RAW 输入。Windows 上请在 Visual Studio 2022 Developer Command Prompt / DevShell 中运行；普通 PowerShell + GCC 下的 `cmd/server` 失败不视为产品缺陷。

- 入口页: `http://127.0.0.1:18080/`
  作用: Quick Start 首页，会展示默认文件、打开在线 workbench 的入口、在线/离线两条使用路径，以及主 API 与兼容 API 的定位。
- 完整在线工作台: `http://127.0.0.1:18080/workbench?file=out/simple.elf`
  作用: 在线 workbench 首屏带 `How to use` 引导，推荐按“载入文件 -> 选择函数 -> 搜索/跳转 -> Reset / Prev / Next / Play -> Follow PC -> Trace / Memory / Syscalls”使用。

## 常用命令

```bash
# 汇编样例源码
~/.moon/bin/moon run cmd/main -- asm example/branch_loop.s -o out/branch_loop.elf

# 结构化运行结果
~/.moon/bin/moon run cmd/main -- run out/simple.elf --format json

# 导出带断点的 trace
~/.moon/bin/moon run cmd/main -- run out/simple.elf --break 0x10010 --trace out/break.trace.json

# 生成离线工作台
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html

# 生成 RAW 并走 RAW 执行/离线路径
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw
~/.moon/bin/moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20
~/.moon/bin/moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html
```

## 文档导航

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): 分层、数据流和模块边界
- [docs/USER_GUIDE.md](docs/USER_GUIDE.md): CLI、离线 workbench、在线 workbench 使用路径
- [docs/API_REFERENCE.md](docs/API_REFERENCE.md): CLI JSON、workbench API、HTTP 路由说明
- [docs/TESTING.md](docs/TESTING.md): 自动化回归、验收命令、在线 smoke check
- [docs/RUNBOOK.md](docs/RUNBOOK.md): clean repo 到 CLI / 离线 / 在线演示的答辩 runbook
- [example/INDEX.md](example/INDEX.md): 样例集索引

## 样例说明

`example/simple.s` 是默认演示源码入口。现在推荐同时掌握两条生成链:

- ELF 主路径:
  `asm example/simple.s -o out/simple.elf`
- RAW 主路径:
  `asm example/simple.s -o out/simple.raw --format raw`

运行 `run` / 离线 `workbench` / `cmd/server` 前，请先在 `out/` 下生成对应临时产物。文件 I/O 和 syscall 演示请优先使用以下源码样例并在 `out/` 下生成临时 ELF:

- 默认 `asm example/simple.s -o out/simple.elf` 会生成 RV64 ELF。
- RAW 路径默认使用 `base=0x10000`、`xlen=64`，例如 `run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20`。
- 如需兼容 RV32 样例或旧基线，请显式传 `--xlen 32`，例如 `asm example/simple.s -o out/simple32.elf --xlen 32`。
- `symbols --raw` 与 `callgraph --raw` 只提供受限说明输出，不伪造符号或函数边界。

- `example/file_open_read_close.s`
- `example/file_lseek_read.s`
- `example/file_fstat_close.s`
- `example/sys_brk_ioctl.s`

完整命令和观察点见 [example/INDEX.md](example/INDEX.md)。
