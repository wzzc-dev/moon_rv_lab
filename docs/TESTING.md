# Testing

当前测试与回归分为三层：

1. 快速 Smoke 回归：PR 主门禁，追求快而稳定。
2. 扩展回归：Linux 第二层主回归，覆盖更多包测试、样例链路和关键语义断言。
3. 平台补充校验：Windows/MSVC 原生补充验证，不替代 Linux 主线。

## 快速 Smoke 回归

快速 smoke 回归对应 workflow `.github/workflows/stable-smoke.yml`。
它继续作为当前最轻量、最稳定的 PR 主门禁。

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
```

预期结果：

- `cmd/main`、`workbench`、`cmd/server` 的 native 测试通过。
- `out/simple.elf` 可以由 `example/simple.s` 稳定生成，且默认产物是 RV64 ELF。
- `out/simple.run.json` 中的 `xlen` 固定为 `64`。
- `run out/simple.elf --max-steps 20` 能在给定步数内完成。
- `out/workbench.html` 成功生成。

Windows 本地说明：

- `moon test cmd/server --target native` 依赖 `moonbitlang/async` 的 MSVC 工具链支持。
- 在 Windows 上请优先使用 Visual Studio Developer Command Prompt，或先执行 `vcvars64.bat` 再跑该命令。

## 扩展回归

扩展回归对应 workflow `.github/workflows/extended-regression.yml`，以及仓库根目录脚本：

```bash
scripts/run_extended_regression.sh
```

这层回归仍然是自动门禁，但比 smoke 更重，目标是把“推荐定期执行”的检查转成真正可执行的第二层基线。

### 本地运行

```bash
chmod +x scripts/run_extended_regression.sh
scripts/run_extended_regression.sh
```

脚本会使用 `out/extended_regression/` 作为产物目录，不覆盖已有 `out/workbench.html`。

### 覆盖内容

包测试：

```bash
~/.moon/bin/moon update
~/.moon/bin/moon test analysis
~/.moon/bin/moon test decode
~/.moon/bin/moon test format
~/.moon/bin/moon test simulator --target native
~/.moon/bin/moon test cmd/main --target native
~/.moon/bin/moon test workbench --target native
```

样例驱动回归：

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/extended_regression/simple.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/simple.elf --format json > out/extended_regression/simple.run.json
~/.moon/bin/moon run cmd/main -- workbench out/extended_regression/simple.elf -o out/extended_regression/simple.workbench.html

~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/extended_regression/simple32.elf --xlen 32
~/.moon/bin/moon run cmd/main -- run out/extended_regression/simple32.elf --format json > out/extended_regression/simple32.run.json
~/.moon/bin/moon run cmd/main -- workbench out/extended_regression/simple32.elf -o out/extended_regression/simple32.workbench.html

~/.moon/bin/moon run cmd/main -- asm example/branch_loop.s -o out/extended_regression/branch_loop.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/branch_loop.elf --max-steps 20 --format json > out/extended_regression/branch_loop.run.json

~/.moon/bin/moon run cmd/main -- asm example/memory_roundtrip.s -o out/extended_regression/memory_roundtrip.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/memory_roundtrip.elf --trace out/extended_regression/memory_roundtrip.trace.json --format json > out/extended_regression/memory_roundtrip.run.json

~/.moon/bin/moon run cmd/main -- asm example/call_chain.s -o out/extended_regression/call_chain.elf
~/.moon/bin/moon run cmd/main -- workbench out/extended_regression/call_chain.elf -o out/extended_regression/call_chain.workbench.html

~/.moon/bin/moon run cmd/main -- asm example/print_42.s -o out/extended_regression/print_42.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/print_42.elf --trace out/extended_regression/print_42.trace.json --format json > out/extended_regression/print_42.run.json

~/.moon/bin/moon run cmd/main -- asm example/file_open_read_close.s -o out/extended_regression/file_open_read_close.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/file_open_read_close.elf --trace out/extended_regression/file_open_read_close.trace.json --format json > out/extended_regression/file_open_read_close.run.json

~/.moon/bin/moon run cmd/main -- asm example/file_lseek_read.s -o out/extended_regression/file_lseek_read.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/file_lseek_read.elf --trace out/extended_regression/file_lseek_read.trace.json --format json > out/extended_regression/file_lseek_read.run.json

~/.moon/bin/moon run cmd/main -- asm example/file_fstat_close.s -o out/extended_regression/file_fstat_close.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/file_fstat_close.elf --trace out/extended_regression/file_fstat_close.trace.json --format json > out/extended_regression/file_fstat_close.run.json

~/.moon/bin/moon run cmd/main -- asm example/sys_brk_ioctl.s -o out/extended_regression/sys_brk_ioctl.elf
~/.moon/bin/moon run cmd/main -- run out/extended_regression/sys_brk_ioctl.elf --trace out/extended_regression/sys_brk_ioctl.trace.json --format json > out/extended_regression/sys_brk_ioctl.run.json
```

### 关键断言

扩展回归不再只验证“命令能跑完”，还会检查以下字段是否稳定：

- `run --format json` 中的 `xlen`
- `entry` / `initial_pc` / `stop_reason`
- trace JSON 中的 `memory_writes`
- syscall 样例中的 `openat/read/write/lseek/fstat/brk/ioctl`
- 离线 workbench HTML 中嵌入的 `xlen` 与 runtime `stop_reason`
- RV32 与 RV64 元数据在 CLI / workbench 之间的一致性

## Windows MSVC 补充校验

Windows 原生补充校验对应 workflow `.github/workflows/windows-msvc-native.yml`。
它的目标是验证 `cmd/server` 的 MSVC 原生测试链路，同时保留一条最小 CLI smoke。

GitHub Actions 中的命令顺序：

```cmd
moon update
moon test cmd/server --target native
moon test cmd/main --target native
moon run cmd/main -- asm example/simple.s -o out/simple.elf
moon run cmd/main -- run out/simple.elf --max-steps 20
```

Windows 本地执行要求：

- 优先使用 Visual Studio Developer Command Prompt for VS 2022。
- 如果当前终端不是该环境，先执行 `vcvars64.bat`，再运行上面的命令。
- 该补充校验只用于确认 MSVC 原生编译链路可用，不改变 Linux 主门禁与扩展回归的优先级。

## 额外建议检查

下面这些检查仍然建议定期执行，但当前不作为 PR 自动门禁：

### 接口与格式

```bash
~/.moon/bin/moon info
~/.moon/bin/moon fmt
```

### 在线 Workbench 手工验收

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

检查项：

1. 打开 `http://127.0.0.1:18080/`
2. 点击 `Open Online Workbench`
3. 打开 `http://127.0.0.1:18080/workbench?file=out/simple.elf`
4. 检查 `Reset / Prev / Next / Play`
5. 检查寄存器、Trace、Memory Writes、Syscalls/Output 联动
6. 切换 `?file=` 后确认页面重载并同步更新 URL
7. 刷新后确认 pane 尺寸、tab、过滤器和 `Follow PC` 状态恢复

## RV32 兼容说明

- 快速 smoke 继续以 RV64 `out/simple.elf` 为主基线。
- 扩展回归会额外验证显式 `--xlen 32` 生成的 RV32 ELF。
- `cmd/server`、`workbench` 和 `run` 都应接受这类显式生成的 RV32 ELF。

## 当前仍不作为门禁的检查

在本轮正确性基线补强完成后，以下项仍不作为自动门禁：

- `moon test` 默认目标的全量回归
- `simulator` 的 `wasm-gc` 全量白盒回归
- 引入外部 oracle 工具链，例如 `QEMU`、`Spike`、`objdump`
- 将 `/api/stream` 重新作为在线 workbench 主数据源
