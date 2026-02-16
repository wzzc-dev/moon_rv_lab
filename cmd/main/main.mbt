///| RISC-V Binary Analyzer CLI

///| A command-line tool for analyzing RISC-V binaries

///|
/// Print usage information
fn print_usage() -> Unit {
  println("RISC-V Binary Analyzer v0.2.0")
  println("")
  println("Usage: rv-analyzer <command> [options]")
  println("")
  println("Commands:")
  println("  disasm <hex>        Disassemble a single instruction (hex format)")
  println("  analyze <file>      Analyze an ELF file and show CFG")
  println("  disasm-file <file>  Disassemble all instructions in an ELF file")
  println("  help                Show this help message")
  println("")
  println("Examples:")
  println("  rv-analyzer disasm 0x123452B7")
  println("  rv-analyzer analyze program.elf")
}

///|
/// Parse a hex string to UInt
fn parse_hex(s : String) -> UInt? {
  if s.length() >= 2 && s[0] == '0' && s[1] == 'x' {
    let mut result : UInt = 0U
    for i = 2; i < s.length(); i = i + 1 {
      let c = s[i]
      let digit = match c {
        '0' => Some(0U)
        '1' => Some(1U)
        '2' => Some(2U)
        '3' => Some(3U)
        '4' => Some(4U)
        '5' => Some(5U)
        '6' => Some(6U)
        '7' => Some(7U)
        '8' => Some(8U)
        '9' => Some(9U)
        'a' | 'A' => Some(10U)
        'b' | 'B' => Some(11U)
        'c' | 'C' => Some(12U)
        'd' | 'D' => Some(13U)
        'e' | 'E' => Some(14U)
        'f' | 'F' => Some(15U)
        _ => None
      }
      match digit {
        Some(d) => result = result * 16U + d
        None => return None
      }
    }
    Some(result)
  } else {
    None
  }
}

///|
/// Parse a decimal string to UInt
fn parse_uint_dec(s : String) -> UInt? {
  let mut result : UInt = 0U
  for c in s {
    let digit = match c {
      '0' => Some(0U)
      '1' => Some(1U)
      '2' => Some(2U)
      '3' => Some(3U)
      '4' => Some(4U)
      '5' => Some(5U)
      '6' => Some(6U)
      '7' => Some(7U)
      '8' => Some(8U)
      '9' => Some(9U)
      _ => None
    }
    match digit {
      Some(d) => result = result * 10U + d
      None => return None
    }
  }
  Some(result)
}

///|
/// Parse a number (hex or decimal) to UInt
fn parse_number(s : String) -> UInt? {
  match parse_hex(s) {
    Some(v) => Some(v)
    None => parse_uint_dec(s)
  }
}

///|
/// Disassemble a single instruction from hex string
fn disasm_hex(hex : String) -> String {
  match parse_number(hex) {
    Some(code) =>
      // Check if it's a compressed instruction
      if @decode.is_compressed(code) {
        let @decode.DecodeResult(inst) = @decode.decode_compressed(
          code & 0xFFFFU,
        )
        @disasm.disassemble(inst)
      } else {
        let @decode.DecodeResult(inst) = @decode.decode(code)
        @disasm.disassemble(inst)
      }
    None => "Error: Invalid instruction code: \{hex}"
  }
}

///|
/// Convert UInt to hex string
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut v = value
    while v > 0U {
      let digit = (v % 16U).reinterpret_as_int()
      let c = if digit < 10 {
        (digit + 48).unsafe_to_char()
      } else {
        (digit + 87).unsafe_to_char()
      }
      result = c.to_string() + result
      v = v / 16U
    }
    result
  }
}

///|
/// Format UInt as hex
fn format_hex_uint(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
/// Analyze an ELF file and print CFG information
/// Note: This is a placeholder - actual file I/O requires platform-specific code
fn analyze_elf_demo() -> Unit {
  println("")
  println("=== ELF Analysis Demo ===")
  println("")
  println("To analyze an ELF file, use the high-level API:")
  println("  let bytes = ... // read file bytes")
  println("  match riscv_analyzer.analyze_elf(bytes) {")
  println("    Some(cfg) => { ... }")
  println("    None => println(\"Not a RISC-V ELF\")")
  println("  }")
  println("")
  println("Or use the low-level API:")
  println("  let elf = riscv_analyzer.parse_elf(bytes).unwrap()")
  println("  let sections = elf.get_code_sections()")
  println("  for (vaddr, code) in sections {")
  println("    let cfg = riscv_analyzer.analyze_code(code, vaddr)")
  println("    // analyze cfg...")
  println("  }")
}

///|
/// Disassemble an ELF file and print all instructions
/// Note: This is a placeholder - actual file I/O requires platform-specific code
fn disasm_elf_demo() -> Unit {
  println("")
  println("=== ELF Disassembly Demo ===")
  println("")
  println("To disassemble an ELF file, use:")
  println("  let bytes = ... // read file bytes")
  println("  let elf = riscv_analyzer.parse_elf(bytes).unwrap()")
  println("  let sections = elf.get_code_sections()")
  println("  for (vaddr, code) in sections {")
  println("    let disasm = riscv_analyzer.disassemble_bytes(code, vaddr)")
  println("    println(disasm)")
  println("  }")
}

///|
/// Main entry point - demonstrates disassembly of sample instructions
fn main {
  // Demo: disassemble sample instructions
  println("RISC-V Binary Analyzer - Demo")
  println("==============================")
  println("")

  // LUI x5, 0x12345 (RV32I)
  let lui_code = "0x123452B7"
  println("\{lui_code}: \{disasm_hex(lui_code)}")

  // ADD x5, x6, x7 (RV32I)
  let add_code = "0x007302B3"
  println("\{add_code}: \{disasm_hex(add_code)}")

  // MUL x5, x6, x7 (RV32M)
  let mul_code = "0x027302B3"
  println("\{mul_code}: \{disasm_hex(mul_code)}")

  // BEQ x5, x6, 0x10 (RV32I)
  let beq_code = "0x00628863"
  println("\{beq_code}: \{disasm_hex(beq_code)}")

  // JAL ra, 0x100 (RV32I)
  let jal_code = "0x100000EF"
  println("\{jal_code}: \{disasm_hex(jal_code)}")

  // C.LI x5, 1 (RV32C compressed)
  let cli_code = "0x0505"
  println("\{cli_code}: \{disasm_hex(cli_code)}")

  // C.ADD x5, x6 (RV32C compressed)
  let cadd_code = "0x9832"
  println("\{cadd_code}: \{disasm_hex(cadd_code)}")

  println("")
  println("=== Supported Instruction Sets ===")
  println("- RV32I: Base integer instructions (40 instructions)")
  println("- RV32M: Multiply/divide extension (8 instructions)")
  println("- RV32C: Compressed instructions (32 instructions)")

  // Show ELF analysis and disassembly examples
  analyze_elf_demo()
  disasm_elf_demo()
}
