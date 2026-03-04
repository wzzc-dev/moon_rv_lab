# RISC-V Binary Analyzer API 参考文档

## 项目概述

RISC-V Binary Analyzer 是一个用 MoonBit 语言编写的 RISC-V 二进制分析工具库，提供指令解码、反汇编、控制流分析和 ELF 文件解析功能。

**版本**: 0.1.0  
**许可证**: Apache-2.0  
**包名**: `wzzc-dev/rvkit`

---

## 模块架构

```
riscv_analyzer/
├── decode/          # RISC-V 指令解码器
│   ├── decoder.mbt  # 解码逻辑
│   └── types.mbt    # 指令类型定义
├── disasm/          # 反汇编引擎
│   └── disasm.mbt   # 汇编文本生成
├── analysis/        # 控制流与数据流分析
│   ├── cfg.mbt      # CFG 构建
│   └── dataflow.mbt # 数据流分析
├── format/          # 文件格式解析
│   ├── elf.mbt      # ELF 解析器
│   ├── elf_defs.mbt # ELF 常量定义
│   └── raw.mbt      # 原始二进制处理
└── cmd/main/        # 命令行工具
    └── main.mbt     # CLI 入口
```

### 模块依赖关系

```
cmd/main
    └── riscv_analyzer (主包)
            ├── decode (解码)
            ├── disasm (反汇编)
            ├── analysis (分析)
            │     └── decode
            └── format (格式)
```

---

## 安装

在 `moon.mod.json` 中添加依赖：

```json
{
  "deps": {
    "wzzc-dev/rvkit": "0.1.0"
  }
}
```

---

## 核心 API

### 1. 指令解码模块 (`decode`)

#### 基本解码函数

```moonbit
"wzzc-dev/rvkit/decode" @decode

/// 解码 32 位指令
pub fn decode(code : UInt) -> DecodeResult

/// 解码 16 位压缩指令
pub fn decode_compressed(code16 : UInt) -> DecodeResult

/// 判断是否为压缩指令
pub fn is_compressed(code : UInt) -> Bool

/// 获取指令长度 (16 或 32)
pub fn instruction_length(code : UInt) -> Int
```

#### DecodeResult 类型

```moonbit
pub struct DecodeResult(Instruction)

// 使用模式匹配
let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
```

#### 指令类别

```moonbit
pub enum InstructionCategory {
  Arithmetic  // 算术运算
  Logical     // 逻辑运算
  Compare     // 比较操作
  Branch      // 分支指令
  Jump        // 跳转指令
  Load        // 加载指令
  Store       // 存储指令
  System      // 系统指令
  Float       // 浮点指令
  Vector      // 向量指令
  Unknown     // 未知指令
}
```

#### 寄存器名称转换

```moonbit
/// 通用寄存器名称 (x0-x31)
pub fn reg_name(reg : UInt) -> String
// reg_name(0)  => "zero"
// reg_name(1)  => "ra"
// reg_name(2)  => "sp"
// reg_name(10) => "a0"

/// 浮点寄存器名称 (f0-f31)
pub fn freg_name(reg : UInt) -> String
// freg_name(0)  => "ft0"
// freg_name(10) => "fa0"

/// 向量寄存器名称 (v0-v31)
pub fn vreg_name(reg : UInt) -> String
// vreg_name(0) => "v0"
```

### 2. 反汇编模块 (`disasm`)

```moonbit
 "wzzc-dev/rvkit/disasm" @disasm

/// 将指令反汇编为汇编字符串
pub fn disassemble(inst : @decode.Instruction) -> String

/// 带地址的反汇编输出
pub fn disassemble_with_addr(inst : @decode.Instruction, addr : UInt) -> String
```

**示例：**

```moonbit
let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
let asm = @disasm.disassemble(inst)
// asm = "add t0, t1, t2"

let with_addr = @disasm.disassemble_with_addr(inst, 0x8000U)
// with_addr = "0x00008000: add t0, t1, t2"
```

### 3. ELF 格式模块 (`format`)

#### ELF 解析

```moonbit
 "wzzc-dev/rvkit/format" @format

/// 判断是否为 ELF 文件
pub fn is_elf(bytes : FixedArray[Byte]) -> Bool

/// 获取 ELF 类别 (32/64 位)
pub fn get_elf_class(bytes : FixedArray[Byte]) -> ElfClass

/// 解析 ELF 文件
pub fn parse_elf(bytes : FixedArray[Byte]) -> ElfFile?
```

#### ElfFile 结构

```moonbit
pub struct ElfFile {
  is_64bit : Bool
  header32 : Elf32Header?
  header64 : Elf64Header?
  sections32 : Array[Elf32SectionHeader]
  sections64 : Array[Elf64SectionHeader]
  programs32 : Array[Elf32ProgramHeader]
  programs64 : Array[Elf64ProgramHeader]
  raw_data : FixedArray[Byte]
}

// ElfFile 方法
pub fn ElfFile::entry_point(Self) -> UInt              // 获取入口点
pub fn ElfFile::is_riscv(Self) -> Bool                 // 是否为 RISC-V
pub fn ElfFile::section_count(Self) -> Int             // 节区数量
pub fn ElfFile::program_count(Self) -> Int             // 程序头数量
pub fn ElfFile::get_section(Self, Int) -> (UInt, UInt, UInt)?  // 获取节区
pub fn ElfFile::get_section_name(Self, Int) -> String  // 节区名称
pub fn ElfFile::get_code_sections(Self) -> Array[(UInt, FixedArray[Byte])]  // 代码段
pub fn ElfFile::get_symbols(Self) -> Array[Symbol]     // 获取符号表
pub fn ElfFile::get_function_symbols(Self) -> Array[Symbol]  // 函数符号
pub fn ElfFile::find_symbol_by_addr(Self, UInt) -> Symbol?  // 按地址查找符号
pub fn ElfFile::extract_bytes(Self, UInt, UInt) -> FixedArray[Byte]?  // 提取字节
```

#### 符号类型

```moonbit
pub struct Symbol {
  name : String
  value : UInt
  size : UInt
  sym_type : SymbolType
  binding : SymbolBinding
  section_index : UInt
}

pub enum SymbolType {
  NoType
  Object
  Func
  Section
  File
  Unknown
}

pub enum SymbolBinding {
  Local
  Global
  Weak
  Unknown
}
```

### 4. 分析模块 (`analysis`)

#### 控制流图 (CFG)

```moonbit
 "wzzc-dev/rvkit/analysis" @analysis

/// 解码指令序列
pub fn decode_instructions(
  bytes : FixedArray[Byte],
  start_addr : UInt
) -> FixedArray[DecodedInst]

/// 构建控制流图
pub fn build_cfg(
  instructions : FixedArray[DecodedInst],
  entry_addr : UInt
) -> CFG

/// 高级 API: 分析代码
pub fn analyze_code(
  bytes : FixedArray[Byte],
  start_addr : UInt
) -> CFG

/// 高级 API: 分析 ELF 文件
pub fn analyze_elf(bytes : FixedArray[Byte]) -> CFG?
```

#### CFG 数据结构

```moonbit
pub struct CFG {
  blocks : FixedArray[BasicBlock]
  edges : FixedArray[Edge]
  entry_points : FixedArray[UInt]
}

pub struct BasicBlock {
  start_addr : UInt
  end_addr : UInt
  instruction_count : Int
  is_terminated : Bool
}

pub struct Edge {
  from_block : UInt
  to_block : UInt
  edge_type : EdgeType
}

pub enum EdgeType {
  Jump           // 无条件跳转
  BranchTaken    // 条件分支成立
  BranchNotTaken // 条件分支不成立
  Call           // 函数调用
  Return         // 函数返回
}
```

#### CFG 导出

```moonbit
/// 导出为 DOT 格式 (Graphviz)
pub fn cfg_to_dot(cfg : CFG, name : String) -> String

/// 导出为 JSON 格式
pub fn cfg_to_json(cfg : CFG) -> String

/// 打印 CFG
pub fn print_cfg(cfg : CFG) -> Unit
```

#### 调用图 (Call Graph)

```moonbit
/// 构建调用图
pub fn build_call_graph(
  instructions : FixedArray[DecodedInst],
  cfg : CFG
) -> CallGraph

/// 获取可达函数
pub fn reachable_functions(cg : CallGraph) -> FixedArray[UInt]

/// 导出为 DOT 格式
pub fn callgraph_to_dot(cg : CallGraph, name : String) -> String

/// 导出为 JSON 格式
pub fn callgraph_to_json(cg : CallGraph) -> String
```

#### 调用图数据结构

```moonbit
pub struct CallGraph {
  nodes : FixedArray[CallGraphNode]
  entry_point : UInt
}

pub struct CallGraphNode {
  address : UInt
  name : String
  size : UInt
  calls : FixedArray[UInt]      // 调用的函数
  called_by : FixedArray[UInt]  // 被调用的位置
}
```

#### 指令分类辅助函数

```moonbit
/// 判断是否为终止指令
pub fn is_terminator(inst : @decode.Instruction) -> Bool

/// 判断是否为条件分支
pub fn is_conditional_branch(inst : @decode.Instruction) -> Bool

/// 判断是否为无条件跳转
pub fn is_unconditional_jump(inst : @decode.Instruction) -> Bool

/// 判断是否为调用指令
pub fn is_call(inst : @decode.Instruction) -> Bool

/// 判断是否为返回指令
pub fn is_return(inst : @decode.Instruction) -> Bool

/// 获取分支目标地址
pub fn get_branch_target(inst : @decode.Instruction) -> Int
```

### 5. 数据流分析

#### 定义-使用链 (Def-Use Chain)

```moonbit
/// 计算定义-使用链
pub fn compute_def_use_chains(
  instructions : FixedArray[DecodedInst]
) -> FixedArray[DefUseChain]

/// 打印定义-使用链
pub fn print_def_use_chains(chains : FixedArray[DefUseChain]) -> Unit
```

#### 数据结构

```moonbit
pub struct DefUseChain {
  reg : UInt
  is_float : Bool
  defs : FixedArray[DefUseEntry]
  uses : FixedArray[DefUseEntry]
}

pub struct DefUseEntry {
  addr : UInt
  index : Int
  reg : UInt
  is_float : Bool
  is_def : Bool
}
```

#### 活跃变量分析

```moonbit
/// 计算活跃变量
pub fn compute_liveness(
  cfg : CFG,
  instructions : FixedArray[DecodedInst]
) -> FixedArray[BlockLiveness]

/// 打印活跃集合
pub fn print_live_set(set : LiveSet) -> String
```

#### 活跃变量数据结构

```moonbit
pub struct BlockLiveness {
  block_addr : UInt
  live_in : LiveSet
  live_out : LiveSet
  def : LiveSet
  uses : LiveSet
}

pub struct LiveSet {
  int_regs : UInt    // 位图表示整数寄存器
  float_regs : UInt  // 位图表示浮点寄存器
}

// LiveSet 操作
pub fn LiveSet::empty() -> Self
pub fn LiveSet::add_int(Self, UInt) -> Self
pub fn LiveSet::add_float(Self, UInt) -> Self
pub fn LiveSet::remove_int(Self, UInt) -> Self
pub fn LiveSet::remove_float(Self, UInt) -> Self
pub fn LiveSet::contains_int(Self, UInt) -> Bool
pub fn LiveSet::contains_float(Self, UInt) -> Bool
pub fn LiveSet::union(Self, Self) -> Self
pub fn LiveSet::equal(Self, Self) -> Bool
```

#### 操作数分析

```moonbit
/// 获取指令的操作数
pub fn get_operands(inst : @decode.Instruction) -> InstOperands

pub struct InstOperands {
  operands : FixedArray[RegOperand]
}

pub struct RegOperand {
  reg : UInt
  is_float : Bool
  role : OperandRole
}

pub enum OperandRole {
  Use     // 使用
  Def     // 定义
  UseDef  // 使用并定义
}
```

---

## 主包 API (riscv_analyzer)

主包重新导出所有子模块的 API，提供统一入口：

```moonbit
 "wzzc-dev/rvkit" // 直接导入主包

// 解码
pub fn decode(UInt) -> DecodeResult
pub fn decode_compressed(UInt) -> DecodeResult
pub fn is_compressed(UInt) -> Bool
pub fn instruction_length(UInt) -> Int
pub fn reg_name(UInt) -> String
pub fn freg_name(UInt) -> String
pub fn vreg_name(UInt) -> String

// 反汇编
pub fn disassemble(Instruction) -> String
pub fn disassemble_with_addr(Instruction, UInt) -> String
pub fn disassemble_bytes(FixedArray[Byte], UInt) -> String

// ELF
pub fn is_elf(FixedArray[Byte]) -> Bool
pub fn get_elf_class(FixedArray[Byte]) -> ElfClass
pub fn parse_elf(FixedArray[Byte]) -> ElfFile?

// 分析
pub fn analyze_code(FixedArray[Byte], UInt) -> CFG
pub fn analyze_elf(FixedArray[Byte]) -> CFG?
pub fn build_cfg(FixedArray[DecodedInst], UInt) -> CFG
pub fn build_call_graph(FixedArray[DecodedInst], CFG) -> CallGraph
pub fn reachable_functions(CallGraph) -> FixedArray[UInt]

// 数据流
pub fn get_operands(Instruction) -> InstOperands
pub fn compute_def_use_chains(FixedArray[DecodedInst]) -> FixedArray[DefUseChain]
pub fn compute_liveness(CFG, FixedArray[DecodedInst]) -> FixedArray[BlockLiveness]
```

---

## 支持的指令集

### 基础指令集

| 扩展 | 描述 | 指令数量 |
|------|------|----------|
| RV32I | 32位基础整数指令集 | 40+ |
| RV64I | 64位基础整数指令集 | 12+ |
| RV32C | 32位压缩指令集 | 32 |
| RV32M | 32位乘除法扩展 | 8 |
| RV64M | 64位乘除法扩展 | 5 |

### 原子扩展

| 扩展 | 描述 | 指令数量 |
|------|------|----------|
| RV32A | 32位原子操作 | 11 |
| RV64A | 64位原子操作 | 11 |

### 浮点扩展

| 扩展 | 描述 | 指令数量 |
|------|------|----------|
| RV32F | 单精度浮点 | 30+ |
| RV64F | 64位单精度浮点 | - |
| RV32D | 双精度浮点 | 30+ |
| RV64D | 64位双精度浮点 | - |

### 向量扩展

| 扩展 | 描述 | 指令数量 |
|------|------|----------|
| RVV | 向量扩展 | 200+ |

### B 扩展 (位操作)

| 扩展 | 描述 | 指令数量 |
|------|------|----------|
| Zba | 地址生成指令 | 6 |
| Zbb | 基本位操作 | 20+ |
| Zbc | 无进位乘法 | 3 |
| Zbs | 单比特操作 | 8 |

### 系统扩展

| 扩展 | 描述 | 指令数量 |
|------|------|----------|
| Zicsr | CSR 指令 | 6 |

---

## 使用示例

### 示例 1：解码指令

```moonbit
 "wzzc-dev/rvkit/decode" @decode

fn example_decode() -> Unit {
  // 解码 32 位指令
  let code = 0x007302B3U  // add t0, t1, t2
  let @decode.DecodeResult(inst) = @decode.decode(code)
  
  // 获取指令类别
  let category = inst.category()
  println("Category: \{category}")  // Arithmetic
  
  // 判断是否为分支
  let is_branch = inst.is_branch()
  println("Is branch: \{is_branch}")  // false
}
```

### 示例 2：反汇编

```moonbit
 "wzzc-dev/rvkit" 

fn example_disasm() -> Unit {
  let code = 0x007302B3U
  let DecodeResult(inst) = decode(code)
  let asm = disassemble(inst)
  println(asm)  // "add t0, t1, t2"
}
```

### 示例 3：解析 ELF 文件

```moonbit
 "wzzc-dev/rvkit"

fn example_elf(bytes : FixedArray[Byte]) -> Unit {
  if is_elf(bytes) {
    match parse_elf(bytes) {
      Some(elf) => {
        println("Entry point: \{elf.entry_point()}")
        println("Is RISC-V: \{elf.is_riscv()}")
        
        // 获取函数符号
        let funcs = elf.get_function_symbols()
        for sym in funcs {
          println("Function: \{sym.name} at 0x\{sym.value}")
        }
      }
      None => println("Failed to parse ELF")
    }
  }
}
```

### 示例 4：构建 CFG

```moonbit
 "wzzc-dev/rvkit"

fn example_cfg(bytes : FixedArray[Byte]) -> Unit {
  // 分析代码
  let cfg = analyze_code(bytes, 0x8000U)
  
  // 打印基本块
  for block in cfg.blocks {
    println("Block: 0x\{block.start_addr} - 0x\{block.end_addr}")
    println("  Instructions: \{block.instruction_count}")
  }
  
  // 导出为 DOT 格式
  let dot = cfg_to_dot(cfg, "main")
  println(dot)
}
```

### 示例 5：构建调用图

```moonbit
 "wzzc-dev/rvkit"

fn example_callgraph(bytes : FixedArray[Byte]) -> Unit {
  let instructions = decode_instructions(bytes, 0x8000U)
  let cfg = build_cfg(instructions, 0x8000U)
  let cg = build_call_graph(instructions, cfg)
  
  // 打印调用关系
  for node in cg.nodes {
    println("Function at 0x\{node.address}")
    println("  Calls: \{node.calls.length()} functions")
    println("  Called by: \{node.called_by.length()} sites")
  }
  
  // 获取从入口可达的函数
  let reachable = reachable_functions(cg)
  println("Reachable functions: \{reachable.length()}")
}
```

### 示例 6：活跃变量分析

```moonbit
 "wzzc-dev/rvkit"

fn example_liveness(bytes : FixedArray[Byte]) -> Unit {
  let instructions = decode_instructions(bytes, 0x8000U)
  let cfg = build_cfg(instructions, 0x8000U)
  let liveness = compute_liveness(cfg, instructions)
  
  for block_live in liveness {
    println("Block at 0x\{block_live.block_addr}")
    println("  Live in: \{print_live_set(block_live.live_in)}")
    println("  Live out: \{print_live_set(block_live.live_out)}")
  }
}
```

---

## 命令行工具

项目提供一个 CLI 工具 `rvkit`：

```bash
# 反汇编
rvkit disasm program.elf
rvkit disasm --raw --base 0x8000 firmware.bin

# 查看 ELF 信息
rvkit info program.elf

# 列出符号
rvkit symbols program.elf
rvkit symbols --all program.elf

# 生成 CFG
rvkit cfg program.elf --function main > cfg.dot

# 生成调用图
rvkit callgraph program.elf > callgraph.dot

# 运行演示
rvkit demo
```

---

## 构建

```bash
# 构建项目
moon build

# 运行测试
moon test

# 更新接口文件并格式化
moon info && moon fmt

# 生成覆盖率报告
moon coverage analyze > uncovered.log
```

---

## 许可证

Apache-2.0
