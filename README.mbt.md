# RISC-V Toolkit (rvkit)

A MoonBit library for assembling, disassembling, and analyzing RISC-V binaries, providing instruction encoding/decoding, assembly/disassembly, control flow analysis, and ELF file parsing.

## Features

- **Instruction Decoding**: Full support for multiple RISC-V instruction set extensions:
  - RV32I/RV64I: Base integer instruction sets
  - RV32M/RV64M: Integer multiplication and division
  - RV32A/RV64A: Atomic operations
  - RV32F/RV64F: Single-precision floating-point
  - RV32D/RV64D: Double-precision floating-point
  - RV32C/RV64C: Compressed instructions (16-bit)
  - RVV: Vector extension
  - Zba/Zbb/Zbc/Zbs: Bit manipulation extensions
  - Zicsr: CSR instructions

- **Disassembly**: Convert decoded instructions to human-readable assembly
- **Decompilation**: Convert machine code to structured pseudo-code with register tracking and string recovery
- **Control Flow Analysis**: Build Control Flow Graphs (CFG) from binary code
- **Call Graph Analysis**: Analyze function call relationships
- **Data Flow Analysis**: Def-use chains and liveness analysis
- **ELF Parsing**: Parse ELF32/ELF64 executable files

## Project Structure

```
riscv_analyzer/
├── decode/          # RISC-V instruction decoder
│   ├── decoder.mbt  # Decoding logic
│   └── types.mbt    # Instruction types and definitions
├── disasm/          # Disassembler engine
│   └── disasm.mbt   # Assembly text generation
├── analysis/        # Control flow and data flow analysis
│   ├── cfg.mbt      # CFG construction
│   └── dataflow.mbt # Data flow analysis
├── format/          # File format parsing
│   ├── elf.mbt      # ELF file parser
│   ├── elf_defs.mbt # ELF format constants
│   └── raw.mbt      # Raw binary handling
└── cmd/main/        # CLI tool
    └── main.mbt     # CLI entry point
```

## Installation

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "wzzc-dev/rvkit": "0.1.0"
  }
}
```

## Usage

### Decode Instructions

```moonbit nocheck
import "wzzc-dev/rvkit/decode" @decode

// Decode 32-bit instruction
let @decode.DecodeResult(inst) = @decode.decode(0x123452B7U)
// inst is LUI(t0, 0x12345000)

// Decode 16-bit compressed instruction
let @decode.DecodeResult(c_inst) = @decode.decode_compressed(0x4000U)
// c_inst is C_LW

// Check if instruction is compressed
let is_compressed = @decode.is_compressed(0x4000U)  // true
```

### Disassemble Instructions

```moonbit nocheck
import "wzzc-dev/rvkit/decode" @decode
import "wzzc-dev/rvkit/disasm" @disasm

let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
let asm = @disasm.disassemble(inst)
// asm = "add t0, t1, t2"

// With address
let asm_with_addr = @disasm.disassemble_with_addr(inst, 0x8000U)
// asm_with_addr = "0x00008000: add t0, t1, t2"
```

### Parse ELF Files

```moonbit nocheck
import "wzzc-dev/rvkit/format" @format

let elf = @format.parse_elf(bytes).?
let entry = elf.entry_point()
let is_riscv = elf.is_riscv()
let code_sections = elf.get_code_sections()

// Get function symbols
let funcs = elf.get_function_symbols()
for sym in funcs {
  println("Function: \{sym.name} at 0x\{sym.value}")
}
```

### Control Flow Analysis

```moonbit nocheck
import "wzzc-dev/rvkit/analysis" @analysis

// Analyze code and build CFG
let cfg = @analysis.analyze_code(code_bytes, start_addr)

// Print basic blocks
for block in cfg.blocks {
  println("Block: 0x\{block.start_addr} - 0x\{block.end_addr}")
}

// Export to DOT format for Graphviz
let dot = @analysis.cfg_to_dot(cfg, "main")
```

### Call Graph Analysis

```moonbit nocheck
import "wzzc-dev/rvkit/analysis" @analysis

let instructions = @analysis.decode_instructions(bytes, 0x8000U)
let cfg = @analysis.build_cfg(instructions, 0x8000U)
let cg = @analysis.build_call_graph(instructions, cfg)

// Get reachable functions from entry
let reachable = @analysis.reachable_functions(cg)

// Export to DOT format
let dot = @analysis.callgraph_to_dot(cg, "callgraph")
```

## Supported Instructions

### RV32I Base Instruction Set

| Category | Instructions |
|----------|-------------|
| U-type | `LUI`, `AUIPC` |
| J-type | `JAL` |
| I-type | `JALR`, `LB`, `LH`, `LW`, `LBU`, `LHU`, `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` |
| B-type | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| S-type | `SB`, `SH`, `SW` |
| R-type | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| System | `ECALL`, `EBREAK`, `FENCE`, `FENCE.I` |

### RV32M/RV64M Multiplication and Division

| Instruction | Description |
|-------------|-------------|
| `MUL` | Multiply |
| `MULH` | Multiply High |
| `MULHSU` | Multiply High Signed-Unsigned |
| `MULHU` | Multiply High Unsigned |
| `DIV` | Divide |
| `DIVU` | Divide Unsigned |
| `REM` | Remainder |
| `REMU` | Remainder Unsigned |

### RV32C/RV64C Compressed Instructions

| Category | Instructions |
|----------|-------------|
| Loads | `C.LW`, `C.LD`, `C.LWSP`, `C.LDSP` |
| Stores | `C.SW`, `C.SD`, `C.SWSP`, `C.SDSP` |
| Arithmetic | `C.ADDI`, `C.ADDIW`, `C.LI`, `C.LUI`, `C.ADD`, `C.ADDW`, `C.ADDI16SP` |
| Bitwise | `C.ANDI`, `C.AND`, `C.OR`, `C.XOR`, `C.SUB`, `C.SUBW` |
| Shifts | `C.SLLI`, `C.SRLI`, `C.SRAI` |
| Branches | `C.BEQZ`, `C.BNEZ` |
| Jumps | `C.J`, `C.JAL`, `C.JR`, `C.JALR` |
| Other | `C.NOP`, `C.MV`, `C.EBREAK` |

## Command Line Tool

The project includes a CLI tool `rvkit`:

```bash
# Disassemble an ELF file
rvkit disasm program.elf

# Disassemble raw binary with base address
rvkit disasm --raw --base 0x8000 firmware.bin

# View ELF information
rvkit info program.elf

# List symbols
rvkit symbols program.elf
rvkit symbols --all program.elf  # Include local symbols

# Generate CFG for a function
rvkit cfg program.elf --function main > cfg.dot

# Generate call graph
rvkit callgraph program.elf > callgraph.dot

# Decompile a function (control flow summary)
rvkit decompile program.elf --function main

# Decompile with pseudo-code output
rvkit decompile program.elf --function main --code

# Decode a hex instruction
rvkit hex 0x007302B3

# Run demo
rvkit demo
```

## Building

```bash
# Build the project
moon build

# Run tests
moon test

# Update interface files and format
moon info && moon fmt

# Generate coverage report
moon coverage analyze > uncovered.log
```

## Example

Compile and analyze a simple RISC-V program:

```bash
# Compile with RISC-V toolchain
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d hello.c -o hello

# Disassemble
rvkit disasm hello

# Generate CFG for main function
rvkit cfg hello --function main > main.dot

# View with Graphviz
dot -Tpng main.dot -o main.png
```

## License

Apache-2.0