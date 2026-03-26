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
  Run(RunOptions)
  Hex(HexOptions)
  Analyze(AnalyzeOptions)
  Decompile(DecompileOptions)
  Interactive(InteractiveOptions)
  Asm(AsmOptions)
  Workbench(WorkbenchCmdOptions)
  Help
  Version
  Demo
} derive(Show)

///|
/// Options for asm command
pub struct AsmOptions {
  input_file : String
  output_file : String
  format : AsmOutputFormat
  base_addr : UInt
} derive(Show)

///|
/// Options for workbench command
pub struct WorkbenchCmdOptions {
  file_path : String
  output : String
  title : String
  max_instructions : Int
} derive(Show)

///|
/// Output format for assembler
pub enum AsmOutputFormat {
  Elf
  Hex
  Raw
} derive(Show)

///|
/// Options for interactive command
pub struct InteractiveOptions {
  file_path : String // Optional: pre-load a file
} derive(Show)

///|
/// Options for disasm command
pub struct DisasmOptions {
  file_path : String
  base_addr : UInt
  format : OutputFormat
  raw_mode : Bool // Treat as raw binary instead of ELF
  output : String // Output file path (empty for stdout)
} derive(Show)

///|
/// Options for info command
pub struct InfoOptions {
  file_path : String
  format : OutputFormat
  output : String
} derive(Show)

///|
/// Options for symbols command
pub struct SymbolsOptions {
  file_path : String
  format : OutputFormat
  show_all : Bool // Show all symbols including local
  output : String
} derive(Show)

///|
/// Options for cfg command
pub struct CfgOptions {
  file_path : String
  function : String // Function name or address
  format : OutputFormat
  output : String
} derive(Show)

///|
/// Options for callgraph command
pub struct CallGraphOptions {
  file_path : String
  format : OutputFormat
  output : String
} derive(Show)

///|
/// Options for run command
pub struct RunOptions {
  file_path : String
  entry : String
  max_steps : Int
  breakpoints : Array[String]
  trace : String
  format : OutputFormat
} derive(Show)

///|
/// Options for hex command (decode hex instruction)
pub struct HexOptions {
  code : String // Hex code string
  format : OutputFormat
} derive(Show)

///|
/// Options for analyze command (comprehensive analysis)
pub struct AnalyzeOptions {
  file_path : String
  format : OutputFormat
  output : String
  detailed : Bool
} derive(Show)

///|
/// Options for decompile command (pseudo-code generation)
pub struct DecompileOptions {
  file_path : String
  function : String // Function name or address (empty for entry point)
  output : String
  show_code : Bool // Show pseudo-code (default: false, only show control flow)
} derive(Show)

///|
/// Output format
pub enum OutputFormat {
  Text
  Json
  Dot
} derive(Show, Eq)

///|
priv enum CommandExecResult {
  Success(String)
  Failure(String)
} derive(Show)

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
    "run" => parse_run_args(args)
    "hex" => parse_hex_args(args)
    "analyze" => parse_analyze_args(args)
    "decompile" | "dec" => parse_decompile_args(args)
    "interactive" | "i" | "repl" => parse_interactive_args(args)
    "asm" | "assemble" => parse_asm_args(args)
    "workbench" | "wb" => parse_workbench_args(args)
    _ => None
  }
}

///|
/// Parse interactive command arguments
fn parse_interactive_args(args : Array[String]) -> Command? {
  let mut file_path = ""
  if args.length() > 1 && args[1][0] != '-' {
    file_path = args[1]
  }
  Some(Command::Interactive({ file_path, }))
}

///|
/// Parse asm command arguments
fn parse_asm_args(args : Array[String]) -> Command? {
  let mut input_file = ""
  let mut output_file = ""
  let mut format = AsmOutputFormat::Elf
  let mut base_addr = 0x10000U

  let mut i = 1
  while i < args.length() {
    let arg = args[i]
    if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output_file = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--format" || arg == "-f" {
      if i + 1 < args.length() {
        format = match args[i + 1] {
          "elf" => AsmOutputFormat::Elf
          "hex" => AsmOutputFormat::Hex
          "raw" => AsmOutputFormat::Raw
          _ => AsmOutputFormat::Elf
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--base" || arg == "-b" {
      if i + 1 < args.length() {
        match parse_number(args[i + 1]) {
          Some(addr) => base_addr = addr
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg[0] != '-' {
      input_file = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if input_file == "" {
    return None
  }

  Some(Command::Asm({ input_file, output_file, format, base_addr }))
}

///|
/// Parse workbench command arguments
fn parse_workbench_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut output = "workbench.html"
  let mut title = ""
  let mut max_instructions = 1200
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--title" {
      if i + 1 < args.length() {
        title = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--max-inst" || arg == "--max-instructions" {
      if i + 1 < args.length() {
        match parse_uint_dec(args[i + 1]) {
          Some(value) => max_instructions = value.reinterpret_as_int()
          None => return None
        }
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

  Some(Command::Workbench({ file_path, output, title, max_instructions }))
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
  let mut output = ""
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
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

  Some(Command::Disasm({ file_path, base_addr, format, raw_mode, output }))
}

///|
/// Parse info command arguments
fn parse_info_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut format = OutputFormat::Text
  let mut output = ""
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
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

  Some(Command::Info({ file_path, format, output }))
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
  let mut output = ""
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
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

  Some(Command::Symbols({ file_path, format, show_all, output }))
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
  let mut output = ""
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
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

  Some(Command::Cfg({ file_path, function, format, output }))
}

///|
/// Parse callgraph command arguments
fn parse_callgraph_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut format = OutputFormat::Dot
  let mut output = ""
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
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

  Some(Command::CallGraph({ file_path, format, output }))
}

///|
/// Parse run command arguments
fn parse_run_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut entry = ""
  let mut max_steps = 200
  let breakpoints : Array[String] = []
  let mut trace = ""
  let mut format = OutputFormat::Text
  let mut i = 1

  while i < args.length() {
    let arg = args[i]
    if arg == "--entry" {
      if i + 1 < args.length() {
        entry = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--max-steps" {
      if i + 1 < args.length() {
        match parse_uint_dec(args[i + 1]) {
          Some(value) => max_steps = value.reinterpret_as_int()
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--break" {
      if i + 1 < args.length() {
        breakpoints.push(args[i + 1])
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--trace" {
      if i + 1 < args.length() {
        trace = args[i + 1]
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

  Some(
    Command::Run({ file_path, entry, max_steps, breakpoints, trace, format }),
  )
}

///|
/// Parse hex command arguments
fn parse_hex_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut code = ""
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
      code = arg
      i = i + 1
    } else {
      i = i + 1
    }
  }

  if code == "" {
    return None
  }

  Some(Command::Hex({ code, format }))
}

///|
/// Parse analyze command arguments
fn parse_analyze_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut format = OutputFormat::Text
  let mut output = ""
  let mut detailed = false
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--detailed" || arg == "-d" {
      detailed = true
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

  Some(Command::Analyze({ file_path, format, output, detailed }))
}

///|
/// Parse decompile command arguments
fn parse_decompile_args(args : Array[String]) -> Command? {
  if args.length() < 2 {
    return None
  }

  let mut file_path = ""
  let mut function = ""
  let mut output = ""
  let mut show_code = false
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
    } else if arg == "--output" || arg == "-o" {
      if i + 1 < args.length() {
        output = args[i + 1]
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--code" || arg == "-c" {
      show_code = true
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

  Some(Command::Decompile({ file_path, function, output, show_code }))
}

///|
/// Print usage information
fn print_usage() -> Unit {
  println("RISC-V Binary Analyzer v\{VERSION}")
  println("")
  println("Usage: rvkit <command> [options] <file>")
  println("")
  println("Commands:")
  println("  disasm <file>           Disassemble a binary file")
  println("  info <file>             Show ELF file information")
  println("  symbols <file>          List symbols in the file")
  println("  cfg <file>              Generate control flow graph")
  println("  callgraph <file>        Generate call graph")
  println("  run <file>              Execute an ELF file with tracing")
  println("  hex <code>              Decode a hex instruction")
  println("  analyze <file>          Comprehensive binary analysis")
  println("  decompile <file>        Generate pseudo-code from binary")
  println("  asm <file>              Assemble RISC-V assembly to ELF/binary")
  println("  workbench <file>        Generate Web workbench HTML")
  println("  demo                    Run demonstration")
  println("  help                    Show this help message")
  println("  version                 Show version information")
  println("")
  println("Global Options:")
  println("  --output, -o <file>     Write output to file (default: stdout)")
  println("  --format, -f <fmt>      Output format: text, json, dot")
  println("")
  println("Disasm Options:")
  println(
    "  --base, -b <addr>       Base address for raw binaries (default: 0)",
  )
  println("  --raw, -r               Treat as raw binary (not ELF)")
  println("")
  println("Symbols Options:")
  println("  --all, -a               Show all symbols including local")
  println("")
  println("CFG Options:")
  println("  --function, -n <name>   Function name or address to analyze")
  println("")
  println("Analyze Options:")
  println("  --detailed, -d          Show detailed analysis")
  println("")
  println("Run Options:")
  println("  --entry <name|addr>     Override entry with symbol or address")
  println("  --max-steps <n>         Stop after n executed instructions")
  println("  --break <name|addr>     Stop before executing this address")
  println("  --trace <file>          Write structured trace JSON to file")
  println("")
  println("Decompile Options:")
  println("  --function, -n <name>   Function name or address to decompile")
  println(
    "  --code, -c              Show pseudo-code (default: control flow only)",
  )
  println("")
  println("Asm Options:")
  println("  --output, -o <file>     Output file path")
  println("  --format, -f <fmt>      Output format: elf (default), hex, raw")
  println("  --base, -b <addr>       Base address (default: 0x10000)")
  println("")
  println("Workbench Options:")
  println(
    "  --output, -o <file>     Output HTML path (default: workbench.html)",
  )
  println("  --title <text>          Override page title")
  println(
    "  --max-inst <n>          Max instructions embedded in page (default: 1200)",
  )
  println("")
  println("Examples:")
  println("  rvkit disasm program.elf")
  println("  rvkit disasm --raw --base 0x8000 firmware.bin")
  println("  rvkit info program.elf")
  println("  rvkit symbols program.elf")
  println("  rvkit cfg program.elf --function main -o cfg.dot")
  println("  rvkit callgraph program.elf -o callgraph.dot")
  println("  rvkit run program.elf --entry main --max-steps 200")
  println("  rvkit run program.elf --break main+0x10 --trace out/trace.json")
  println("  rvkit hex 0x123452B7")
  println("  rvkit analyze program.elf --detailed")
  println("  rvkit decompile program.elf --function main")
  println("  rvkit decompile program.elf --function main --code -o pseudo.c")
  println("  rvkit asm code.s -o program.elf")
  println("  rvkit asm code.s -f hex")
  println("  rvkit workbench example/hello.elf -o out/workbench.html")
}

///|
/// Print version information
fn print_version() -> Unit {
  println("rvkit \{VERSION}")
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
/// Read file contents as bytes using moonbitlang/x/fs
fn read_file_bytes(path : String) -> FixedArray[Byte]? {
  if !@fs.path_exists(path) {
    None
  } else {
    try {
      let bytes = @fs.read_file_to_bytes(path)
      Some(bytes.to_fixedarray())
    } catch {
      _ => None
    }
  }
}

///|
/// Write string to file
fn write_output_file(path : String, content : String) -> Bool {
  try {
    @fs.write_string_to_file(path, content)
    true
  } catch {
    _ => false
  }
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
        let output = format_disasm(instructions, opts.format)
        write_or_print(output, opts.output)
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
            let output = format_disasm(instructions, opts.format)
            write_or_print(output, opts.output)
          }
          None => println("Error: Failed to parse ELF file")
        }
      }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Format disassembly results as string
fn format_disasm(
  instructions : FixedArray[@analysis.DecodedInst],
  format : OutputFormat,
) -> String {
  match format {
    OutputFormat::Json => {
      let mut result = "[\n"
      let len = instructions.length()
      for i = 0; i < len; i = i + 1 {
        let inst_info = instructions[i]
        let addr_str = format_hex(inst_info.addr)
        let asm_str = escape_json_string(@disasm.disassemble(inst_info.inst))
        let comma = if i < len - 1 { "," } else { "" }
        result = result +
          "  {\"addr\": \"\{addr_str}\", \"inst\": \"\{asm_str}\"}\{comma}\n"
      }
      result = result + "]"
      result
    }
    OutputFormat::Text | OutputFormat::Dot => {
      let mut result = ""
      for inst_info in instructions {
        let addr_str = format_hex_padded(inst_info.addr)
        let disasm_str = @disasm.disassemble(inst_info.inst)
        result = result + "\{addr_str}: \{disasm_str}\n"
      }
      result
    }
  }
}

///|
/// Write output to file or print to stdout
fn write_or_print(content : String, output_path : String) -> Unit {
  if output_path == "" {
    println(content)
  } else if write_output_file(output_path, content) {
    println("Output written to: \{output_path}")
  } else {
    println("Error: Failed to write output file: \{output_path}")
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
        Some(elf) => {
          let output = match opts.format {
            OutputFormat::Json => format_elf_info_json(elf)
            OutputFormat::Text | OutputFormat::Dot => format_elf_info_text(elf)
          }
          write_or_print(output, opts.output)
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Format ELF info as text string
fn format_elf_info_text(elf : @format.ElfFile) -> String {
  let mut result = ""
  result = result + "ELF File Information\n"
  result = result + "====================\n\n"
  let class_str = elf_class_str(elf)
  let arch = arch_str(elf)
  result = result + "Class: \{class_str}\n"
  result = result + "Architecture: \{arch}\n"
  result = result + "Entry Point: \{format_hex(elf.entry_point())}\n"
  result = result + "Sections: \{elf.section_count()}\n"
  result = result + "Program Headers: \{elf.program_count()}\n\n"
  result = result + "Sections:\n"
  for i = 0; i < elf.section_count(); i = i + 1 {
    let name = elf.get_section_name(i)
    match elf.get_section(i) {
      Some((addr, _offset, size)) => {
        let addr_str = format_hex(addr)
        result = result + "  [\{i}] \{name}: addr=\{addr_str}, size=\{size}\n"
      }
      None => ignore(())
    }
  }
  result
}

///|
/// Format ELF info as JSON string
fn format_elf_info_json(elf : @format.ElfFile) -> String {
  let class_str = elf_class_str(elf)
  let arch = arch_str(elf)
  let entry_str = format_hex(elf.entry_point())
  let mut result = "{\n"
  result = result + "  \"class\": \"\{class_str}\",\n"
  result = result + "  \"architecture\": \"\{arch}\",\n"
  result = result + "  \"entry_point\": \"\{entry_str}\",\n"
  result = result + "  \"section_count\": \{elf.section_count()},\n"
  result = result + "  \"program_count\": \{elf.program_count()}\n"
  result = result + "}"
  result
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
          let output = match opts.format {
            OutputFormat::Json => format_symbols_json(symbols, opts.show_all)
            OutputFormat::Text | OutputFormat::Dot =>
              format_symbols_text(symbols, opts.show_all)
          }
          write_or_print(output, opts.output)
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Format symbols as text string
fn format_symbols_text(
  symbols : Array[@format.Symbol],
  show_all : Bool,
) -> String {
  let mut result = "Symbols\n=======\n\n"
  for sym in symbols {
    if !show_all && is_local_binding(sym.binding) {
      continue
    }
    let addr_str = format_hex_padded(sym.value)
    let binding_str = binding_to_str(sym.binding)
    let type_str = sym_type_to_str(sym.sym_type)
    result = result + "\{addr_str} \{type_str} \{binding_str} \{sym.name}\n"
  }
  result
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
/// Format symbols as JSON string
fn format_symbols_json(
  symbols : Array[@format.Symbol],
  show_all : Bool,
) -> String {
  let mut result = "[\n"
  let mut first = true
  for sym in symbols {
    if !show_all && is_local_binding(sym.binding) {
      continue
    }
    if !first {
      result = result + ",\n"
    }
    first = false
    let name_str = escape_json_string(sym.name)
    let addr_str = format_hex(sym.value)
    let type_str = sym_type_to_json_str(sym.sym_type)
    let binding_str = binding_to_json_str(sym.binding)
    result = result +
      "  {\"name\": \"\{name_str}\", \"value\": \"\{addr_str}\", \"size\": \{sym.size}, \"type\": \"\{type_str}\", \"binding\": \"\{binding_str}\"}"
  }
  result = result + "\n]"
  result
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
          let output = match opts.format {
            OutputFormat::Dot => @analysis.cfg_to_dot(cfg, name)
            OutputFormat::Json => @analysis.cfg_to_json(cfg)
            OutputFormat::Text => {
              @analysis.print_cfg(cfg)
              ""
            }
          }
          if opts.output != "" && output != "" {
            if write_output_file(opts.output, output) {
              println("Output written to: \{opts.output}")
            } else {
              println("Error: Failed to write output file")
            }
          } else if output != "" {
            println(output)
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
          let output = match opts.format {
            OutputFormat::Dot => @analysis.callgraph_to_dot(cg, "callgraph")
            OutputFormat::Json => @analysis.callgraph_to_json(cg)
            OutputFormat::Text => {
              @analysis.print_call_graph(cg)
              ""
            }
          }
          if opts.output != "" && output != "" {
            if write_output_file(opts.output, output) {
              println("Output written to: \{opts.output}")
            } else {
              println("Error: Failed to write output file")
            }
          }
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Split a selector like `main+0x10` into symbol and signed offset.
fn split_selector(selector : String) -> (String, Int)? {
  for i = 1; i < selector.length(); i = i + 1 {
    let ch = selector[i]
    if ch == '+' || ch == '-' {
      let mut base = ""
      let mut suffix = ""
      for j = 0; j < i; j = j + 1 {
        base = base + selector[j].to_string()
      }
      for j = i + 1; j < selector.length(); j = j + 1 {
        suffix = suffix + selector[j].to_string()
      }
      if base == "" || suffix == "" {
        return None
      }
      match parse_number(suffix) {
        Some(value) =>
          return Some(
            (
              base,
              if ch == '+' {
                value.reinterpret_as_int()
              } else {
                -value.reinterpret_as_int()
              },
            ),
          )
        None => return None
      }
    }
  }
  None
}

///|
/// Resolve a symbol-or-address selector against the loaded image.
fn resolve_run_selector(
  selector : String,
  image : @simulator.ProgramImage,
) -> UInt? {
  match parse_number(selector) {
    Some(addr) => Some(addr)
    None =>
      match split_selector(selector) {
        Some((name, offset)) =>
          match image.resolve_symbol(name) {
            Some(base) =>
              Some(
                if offset >= 0 {
                  base + offset.reinterpret_as_uint()
                } else {
                  base - (-offset).reinterpret_as_uint()
                },
              )
            None => None
          }
        None => image.resolve_symbol(selector)
      }
  }
}

///|
/// Format run output as plain text.
fn format_run_text(state : @simulator.ExecState) -> String {
  let snapshot = @simulator.snapshot(state)
  let mut result = ""
  result = result + "Execution Summary\n"
  result = result + "Entry: \{format_hex(state.image.entry_point)}\n"
  result = result + "PC: \{format_hex(snapshot.pc)}\n"
  result = result + "XLEN: \{state.image.xlen}\n"
  result = result + "Steps: \{snapshot.steps}\n"
  result = result +
    "Stop Reason: \{@simulator.stop_reason_to_string(snapshot.stop_reason)}\n"
  if state.stdout != "" {
    result = result + "\n[stdout]\n" + state.stdout + "\n"
  }
  if state.stderr != "" {
    result = result + "\n[stderr]\n" + state.stderr + "\n"
  }
  result = result + "\nRegisters:\n"
  for i = 0; i < snapshot.registers.length(); i = i + 1 {
    let value = snapshot.registers[i]
    if i == 0 || value != 0U {
      result = result +
        "  \{@decode.reg_name(i.reinterpret_as_uint())}: \{format_hex(value)}\n"
    }
  }
  result
}

///|
/// Format run output as JSON.
fn format_run_json(state : @simulator.ExecState) -> String {
  let snapshot = @simulator.snapshot(state)
  let mut json = "{"
  json = json +
    "\"entry\":\"" +
    escape_json_string(format_hex(state.image.entry_point)) +
    "\""
  json = json + ",\"xlen\":" + state.image.xlen.to_string()
  json = json + ",\"snapshot\":" + @simulator.exec_snapshot_to_json(snapshot)
  json = json + ",\"trace\":" + @simulator.trace_events_to_json(state.trace)
  json = json + "}"
  json
}

///|
/// Execute run command.
fn execute_run(opts : RunOptions) -> Unit {
  match execute_run_result(opts) {
    Success(output) => println(output)
    Failure(err) => println(err)
  }
}

///|
/// Execute run command and return the rendered CLI output.
fn execute_run_result(opts : RunOptions) -> CommandExecResult {
  match @simulator.load(opts.file_path) {
    @simulator.Loaded(initial_state) => {
      let mut state = initial_state
      if opts.entry != "" {
        match resolve_run_selector(opts.entry, state.image) {
          Some(entry_addr) => state = @simulator.with_entry(state, entry_addr)
          None => return Failure("Error: Entry not found: \{opts.entry}")
        }
      }

      let breakpoints : Array[@simulator.Breakpoint] = []
      for selector in opts.breakpoints {
        match resolve_run_selector(selector, state.image) {
          Some(addr) => breakpoints.push(@simulator.breakpoint(addr))
          None => return Failure("Error: Breakpoint not found: \{selector}")
        }
      }

      state = @simulator.with_breakpoints(state, breakpoints)
      let finished = @simulator.run_with_limit(state, opts.max_steps)

      if opts.trace != "" &&
        !write_output_file(
          opts.trace,
          @simulator.trace_events_to_json(finished.trace),
        ) {
        return Failure("Error: Failed to write trace file: \{opts.trace}")
      }

      match opts.format {
        OutputFormat::Json => Success(format_run_json(finished))
        _ => Success(format_run_text(finished))
      }
    }
    @simulator.LoadFailed(err) => Failure("Error: \{err}")
  }
}

///|
/// Execute hex command (decode single hex instruction)
fn execute_hex(opts : HexOptions) -> Unit {
  let code = opts.code
  match parse_number(code) {
    Some(inst_code) => {
      let is_compressed = @decode.is_compressed(inst_code)
      let (inst, length) = if is_compressed {
        let @decode.DecodeResult(inst) = @decode.decode_compressed(
          inst_code & 0xFFFFU,
        )
        (inst, 2)
      } else {
        let @decode.DecodeResult(inst) = @decode.decode(inst_code)
        (inst, 4)
      }
      let disasm_str = @disasm.disassemble(inst)
      let category = inst.category()
      let category_str = category_to_string(category)

      match opts.format {
        OutputFormat::Json => {
          let inst_json = escape_json_string(disasm_str)
          let cat_json = escape_json_string(category_str)
          println("{")
          println("  \"code\": \"\{code}\",")
          println("  \"length\": \{length},")
          println("  \"disassembly\": \"\{inst_json}\",")
          println("  \"category\": \"\{cat_json}\"")
          println("}")
        }
        OutputFormat::Text | OutputFormat::Dot => {
          println("Code: \{code} (\{length} bytes)")
          println("Disassembly: \{disasm_str}")
          println("Category: \{category_str}")
        }
      }
    }
    None => println("Error: Invalid hex code: \{code}")
  }
}

///|
/// Execute asm command (assemble RISC-V assembly)
fn execute_asm(opts : AsmOptions) -> Unit {
  // Read input file
  match read_file_string(opts.input_file) {
    Some(source) => {
      // Assemble the source
      let result = @asm.assemble_with_symbols(source, opts.base_addr)

      // Check for errors
      if result.errors.length() > 0 {
        println("Assembly errors:")
        for err in result.errors {
          println("  Line \{err.line}: \{err.message}")
        }
        return
      }

      // Encode to bytes
      let bytes = @asm.encode_to_bytes(result)

      // Output based on format
      match opts.format {
        AsmOutputFormat::Elf => {
          let elf = @format.assemble_to_elf(bytes, opts.base_addr)
          if opts.output_file == "" {
            // Output to stdout as hex
            println("ELF binary (\{elf.length()} bytes):")
            print_hex_dump(elf)
          } else {
            // Write to file
            match write_file_bytes(opts.output_file, elf) {
              true => println("Written ELF to: \{opts.output_file}")
              false => println("Error: Failed to write to \{opts.output_file}")
            }
          }
        }
        AsmOutputFormat::Hex => {
          let hex = @asm.assemble_to_hex(source)
          if opts.output_file == "" {
            println(hex)
          } else {
            match write_file_string(opts.output_file, hex) {
              true => println("Written hex to: \{opts.output_file}")
              false => println("Error: Failed to write to \{opts.output_file}")
            }
          }
        }
        AsmOutputFormat::Raw =>
          if opts.output_file == "" {
            println("Raw binary (\{bytes.length()} bytes):")
            print_hex_dump(bytes)
          } else {
            match write_file_bytes(opts.output_file, bytes) {
              true => println("Written raw binary to: \{opts.output_file}")
              false => println("Error: Failed to write to \{opts.output_file}")
            }
          }
      }

      // Show summary
      println("")
      println("Assembly summary:")
      println("  Instructions: \{result.instructions.length()}")
      println("  Symbols: \{result.symbols.entries.length()}")
      if result.symbols.entries.length() > 0 {
        println("  Labels:")
        for entry in result.symbols.entries {
          let (name, sym) = entry
          println("    \{name}: \{format_hex(sym.address)}")
        }
      }
    }
    None => println("Error: Cannot read file: \{opts.input_file}")
  }
}

///|
/// Execute workbench command (generate standalone Web frontend page)
fn execute_workbench(opts : WorkbenchCmdOptions) -> Unit {
  match execute_workbench_result(opts) {
    Success(output) => println(output)
    Failure(err) => println(err)
  }
}

///|
/// Execute workbench command and return the rendered CLI output.
fn execute_workbench_result(opts : WorkbenchCmdOptions) -> CommandExecResult {
  let wb_opts = @workbench.create_options(opts.title, opts.max_instructions)

  match @workbench.generate_from_file(opts.file_path, opts.output, wb_opts) {
    Some(err) => Failure("Error: \{err}")
    None =>
      Success(
        "Workbench generated: \{opts.output}\n" +
        "Open the HTML file in a browser to use the disassembly/CFG/trace workbench.",
      )
  }
}

///|
/// Print hex dump of bytes
fn print_hex_dump(bytes : FixedArray[Byte]) -> Unit {
  let mut offset = 0
  while offset < bytes.length() {
    // Print offset
    let offset_str = format_hex(offset.reinterpret_as_uint())
    let padding = "0".repeat(4 - offset_str.length())
    println("\{padding}\{offset_str}: ")

    // Print up to 16 bytes per line
    let mut i = 0
    while i < 16 && offset + i < bytes.length() {
      let b = bytes[offset + i].to_uint()
      let hex = format_hex(b)
      let pad = "0".repeat(2 - hex.length())
      println("\{pad}\{hex} ")
      i = i + 1
    }
    offset = offset + 16
  }
}

///|
/// Read file contents as string
fn read_file_string(path : String) -> String? {
  if !@fs.path_exists(path) {
    return None
  }
  try {
    let bytes = @fs.read_file_to_bytes(path)
    // Convert bytes to string
    let mut result = ""
    for i = 0; i < bytes.length(); i = i + 1 {
      let c = bytes[i].to_int().unsafe_to_char()
      result = result + c.to_string()
    }
    Some(result)
  } catch {
    _ => None
  }
}

///|
/// Write bytes to file
fn write_file_bytes(path : String, data : FixedArray[Byte]) -> Bool {
  let bytes = Bytes::from_array(data)
  try {
    @fs.write_bytes_to_file(path, bytes)
    true
  } catch {
    _ => false
  }
}

///|
/// Write string to file (use existing write_output_file)
fn write_file_string(path : String, data : String) -> Bool {
  write_output_file(path, data)
}

///|
/// Convert instruction category to string
fn category_to_string(cat : @decode.InstructionCategory) -> String {
  match cat {
    @decode.InstructionCategory::Arithmetic => "Arithmetic"
    @decode.InstructionCategory::Logical => "Logical"
    @decode.InstructionCategory::Compare => "Compare"
    @decode.InstructionCategory::Branch => "Branch"
    @decode.InstructionCategory::Jump => "Jump"
    @decode.InstructionCategory::Load => "Load"
    @decode.InstructionCategory::Store => "Store"
    @decode.InstructionCategory::System => "System"
    @decode.InstructionCategory::Float => "Float"
    @decode.InstructionCategory::Vector => "Vector"
    @decode.InstructionCategory::Unknown => "Unknown"
  }
}

///|
/// Execute analyze command (comprehensive analysis)
fn execute_analyze(opts : AnalyzeOptions) -> Unit {
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
          let output = analyze_elf(elf, opts.detailed, opts.format)
          if opts.output != "" {
            if write_output_file(opts.output, output) {
              println("Analysis written to: \{opts.output}")
            } else {
              println("Error: Failed to write output file")
            }
          } else {
            println(output)
          }
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
}

///|
/// Perform comprehensive ELF analysis
fn analyze_elf(
  elf : @format.ElfFile,
  detailed : Bool,
  format : OutputFormat,
) -> String {
  match format {
    OutputFormat::Json => analyze_elf_json(elf, detailed)
    OutputFormat::Text | OutputFormat::Dot => analyze_elf_text(elf, detailed)
  }
}

///|
/// Analyze ELF and return text output
fn analyze_elf_text(elf : @format.ElfFile, detailed : Bool) -> String {
  let mut result = ""
  result = result + "=== ELF Binary Analysis ===\n\n"

  // Basic info
  let class_str = elf_class_str(elf)
  let arch = arch_str(elf)
  result = result + "File Type: \{class_str}\n"
  result = result + "Architecture: \{arch}\n"
  result = result + "Entry Point: \{format_hex(elf.entry_point())}\n"
  result = result + "Sections: \{elf.section_count()}\n"
  result = result + "Program Headers: \{elf.program_count()}\n\n"

  // Symbols
  let symbols = elf.get_symbols()
  let func_symbols = elf.get_function_symbols()
  result = result +
    "Symbols: \{symbols.length()} total, \{func_symbols.length()} functions\n\n"

  // Code analysis
  let code_sections = elf.get_code_sections()
  if code_sections.length() > 0 {
    let (vaddr, code) = code_sections[0]
    let instructions = @analysis.decode_instructions(code, vaddr)
    result = result + "Code Analysis:\n"
    result = result + "  Instructions: \{instructions.length()}\n"

    // CFG analysis
    let cfg = @analysis.build_cfg(instructions, vaddr)
    result = result + "  Basic Blocks: \{cfg.blocks.length()}\n"
    result = result + "  CFG Edges: \{cfg.edges.length()}\n"

    // Call graph
    let cg = @analysis.build_call_graph(instructions, cfg)
    result = result + "  Functions in Call Graph: \{cg.nodes.length()}\n"

    if detailed {
      result = result + "\n--- Detailed Analysis ---\n\n"

      // Instruction categories
      result = result + "Instruction Categories:\n"
      let categories = count_instruction_categories(instructions)
      for item in categories {
        let (cat, count) = item
        result = result + "  \{cat}: \{count}\n"
      }

      // Control flow summary
      result = result + "\nControl Flow:\n"
      result = result + "  Entry Points: \{cfg.entry_points.length()}\n"

      // Call targets
      result = result + "\nCall Targets:\n"
      for node in cg.nodes {
        if node.calls.length() > 0 {
          result = result +
            "  \{format_hex(node.address)} (\{node.name}): \{node.calls.length()} calls\n"
        }
      }
    }
  } else {
    result = result + "No executable code sections found\n"
  }

  result
}

///|
/// Count instruction categories
fn count_instruction_categories(
  instructions : FixedArray[@analysis.DecodedInst],
) -> Array[(String, Int)] {
  let counts : Map[String, Int] = {}
  for inst_info in instructions {
    let cat = inst_info.inst.category()
    let cat_str = category_to_string(cat)
    let current = counts.get_or_default(cat_str, 0)
    counts.set(cat_str, current + 1)
  }
  counts.to_array()
}

///|
/// Analyze ELF and return JSON output
fn analyze_elf_json(elf : @format.ElfFile, detailed : Bool) -> String {
  let mut result = "{\n"
  let class_str = elf_class_str(elf)
  let arch = arch_str(elf)

  result = result + "  \"file_type\": \"\{class_str}\",\n"
  result = result + "  \"architecture\": \"\{arch}\",\n"
  result = result + "  \"entry_point\": \"\{format_hex(elf.entry_point())}\",\n"
  result = result + "  \"section_count\": \{elf.section_count()},\n"
  result = result + "  \"program_count\": \{elf.program_count()},\n"

  let symbols = elf.get_symbols()
  let func_symbols = elf.get_function_symbols()
  result = result + "  \"symbol_count\": \{symbols.length()},\n"
  result = result + "  \"function_count\": \{func_symbols.length()}"

  let code_sections = elf.get_code_sections()
  if code_sections.length() > 0 {
    let (vaddr, code) = code_sections[0]
    let instructions = @analysis.decode_instructions(code, vaddr)
    let cfg = @analysis.build_cfg(instructions, vaddr)
    let cg = @analysis.build_call_graph(instructions, cfg)

    result = result + ",\n  \"analysis\": {\n"
    result = result + "    \"instruction_count\": \{instructions.length()},\n"
    result = result + "    \"basic_blocks\": \{cfg.blocks.length()},\n"
    result = result + "    \"cfg_edges\": \{cfg.edges.length()},\n"
    result = result + "    \"call_graph_nodes\": \{cg.nodes.length()}\n"
    result = result + "  }"
  }

  result = result + "\n}"
  result
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
/// Execute decompile command
fn execute_decompile(opts : DecompileOptions) -> Unit {
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

          // Build symbol map for function name lookup
          let symbol_map : Map[UInt, String] = {}
          let symbols = elf.get_function_symbols()
          for sym in symbols {
            symbol_map[sym.value] = sym.name
          }

          // Extract string literals from .rodata
          let string_map = elf.extract_strings()

          // Determine function address to decompile
          let mut func_addr : UInt = 0U
          let mut func_name = "entry"
          let mut func_size = 0U

          if opts.function != "" {
            // Try to find function by name in symbol table
            let mut found = false
            for sym in symbols {
              if sym.name == opts.function {
                func_addr = sym.value
                func_name = sym.name
                func_size = sym.size
                found = true
                break
              }
            }
            // If not found by name, try parsing as hex address
            if !found {
              match parse_number(opts.function) {
                Some(addr) => {
                  func_addr = addr
                  func_name = "func_" + format_hex(addr)
                  // Find size if in symbol table
                  for sym in symbols {
                    if sym.value == addr {
                      func_size = sym.size
                      func_name = sym.name
                      break
                    }
                  }
                }
                None => {
                  println("Error: Function not found: \{opts.function}")
                  return
                }
              }
            }
          } else {
            // Use entry point
            func_addr = elf.entry_point()
            func_name = "_start"
            // Try to find _start symbol
            for sym in symbols {
              if sym.name == "_start" {
                func_addr = sym.value
                func_size = sym.size
                break
              }
            }
          }

          // Find which code section contains this function
          let mut target_section_idx = -1
          let mut section_base = 0U
          for i = 0; i < code_sections.length(); i = i + 1 {
            let (vaddr, code) = code_sections[i]
            let end_addr = vaddr + code.length().reinterpret_as_uint()
            if func_addr >= vaddr && func_addr < end_addr {
              target_section_idx = i
              section_base = vaddr
              break
            }
          }

          if target_section_idx < 0 {
            println(
              "Error: Function address not in code sections: \{format_hex(func_addr)}",
            )
            return
          }

          // Decode all instructions in the section
          let (section_vaddr, section_code) = code_sections[target_section_idx]
          let all_instructions = @analysis.decode_instructions(
            section_code, section_vaddr,
          )

          // Extract instructions within function bounds
          let func_end = if func_size > 0U {
            func_addr + func_size
          } else {
            // Estimate function end by looking for next function or return
            section_vaddr + section_code.length().reinterpret_as_uint()
          }

          let func_instructions : Array[@analysis.DecodedInst] = []
          for inst in all_instructions {
            if inst.addr >= func_addr && inst.addr < func_end {
              func_instructions.push(inst)
            }
          }

          if func_instructions.length() == 0 {
            println(
              "Error: No instructions found for function at \{format_hex(func_addr)}",
            )
            return
          }

          // Build CFG for function
          let func_cfg = @analysis.build_cfg(
            FixedArray::from_array(func_instructions),
            func_addr,
          )

          // Generate output based on show_code option
          let mut output = ""

          if opts.show_code {
            // Generate pseudo-code with enhanced analysis
            let pseudo_code = @analysis.decompile(
              func_cfg,
              FixedArray::from_array(func_instructions),
              symbol_map,
              string_map,
            )

            output = "// Pseudo-code generated by RISC-V Binary Analyzer\n"
            output = output +
              "// Function: \{func_name} @ \{format_hex(func_addr)}\n\n"
            output = output + "void \{func_name}() {\n"
            output = output + pseudo_code
            output = output + "}\n"
          } else {
            // Generate simplified output (control flow summary)
            output = "// Function: \{func_name} @ \{format_hex(func_addr)}\n\n"
            output = output + "// Basic Blocks: \{func_cfg.blocks.length()}\n"
            output = output + "// Edges: \{func_cfg.edges.length()}\n\n"

            // Show control flow structure
            for block in func_cfg.blocks {
              output = output + "Block \{format_hex(block.start_addr)}:\n"

              // Find outgoing edges
              let outgoing : Array[String] = []
              for edge in func_cfg.edges {
                if edge.from_block == block.start_addr {
                  let edge_desc = match edge.edge_type {
                    @analysis.Jump => "jump"
                    @analysis.BranchTaken => "branch (taken)"
                    @analysis.BranchNotTaken => "branch (not taken)"
                    @analysis.Call => "call"
                    @analysis.Return => "return"
                  }
                  outgoing.push(
                    "  -> \{format_hex(edge.to_block)} (" + edge_desc + ")",
                  )
                }
              }

              for desc in outgoing {
                output = output + desc + "\n"
              }

              if outgoing.length() > 0 {
                output = output + "\n"
              }
            }
          }

          if opts.output != "" {
            if write_output_file(opts.output, output) {
              println("Pseudo-code written to: \{opts.output}")
            } else {
              println("Error: Failed to write output file")
            }
          } else {
            println(output)
          }
        }
        None => println("Error: Failed to parse ELF file")
      }
    }
    None => println("Error: Cannot read file: \{opts.file_path}")
  }
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
    Command::Run(opts) => execute_run(opts)
    Command::Hex(opts) => execute_hex(opts)
    Command::Analyze(opts) => execute_analyze(opts)
    Command::Decompile(opts) => execute_decompile(opts)
    Command::Interactive(opts) => execute_interactive(opts)
    Command::Asm(opts) => execute_asm(opts)
    Command::Workbench(opts) => execute_workbench(opts)
  }
}

///|
/// Main entry point
fn main {
  let args = @sys.get_cli_args()
  // args[0] is program name, skip it
  let cmd_args : Array[String] = if args.length() > 1 {
    let result = []
    for i = 1; i < args.length(); i = i + 1 {
      result.push(args[i])
    }
    result
  } else {
    []
  }
  match parse_args(cmd_args) {
    Some(cmd) => execute(cmd)
    None => {
      println("Error: Invalid arguments")
      println("")
      print_usage()
    }
  }
}

///|
/// Interactive analysis context
struct InteractiveContext {
  elf : @format.ElfFile?
  file_path : String
  instructions : (FixedArray[@analysis.DecodedInst], @analysis.CFG, UInt)?
}

///|
/// Execute interactive analysis mode
fn execute_interactive(opts : InteractiveOptions) -> Unit {
  println("RISC-V Binary Analyzer - Interactive Mode")
  println("Type 'help' for available commands, 'quit' to exit")
  println("")

  let mut ctx = InteractiveContext::{
    elf: None,
    file_path: "",
    instructions: None,
  }

  // Pre-load file if specified
  if opts.file_path != "" {
    match load_file(opts.file_path) {
      Some((elf, data)) => {
        ctx = {
          elf: Some(elf),
          file_path: opts.file_path,
          instructions: Some(data),
        }
        println("Loaded: \{opts.file_path}")
      }
      None => println("Error: Failed to load \{opts.file_path}")
    }
  }

  // If no file loaded, show help and exit
  match ctx.elf {
    Some(elf) => {
      // Show file info and basic analysis
      println(get_elf_info(elf))

      match ctx.instructions {
        Some((instrs, cfg, base)) => {
          println("")
          println("=== Code Analysis ===")
          println("Instructions: \{instrs.length()}")
          println("Basic Blocks: \{cfg.blocks.length()}")
          println("CFG Edges: \{cfg.edges.length()}")
          println("")
          println("First 10 instructions:")
          println(disasm_range(instrs, base, 10))
        }
        None => ()
      }
    }
    None => {
      println("No file loaded.")
      println("Usage: riscv_analyzer interactive <file>")
      println("       riscv_analyzer i <file>")
    }
  }
}

///|
/// Load file and return analysis context
fn load_file(
  file_path : String,
) -> (@format.ElfFile, (FixedArray[@analysis.DecodedInst], @analysis.CFG, UInt))? {
  match read_file_bytes(file_path) {
    Some(bytes) => {
      if !@format.is_elf(bytes) {
        return None
      }
      match @format.parse_elf(bytes) {
        Some(elf) => {
          if !elf.is_riscv() {
            return None
          }
          let code_sections = elf.get_code_sections()
          if code_sections.length() == 0 {
            return None
          }
          let (vaddr, code) = code_sections[0]
          let instructions = @analysis.decode_instructions(code, vaddr)
          let cfg = @analysis.build_cfg(instructions, vaddr)
          Some((elf, (instructions, cfg, vaddr)))
        }
        None => None
      }
    }
    None => None
  }
}

///|
/// Split command line into parts
fn split_command(line : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  for c in line {
    if c == ' ' || c == '\t' {
      if current != "" {
        result.push(current)
        current = ""
      }
    } else {
      current = current + c.to_string()
    }
  }
  if current != "" {
    result.push(current)
  }
  result
}

///|
/// Print interactive help
fn print_interactive_help() -> Unit {
  println("Available commands:")
  println("  load <file>     Load an ELF file for analysis")
  println("  info            Show file information")
  println(
    "  disasm [addr] [count]  Disassemble instructions (default: 10 from start)",
  )
  println("  symbols         Show symbol table")
  println("  cfg [func]      Show control flow graph for function")
  println("  analyze         Perform comprehensive analysis")
  println("  x <addr> [count] Examine instructions at address")
  println("  help            Show this help message")
  println("  quit            Exit interactive mode")
}

///|
/// Get ELF file info as string
fn get_elf_info(elf : @format.ElfFile) -> String {
  let mut result = ""
  result = result + "=== File Information ===\n"
  result = result + "Class: \{elf_class_str(elf)}\n"
  result = result + "Architecture: \{arch_str(elf)}\n"
  result = result + "Entry Point: \{format_hex(elf.entry_point())}\n"
  result = result + "Sections: \{elf.section_count()}\n"
  result = result + "Program Headers: \{elf.program_count()}\n"
  let symbols = elf.get_symbols()
  let funcs = elf.get_function_symbols()
  result = result +
    "Symbols: \{symbols.length()} total, \{funcs.length()} functions\n"
  result
}

///|
/// Format symbols for display
fn format_symbols(elf : @format.ElfFile) -> String {
  let mut result = "=== Symbol Table ===\n"
  let symbols = elf.get_symbols()
  for sym in symbols {
    let type_str = match sym.sym_type {
      @format.SymbolType::Func => "FUNC"
      @format.SymbolType::Object => "OBJ"
      @format.SymbolType::Section => "SEC"
      @format.SymbolType::File => "FILE"
      @format.SymbolType::NoType => "NOTYPE"
      @format.SymbolType::Unknown => "UNKN"
    }
    result = result + "\{format_hex(sym.value)} \{type_str} \{sym.name}\n"
  }
  result
}

///|
/// Disassemble a range of instructions
fn disasm_range(
  instructions : FixedArray[@analysis.DecodedInst],
  start_addr : UInt,
  count : Int,
) -> String {
  let mut result = ""
  let mut printed = 0
  for inst in instructions {
    if printed >= count {
      break
    }
    if inst.addr >= start_addr {
      result = result +
        "\{format_hex(inst.addr)}: \{@disasm.disassemble(inst.inst)}\n"
      printed = printed + 1
    }
  }
  if result == "" {
    result = "No instructions found at address \{format_hex(start_addr)}\n"
  }
  result
}

///|
/// Examine instructions at a specific address
fn examine_at(
  instructions : FixedArray[@analysis.DecodedInst],
  addr : UInt,
  count : Int,
) -> String {
  let mut result = ""
  let mut found = 0
  for inst in instructions {
    if found >= count {
      break
    }
    if inst.addr == addr || (inst.addr >= addr && found == 0) {
      result = result +
        "\{format_hex(inst.addr)}: \{@disasm.disassemble(inst.inst)}\n"
      found = found + 1
    }
  }
  if result == "" {
    result = "No instruction at address \{format_hex(addr)}\n"
  }
  result
}

///|
/// Format CFG for a function
fn format_cfg_for_func(
  cfg : @analysis.CFG,
  instructions : FixedArray[@analysis.DecodedInst],
  func_name : String,
) -> String {
  let mut result = "=== Control Flow Graph ===\n"
  result = result + "Basic Blocks: \{cfg.blocks.length()}\n"
  result = result + "Edges: \{cfg.edges.length()}\n\n"

  // Show first few blocks
  let max_blocks = if cfg.blocks.length() > 10 {
    10
  } else {
    cfg.blocks.length()
  }
  for i = 0; i < max_blocks; i = i + 1 {
    let block = cfg.blocks[i]
    result = result +
      "Block \{i}: [\{format_hex(block.start_addr)} - \{format_hex(block.end_addr)}]\n"
  }
  if cfg.blocks.length() > 10 {
    result = result + "... (\{cfg.blocks.length() - 10} more blocks)\n"
  }
  result
}

///|
/// Parse integer from string
fn parse_int(s : String) -> Int? {
  let mut result = 0
  let mut negative = false
  let mut start = 0
  if s.length() > 0 && s[0] == '-' {
    negative = true
    start = 1
  }
  for i = start; i < s.length(); i = i + 1 {
    let c = s[i]
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - '0'.to_int())
    } else {
      return None
    }
  }
  if negative {
    Some(-result)
  } else {
    Some(result)
  }
}
