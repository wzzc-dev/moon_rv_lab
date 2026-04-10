# Testing

如果你需要按“clean repo -> CLI -> 离线 workbench -> 在线演示”的顺序复现一遍最终验收，请直接使用 `docs/RUNBOOK.md`；本页主要负责自动化回归和 smoke 门禁。

## 稳定 Smoke 回归

稳定 smoke 回归是当前发布门禁，对应 workflow 为 `.github/workflows/stable-smoke.yml`。
Linux smoke 继续作为主门禁，并同时覆盖默认 ELF 路径与 RAW 主路径；Windows/MSVC 仅作为补充校验，对应 `.github/workflows/windows-msvc-native.yml`，不替代现有 Linux 主线。

共享内部契约新增了 `program/` 包，建议把它和 `simulator` 一起视为基础设施门禁：前者负责统一 ELF / RAW 装载与 request 语义，后者负责统一执行入口与 stop reason。

如果本地没有 `out/` 目录，先创建一次：

```bash
mkdir -p out
```

随后执行这组固定命令：

```bash
~/.moon/bin/moon update
~/.moon/bin/moon test cmd/main --target native
~/.moon/bin/moon test workbench --target native
~/.moon/bin/moon test cmd/server --target native
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf
~/.moon/bin/moon run cmd/main -- run out/simple.elf --format json > out/simple.run.json
grep '"xlen":64' out/simple.run.json
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw
~/.moon/bin/moon run cmd/main -- info out/simple.raw --raw --base 0x10000 --xlen 64 --format json > out/simple.raw.info.json
grep '"input_format":"raw"' out/simple.raw.info.json
grep '"xlen":64' out/simple.raw.info.json
~/.moon/bin/moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --format json > out/simple.raw.run.json
grep '"xlen":64' out/simple.raw.run.json
~/.moon/bin/moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20
~/.moon/bin/moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html
# 另开一个终端，或后台启动在线 server
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080 > out/server.log 2>&1 &
curl -sS "http://127.0.0.1:18080/api/workbench/overview?file=out/simple.raw&raw=1&base=0x10000&xlen=64&max_events=20" > out/simple.raw.overview.api.json
grep '"input_format":"raw"' out/simple.raw.overview.api.json
grep '"file_class":"RAW"' out/simple.raw.overview.api.json
curl -sS "http://127.0.0.1:18080/api/workbench/function?file=out/simple.raw&raw=1&base=0x10000&xlen=64&addr=entry" > out/simple.raw.function.api.json
grep '"name":"entry"' out/simple.raw.function.api.json
```

预期结果：

- `cmd/main`、`workbench`、`cmd/server` 的 native 测试通过。
- `out/simple.elf` 可以由 `example/simple.s` 稳定生成，且默认产物是 RV64 ELF。
- `out/simple.run.json` 中的 `xlen` 固定为 `64`。
- `run out/simple.elf --max-steps 20` 能在给定步数内完成。
- `out/workbench.html` 成功生成。
- `out/simple.raw` 可以由同一份源码稳定生成，且 RAW 默认验收参数固定为 `base=0x10000`、`xlen=64`。
- `out/simple.raw.info.json` 与 `out/simple.raw.run.json` 都明确记录 RAW 输入和 `xlen=64`。
- `run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20` 能在给定步数内完成。
- `out/simple_raw.html` 成功生成。
- 在线 `/api/workbench/overview` 与 `/api/workbench/function` 的 RAW 请求返回稳定结果，且 `entry` synthetic function 不回退。

Windows 本地说明：

- `moon test cmd/server --target native` 依赖 `moonbitlang/async` 的 MSVC 工具链支持。
- 在 Windows 上请优先使用 Visual Studio Developer Command Prompt，或先执行 `vcvars64.bat` 再跑该命令。

## Windows MSVC 补充校验

Windows 原生补充校验对应 workflow `.github/workflows/windows-msvc-native.yml`。
它的目标是验证 `cmd/server` 的 MSVC 原生测试链路，并补一条覆盖 ELF 与 RAW 的 CLI smoke；Linux `.github/workflows/stable-smoke.yml` 仍然是主门禁。

GitHub Actions 中的命令顺序：

```cmd
moon update
moon test cmd/server --target native
moon test cmd/main --target native
moon run cmd/main -- asm example/simple.s -o out/simple.elf
moon run cmd/main -- run out/simple.elf --max-steps 20
moon run cmd/main -- asm example/simple.s -o out/simple.raw --format raw
moon run cmd/main -- info out/simple.raw --raw --base 0x10000 --xlen 64
moon run cmd/main -- run out/simple.raw --raw --base 0x10000 --xlen 64 --max-steps 20
moon run cmd/main -- workbench out/simple.raw --raw --base 0x10000 --xlen 64 -o out/simple_raw.html
```

Windows 本地执行要求：

- 优先使用 Visual Studio Developer Command Prompt for VS 2022。
- 如果当前终端不是该环境，先执行 `vcvars64.bat`，再运行上面的命令。
- 该补充校验主要用于确认 MSVC 原生编译链路可用，以及 RAW 离线路径不会在 Windows 上回退，不改变 Linux smoke 的发布优先级。

## 重型 / 完整回归

下面这些检查仍然建议定期执行，但当前不作为稳定发布门禁：

### 接口与格式

```bash
~/.moon/bin/moon info
~/.moon/bin/moon fmt
```

### Simulator 回归

```bash
~/.moon/bin/moon test simulator --target native
~/.moon/bin/moon test program --target native
```

`simulator` 与 `program` 当前都以 `native` 回归为标准命令；默认 `wasm-gc` 全量通过不属于本轮稳定性目标。

### 样例驱动回归

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple32.elf --xlen 32
~/.moon/bin/moon run cmd/main -- run out/simple32.elf --max-steps 20

~/.moon/bin/moon run cmd/main -- asm example/branch_loop.s -o out/branch_loop.elf
~/.moon/bin/moon run cmd/main -- run out/branch_loop.elf --max-steps 20

~/.moon/bin/moon run cmd/main -- asm example/memory_roundtrip.s -o out/memory_roundtrip.elf
~/.moon/bin/moon run cmd/main -- run out/memory_roundtrip.elf --trace out/memory_roundtrip.trace.json

~/.moon/bin/moon run cmd/main -- asm example/call_chain.s -o out/call_chain.elf
~/.moon/bin/moon run cmd/main -- workbench out/call_chain.elf -o out/call_chain.html

~/.moon/bin/moon run cmd/main -- asm example/print_42.s -o out/print_42.elf
~/.moon/bin/moon run cmd/main -- run out/print_42.elf --trace out/print_42.trace.json

~/.moon/bin/moon run cmd/main -- asm example/file_open_read_close.s -o out/file_open_read_close.elf
~/.moon/bin/moon run cmd/main -- run out/file_open_read_close.elf --trace out/file_open_read_close.trace.json

~/.moon/bin/moon run cmd/main -- asm example/file_lseek_read.s -o out/file_lseek_read.elf
~/.moon/bin/moon run cmd/main -- run out/file_lseek_read.elf --trace out/file_lseek_read.trace.json

~/.moon/bin/moon run cmd/main -- asm example/file_fstat_close.s -o out/file_fstat_close.elf
~/.moon/bin/moon run cmd/main -- run out/file_fstat_close.elf --trace out/file_fstat_close.trace.json

~/.moon/bin/moon run cmd/main -- asm example/sys_brk_ioctl.s -o out/sys_brk_ioctl.elf
~/.moon/bin/moon run cmd/main -- run out/sys_brk_ioctl.elf --trace out/sys_brk_ioctl.trace.json --format json
```

### 在线 Workbench 手工验收

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

当前在线 workbench 首屏依赖 `/api/workbench/overview`，函数切片依赖 `/api/workbench/function`；`/api/snapshot` 与 `/api/stream` 仅保留兼容定位。

检查项：

1. 打开 `http://127.0.0.1:18080/`
2. 点击 `Open Online Workbench`
3. 打开 `http://127.0.0.1:18080/workbench?file=out/simple.elf`
4. 检查 `Reset / Prev / Next / Play`
5. 检查寄存器、Trace、Memory Writes、Syscalls/Output 联动
6. 切换 `?file=` 后确认页面重载并同步更新 URL
7. 刷新后确认 pane 尺寸、tab、过滤器和 `Follow PC` 状态恢复
8. 打开 `http://127.0.0.1:18080/workbench?file=out/simple.raw&raw=1&base=0x10000&xlen=64`
9. 检查函数列表出现 `entry`，且 `Load` 后 URL 继续保留 `raw/base/xlen`
10. 检查切回 `ELF` 后 RAW 专属字段隐藏，普通加载路径不受污染

## RV32 兼容说明

- 默认 smoke 继续以 RV64 `out/simple.elf` 为主基线。
- 如需验证兼容入口，请显式使用 `--xlen 32` 生成 `out/simple32.elf`。
- `cmd/server`、`workbench` 和 `run` 都应接受这类显式生成的 RV32 ELF。

## 当前不作为门禁的检查

在本轮稳定性收敛完成前，以下项不作为发布门禁：

- `moon test` 默认目标的全量回归
- `simulator` 的 `wasm-gc` 全量白盒回归
- 将 `/api/stream` 重新作为在线 workbench 主数据源
