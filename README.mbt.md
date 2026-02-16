# RISC-V Binary Analyzer

A MoonBit library for analyzing RISC-V binaries, providing instruction decoding, disassembly, control flow analysis, and ELF file parsing.

## Features

- **Instruction Decoding**: Full support for RV32I base instruction set (40 instructions)
- **Disassembly**: Convert decoded instructions to human-readable assembly
- **Control Flow Analysis**: Build Control Flow Graphs (CFG) from binary code
- **ELF Parsing**: Parse ELF32/ELF64 executable files

## Project Structure

```
riscv_analyzer/
├── decode/          # RISC-V instruction decoder
│   ├── decoder.mbt  # Decoding logic for RV32I
│   └── types.mbt    # Instruction types and definitions
├── disasm/          # Disassembler engine
│   └── disasm.mbt   # Assembly text generation
├── analysis/        # Control flow analysis
│   └── cfg.mbt      # CFG construction and basic block analysis
├── format/          # File format parsing
│   ├── elf.mbt      # ELF file parser
│   └── elf_defs.mbt # ELF format constants
└── cmd/main/        # CLI tool (demo)
```

## Installation

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "wzzc-dev/riscv_analyzer": "0.1.0"
  }
}
```

## Usage

### Decode Instructions

```moonbit nocheck
import "wzzc-dev/riscv_analyzer/decode" @decode

let @decode.DecodeResult(inst) = @decode.decode(0x123452B7U)
// inst is LUI(t0, 0x12345000)
```

### Disassemble Instructions

```moonbit nocheck
import "wzzc-dev/riscv_analyzer/decode" @decode
import "wzzc-dev/riscv_analyzer/disasm" @disasm

let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
let asm = @disasm.disassemble(inst)
// asm = "add t0, t1, t2"
```

### Parse ELF Files

```moonbit nocheck
import "wzzc-dev/riscv_analyzer/format" @format

let elf = @format.parse_elf(bytes).?
let entry = elf.entry_point()
let is_riscv = elf.is_riscv()
let code_sections = elf.get_code_sections()
```

### Control Flow Analysis

```moonbit nocheck
import "wzzc-dev/riscv_analyzer/analysis" @analysis

let cfg = @analysis.analyze_code(code_bytes, start_address)
@analysis.print_cfg(cfg)
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

## Building

```bash
# Build the project
moon build

# Run tests
moon test

# Update interface files
moon info && moon fmt
```

## License

Apache-2.0
