# User Guide

## 前置条件

- 已安装 MoonBit 工具链
- 当前命令默认使用 `~/.moon/bin/moon`
- 建议先创建输出目录:

```bash
mkdir -p out
```

## 路径一: CLI 执行与分析

### 1. 先汇编默认样例再运行

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20
```

你会看到:

- `Entry`
- `PC`
- `Steps`
- `Stop Reason`
- 非零寄存器摘要

### 2. 断点执行

```bash
~/.moon/bin/moon run cmd/main -- run out/simple.elf --break 0x10010
```

预期现象:

- 在 `0x10010` 前停止
- `Stop Reason` 为 `breakpoint @0x10010`
- 只显示断点前已生效的寄存器变化

### 3. JSON 输出

```bash
~/.moon/bin/moon run cmd/main -- run out/simple.elf --format json
```

JSON 顶层包含:

- `entry`
- `xlen`
- `snapshot`
- `trace`

### 4. 导出 trace 文件

```bash
~/.moon/bin/moon run cmd/main -- run out/simple.elf --trace out/trace.json
```

导出的 `out/trace.json` 与 `run --format json` 里的 `trace` 字段结构一致。

### 5. 从源码汇编再运行

```bash
~/.moon/bin/moon run cmd/main -- asm example/branch_loop.s -o out/branch_loop.elf
~/.moon/bin/moon run cmd/main -- run out/branch_loop.elf --max-steps 20
```

## 路径二: 离线 Workbench

离线模式适合提交材料、录屏或不依赖 server 的答辩演示。

```bash
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
```

打开 `out/workbench.html` 后可用:

- 左侧函数/节区导航
- 中央反汇编主 pane
- 下方 `CFG` / `Trace` / `Memory Writes` / `Syscalls/Output`
- 右侧 `State` / `Registers` / `Execution`
- `Reset / Prev / Next / Play`
- `Follow PC`
- `Show Only Current Function`

推荐第二个离线演示对象:

```bash
~/.moon/bin/moon run cmd/main -- asm example/file_fstat_close.s -o out/file_fstat_close.elf
~/.moon/bin/moon run cmd/main -- workbench out/file_fstat_close.elf -o out/file_fstat_close.html
```

## 路径三: 在线 Workbench

### 1. 启动服务

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

### 2. 打开路由

- 入口页: `http://127.0.0.1:18080/`
- 完整工作台: `http://127.0.0.1:18080/workbench`
- 指定文件: `http://127.0.0.1:18080/workbench?file=out/simple.elf`

### 3. 页面内操作

- 顶部输入框支持切换 ELF 文件
- 切换文件后地址栏会同步写回 `?file=...`
- pane 尺寸、当前 tab、过滤器、`Follow PC` 等状态会写入 `localStorage`

## 文件 I/O 样例

推荐顺序:

```bash
~/.moon/bin/moon run cmd/main -- asm example/file_open_read_close.s -o out/file_open_read_close.elf
~/.moon/bin/moon run cmd/main -- run out/file_open_read_close.elf --trace out/file_open_read_close.trace.json

~/.moon/bin/moon run cmd/main -- asm example/file_lseek_read.s -o out/file_lseek_read.elf
~/.moon/bin/moon run cmd/main -- run out/file_lseek_read.elf --trace out/file_lseek_read.trace.json

~/.moon/bin/moon run cmd/main -- asm example/file_fstat_close.s -o out/file_fstat_close.elf
~/.moon/bin/moon run cmd/main -- run out/file_fstat_close.elf --trace out/file_fstat_close.trace.json
```

这些样例依赖仓库内的 `example/io.txt`。

## 推荐演示闭环

1. `asm example/simple.s -o out/simple.elf`
2. `run out/simple.elf --break 0x10010`
3. `run out/simple.elf --trace out/trace.json`
4. `workbench out/simple.elf -o out/workbench.html`
5. `cmd/server --file out/simple.elf --port 18080`
6. 浏览器打开 `/workbench`
