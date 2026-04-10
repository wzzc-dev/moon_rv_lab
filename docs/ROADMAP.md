# Roadmap

## 当前轮次: 在线 RAW 产品化

- 目标: 把在线 `/workbench` 与 `/api/workbench/overview|function` 补齐到和离线 RAW 同级可用性
- 已覆盖:
  - `/workbench?file=<path>&raw=1&base=<addr>&xlen=32|64`
  - `/api/workbench/overview`
  - `/api/workbench/function`
  - 在线 toolbar 的 `ELF / RAW` 切换、`Base`、`XLEN`
  - URL、刷新和分享时对 `raw/base/xlen` 的保留
- 明确边界:
  - RAW 在线初版继续只暴露 synthetic function `entry`
  - `/api/snapshot` 与 `/api/stream` 仍保持 ELF-only 兼容接口
  - 不扩 ISA、不扩 syscall 范围、不新增 RAW 函数恢复

## 后续观察点

- 继续把共享内部契约固定在 `program/`，避免 CLI / workbench / server / simulator 再次各自分叉维护输入语义
- 逐步把 `cmd/main/main.mbt`、`workbench/workbench.mbt` 和 `analysis/dataflow.mbt` 拆成“编排层 + 子模块”
- 用 capability matrix 持续对齐 decode / analyze / execute / workbench 的真实支持范围
- 继续跟踪在线 RAW 与 ELF 切换时的交互细节和错误文案
- 只在确有需求时再评估 `/api/snapshot`、`/api/stream` 的 RAW 兼容方案
