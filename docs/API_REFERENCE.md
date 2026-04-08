# API Reference

## CLI 命令

### `asm`

```bash
~/.moon/bin/moon run cmd/main -- asm <file> [-o <output>] [--format elf|hex|raw] [--base <addr>] [--xlen 32|64]
```

- `--xlen` 仅影响 ELF 输出。
- 默认值为 `64`，因此 `asm example/simple.s -o out/simple.elf` 会生成 RV64 ELF。
- 显式传 `--xlen 32` 可保留 RV32 兼容产物，例如 `out/simple32.elf`。

### `run`

```bash
~/.moon/bin/moon run cmd/main -- run <file> [--entry <name|addr>] [--max-steps <n>] [--break <name|addr>] [--trace <file>] [--format text|json] [--raw] [--base <addr>] [--xlen 32|64]
```

- ELF 路径默认不需要额外元数据。
- RAW 路径请显式传 `--raw --base <addr> --xlen <32|64>`；当前默认值为 `base=0x10000`、`xlen=64`。
- RAW 输入不提供符号表；`--entry` / `--break` 建议直接使用地址。

#### 文本输出

文本模式输出一个执行摘要，包含：

- `Entry`
- `PC`
- `XLEN`
- `Steps`
- `Stop Reason`
- `stdout/stderr`
- 非零寄存器

#### JSON 输出

`--format json` 返回固定顶层结构：

```json
{
  "entry": "0x10000",
  "xlen": 64,
  "snapshot": {
    "pc": "0x1002c",
    "steps": 12,
    "stop_reason": "ebreak @0x1002c",
    "stdout": "",
    "stderr": "",
    "registers": {
      "zero": "0x0",
      "ra": "0x0"
    }
  },
  "trace": [
    {
      "step": 1,
      "pc_before": "0x10000",
      "pc_after": "0x10004",
      "addr": "0x10000",
      "asm": "addi a0, zero, 42",
      "category": "Arithmetic",
      "register_writes": [],
      "memory_writes": [],
      "stdout_append": "",
      "stderr_append": "",
      "stop_reason": "running",
      "syscall": null
    }
  ]
}
```

#### `--trace`

- `--trace out/trace.json` 会把 `trace` 数组单独写到文件。
- 文件内容与 JSON 输出里的 `trace` 字段结构一致。

### `symbols` / `callgraph` 的 RAW 受限模式

- `symbols --raw --format json` 返回固定受限结构:
  - `input_format: "raw"`
  - `supported: false`
  - `symbols: []`
  - `message: "RAW input does not provide a symbol table."`
- `callgraph --raw --format json` 返回固定受限结构:
  - `input_format: "raw"`
  - `supported: false`
  - `functions: []`
  - `edges: []`
  - `message: "RAW input lacks reliable function boundaries, so call graph generation is unavailable."`

### `workbench`

```bash
~/.moon/bin/moon run cmd/main -- workbench <file> -o out/workbench.html [--title <text>] [--max-inst <n>] [--raw] [--base <addr>] [--xlen 32|64]
```

输出是一个完全离线的单文件 HTML，内嵌：

- 静态分析结果
- runtime 初始状态
- 完整执行事件
- Godbolt 风格 UI 壳

页面行为与在线 `/workbench` 保持一致，包括：

- 默认展开的 `How to use` 使用引导
- 顶部函数选择、搜索/跳转与左侧函数/节区导航联动
- `Reset / Prev / Next / Play`、`Follow PC`、`Trace / Memory Writes / Syscalls/Output`
- `Replay Breakpoints` 只对当前 trace reachable 地址生效，可在反汇编和 CFG block start 上切换，并沿用 `localStorage` 持久化
- 命中回放断点时只会额外显示 `Replay breakpoint @...`，不会覆盖运行时真实的 `stop_reason`
- `State Compare` 提供 `Prev step` 与 `Initial` 两种 baseline；前者直接读取当前 event 的寄存器/内存/输出增量，后者基于 `runtime.initial_registers`、累计输出与最近 memory writes 做纯客户端对比
- 空态、错误态和截断提示中的下一步操作建议

输入可以是:

- 默认生成的 RV64 ELF
- 显式 `--xlen 32` 生成的 RV32 ELF
- 通过 `asm --format raw` 生成的 RAW 文件，再配合 `--raw --base <addr> --xlen <32|64>`

说明:

- RAW 已覆盖离线 `workbench` HTML、在线 `/workbench`、`/api/workbench/overview` 与 `/api/workbench/function`
- `/api/snapshot` 与 `/api/stream` 继续保持 ELF-only 兼容接口

这些交互全部在客户端完成，不会修改 `/api/workbench/overview`、`/api/workbench/function`、`/api/snapshot`、`/api/stream` 的 wire format。

## `workbench/` 包

### `create_options`

```moonbit
pub fn create_options(title : String, max_instructions : Int) -> WorkbenchOptions
```

### `create_input_options`

```moonbit
pub fn create_input_options(
  title : String,
  max_instructions : Int,
  raw_mode : Bool,
  base_addr : UInt,
  xlen : Int
) -> WorkbenchOptions
```

### `generate_from_file`

```moonbit
pub fn generate_from_file(
  input_file : String,
  output_file : String,
  options : WorkbenchOptions
) -> WorkbenchError?
```

### `overview_api_json_from_file`

```moonbit
pub fn overview_api_json_from_file(
  input_file : String,
  max_events : Int
) -> String
```

返回在线 workbench 的主概览载荷，包含：

- `meta`
- `function_count`
- `instruction_count`
- `total_instruction_count`
- `functions`
- `sections`
- `runtime`
- `events`

在线 workbench 首屏与导航以该接口为主。

RAW 模式补充:

- `meta.input_format` 固定为 `"raw"`
- `meta.file_class` 固定为 `"RAW"`
- 函数列表只暴露一个 synthetic function `entry`

回放断点与 `State Compare` 继续复用现有字段，不新增 schema，客户端主要读取：

- `runtime.initial_registers`
- `events[*].addr`
- `events[*].register_writes`
- `events[*].memory_writes`
- `events[*].stdout_append`
- `events[*].stderr_append`
- `events[*].stop_reason`

### `function_api_json_from_file`

```moonbit
pub fn function_api_json_from_file(
  input_file : String,
  addr_or_name : String
) -> String
```

返回单个函数切片数据，支持三种定位方式：

- 函数名
- 函数起始地址，例如 `0x10000`
- 落在函数范围内的地址

返回载荷包含：

- `function`
- `instructions`
- `blocks`
- `edges`
- `available`

在线 workbench 的函数级 CFG 与明细面板以该接口为主。

RAW 模式补充:

- 支持用 `entry`、`0x10000` 或落在该 synthetic range 内的地址请求切片
- 不新增函数恢复逻辑

### `overview_api_json_from_file_with_options`

```moonbit
pub fn overview_api_json_from_file_with_options(
  input_file : String,
  max_events : Int,
  options : WorkbenchOptions
) -> String
```

用于把在线 `/api/workbench/overview` 与共享 ELF/RAW 装载路径统一到同一组 `WorkbenchOptions`。

### `function_api_json_from_file_with_options`

```moonbit
pub fn function_api_json_from_file_with_options(
  input_file : String,
  addr_or_name : String,
  options : WorkbenchOptions
) -> String
```

用于把在线 `/api/workbench/function` 与共享 ELF/RAW 装载路径统一到同一组 `WorkbenchOptions`。

### `snapshot_api_json_from_file`

```moonbit
pub fn snapshot_api_json_from_file(
  input_file : String,
  max_instructions : Int
) -> String
```

兼容接口，返回一次性快照载荷：

```json
{
  "ok": true,
  "data": {
    "meta": {},
    "functions": [],
    "sections": [],
    "instructions": [],
    "blocks": [],
    "edges": [],
    "runtime": {},
    "events": []
  }
}
```

### `stream_api_json_from_file`

```moonbit
pub fn stream_api_json_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int
) -> String
```

兼容接口，返回事件流兼容载荷：

```json
{
  "ok": true,
  "events": [],
  "total_events": 12
}
```

### `stream_event_payloads_from_file`

```moonbit
pub fn stream_event_payloads_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int
) -> StreamEventsLoadResult
```

供 `/api/stream` 与 SSE 风格事件输出复用。

### `online_page_html`

```moonbit
pub fn online_page_html(
  default_file : String,
  initial_file : String,
  max_instructions : Int,
  overview_endpoint : String
) -> String
```

返回 `/workbench` 路由使用的在线 HTML 壳。页面会先加载：

- `/api/workbench/overview`
- `/api/workbench/function`

页面首屏默认展开 `How to use` 面板；`/api/snapshot` 与 `/api/stream` 保留为兼容接口，不再作为在线 workbench 的主入口。

### `online_page_html_with_options`

```moonbit
pub fn online_page_html_with_options(
  default_file : String,
  initial_file : String,
  max_instructions : Int,
  overview_endpoint : String,
  function_endpoint : String,
  options : WorkbenchOptions
) -> String
```

用于给 `/workbench` 注入 `raw_mode`、`base_addr`、`xlen` 等在线 boot metadata。

## HTTP 路由

Windows 上启动或验证 `cmd/server` 时，请使用 Visual Studio 2022 Developer Command Prompt / DevShell，或先初始化 MSVC 环境。普通 PowerShell + GCC 失败不视为接口问题。

### `GET /`

- Quick Start 首页
- 展示默认文件、`Open Online Workbench` 入口、在线/离线两条使用路径
- 说明 `/api/workbench/overview` 与 `/api/workbench/function` 是主接口，`/api/snapshot` 与 `/api/stream` 是兼容接口

### `GET /workbench`

- 返回完整在线工作台 HTML
- 支持 `?file=<path>&raw=1&base=<addr>&xlen=32|64`
- `raw=1` 时默认值固定为 `base=0x10000`、`xlen=64`
- 首屏默认展示 `How to use` 面板
- 页面主数据源为 `/api/workbench/overview`
- 函数切片按需从 `/api/workbench/function` 加载
- `/api/snapshot` 与 `/api/stream` 仅保留 ELF-only 兼容定位
- 页面交互围绕“载入文件 -> 选择函数 -> 搜索/跳转 -> 浏览 Trace/Memory/Syscalls”展开
- 页面内的 `Replay Breakpoints` 和 `State Compare` 都是纯客户端能力，不新增查询参数，也不新增响应字段
- 回放断点只在当前 trace reachable 地址上生效，命中后额外显示 `Replay breakpoint @...`

### `GET /api/health`

示例：

```json
{
  "ok": true
}
```

### `GET /api/workbench/overview?file=<path>&max_events=<n>[&raw=1&base=<addr>&xlen=32|64]`

示例：

```bash
curl -sS "http://127.0.0.1:18080/api/workbench/overview?file=out/simple.elf&max_events=20"
curl -sS "http://127.0.0.1:18080/api/workbench/overview?file=out/simple.raw&raw=1&base=0x10000&xlen=64&max_events=20"
```

返回在线 workbench 的概览载荷。

当 `raw=1` 时:

- 非法 `base` 或 `xlen` 会直接返回 `400` JSON 错误
- 响应中的 `meta.input_format` 为 `"raw"`
- 函数列表只包含 synthetic `entry`

当前 workbench 的回放断点和状态对比继续消费已有 `runtime` / `events` 字段，不新增响应字段。

### `GET /api/workbench/function?file=<path>&addr=<hex-or-name>[&raw=1&base=<addr>&xlen=32|64]`

示例：

```bash
curl -sS "http://127.0.0.1:18080/api/workbench/function?file=out/simple.elf&addr=0x10000"
curl -sS "http://127.0.0.1:18080/api/workbench/function?file=out/simple.raw&raw=1&base=0x10000&xlen=64&addr=entry"
```

返回指定函数的切片载荷。

### `GET /api/snapshot?file=<path>&max_inst=<n>`

示例：

```bash
curl -sS "http://127.0.0.1:18080/api/snapshot?file=out/simple.elf&max_inst=20"
```

兼容接口，返回一次性快照载荷。当前保持 ELF-only。

### `GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>`

示例：

```bash
curl -sN "http://127.0.0.1:18080/api/stream?file=out/simple.elf&max_inst=12&max_events=4&interval_ms=10"
```

兼容接口，返回事件流或 SSE 事件输出。当前保持 ELF-only。

## 稳定兼容接口

当前阶段保持以下接口不删除：

- `cmd/main` 的 `run` / `workbench` 参数与输出格式
- `generate_from_file`
- `overview_api_json_from_file`
- `function_api_json_from_file`
- `snapshot_api_json_from_file`
- `stream_api_json_from_file`
- `stream_event_payloads_from_file`
- `/api/health`
- `/api/workbench/overview`
- `/api/workbench/function`
- `/api/snapshot`
- `/api/stream`
- `/workbench`
