# API Reference

## CLI 命令

### `run`

```bash
~/.moon/bin/moon run cmd/main -- run <file> [--entry <name|addr>] [--max-steps <n>] [--break <name|addr>] [--trace <file>] [--format text|json]
```

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

### `workbench`

```bash
~/.moon/bin/moon run cmd/main -- workbench <file> -o out/workbench.html [--title <text>] [--max-inst <n>]
```

输出是一个完全离线的单文件 HTML，内嵌：

- 静态分析结果
- runtime 初始状态
- 完整执行事件
- Godbolt 风格 UI 壳

## `workbench/` 包

### `create_options`

```moonbit
pub fn create_options(title : String, max_instructions : Int) -> WorkbenchOptions
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

`/api/snapshot` 与 `/api/stream` 保留为兼容接口，不再作为在线 workbench 的主入口。

## HTTP 路由

### `GET /`

- 轻量入口页
- 展示默认文件、主 API 说明和 `/workbench` 入口

### `GET /workbench`

- 返回完整在线工作台 HTML
- 支持 `?file=<path>`
- 页面主数据源为 `/api/workbench/overview`
- 函数切片按需从 `/api/workbench/function` 加载
- `/api/snapshot` 与 `/api/stream` 仅保留兼容定位

### `GET /api/health`

示例：

```json
{
  "ok": true
}
```

### `GET /api/workbench/overview?file=<path>&max_events=<n>`

示例：

```bash
curl -sS "http://127.0.0.1:18080/api/workbench/overview?file=out/simple.elf&max_events=20"
```

返回在线 workbench 的概览载荷。

### `GET /api/workbench/function?file=<path>&addr=<hex-or-name>`

示例：

```bash
curl -sS "http://127.0.0.1:18080/api/workbench/function?file=out/simple.elf&addr=0x10000"
```

返回指定函数的切片载荷。

### `GET /api/snapshot?file=<path>&max_inst=<n>`

示例：

```bash
curl -sS "http://127.0.0.1:18080/api/snapshot?file=out/simple.elf&max_inst=20"
```

兼容接口，返回一次性快照载荷。

### `GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>`

示例：

```bash
curl -sN "http://127.0.0.1:18080/api/stream?file=out/simple.elf&max_inst=12&max_events=4&interval_ms=10"
```

兼容接口，返回事件流或 SSE 事件输出。

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
