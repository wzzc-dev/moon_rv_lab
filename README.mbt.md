# MoonRV Lab / rvkit

MoonBit 编写的 RISC-V 二进制分析与执行实验项目。当前仓库已经具备静态分析、RV64I 执行主干、8 项 syscall、离线 workbench 和在线 `/workbench` 工作台，可直接用于演示、回归和项目验收。

## 当前范围

- 静态分析:
  `asm`、`disasm`、`info`、`symbols`、`cfg`、`callgraph`、`analyze`、`decompile`
- 执行能力:
  `run`、断点、trace JSON、RV64I 主干执行、`exit/read/write/openat/close/lseek/fstat/brk/ioctl`
- 展示能力:
  离线单文件 `workbench`，在线 `/workbench`，以及 `/api/snapshot` / `/api/stream`

## 快速开始

```bash
# 自动化回归
~/.moon/bin/moon test

# 先汇编默认演示源码
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf

# 运行默认演示 ELF
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20

# 断点执行
~/.moon/bin/moon run cmd/main -- run out/simple.elf --break 0x10010

# 导出 trace JSON
~/.moon/bin/moon run cmd/main -- run out/simple.elf --trace out/trace.json

# 生成离线 workbench
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
```

## 在线访问

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

- 入口页: `http://127.0.0.1:18080/`
  作用: 轻量说明页，展示 API 和打开工作台入口。
- 完整在线工作台: `http://127.0.0.1:18080/workbench?file=out/simple.elf`
  作用: Godbolt 风格在线 workbench，支持文件切换、单步、播放、寄存器/Trace/Memory 联动。

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

- `example/file_open_read_close.s`
- `example/file_lseek_read.s`
- `example/file_fstat_close.s`
- `example/sys_brk_ioctl.s`

完整命令和观察点见 [example/INDEX.md](example/INDEX.md)。
