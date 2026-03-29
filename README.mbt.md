# MoonRV Lab / rvkit

MoonBit 编写的 RISC-V 二进制分析与执行实验项目。当前仓库已经具备静态分析、默认 RV64 演示链路、显式 RV32 兼容装配入口、8 项 syscall、离线 workbench 和在线 `/workbench` 工作台，可直接用于演示、回归和项目验收。

## 当前范围

- 静态分析:
  `asm`、`disasm`、`info`、`symbols`、`cfg`、`callgraph`、`analyze`、`decompile`
- 执行能力:
  `run`、断点、trace JSON、按 ELF 位宽装载执行（默认 RV64，显式兼容 RV32）、`exit/read/write/openat/close/lseek/fstat/brk/ioctl`
- 展示能力:
  离线单文件 `workbench`，在线 `/workbench`，主接口 `/api/workbench/overview` / `/api/workbench/function`，以及兼容接口 `/api/snapshot` / `/api/stream`

## 快速开始

```bash
# 自动化回归
~/.moon/bin/moon test

# 先汇编默认演示源码
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf

# 运行默认 RV64 演示 ELF
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20

# 断点执行
~/.moon/bin/moon run cmd/main -- run out/simple.elf --break 0x10010

# 导出 trace JSON
~/.moon/bin/moon run cmd/main -- run out/simple.elf --trace out/trace.json

# 生成离线 workbench
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html

# 显式生成 RV32 兼容 ELF
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple32.elf --xlen 32
~/.moon/bin/moon run cmd/main -- run out/simple32.elf --max-steps 20
```

## 前端使用路径

- 离线路径:
  `~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html`
  作用: 生成单文件 HTML，适合录屏、提交材料和不依赖 server 的演示。
- 在线路径:
  `~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080`
  作用: 启动首页 `/` 与在线 `/workbench`。Windows 上请在 Visual Studio 2022 Developer Command Prompt / DevShell 中运行；普通 PowerShell + GCC 下的 `cmd/server` 失败不视为产品缺陷。

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
```

## 文档导航

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): 分层、数据流和模块边界
- [docs/USER_GUIDE.md](docs/USER_GUIDE.md): CLI、离线 workbench、在线 workbench 使用路径
- [docs/API_REFERENCE.md](docs/API_REFERENCE.md): CLI JSON、workbench API、HTTP 路由说明
- [docs/TESTING.md](docs/TESTING.md): 自动化回归、验收命令、在线 smoke check
- [example/INDEX.md](example/INDEX.md): 样例集索引

## 样例说明

`example/simple.s` 是默认演示源码入口。运行 `run` / `workbench` / `cmd/server` 前，请先在 `out/` 下生成临时 `simple.elf`。文件 I/O 和 syscall 演示请优先使用以下源码样例并在 `out/` 下生成临时 ELF:

- 默认 `asm example/simple.s -o out/simple.elf` 会生成 RV64 ELF。
- 如需兼容 RV32 样例或旧基线，请显式传 `--xlen 32`，例如 `asm example/simple.s -o out/simple32.elf --xlen 32`。

- `example/file_open_read_close.s`
- `example/file_lseek_read.s`
- `example/file_fstat_close.s`
- `example/sys_brk_ioctl.s`

完整命令和观察点见 [example/INDEX.md](example/INDEX.md)。
