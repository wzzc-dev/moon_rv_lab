# RISC-V Toolkit (rvkit)

一个用 [MoonBit](https://moonbitlang.com) 编写的 RISC-V 二进制分析工具包，提供指令编码/解码、汇编/反汇编、控制流分析和 ELF 文件解析功能。

## 功能特性

- **指令解码**: 完整支持多种 RISC-V 指令集扩展：
  - RV32I/RV64I: 基础整数指令集
  - RV32M/RV64M: 整数乘除法
  - RV32A/RV64A: 原子操作
  - RV32F/RV64F: 单精度浮点
  - RV32D/RV64D: 双精度浮点
  - RV32C/RV64C: 压缩指令 (16位)
  - RVV: 向量扩展
  - Zba/Zbb/Zbc/Zbs: 位操作扩展
  - Zicsr: CSR 指令

- **汇编器**: 两遍扫描汇编器，支持标签、符号和伪指令
- **反汇编**: 将解码后的指令转换为可读的汇编代码
- **反编译**: 将机器码转换为结构化伪代码，支持寄存器跟踪和字符串恢复
- **控制流分析**: 从二进制代码构建控制流图 (CFG)
- **调用图分析**: 分析函数调用关系
- **数据流分析**: 定义-使用链和活跃性分析
- **ELF 解析**: 解析 ELF32/ELF64 可执行文件
- **DWARF 调试信息**: 解析 DWARF 调试信息

---

## 快速开始

### 安装依赖

确保已安装 [MoonBit](https://moonbitlang.com/download/) 工具链。

### 构建项目

```bash
# 克隆项目
git clone https://github.com/wzzc-dev/rvkit.git
cd rvkit

# 构建项目
moon build

# 运行测试
moon test

# 构建 CLI 工具
moon build --target native
```

### 使用 CLI 工具

```bash
# 运行演示
./_build/native/cli/main/main demo

# 反汇编 ELF 文件
./_build/native/cli/main/main disasm example/hello.elf

# 解码单条指令
./_build/native/cli/main/main hex 0x007302B3
# 输出: add t0, t1, t2
```

---

## 作为库使用

在 `moon.mod.json` 中添加依赖：

```json
{
  "deps": {
    "wzzc-dev/rvkit": "0.1.0"
  }
}
```

### 指令解码

```moonbit
import "wzzc-dev/rvkit/decode" @decode

// 解码 32 位指令
let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
// inst = ADD(t0, t1, t2)

// 解码 16 位压缩指令
let @decode.DecodeResult(c_inst) = @decode.decode_compressed(0x4000U)
// c_inst = C_LW(...)

// 检查是否为压缩指令
let is_compressed = @decode.is_compressed(0x4000U)  // true
```

### 指令编码

```moonbit
import "wzzc-dev/rvkit/encode" @encode
import "wzzc-dev/rvkit/decode" @decode

// 编码指令为二进制
let @encode.EncodeResult(code, is_compressed) = @encode.encode(@decode.Instruction::ADD(5, 6, 7))
// code = 0x007302B3U, is_compressed = false

// 编码为字节数组
let bytes = @encode.encode_to_bytes(@decode.Instruction::ADD(5, 6, 7))
// bytes = [0xB3, 0x02, 0x73, 0x00]
```

### 反汇编

```moonbit
import "wzzc-dev/rvkit/decode" @decode
import "wzzc-dev/rvkit/disasm" @disasm

let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)

// 反汇编为文本
let asm = @disasm.disassemble(inst)
// asm = "add t0, t1, t2"

// 带地址的反汇编
let asm_with_addr = @disasm.disassemble_with_addr(inst, 0x8000U)
// asm_with_addr = "0x00008000: add t0, t1, t2"
```

### 汇编器

```moonbit
import "wzzc-dev/rvkit/asm" @asm

// 简单汇编
let instructions = @asm.assemble("add t0, t1, t2\nli a0, 42")

// 汇编为字节数组
let bytes = @asm.assemble_to_bytes("add t0, t1, t2")

// 带符号表的汇编（支持标签）
let result = @asm.assemble_with_symbols("""
start:
    li t0, 42
    mv a0, t0
loop:
    addi t0, t0, -1
    bnez t0, loop
    ret
""", 0x8000U)

// result.instructions  - 汇编后的指令
// result.symbols       - 符号表
```

### 解析 ELF 文件

```moonbit
import "wzzc-dev/rvkit/format" @format

let elf = @format.parse_elf(bytes).?

// 获取基本信息
let entry = elf.entry_point()
let is_riscv = elf.is_riscv()
let code_sections = elf.get_code_sections()

// 获取函数符号
let funcs = elf.get_function_symbols()
for sym in funcs {
  println("Function: \{sym.name} at 0x\{sym.value}")
}
```

### 控制流分析

```moonbit
import "wzzc-dev/rvkit/analysis" @analysis

// 分析代码并构建 CFG
let cfg = @analysis.analyze_code(code_bytes, start_addr)

// 打印基本块
for block in cfg.blocks {
  println("Block: 0x\{block.start_addr} - 0x\{block.end_addr}")
}

// 导出为 DOT 格式（用于 Graphviz）
let dot = @analysis.cfg_to_dot(cfg, "main")
```

### 调用图分析

```moonbit
import "wzzc-dev/rvkit/analysis" @analysis

let instructions = @analysis.decode_instructions(bytes, 0x8000U)
let cfg = @analysis.build_cfg(instructions, 0x8000U)
let cg = @analysis.build_call_graph(instructions, cfg)

// 获取从入口可达的函数
let reachable = @analysis.reachable_functions(cg)

// 导出为 DOT 格式
let dot = @analysis.callgraph_to_dot(cg, "callgraph")
```

---

## CLI 命令参考

```bash
rvkit <command> [options]

命令:
  disasm    反汇编二进制文件
  info      显示 ELF 文件信息
  symbols   列出符号表
  cfg       生成控制流图
  callgraph 生成调用图
  hex       解码十六进制指令
  analyze   综合分析
  decompile 反编译生成伪代码
  asm       汇编源文件
  demo      运行演示
  help      显示帮助
  version   显示版本

全局选项:
  --format <text|json|dot>  输出格式 (默认: text)
  --output <file>           输出文件 (默认: stdout)
```

### disasm - 反汇编

```bash
# 反汇编 ELF 文件
rvkit disasm program.elf

# 反汇编原始二进制（指定基址）
rvkit disasm firmware.bin --raw --base 0x8000

# JSON 格式输出
rvkit disasm program.elf --format json
```

### info - ELF 信息

```bash
rvkit info program.elf
```

### symbols - 符号表

```bash
# 显示函数符号
rvkit symbols program.elf

# 显示所有符号（包括局部符号）
rvkit symbols program.elf --all
```

### cfg - 控制流图

```bash
# 为指定函数生成 CFG
rvkit cfg program.elf --function main > cfg.dot

# 用 Graphviz 可视化
dot -Tpng cfg.dot -o cfg.png
```

### callgraph - 调用图

```bash
# 生成调用图
rvkit callgraph program.elf > callgraph.dot

# 可视化
dot -Tpng callgraph.dot -o callgraph.png
```

### decompile - 反编译

```bash
# 反编译指定函数（控制流摘要）
rvkit decompile program.elf --function main

# 生成伪代码
rvkit decompile program.elf --function main --code
```

### hex - 解码指令

```bash
# 解码单条指令
rvkit hex 0x007302B3
# 输出: add t0, t1, t2
```

### analyze - 综合分析

```bash
# 综合分析
rvkit analyze program.elf

# 详细输出
rvkit analyze program.elf --detailed
```

### asm - 汇编

```bash
# 汇编为 ELF 文件
rvkit asm input.s -o output.elf

# 汇编为原始二进制
rvkit asm input.s -o output.bin --format raw

# 指定基地址
rvkit asm input.s -o output.elf --base 0x8000
```

---

## 项目结构

```
riscv_analyzer/
├── moon.mod.json      # 项目配置
├── rvkit.mbt          # 主包 API 重导出
├── decode/            # RISC-V 指令解码
│   ├── decoder.mbt    # 解码逻辑
│   └── types.mbt      # 指令类型定义
├── encode/            # 指令编码
│   └── encoder.mbt    # 编码逻辑
├── disasm/            # 反汇编引擎
│   └── disasm.mbt     # 汇编文本生成
├── asm/               # 汇编器
│   ├── assembler.mbt  # 两遍扫描汇编器
│   ├── parser.mbt     # 语法解析
│   └── lexer.mbt      # 词法分析
├── analysis/          # 控制流和数据流分析
│   ├── cfg.mbt        # CFG 构建
│   ├── dataflow.mbt   # 数据流分析
│   └── decompile.mbt  # 反编译器
├── format/            # 文件格式解析
│   ├── elf.mbt        # ELF 解析器
│   ├── elf_defs.mbt   # ELF 格式常量
│   ├── dwarf.mbt      # DWARF 调试信息
│   └── raw.mbt        # 原始二进制处理
├── cmd/main/          # CLI 工具
│   └── main.mbt       # 命令行入口
├── example/           # 示例文件
│   ├── hello.c        # C 源码示例
│   └── *.s            # 汇编示例
└── riscv_rt/          # RISC-V 运行时库
```

---

## 开发

```bash
# 构建项目
moon build

# 运行测试
moon test

# 更新测试快照
moon test --update

# 更新接口文件并格式化代码
moon info && moon fmt

# 生成覆盖率报告
moon coverage analyze > uncovered.log
```

---

## 示例：完整分析流程

```bash
# 1. 编译 RISC-V 程序
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d -nostdlib \
    -static example/hello.c -o hello.elf

# 2. 查看 ELF 信息
rvkit info hello.elf

# 3. 反汇编
rvkit disasm hello.elf

# 4. 生成调用图
rvkit callgraph hello.elf > callgraph.dot
dot -Tpng callgraph.dot -o callgraph.png

# 5. 为 main 函数生成 CFG
rvkit cfg hello.elf --function main > main.dot
dot -Tpng main.dot -o main.png

# 6. 反编译 main 函数
rvkit decompile hello.elf --function main --code
```

---

## 支持的指令

### RV32I 基础指令集

| 类型 | 指令 |
|------|------|
| U-type | `LUI`, `AUIPC` |
| J-type | `JAL` |
| I-type | `JALR`, `LB`, `LH`, `LW`, `LBU`, `LHU`, `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| B-type | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| S-type | `SB`, `SH`, `SW` |
| R-type | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| System | `ECALL`, `EBREAK`, `FENCE`, `FENCE.I` |

### RV32M/RV64M 乘除法扩展

`MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`, `REM`, `REMU`

### RV32C/RV64C 压缩指令

| 类型 | 指令 |
|------|------|
| 加载 | `C.LW`, `C.LD`, `C.LWSP`, `C.LDSP` |
| 存储 | `C.SW`, `C.SD`, `C.SWSP`, `C.SDSP` |
| 算术 | `C.ADDI`, `C.ADDIW`, `C.LI`, `C.LUI`, `C.ADD`, `C.ADDW`, `C.ADDI16SP` |
| 位运算 | `C.ANDI`, `C.AND`, `C.OR`, `C.XOR`, `C.SUB`, `C.SUBW` |
| 移位 | `C.SLLI`, `C.SRLI`, `C.SRAI` |
| 分支 | `C.BEQZ`, `C.BNEZ` |
| 跳转 | `C.J`, `C.JAL`, `C.JR`, `C.JALR` |
| 其他 | `C.NOP`, `C.MV`, `C.EBREAK` |

---

## 许可证

Apache-2.0
