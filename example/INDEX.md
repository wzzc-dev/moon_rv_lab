# Example Index

本目录提供一组用于 CLI、trace、离线 workbench 和在线 `/workbench` 演示的最小样例。

## 使用约定

- 汇编源码默认先转 ELF，再交给 `run` 或 `workbench`。
- 推荐把临时产物写到 `out/`，避免把生成物混入样例目录。
- 默认命令统一使用 `~/.moon/bin/moon ...`。

## 基础执行样例

| 文件 | 用途 | 推荐命令 | 观察点 |
| --- | --- | --- | --- |
| `simple.s` | 算术/逻辑/移位/LUI | `~/.moon/bin/moon run cmd/main -- run example/simple.elf --max-steps 20` | `a0/a1/a2/t0` 最终值、`ebreak` 停止原因 |
| `branch_loop.s` | 分支与循环 | `asm example/branch_loop.s -> run out/branch_loop.elf` | `a0` 在循环里累加，`bne` 形成回边 |
| `memory_roundtrip.s` | 栈访存 | `asm example/memory_roundtrip.s -> run --trace out/memory_roundtrip.elf` | `sw/lw` 对应的寄存器和内存写入 |
| `call_chain.s` | 函数调用与返回 | `asm example/call_chain.s -> workbench out/call_chain.elf` | `jal/jalr` 与返回地址流转 |

## Syscall 样例

| 文件 | 覆盖 syscall | 推荐命令 | 观察点 |
| --- | --- | --- | --- |
| `print_42.s` | `write`, `exit` | `asm example/print_42.s -> run out/print_42.elf` | stdout 输出 `42`，trace 中出现 `write/exit` |
| `file_open_read_close.s` | `openat`, `read`, `write`, `close`, `exit` | `asm example/file_open_read_close.s -> run --trace out/file_open_read_close.elf` | 从 `example/io.txt` 读取并写到 stdout |
| `file_lseek_read.s` | `openat`, `lseek`, `read`, `write`, `close`, `exit` | `asm example/file_lseek_read.s -> run --trace out/file_lseek_read.elf` | `lseek` 后重新读取得到偏移后的内容 |
| `file_fstat_close.s` | `openat`, `fstat`, `close`, `exit` | `asm example/file_fstat_close.s -> workbench out/file_fstat_close.elf` | `Trace`/`Memory Writes` 中出现 128 字节 stat 缓冲区写入 |
| `sys_brk_ioctl.s` | `brk`, `ioctl`, `exit` | `asm example/sys_brk_ioctl.s -> run --trace out/sys_brk_ioctl.elf` | trace 中能看到 `brk` 查询/设置和 `ioctl` 返回值 |

## 文件 I/O 演示样例

- `file_open_read_close.s`: 最短文件读取闭环。
- `file_lseek_read.s`: 演示偏移读和重复读取。
- `file_fstat_close.s`: 演示 metadata 写回内存，适合在 workbench 里看 `Memory Writes`。
- `io.txt`: 供上述样例读取的宿主文件。

## 推荐演示顺序

1. `example/simple.elf`
   命令: `~/.moon/bin/moon run cmd/main -- run example/simple.elf --max-steps 20`
   作用: 先展示执行引擎、寄存器变化和 stop reason。
2. `example/simple.elf`
   命令: `~/.moon/bin/moon run cmd/main -- workbench example/simple.elf -o out/workbench.html`
   作用: 展示离线 Godbolt 风格工作台。
3. `example/file_open_read_close.s`
   命令: `~/.moon/bin/moon run cmd/main -- asm example/file_open_read_close.s -o out/file_open_read_close.elf`
   作用: 进入 syscall + 文件 I/O 演示。
4. 在线工作台
   命令: `~/.moon/bin/moon run cmd/server --target native -- --file example/simple.elf --port 18080`
   作用: 浏览器中展示 `/workbench`、文件切换、单步和播放。
