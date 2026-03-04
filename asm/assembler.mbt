///| RISC-V Two-Pass Assembler

///|
/// Assembler state for two-pass assembly
struct Assembler {
  symbols : SymbolTable
  current_address : UInt
  instructions : Array[AssembledInst]
  start_address : UInt
}

///|
/// Create a new assembler
fn Assembler::new(start_address : UInt) -> Assembler {
  {
    symbols: SymbolTable::new(),
    current_address: start_address,
    instructions: [],
    start_address,
  }
}

///|
/// Pass 1: Collect labels and calculate addresses
fn pass1(state : Assembler, statements : Array[AsmStatement]) -> Assembler {
  let mut current_addr = state.current_address
  let mut symbols = state.symbols

  for stmt in statements {
    match stmt {
      AsmStatement::Label(name) =>
        // Add label to symbol table
        symbols = symbols.add(name, current_addr, false)
      AsmStatement::Instruction(inst) => {
        // Advance address by instruction size
        let size = instruction_size(inst)
        current_addr = current_addr + size.reinterpret_as_uint()
      }
      AsmStatement::Directive(name, _args) =>
        // Handle directives
        match name {
          ".text" | ".data" | ".bss" => continue
          ".word" | ".half" | ".byte" => {
            // Data directives affect address
            let size = match name {
              ".word" => 4
              ".half" => 2
              ".byte" => 1
              _ => 0
            }
            current_addr = current_addr + size.reinterpret_as_uint()
          }
          _ => continue
        }
      AsmStatement::Data(bytes) =>
        current_addr = current_addr + bytes.length().reinterpret_as_uint()
      AsmStatement::Empty => continue
      AsmStatement::Error(_) => continue
    }
  }

  {
    symbols,
    current_address: current_addr,
    instructions: state.instructions,
    start_address: state.start_address,
  }
}

///|
/// Pass 2: Generate code and resolve symbols
fn pass2(state : Assembler, statements : Array[AsmStatement]) -> Assembler {
  let mut current_addr = state.start_address
  let instructions : Array[AssembledInst] = []

  for stmt in statements {
    match stmt {
      AsmStatement::Label(_) =>
        // Already processed in pass 1
        continue
      AsmStatement::Instruction(inst) => {
        // Add instruction with current address
        let size = instruction_size(inst)
        instructions.push({ instruction: inst, address: current_addr, size })
        current_addr = current_addr + size.reinterpret_as_uint()
      }
      AsmStatement::Directive(name, _args) =>
        // Handle directives that generate data
        match name {
          ".text" | ".data" | ".bss" => continue
          _ => continue
        }
      AsmStatement::Data(_bytes) =>
        // Data bytes will be handled separately
        continue
      AsmStatement::Empty => continue
      AsmStatement::Error(_) => continue
    }
  }

  {
    symbols: state.symbols,
    current_address: current_addr,
    instructions,
    start_address: state.start_address,
  }
}

///|
/// Get instruction size (2 for compressed, 4 for regular)
pub fn instruction_size(inst : @decode.Instruction) -> Int {
  match inst {
    // Compressed instructions (16-bit)
    @decode.C_NOP
    | @decode.C_EBREAK
    | @decode.C_ADDI(_, _)
    | @decode.C_LI(_, _)
    | @decode.C_LUI(_, _)
    | @decode.C_ADDI16SP(_)
    | @decode.C_J(_)
    | @decode.C_JAL(_)
    | @decode.C_JR(_)
    | @decode.C_JALR(_)
    | @decode.C_BEQZ(_, _)
    | @decode.C_BNEZ(_, _)
    | @decode.C_MV(_, _)
    | @decode.C_ADD(_, _)
    | @decode.C_AND(_, _)
    | @decode.C_OR(_, _)
    | @decode.C_XOR(_, _)
    | @decode.C_SUB(_, _)
    | @decode.C_LW(_, _, _)
    | @decode.C_SW(_, _, _) => 2
    // Regular instructions (32-bit)
    _ => 4
  }
}

///|
/// Assemble source code with two-pass algorithm
pub fn assemble_with_symbols(
  input : String,
  start_address : UInt,
) -> AssemblyResult {
  let statements = parse(input)
  let state = Assembler::new(start_address)

  // Pass 1: Collect labels
  let state1 = pass1(state, statements)

  // Pass 2: Generate code
  let state2 = pass2(state1, statements)

  {
    instructions: state2.instructions,
    symbols: state2.symbols,
    errors: [],
    start_address: state2.start_address,
  }
}

///|
/// Encode assembled instructions to bytes
pub fn encode_to_bytes(result : AssemblyResult) -> FixedArray[Byte] {
  let mut total_size = 0
  for inst in result.instructions {
    total_size = total_size + inst.size
  }

  let bytes = FixedArray::make(total_size, b'\x00')
  let mut offset = 0

  for assembled in result.instructions {
    let encoded = @encode.encode(assembled.instruction)
    let code = encoded.code

    if assembled.size == 4 {
      // 32-bit instruction, little-endian
      bytes[offset] = (code & 0xFFU).to_byte()
      bytes[offset + 1] = ((code >> 8) & 0xFFU).to_byte()
      bytes[offset + 2] = ((code >> 16) & 0xFFU).to_byte()
      bytes[offset + 3] = ((code >> 24) & 0xFFU).to_byte()
    } else {
      // 16-bit compressed instruction, little-endian
      bytes[offset] = (code & 0xFFU).to_byte()
      bytes[offset + 1] = ((code >> 8) & 0xFFU).to_byte()
    }
    offset = offset + assembled.size
  }

  bytes
}

///|
/// Assemble source code and return raw bytes
pub fn assemble_to_bytes(input : String) -> FixedArray[Byte] {
  let result = assemble_with_symbols(input, 0U)
  encode_to_bytes(result)
}

///|
/// Assemble and return hex string
pub fn assemble_to_hex(input : String) -> String {
  let bytes = assemble_to_bytes(input)
  let mut hex = ""
  for i = 0; i < bytes.length(); i = i + 1 {
    let b = bytes[i].to_uint()
    hex = hex + byte_to_hex(b)
    if i < bytes.length() - 1 {
      hex = hex + " "
    }
  }
  hex
}

///|
/// Convert byte to hex string
fn byte_to_hex(b : UInt) -> String {
  let high = (b >> 4) & 0xFU
  let low = b & 0xFU
  nibble_to_hex(high) + nibble_to_hex(low)
}

///|
/// Convert nibble to hex character
fn nibble_to_hex(n : UInt) -> String {
  match n {
    0U => "0"
    1U => "1"
    2U => "2"
    3U => "3"
    4U => "4"
    5U => "5"
    6U => "6"
    7U => "7"
    8U => "8"
    9U => "9"
    10U => "a"
    11U => "b"
    12U => "c"
    13U => "d"
    14U => "e"
    15U => "f"
    _ => "0"
  }
}
