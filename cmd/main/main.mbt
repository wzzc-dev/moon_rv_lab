///| RISC-V Binary Analyzer CLI

///|

///| A comprehensive command-line tool for analyzing RISC-V binaries

///|
/// CLI version
const VERSION : String = "0.4.0"

///|
/// Command types
pub enum Command {
  Disasm(DisasmOptions)
  Info(InfoOptions)
  Symbols(SymbolsOptions)
  Cfg(CfgOptions)
  CallGraph(CallGraphOptions)
  Help
  Version
  Demo
} derive(Show)

///|
/// Options for disasm command
pub struct DisasmOptions {
  file_path : String
  base_addr : UInt
  format : OutputFormat
  raw_mode : Bool // Treat as raw binary instead of ELF
} derive(Show)

///|
/// Options for info command
pub struct InfoOptions {
  file_path : String
  format : OutputFormat
} derive(Show)

///|
/// Options for symbols command
pub struct SymbolsOptions {
  file_path : String
  format : OutputFormat
  show_all : Bool // Show all symbols including local
} derive(Show)

///|
/// Options for cfg command
pub struct CfgOptions {
  file_path : String
  function : String // Function name or address
  format : OutputFormat
} derive(Show)

///|
/// Options for callgraph command
pub struct CallGraphOptions {
  file_path : String
  format : OutputFormat
} derive(Show)

///|
/// Output format
pub enum OutputFormat {
  Text
  Json
  Dot
} derive(Show, Eq)

///|
/// Parse output format from string
fn parse_format(s : String) -> OutputFormat {
  match s {
    "json" => OutputFormat::Json
    "dot" => OutputFormat::Dot
    _ => OutputFormat::Text
  }
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
/// Format UInt as hex with 0x prefix
fn _format_hex(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
/// Format UInt as padded hex (8 digits)
fn format_hex_padded(value : UInt) -> String {
  let hex = uint_to_hex(value)
  let padding = 8 - hex.length()
  let mut pad = ""
  for i = 0; i < padding; i = i + 1 {
    pad = pad + "0"
  }
  "0x" + pad + hex
}

///|
/// Parse command line arguments
pub fn parse_args(args : Array[String]) -> Command? {
  if args.length() == 0 {
    return Some(Command::Help)
  }

  let cmd = args[0]

  match cmd {
    "help" | "--help" | "-h" => Some(Command::Help)
    "version" | "--version" | "-v" => Some(Command::Version)
    "demo" => Some(Command::Demo)
    "disasm" => parse_disasm_args(args)
    "info" => parse_info_args(args)
    "symbols" | "syms" => parse_symbols_args(args)
    "cfg" => parse_cfg_args(args)
    "callgraph" | "cg" => parse_callgraph_args(args)
    _ => None
  }
}

///|
/// Parse disasm command arguments
fn parse_disasm_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut base_addr = 0U
  let mut format = OutputFormat::Text
  let mut raw_mode = false
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--base" || arg == "-b" {
      if i + 1 < args.length() {
        match parse_number(args[i + 1]) {
          Some(addr) => base_addr = addr
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--format" || arg == "-f" {
      if i + 1 < args.length() {
        format = parse_format(args[i + 1])
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--raw" || arg == "-r" {
      raw_mode = true
      i = i + 1
    } else if arg[0] != '-' {
      file_path = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if file_path == "" {
    return None
  }

  Some(Command::Disasm({ file_path, base_addr, format, raw_mode }))
}

///|
/// Parse info command arguments
fn parse_info_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut format = OutputFormat::Text
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--format" || arg == "-f" {
      if i + 1 < args.length() {
        format = parse_format(args[i + 1])
        i = i + 2
      } else {
        return None
      }
    } else if arg[0] != '-' {
      file_path = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if file_path == "" {
    return None
  }

  Some(Command::Info({ file_path, format }))
}

///|
/// Parse symbols command arguments
fn parse_symbols_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut format = OutputFormat::Text
  let mut show_all = false
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--format" || arg == "-f" {
      if i + 1 < args.length() {
        format = parse_format(args[i + 1])
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--all" || arg == "-a" {
      show_all = true
      i = i + 1
    } else if arg[0] != '-' {
      file_path = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if file_path == "" {
    return None
  }

  Some(Command::Symbols({ file_path, format, show_all }))
}

///|
/// Parse cfg command arguments
fn parse_cfg_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut function = ""
  let mut format = OutputFormat::Dot
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--function" || arg == "-n" {
      if i + 1 < args.length() {
        function = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--format" || arg == "-f" {
      if i + 1 < args.length() {
        format = parse_format(args[i + 1])
        i = i + 2
      } else {
        return None
      }
    } else if arg[0] != '-' {
      file_path = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if file_path == "" {
    return None
  }

  Some(Command::Cfg({ file_path, function, format }))
}

///|
/// Parse callgraph command arguments
fn parse_callgraph_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut format = OutputFormat::Dot
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--format" || arg == "-f" {
      if i + 1 < args.length() {
        format = parse_format(args[i + 1])
        i = i + 2
      } else {
        return None
      }
    } else if arg[0] != '-' {
      file_path = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if file_path == "" {
    return None
  }

  Some(Command::CallGraph({ file_path, format }))
}

///|
/// Print usage information
fn _print_usage() -> Unit {
  println("RISC-V Binary Analyzer v\{VERSION}")
  println("")
  println("Usage: rv-analyzer <command> [options] <file>")
  println("")
  println("Commands:")
  println("  disasm <file>           Disassemble a binary file")
  println("  info <file>             Show ELF file information")
  println("  symbols <file>          List symbols in the file")
  println("  cfg <file>              Generate control flow graph (DOT format)")
  println("  callgraph <file>        Generate call graph (DOT format)")
  println("  demo                    Run demonstration")
  println("  help                    Show this help message")
  println("  version                 Show version information")
  println("")
  println("Disasm Options:")
  println(
    "  --base, -b <addr>       Base address for raw binaries (default: 0)",
  )
  println("  --raw, -r               Treat as raw binary (not ELF)")
  println("  --format, -f <fmt>      Output format: text, json (default: text)")
  println("")
  println("Symbols Options:")
  println("  --all, -a               Show all symbols including local")
  println("  --format, -f <fmt>      Output format: text, json (default: text)")
  println("")
  println("CFG Options:")
  println("  --function, -n <name>   Function name or address to analyze")
  println(
    "  --format, -f <fmt>      Output format: dot, text, json (default: dot)",
  )
  println("")
  println("Examples:")
  println("  rv-analyzer disasm program.elf")
  println("  rv-analyzer disasm --raw --base 0x8000 firmware.bin")
  println("  rv-analyzer info program.elf")
  println("  rv-analyzer symbols program.elf")
  println("  rv-analyzer cfg program.elf --function main")
  println("  rv-analyzer callgraph program.elf > callgraph.dot")
}

///|
/// Print version information
fn _print_version() -> Unit {
  println("rv-analyzer \{VERSION}")
  println("RISC-V Binary Analyzer")
  println(
    "Supported architectures: RV32I, RV32M, RV32C, RV64I, RV64M, RV32A, RV64A, RV32F, RV64F, RV32D, RV64D, Zicsr, Zba, Zbb, Zbc, Zbs",
  )
}

///|
/// Disassemble a single instruction from hex string
fn disasm_hex(hex : String) -> String {
  match parse_number(hex) {
    Some(code) =>
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
/// Run demonstration
fn run_demo() -> Unit {
  println("RISC-V Binary Analyzer - Demo")
  println("==============================")
  println("")

  // RV32I instructions
  println("=== RV32I Base Instructions ===")
  let lui_addr = format_hex_padded(0x123452B7U)
  let lui_inst = disasm_hex("0x123452B7")
  println("\{lui_addr}: \{lui_inst}")
  let add_addr = format_hex_padded(0x007302B3U)
  let add_inst = disasm_hex("0x007302B3")
  println("\{add_addr}: \{add_inst}")
  let sub_addr = format_hex_padded(0x407302B3U)
  let sub_inst = disasm_hex("0x407302B3")
  println("\{sub_addr}: \{sub_inst}")
  let beq_addr = format_hex_padded(0x00208463U)
  let beq_inst = disasm_hex("0x00208463")
  println("\{beq_addr}: \{beq_inst}")
  let jal_addr = format_hex_padded(0x100000EFU)
  let jal_inst = disasm_hex("0x100000EF")
  println("\{jal_addr}: \{jal_inst}")
  println("")

  // RV32M instructions
  println("=== RV32M Extension ===")
  let mul_addr = format_hex_padded(0x027302B3U)
  let mul_inst = disasm_hex("0x027302B3")
  println("\{mul_addr}: \{mul_inst}")
  let div_addr = format_hex_padded(0x047302B3U)
  let div_inst = disasm_hex("0x047302B3")
  println("\{div_addr}: \{div_inst}")
  println("")

  // RV32C instructions
  println("=== RV32C Compressed Instructions ===")
  let cli_inst = disasm_hex("0x0505")
  println("    0x0505: \{cli_inst}")
  let cadd_inst = disasm_hex("0x9832")
  println("    0x9832: \{cadd_inst}")
  println("")

  // RV64I instructions
  println("=== RV64I Instructions ===")
  let ld_addr = format_hex_padded(0x06433283U)
  let ld_inst = disasm_hex("0x06433283")
  println("\{ld_addr}: \{ld_inst}")
  let addiw_addr = format_hex_padded(0x0643029BU)
  let addiw_inst = disasm_hex("0x0643029B")
  println("\{addiw_addr}: \{addiw_inst}")
  println("")

  // RV32A instructions
  println("=== RV32A Atomic Instructions ===")
  let lrw_addr = format_hex_padded(0x100322AFU)
  let lrw_inst = disasm_hex("0x100322AF")
  println("\{lrw_addr}: \{lrw_inst}")
  let amoswap_addr = format_hex_padded(0x087322AFU)
  let amoswap_inst = disasm_hex("0x087322AF")
  println("\{amoswap_addr}: \{amoswap_inst}")
  println("")

  // RV32F instructions
  println("=== RV32F Single-Precision Floating-Point ===")
  let flw_addr = format_hex_padded(0x00052507U)
  let flw_inst = disasm_hex("0x00052507")
  println("\{flw_addr}: \{flw_inst}")
  let fadd_s_addr = format_hex_padded(0x000580D3U)
  let fadd_s_inst = disasm_hex("0x000580D3")
  println("\{fadd_s_addr}: \{fadd_s_inst}")
  let fmul_s_addr = format_hex_padded(0x100580D3U)
  let fmul_s_inst = disasm_hex("0x100580D3")
  println("\{fmul_s_addr}: \{fmul_s_inst}")
  println("")

  // RV32D instructions
  println("=== RV32D Double-Precision Floating-Point ===")
  let fld_addr = format_hex_padded(0x00053507U)
  let fld_inst = disasm_hex("0x00053507")
  println("\{fld_addr}: \{fld_inst}")
  let fadd_d_addr = format_hex_padded(0x020580D3U)
  let fadd_d_inst = disasm_hex("0x020580D3")
  println("\{fadd_d_addr}: \{fadd_d_inst}")
  println("")

  // Zbb instructions
  println("=== Zbb Bit Manipulation Extension ===")
  let clz_addr = format_hex_padded(0x60003013U)
  let clz_inst = disasm_hex("0x60003013")
  println("\{clz_addr}: \{clz_inst}")
  let rev8_addr = format_hex_padded(0x6b830013U)
  let rev8_inst = disasm_hex("0x6b830013")
  println("\{rev8_addr}: \{rev8_inst}")
  println("")

  println("=== Supported Instruction Sets ===")
  println("- RV32I: Base integer instructions (40+ instructions)")
  println("- RV32M: Multiply/divide extension (8 instructions)")
  println("- RV32C: Compressed instructions (32 instructions)")
  println("- RV64I: 64-bit base instructions (12+ instructions)")
  println("- RV64M: 64-bit multiply/divide (5 instructions)")
  println("- RV32A/RV64A: Atomic operations (22 instructions)")
  println("- RV32F/RV64F: Single-precision floating-point (30+ instructions)")
  println("- RV32D/RV64D: Double-precision floating-point (30+ instructions)")
  println("- Zicsr: CSR instructions (6 instructions)")
  println("- Zba: Address generation (3 instructions)")
  println("- Zbb: Basic bit manipulation (16+ instructions)")
  println("- Zbc: Carry-less multiplication (3 instructions)")
  println("- Zbs: Single-bit instructions (8 instructions)")
  println("")
  println("=== Supported File Formats ===")
  println("- ELF32/ELF64 (RISC-V)")
  println("- Raw binary files")
  println("")
  println("=== Analysis Features ===")
  println("- Control Flow Graph (CFG) construction")
  println("- Call Graph analysis")
  println("- Def-Use chain analysis")
  println("- Live variable analysis")
  println("- DOT/JSON export for visualization")
}

///|
/// Main entry point
fn main {
  // For now, run demo since we can't access actual command line args
  // In a real deployment, use: let args = ... (platform-specific)
  run_demo()
}
