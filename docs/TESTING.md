# Testing

## 稳定 Smoke 回归

稳定 smoke 回归是当前发布门禁，对应 workflow 为 `.github/workflows/stable-smoke.yml`。
Linux smoke 继续作为主门禁；Windows/MSVC 仅作为补充校验，对应 `.github/workflows/windows-msvc-native.yml`，不替代现有 Linux 主线。

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

## Windows MSVC 补充校验

Windows 原生补充校验对应 workflow `.github/workflows/windows-msvc-native.yml`。
它的目标是验证 `cmd/server` 的 MSVC 原生测试链路，同时补一条最小 CLI smoke；Linux `.github/workflows/stable-smoke.yml` 仍然是主门禁。

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
- 该补充校验主要用于确认 MSVC 原生编译链路可用，不改变 Linux smoke 的发布优先级。

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
```

`simulator` 当前以 `native` 白盒回归为标准命令；默认 `wasm-gc` 全量通过不属于本轮稳定性目标。

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

检查项：

1. 打开 `http://127.0.0.1:18080/`
2. 点击 `Open Online Workbench`
3. 打开 `http://127.0.0.1:18080/workbench?file=out/simple.elf`
4. 检查 `Reset / Prev / Next / Play`
5. 检查寄存器、Trace、Memory Writes、Syscalls/Output 联动
6. 切换 `?file=` 后确认页面重载并同步更新 URL
7. 刷新后确认 pane 尺寸、tab、过滤器和 `Follow PC` 状态恢复

## RV32 兼容说明

- 默认 smoke 继续以 RV64 `out/simple.elf` 为主基线。
- 如需验证兼容入口，请显式使用 `--xlen 32` 生成 `out/simple32.elf`。
- `cmd/server`、`workbench` 和 `run` 都应接受这类显式生成的 RV32 ELF。

## 当前不作为门禁的检查

在本轮稳定性收敛完成前，以下项不作为发布门禁：

- `moon test` 默认目标的全量回归
- `simulator` 的 `wasm-gc` 全量白盒回归
- 将 `/api/stream` 重新作为在线 workbench 主数据源
