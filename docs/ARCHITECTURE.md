# Architecture

## 分层概览

MoonRV Lab 当前按“静态分析核心 -> 执行内核 -> 展示层 -> 入口层”组织。

```text
example/*.elf or example/*.s
        |
        v
cmd/main (CLI) ------------------------------+
        |                                    |
        v                                    v
format / asm / decode / disasm / analysis   cmd/server
        |                                    |
        +-------------> simulator <----------+
                             |
                             v
                      trace / snapshot
                             |
                             v
                         workbench
```

## 模块职责

### `asm/`

- 把最小 RISC-V 汇编源码转成内部指令和 ELF/hex/raw 输出。
- 默认 `asm` 产出 RV64 ELF，显式 `--xlen 32` 保留 RV32 兼容入口。
- 样例和测试中的 `.s` 文件主要通过这一层进入系统。

### `format/`

- 负责 ELF 识别、解析、段/节提取和符号读取。
- `run`、`workbench`、`/api/snapshot` 都先经过这一层完成装载。

### `decode/` + `disasm/`

- `decode/` 负责把二进制指令还原成结构化指令。
- `disasm/` 负责把结构化指令渲染成汇编文本。
- 静态分析与运行 trace 都依赖这两个模块提供统一指令视图。

### `analysis/`

- 构建 CFG、CallGraph、数据流结果和反编译视图。
- 为 CLI 静态命令和 workbench 的函数/CFG 面板提供数据。

### `simulator/`

- 当前唯一执行后端。
- 负责 ELF 装载后的初始状态建立、`step`、`run_with_limit`、断点、寄存器/内存 diff、trace 记录。
- 按输入 ELF 的位宽建立执行状态；当前默认演示链路走 RV64，显式 `--xlen 32` 仍可生成并执行 RV32 ELF。
- syscall 覆盖 `exit/read/write/openat/close/lseek/fstat/brk/ioctl`。

### `workbench/`

- 把静态分析结果和 simulator runtime 数据投影为 `WorkbenchData`。
- 提供三类能力:
  - 离线单文件 HTML 生成
  - `/api/workbench/overview` + `/api/workbench/function` 主接口
  - `/api/snapshot` / `/api/stream` 兼容接口
- 在线和离线页面共用同一套 HTML/CSS/JS 壳，只是启动模式不同:
  - 离线模式内嵌完整 `WorkbenchData`
  - 在线模式先拉取 `/api/workbench/overview`，再按需请求 `/api/workbench/function`
- 在线主接口通过同一组 `WorkbenchOptions` 统一装载 ELF 与 RAW；`/api/snapshot` / `/api/stream` 继续保持 ELF-only 兼容接口

### `cmd/main/`

- 统一 CLI 入口。
- 对外暴露 `asm/disasm/info/symbols/cfg/callgraph/run/analyze/decompile/workbench` 等命令。
- 当前 `run` 和 `workbench` 已经形成验收闭环:
  - `run`: 真实执行 + 文本/JSON 输出 + trace 文件
  - `workbench`: 生成离线 Godbolt 风格页面

### `cmd/server/`

- 只负责在线路由和 HTML/API 出口，不承载模拟器状态。
- `/` 是轻量入口页。
- `/workbench` 是完整在线工作台。
- `/api/workbench/overview` / `/api/workbench/function` 是在线 workbench 主接口；`/api/snapshot` / `/api/stream` 保持兼容。

## 关键数据流

### CLI `run`

1. `cmd/main` 解析参数。
2. `simulator.load(file)` 读取 ELF、建立 `ProgramImage` 和 `ExecState`。
3. 应用 `--entry`、`--break`、`--max-steps`。
4. `simulator.run_with_limit` 执行并积累 trace。
5. 输出文本 summary 或 JSON。
6. 如指定 `--trace`，额外写出结构化 trace 文件。

### 离线 `workbench`

1. `cmd/main workbench` 调用 `workbench.generate_from_file`。
2. `workbench` 在后台完成 ELF 解析、指令索引、CFG、runtime 事件整理。
3. 把 `WorkbenchData` 内嵌到单文件 HTML。
4. 浏览器离线打开后即可本地单步/播放。

### 在线 `/workbench`

1. `cmd/server` 返回在线 workbench HTML 壳。
2. 页面读取 `?file=`，并在 RAW 模式下同时读取 `raw/base/xlen`，或退回 server 默认文件。
3. 前端请求 `/api/workbench/overview?file=...`，RAW 时再附带 `raw/base/xlen`，获取概览与 runtime/events。
4. 用户选择函数或地址后，再按需请求 `/api/workbench/function?file=...&addr=...`；RAW 继续沿用 synthetic `entry` 函数模型。
5. 页面在本地根据 overview 的 `events` 和函数切片数据做播放、单步和 inspector 联动。

## 设计边界

- `simulator/` 是唯一执行真相来源，workbench 不再维护独立伪执行逻辑。
- `cmd/server` 不持有运行态，不做会话级调度。
- `tools/rvrunner.cpp` 保留为外部对照原型，不是主产品执行链。
- 当前验收目标不继续扩 ISA，不引入特权级、CSR 或 JIT。
