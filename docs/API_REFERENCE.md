# API Reference

## CLI 命令

### `run`

```bash
~/.moon/bin/moon run cmd/main -- run <file> [--entry <name|addr>] [--max-steps <n>] [--break <name|addr>] [--trace <file>] [--format text|json]
```

#### 文本输出

文本模式输出一个执行摘要，包含:

- `Entry`
- `PC`
- `XLEN`
- `Steps`
- `Stop Reason`
- `stdout/stderr`
- 非零寄存器

#### JSON 输出

`--format json` 返回固定顶层结构:

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

- `--trace out/trace.json` 会把 trace 数组单独写到文件。
- 文件内容与 JSON 输出里的 `trace` 字段结构一致。

### `workbench`

```bash
~/.moon/bin/moon run cmd/main -- workbench <file> -o out/workbench.html [--title <text>] [--max-inst <n>]
```

输出是一个完全离线的单文件 HTML，内嵌:

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

### `snapshot_api_json_from_file`

```moonbit
pub fn snapshot_api_json_from_file(
  input_file : String,
  max_instructions : Int
) -> String
```

返回:

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

`data` 的主要字段:

- `meta`: 文件、入口、统计信息
- `instructions`: 反汇编列表
- `blocks` / `edges`: CFG 结构
- `runtime.initial_pc`
- `runtime.initial_registers`
- `events`: 真实执行顺序事件

### `stream_api_json_from_file`

```moonbit
pub fn stream_api_json_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int
) -> String
```

返回:

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

用于 `/api/stream` 和 SSE 风格事件输出测试。

### `online_page_html`

```moonbit
pub fn online_page_html(
  default_file : String,
  initial_file : String,
  max_instructions : Int,
  snapshot_endpoint : String
) -> String
```

返回在线 `/workbench` 路由使用的完整 HTML 壳。

## HTTP 路由

### `GET /`

- 轻量入口页
- 展示默认文件、API 说明和 `/workbench` 入口

### `GET /workbench`

- 返回完整在线工作台 HTML
- 支持 `?file=<path>`
- 页面主数据源为 `/api/snapshot`

### `GET /api/health`

示例:

```json
{
  "ok": true,
  "service": "moonrv-lab-server"
}
```

### `GET /api/snapshot?file=<path>&max_inst=<n>`

示例:

```bash
curl -sS "http://127.0.0.1:18080/api/snapshot?file=example/simple.elf&max_inst=20"
```

返回 `WorkbenchData`，供在线工作台一次性加载。

### `GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>`

示例:

```bash
curl -sN "http://127.0.0.1:18080/api/stream?file=example/simple.elf&max_inst=12&max_events=4&interval_ms=10"
```

返回事件流兼容载荷。当前保留兼容，在线 workbench v1 不把它作为主渲染链。

## 稳定兼容接口

阶段五收尾默认保持以下接口不变:

- `cmd/main` 的 `run` / `workbench` 参数与输出格式
- `generate_from_file`
- `snapshot_api_json_from_file`
- `stream_api_json_from_file`
- `stream_event_payloads_from_file`
- `/api/health`
- `/api/snapshot`
- `/api/stream`
- `/workbench`
