# Testing

## 自动化回归

阶段五收尾默认先跑以下命令:

```bash
~/.moon/bin/moon info
~/.moon/bin/moon fmt
~/.moon/bin/moon test
```

当前回归重点:

- `cmd/main` 命令级白盒测试
- `simulator` 指令与 syscall 测试
- `workbench` 离线/在线 HTML 与 payload 测试
- `cmd/server` 路由 HTML 测试

## 命令级 smoke check

```bash
~/.moon/bin/moon run cmd/main -- asm example/simple.s -o out/simple.elf
~/.moon/bin/moon run cmd/main -- run out/simple.elf --max-steps 20
~/.moon/bin/moon run cmd/main -- run out/simple.elf --break 0x10010
~/.moon/bin/moon run cmd/main -- run out/simple.elf --trace out/trace.json
~/.moon/bin/moon run cmd/main -- workbench out/simple.elf -o out/workbench.html
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

预期结果:

- `run` 输出包含 `Execution Summary`
- `--break` 在 `0x10010` 前停止
- `--trace` 生成结构化 JSON 文件
- `workbench` 生成可离线打开的单文件 HTML
- `cmd/server` 提供 `/`、`/workbench`、`/api/health`、`/api/snapshot`、`/api/stream`

## 样例驱动回归

### 基础执行

```bash
~/.moon/bin/moon run cmd/main -- asm example/branch_loop.s -o out/branch_loop.elf
~/.moon/bin/moon run cmd/main -- run out/branch_loop.elf --max-steps 20

~/.moon/bin/moon run cmd/main -- asm example/memory_roundtrip.s -o out/memory_roundtrip.elf
~/.moon/bin/moon run cmd/main -- run out/memory_roundtrip.elf --trace out/memory_roundtrip.trace.json

~/.moon/bin/moon run cmd/main -- asm example/call_chain.s -o out/call_chain.elf
~/.moon/bin/moon run cmd/main -- workbench out/call_chain.elf -o out/call_chain.html
```

### Syscall 与文件 I/O

```bash
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

覆盖的 syscall:

- `exit`
- `read`
- `write`
- `openat`
- `close`
- `lseek`
- `fstat`
- `brk`
- `ioctl`

## 在线 Workbench 验收

### 启动

```bash
~/.moon/bin/moon run cmd/server --target native -- --file out/simple.elf --port 18080
```

### 浏览器检查

1. 打开 `http://127.0.0.1:18080/`
2. 点击 `Open Online Workbench`
3. 打开 `http://127.0.0.1:18080/workbench?file=out/simple.elf`
4. 检查 `Reset / Prev / Next / Play`
5. 检查寄存器、Trace、Memory Writes、Syscalls/Output 联动
6. 切换 `?file=` 后确认页面重新加载并同步更新 URL
7. 刷新页面后确认 pane 尺寸、tab、过滤器和 `Follow PC` 状态恢复

## 验收对照

### 已完成

- RV64I 执行主干
- `run` CLI、断点与 trace JSON
- 8 项 syscall
- 离线 `workbench`
- 在线 `/workbench`
- `cmd/main` 命令级回归
- `example/` 样例索引和文件 I/O 样例
- 文档同步到当前仓库路径和命令

### 当前不做

- 扩 ISA 到 `M/C/CSR/privileged`
- 引入 JIT 或复杂 server 会话状态
- 把 `/api/stream` 改成在线 workbench 主数据源
- 大型真实程序样本集
