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

默认 `asm` 会生成 RV64 ELF，因此 `run out/simple.elf` 的摘要里会显示 `XLEN: 64`。

你会看到:

- `Entry`
- `PC`
- `Steps`
- `Stop Reason`
- 非零寄存器摘要

### 1.1 同一份源码走 RAW 路径

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw
~/.moon/bin/moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20
```

RAW 路径的约定:

- 当前默认值固定为 `base=0x10000`、`xlen=64`
- `run` 的文本/JSON 摘要结构与 ELF 保持一致，但符号名解析不可用
- `symbols --raw` 只返回“无符号表”说明，`callgraph --raw` 只返回显式“不支持”结果

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

### 6. 显式生成 RV32 兼容 ELF

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple32.elf --xlen 32
~/.moon/bin/moon run cmd/main -- run out/simple32.elf --max-steps 20
```

预期现象:

- `out/simple32.elf` 仍可被 `run`、`workbench`、`cmd/server` 使用
- 执行摘要中的 `XLEN` 变为 `32`

## 路径二: 离线 Workbench

离线模式适合提交材料、录屏或不依赖 server 的答辩演示。

```bash
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
```

RAW 等价命令:

```bash
~/.moon/bin/moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html
```

打开 `out/workbench.html` 后，离线页面与在线 `/workbench` 共用同一套交互:

- 首屏 `How to use` 面板默认展开，可手动关闭，关闭状态会写入 `localStorage`
- 左侧函数/节区导航会和顶部搜索框联动；点击节区地址可直接把地址带入搜索
- 中央反汇编主 pane 会显示当前函数、过滤条件、focus 地址以及当前 step/pc
- 下方 `CFG` / `Trace` / `Memory Writes` / `Syscalls/Output` 用于联动查看控制流、执行轨迹、写内存和 syscall/stdout/stderr
- 右侧 `State` / `State Compare` / `Replay Breakpoints` / `Registers` / `Execution` 用于查看当前步骤摘要、状态对比和断点列表
- `Reset / Prev / Next / Play` 用于浏览轨迹，`Follow PC` 用于自动跟随当前执行位置
- 反汇编表和 CFG 只允许给当前 trace reachable 的地址设置回放断点；灰态地址表示当前轨迹不会执行到，不能静默设断点
- `Play` 或 `Next` 命中回放断点后会立即暂停，并额外显示 `Replay breakpoint @...`；它不会覆盖运行时真实的 `stop_reason`
- `State Compare` 提供 `Prev step` 和 `Initial` 两种 baseline，切换结果同样走纯客户端计算并持久化到 `localStorage`

推荐按以下顺序使用:

1. 先看 `How to use` 面板确认操作路径。
2. 从左侧函数列表或顶部函数选择框进入目标函数。
3. 用搜索框按地址、函数名、指令文本或 category 过滤；输入地址后按 Enter 直接跳转。
4. 在反汇编或 CFG 上给 trace reachable 地址加回放断点；如果入口显示灰态，先用 `Trace` 面板确认该地址是否真的出现在当前轨迹里。
5. 用 `Play` 或 `Next` 浏览执行轨迹；命中后页面会额外显示 `Replay breakpoint @...`，方便和真实的 `ebreak` / syscall 停止区分开。
6. 在右侧 `State Compare` 里切换 `Prev step` / `Initial`，分别查看“本步 delta”与“相对初始状态的累计变化”。
7. 需要固定视角时关闭 `Follow PC`，需要跟随执行位置时再打开。
8. 结合 `Memory Writes` 与 `Syscalls/Output` 继续排查输出、文件 I/O 或停止原因。

这里要特别区分两类断点:

- `run --break` 是执行内核里的真实断点，会改变 CLI 运行何时停下。
- workbench 里的 `Replay Breakpoints` 只是轨迹回放断点，只会让页面在已有 trace 的某个地址暂停，不会回写 ELF，也不会新增 server/API 字段。

当前页面没有 `Show Only Current Function` 控件；如需收窄范围，请组合使用函数选择、左侧过滤提示和搜索框。

推荐第二个离线演示对象:

```bash
~/.moon/bin/moon run cmd/main -- asm example/file_fstat_close.s -o out/file_fstat_close.elf
~/.moon/bin/moon run cmd/main -- workbench out/file_fstat_close.elf -o out/file_fstat_close.html
```

RAW 离线路径说明:

- 当前离线 `workbench` 已支持 RAW 输入
- RAW 页面会保留现有 Godbolt 风格布局、trace 回放、`Replay Breakpoints` 和 `State Compare`
- RAW 页面使用显式 `base/xlen` 元数据生成 overview 与 runtime
- 在线 `/workbench` 与 `/api/workbench/overview|function` 现已支持同一组 RAW 参数：`raw=1&base=<addr>&xlen=32|64`

## 路径三: 在线 Workbench

### 1. 启动服务

Windows 上请优先使用 Visual Studio 2022 Developer Command Prompt / DevShell，或先执行 `vcvars64.bat` / `Launch-VsDevShell.ps1` 再运行 `cmd/server`。普通 PowerShell + GCC 失败不在支持路径内。

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

### 2. 打开路由

- 入口页: `http://127.0.0.1:18080/`
  这里是 Quick Start 首页，会展示默认文件、在线/离线路径、主 API 与兼容 API 的定位，并提供 `Open Online Workbench` 入口。
- 完整工作台: `http://127.0.0.1:18080/workbench`
- 指定文件: `http://127.0.0.1:18080/workbench?file=out/simple.elf`
- RAW 指定文件: `http://127.0.0.1:18080/workbench?file=out/simple.raw&raw=1&base=0x10000&xlen=64`

### 3. 页面内操作

- 推荐先从入口页进入 `/workbench?file=...`，这样默认文件会直接带入查询参数
- 在线 workbench 主链路会先加载 `/api/workbench/overview`，再按需请求 `/api/workbench/function`；`/api/snapshot` 与 `/api/stream` 仅保留 ELF-only 兼容定位
- 顶部输入框支持切换 `ELF / RAW`；选择 `RAW` 后会额外显示 `Base` 和 `XLEN`
- 点击 `Load` 后会重新加载 overview 与函数切片；RAW 模式下地址栏会完整保留 `raw/base/xlen`
- 在线 RAW 继续沿用离线函数模型，只暴露一个 synthetic function `entry`
- 切回 `ELF` 后，RAW 专属字段会隐藏，不再污染普通加载路径
- `How to use` 面板默认展开，可关闭；关闭状态同样会写入 `localStorage`
- 在线/离线 workbench 共用 `Replay Breakpoints` 与 `State Compare` 交互；这两项能力都只依赖已有 overview/function/runtime/event 数据，不新增 `/api/workbench/*` 字段
- 回放断点只能设置在当前 trace reachable 地址上；`Play` / `Next` 命中后会额外显示 `Replay breakpoint @...`
- `State Compare` 的 `Prev step` 展示当前 event 的寄存器/内存/输出增量，`Initial` 展示相对初始寄存器的累计变化，并补充最近写内存与累计 stdout/stderr 摘要
- 切换文件后地址栏会同步写回 `?file=...`；RAW 模式下会附带 `&raw=1&base=...&xlen=...`
- pane 尺寸、当前 tab、过滤器、`Follow PC`、帮助面板折叠状态、回放断点和 compare mode 等 UI 状态会写入 `localStorage`
- 页面内的空态、错误态和截断提示会直接告诉你下一步可以做什么，例如“清空搜索”“选择函数”“调整 `--max-inst`”等

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
2. `asm example/simple.s -o out/simple.raw --format raw`
3. `run out/simple.elf --break 0x10010`
4. `run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20`
5. `run out/simple.elf --trace out/trace.json`
6. `workbench out/simple.elf -o out/workbench.html`
7. `workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html`
8. `moon run cmd/server --target native -- --file out/simple.elf --port 18080`
9. 浏览器先打开 `/` 查看 Quick Start，再进入 `/workbench?file=out/simple.elf`

进入 workbench 后，建议再手工确认一次:

- 只给 trace reachable 地址设置 `Replay Breakpoints`
- `Play` 命中后会自动停下，并显示 `Replay breakpoint @...`
- `State Compare` 在 `Prev step` / `Initial` 两种模式下都能看到预期变化
