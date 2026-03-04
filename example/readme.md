# 简介

```shell
riscv64-unknown-elf-gcc -S -march=rv64gc -mabi=lp64d -O3 hello.c -o hello.s
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d hello.s -o a.out
cp ../_build/native/debug/build/cmd/main/main.exe rvkit
./rvkit disasm a.out >> output.txt
```

```shell
# 分析一个 RISC-V 固件
rvkit info firmware.bin        # 查看文件类型和结构
rvkit symbols firmware.bin     # 查看有哪些函数
rvkit cfg firmware.bin -n main -o main.dot  # 生成 main 函数的控制流图
rvkit disasm firmware.bin      # 反汇编查看实际指令
```

## 汇编器演示

将 RISC-V 汇编代码汇编为可执行文件：

```shell
# 构建 rvkit
cd /Volumes/Data/Code/moon/scc/riscv_analyzer
moon build --target native

# 汇编为 ELF 可执行文件（默认格式）
./_build/native/debug/build/cmd/main/main.exe asm example/simple.s -o example/simple.elf

# 汇编为十六进制格式
./_build/native/debug/build/cmd/main/main.exe asm example/simple.s -o example/simple.hex --format hex

# 汇编为原始二进制
./_build/native/debug/build/cmd/main/main.exe asm example/simple.s -o example/simple.bin --format raw

# 指定基地址
./_build/native/debug/build/cmd/main/main.exe asm example/simple.s -o example/simple.elf --base 0x80000000
```

## 使用 libriscv 运行二进制

[libriscv](https://github.com/libriscv/libriscv) 是一个高性能 RISC-V 模拟器，可以用来运行 rvkit 生成的二进制文件。

### 构建 libriscv

```shell
# 克隆 libriscv
git clone --depth 1 https://github.com/libriscv/libriscv.git /tmp/libriscv

# 构建
cd /tmp/libriscv/emulator
./build.sh --defaults
```

### 构建运行器

```shell
cd /Volumes/Data/Code/moon/scc/riscv_analyzer/tools
mkdir -p build && cd build
cmake .. && make -j4
```

### 运行测试

```shell
# 生成二进制
./_build/native/debug/build/cmd/main/main.exe asm example/simple.s -o example/simple.bin --format raw

# 使用 libriscv 运行
./tools/build/rvrunner example/simple.bin 0x10000
```

### 运行结果示例

```
Loaded 44 bytes from example/simple.bin
Entry point: 0x10000
Running...
---
---
Machine stopped.
Instructions executed: 11

Final registers:
  x10 (a0): 0x0000002a   # 42 (初始值)
  x11 (a1): 0x00000034   # 52 (42 + 10)
  x12 (a2): 0x0000005e   # 94 (42 + 52)
  x13 (a3): 0x0000000a   # 10 (52 - 42)
  x14 (a4): 0x0000002a   # 42 (42 & 0xFF)
  x15 (a5): 0x0000012a   # 298 (42 | 0x100)
  x16 (a6): 0x000000d5   # 213 (42 ^ 0xFF)
  x17 (a7): 0x000000a8   # 168 (42 << 2)
  x8  (s0): 0x00000015   # 21 (42 >> 1)
  x5  (t0): 0x12345000   # lui t0, 0x12345
```
