///| RISC-V Binary Analyzer CLI

///| A command-line tool for analyzing RISC-V binaries

///|
/// Print usage information
fn print_usage() -> Unit {
  println("RISC-V Binary Analyzer")
  println("Usage: rv-disasm [hex_code]")
  println("")
  println("Examples:")
  println("  rv-disasm 0x123452B7    # Decode a single instruction")
  println("  rv-disasm 305418599     # Decode using decimal")
}

///|
/// Parse a hex string to UInt
fn parse_hex(s : String) -> UInt? {
  if s.length() >= 2 && s[0] == '0' && s[1] == 'x' {
    // Skip "0x" prefix
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
pub fn disasm_hex(hex : String) -> String {
  match parse_number(hex) {
    Some(code) => {
      let @decode.DecodeResult(inst) = @decode.decode(code)
      @disasm.disassemble(inst)
    }
    None => "Error: Invalid instruction code: \{hex}"
  }
}

///|
/// Main entry point - demonstrates disassembly of sample instructions
fn main {
  println("RISC-V Binary Analyzer - Demo")
  println("==============================")
  println("")

  // LUI x5, 0x12345
  let lui_code = "0x123452B7"
  println("\{lui_code}: \{disasm_hex(lui_code)}")

  // ADD x5, x6, x7
  let add_code = "0x007302B3"
  println("\{add_code}: \{disasm_hex(add_code)}")

  // BEQ x5, x6, 0x10
  let beq_code = "0x00628863"
  println("\{beq_code}: \{disasm_hex(beq_code)}")

  // JAL ra, 0x100
  let jal_code = "0x100000EF"
  println("\{jal_code}: \{disasm_hex(jal_code)}")
}
