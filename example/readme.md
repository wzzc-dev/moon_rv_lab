# Example Readme

`example/` 保存答辩和回归使用的最小样例集，默认以源码 `.s` 为主，稳定演示入口保留 `simple.elf`。

## 快速开始

```bash
# 1. 组装一个样例
~/.moon/bin/moon run cmd/main -- asm example/branch_loop.s -o out/branch_loop.elf

# 2. 运行并查看 stop reason / registers
~/.moon/bin/moon run cmd/main -- run out/branch_loop.elf --max-steps 20

# 3. 导出 trace
~/.moon/bin/moon run cmd/main -- run out/branch_loop.elf --trace out/branch_loop.trace.json

# 4. 生成离线 workbench
~/.moon/bin/moon run cmd/main -- workbench out/branch_loop.elf -o out/branch_loop.html

# 5. 启动在线 workbench
~/.moon/bin/moon run cmd/server --target native -- --file example/simple.elf --port 18080
```

## 目录说明

- `simple.s` / `simple.elf`: 默认演示入口，适合 `run`、trace、在线工作台。
- `branch_loop.s`, `memory_roundtrip.s`, `call_chain.s`: 基础执行与控制流样例。
- `print_42.s`: 最短 syscall 闭环，覆盖 `write + exit`。
- `file_open_read_close.s`, `file_lseek_read.s`, `file_fstat_close.s`: 文件 I/O 样例。
- `sys_brk_ioctl.s`: `brk` 和 `ioctl` 行为观察样例。
- `io.txt`: 文件 I/O 样例依赖的宿主文件。

更完整的用途、命令和观察点见 [INDEX.md](INDEX.md)。
