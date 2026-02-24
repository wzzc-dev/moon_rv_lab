///| RISC-V Binary Analyzer CLI

///|

///| A comprehensive command-line tool for analyzing RISC-V binaries

///|
/// CLI version
const VERSION : String = "0.4.0"

///|
/// Error types for CLI operations
pub enum CliError {
  FileNotFound(String)
  FileReadError(String)
  InvalidFormat(String)
  ParseError(String)
  InvalidArguments(String)
  NotAnElf(String)
  NotRiscV(String)
  NoCodeSection(String)
  FunctionNotFound(String)
} derive(Show)

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
fn format_hex(value : UInt) -> String {
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
fn print_usage() -> Unit {
  println("RISC-V Binary Analyzer v\{VERSION}")
  println("")
  println("Usage: rv-analyzer <command> [options] <file>")
  println("")
  println("Commands:")
  println("  disasm <file>           Disassemble a binary file")
  println("  info <file>             Show ELF file information")
  println("  symbols <file>          List symbols in the file")
  println("  cfg <file>              Generate control flow graph")
  println("  callgraph <file>        Generate call graph")
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
  println("CallGraph Options:")
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
fn print_version() -> Unit {
  println("rv-analyzer \{VERSION}")
  println("RISC-V Binary Analyzer")
  println(
    "Supported: RV32I, RV32M, RV32C, RV64I, RV64M, RV32A, RV64A, RV32F, RV64F, RV32D, RV64D, RVV, Zicsr, Zba, Zbb, Zbc, Zbs",
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
  println("- RVV: Vector extension (200+ instructions)")
  println("- Zicsr: CSR instructions (6 instructions)")
  println("- Zba: Address generation (6 instructions)")
  println("- Zbb: Basic bit manipulation (20+ instructions)")
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

// ============================================================================
// File I/O Operations
// ============================================================================

///|
/// Read file contents as bytes (MoonBit foreign function interface)
fn read_file_bytes(path : String) -> FixedArray[Byte]? {
  // Use MoonBit's io module for file reading
  // This is a placeholder - actual implementation depends on platform
  // For now, return None to indicate file reading needs platform support
  ignore(path)
  None
}

// ============================================================================
// Command Execution Functions
// ============================================================================

///|
/// Execute disasm command
fn execute_disasm(opts : DisasmOptions) -> Unit {
  match read_file_bytes(opts.file_path) {
    Some(bytes) =>
      if opts.raw_mode {
        let instructions = @analysis.decode_instructions(bytes, opts.base_addr)
        output_disasm(instructions, opts.format)
      } else {
        if !@format.is_elf(bytes) {
          println("Error: Not a valid ELF file: \{opts.file_path}")
          println("Use --raw option for raw binary files")
          return
        }
        match @format.parse_elf(bytes) {
          Some(elf) => {
            if !elf.is_riscv() {
              println("Error: Not a RISC-V ELF file")
              return
            }
            let code_sections = elf.get_code_sections()
            if code_sections.length() == 0 {
              println("Error: No executable code sections found")
              return
            }
            let (vaddr, code) = code_sections[0]
            let instructions = @analysis.decode_instructions(code, vaddr)
            output_disasm(instructions, opts.format)
          }
          None => println("Error: Failed to parse ELF file")
        }
      }
    None => {
      println("Error: Cannot read file: \{opts.file_path}")
      println("Note: File I/O requires platform support")
    }
  }
}

///|
/// Output disassembly results
fn output_disasm(
  instructions : FixedArray[@analysis.DecodedInst],
  format : OutputFormat,
) -> Unit {
  match format {
    OutputFormat::Json => {
      println("[")
      let len = instructions.length()
      for i = 0; i < len; i = i + 1 {
        let inst_info = instructions[i]
        let addr_str = format_hex(inst_info.addr)
        let asm_str = escape_json_string(@disasm.disassemble(inst_info.inst))
        let comma = if i < len - 1 { "," } else { "" }
        println(
          "  {\"addr\": \"\{addr_str}\", \"inst\": \"\{asm_str}\"}\{comma}",
        )
      }
      println("]")
    }
    OutputFormat::Text | OutputFormat::Dot =>
      for inst_info in instructions {
        let addr_str = format_hex_padded(inst_info.addr)
        let disasm_str = @disasm.disassemble(inst_info.inst)
        println("\{addr_str}: \{disasm_str}")
      }
  }
}

///|
/// Get ELF class string
fn elf_class_str(elf : @format.ElfFile) -> String {
  if elf.is_64bit {
    "ELF64"
  } else {
    "ELF32"
  }
}

///|
/// Get architecture string
fn arch_str(elf : @format.ElfFile) -> String {
  if elf.is_riscv() {
    "RISC-V"
  } else {
    "Unknown"
  }
}

///|
/// Execute info command
fn execute_info(opts : InfoOptions) -> Unit {
  match read_file_bytes(opts.file_path) {
    Some(bytes) => {
      if !@format.is_elf(bytes) {
        println("Error: Not a valid ELF file: \{opts.file_path}")
        return
      }
      match @format.parse_elf(bytes) {
        Some(elf) =>
          match opts.format {
            OutputFormat::Json => output_elf_info_json(elf)
            OutputFormat::Text | OutputFormat::Dot => output_elf_info_text(elf)
          }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Output ELF info as text
fn output_elf_info_text(elf : @format.ElfFile) -> Unit {
  println("ELF File Information")
  println("====================")
  println("")
  let class_str = elf_class_str(elf)
  let arch = arch_str(elf)
  println("Class: \{class_str}")
  println("Architecture: \{arch}")
  println("Entry Point: \{format_hex(elf.entry_point())}")
  println("Sections: \{elf.section_count()}")
  println("Program Headers: \{elf.program_count()}")
  println("")
  println("Sections:")
  for i = 0; i < elf.section_count(); i = i + 1 {
    let name = elf.get_section_name(i)
    match elf.get_section(i) {
      Some((addr, _offset, size)) => {
        let addr_str = format_hex(addr)
        println("  [\{i}] \{name}: addr=\{addr_str}, size=\{size}")
      }
      None => ignore(())
    }
  }
}

///|
/// Output ELF info as JSON
fn output_elf_info_json(elf : @format.ElfFile) -> Unit {
  let class_str = elf_class_str(elf)
  let arch = arch_str(elf)
  let entry_str = format_hex(elf.entry_point())
  println("{")
  println("  \"class\": \"\{class_str}\",")
  println("  \"architecture\": \"\{arch}\",")
  println("  \"entry_point\": \"\{entry_str}\",")
  println("  \"section_count\": \{elf.section_count()},")
  println("  \"program_count\": \{elf.program_count()}")
  println("}")
}

///|
/// Check if symbol binding is local
fn is_local_binding(binding : @format.SymbolBinding) -> Bool {
  match binding {
    @format.SymbolBinding::Local => true
    _ => false
  }
}

///|
/// Get binding string
fn binding_to_str(binding : @format.SymbolBinding) -> String {
  match binding {
    @format.SymbolBinding::Local => "LOCAL"
    @format.SymbolBinding::Global => "GLOBAL"
    @format.SymbolBinding::Weak => "WEAK"
    _ => "UNKNOWN"
  }
}

///|
/// Get symbol type string
fn sym_type_to_str(sym_type : @format.SymbolType) -> String {
  match sym_type {
    @format.SymbolType::Func => "FUNC"
    @format.SymbolType::Object => "OBJECT"
    @format.SymbolType::Section => "SECTION"
    @format.SymbolType::File => "FILE"
    @format.SymbolType::NoType => "NOTYPE"
    _ => "UNKNOWN"
  }
}

///|
/// Execute symbols command
fn execute_symbols(opts : SymbolsOptions) -> Unit {
  match read_file_bytes(opts.file_path) {
    Some(bytes) => {
      if !@format.is_elf(bytes) {
        println("Error: Not a valid ELF file: \{opts.file_path}")
        return
      }
      match @format.parse_elf(bytes) {
        Some(elf) => {
          let symbols = elf.get_symbols()
          match opts.format {
            OutputFormat::Json => output_symbols_json(symbols, opts.show_all)
            OutputFormat::Text | OutputFormat::Dot =>
              output_symbols_text(symbols, opts.show_all)
          }
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Output symbols as text
fn output_symbols_text(
  symbols : Array[@format.Symbol],
  show_all : Bool,
) -> Unit {
  println("Symbols")
  println("=======")
  println("")
  for sym in symbols {
    if !show_all && is_local_binding(sym.binding) {
      continue
    }
    let addr_str = format_hex_padded(sym.value)
    let binding_str = binding_to_str(sym.binding)
    let type_str = sym_type_to_str(sym.sym_type)
    println("\{addr_str} \{type_str} \{binding_str} \{sym.name}")
  }
}

///|
/// Get binding string for JSON
fn binding_to_json_str(binding : @format.SymbolBinding) -> String {
  match binding {
    @format.SymbolBinding::Local => "local"
    @format.SymbolBinding::Global => "global"
    @format.SymbolBinding::Weak => "weak"
    _ => "unknown"
  }
}

///|
/// Get symbol type string for JSON
fn sym_type_to_json_str(sym_type : @format.SymbolType) -> String {
  match sym_type {
    @format.SymbolType::Func => "func"
    @format.SymbolType::Object => "object"
    @format.SymbolType::Section => "section"
    @format.SymbolType::File => "file"
    @format.SymbolType::NoType => "notype"
    _ => "unknown"
  }
}

///|
/// Output symbols as JSON
fn output_symbols_json(
  symbols : Array[@format.Symbol],
  show_all : Bool,
) -> Unit {
  println("[")
  let mut first = true
  for sym in symbols {
    if !show_all && is_local_binding(sym.binding) {
      continue
    }
    if !first {
      println(",")
    }
    first = false
    let name_str = escape_json_string(sym.name)
    let addr_str = format_hex(sym.value)
    let type_str = sym_type_to_json_str(sym.sym_type)
    let binding_str = binding_to_json_str(sym.binding)
    let line = "  {\"name\": \"\{name_str}\", \"value\": \"\{addr_str}\", \"size\": \{sym.size}, \"type\": \"\{type_str}\", \"binding\": \"\{binding_str}\"}"
    println(line)
  }
  println("]")
}

///|
/// Execute cfg command
fn execute_cfg(opts : CfgOptions) -> Unit {
  match read_file_bytes(opts.file_path) {
    Some(bytes) => {
      if !@format.is_elf(bytes) {
        println("Error: Not a valid ELF file: \{opts.file_path}")
        return
      }
      match @format.parse_elf(bytes) {
        Some(elf) => {
          if !elf.is_riscv() {
            println("Error: Not a RISC-V ELF file")
            return
          }
          let code_sections = elf.get_code_sections()
          if code_sections.length() == 0 {
            println("Error: No executable code sections found")
            return
          }
          let (vaddr, code) = code_sections[0]
          let cfg = @analysis.analyze_code(code, vaddr)
          let name = if opts.function == "" { "main" } else { opts.function }
          match opts.format {
            OutputFormat::Dot => println(@analysis.cfg_to_dot(cfg, name))
            OutputFormat::Json => println(@analysis.cfg_to_json(cfg))
            OutputFormat::Text => @analysis.print_cfg(cfg)
          }
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Execute callgraph command
fn execute_callgraph(opts : CallGraphOptions) -> Unit {
  match read_file_bytes(opts.file_path) {
    Some(bytes) => {
      if !@format.is_elf(bytes) {
        println("Error: Not a valid ELF file: \{opts.file_path}")
        return
      }
      match @format.parse_elf(bytes) {
        Some(elf) => {
          if !elf.is_riscv() {
            println("Error: Not a RISC-V ELF file")
            return
          }
          let code_sections = elf.get_code_sections()
          if code_sections.length() == 0 {
            println("Error: No executable code sections found")
            return
          }
          let (vaddr, code) = code_sections[0]
          let instructions = @analysis.decode_instructions(code, vaddr)
          let cfg = @analysis.build_cfg(instructions, vaddr)
          let cg = @analysis.build_call_graph(instructions, cfg)
          match opts.format {
            OutputFormat::Dot =>
              println(@analysis.callgraph_to_dot(cg, "callgraph"))
            OutputFormat::Json => println(@analysis.callgraph_to_json(cg))
            OutputFormat::Text => @analysis.print_call_graph(cg)
          }
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Escape special characters for JSON strings
fn escape_json_string(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => result = result + c.to_string()
    }
  }
  result
}

///|
/// Execute a parsed command
pub fn execute(cmd : Command) -> Unit {
  match cmd {
    Command::Help => print_usage()
    Command::Version => print_version()
    Command::Demo => run_demo()
    Command::Disasm(opts) => execute_disasm(opts)
    Command::Info(opts) => execute_info(opts)
    Command::Symbols(opts) => execute_symbols(opts)
    Command::Cfg(opts) => execute_cfg(opts)
    Command::CallGraph(opts) => execute_callgraph(opts)
  }
}

///|
/// Main entry point
fn main {
  // Run demo by default since MoonBit doesn't support command line args yet
  // In a real deployment with platform support:
  //   let args = get_command_line_args()
  //   match parse_args(args) {
  //     Some(cmd) => execute(cmd)
  //     None => {
  //       println("Error: Invalid arguments")
  //       print_usage()
  //     }
  //   }
  run_demo()
}
