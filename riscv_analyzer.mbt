///| Main package for RISC-V binary analyzer

///|
/// This package provides a comprehensive RISC-V binary analysis toolkit including:
/// - Instruction decoding (RV32I, RV32M, RV32C)
/// - Disassembly to human-readable assembly
/// - Control Flow Graph (CFG) construction
/// - Call Graph analysis
/// - ELF file parsing

///|
/// Re-export decode module types and functions
pub type DecodeResult = @decode.DecodeResult

///|
pub type Instruction = @decode.Instruction

///|
pub type InstructionCategory = @decode.InstructionCategory

///|
/// Re-export decode functions
pub fn decode(code : UInt) -> DecodeResult {
  @decode.decode(code)
}

///|
pub fn decode_compressed(code16 : UInt) -> DecodeResult {
  @decode.decode_compressed(code16)
}

///|
pub fn is_compressed(code : UInt) -> Bool {
  @decode.is_compressed(code)
}

///|
pub fn instruction_length(code : UInt) -> Int {
  @decode.instruction_length(code)
}

///|
pub fn reg_name(reg : UInt) -> String {
  @decode.reg_name(reg)
}

///|
/// Re-export analysis module types and functions
pub type BasicBlock = @analysis.BasicBlock

///|
pub type EdgeType = @analysis.EdgeType

///|
pub type Edge = @analysis.Edge

///|
pub type CFG = @analysis.CFG

///|
pub type DecodedInst = @analysis.DecodedInst

///|
pub type CallGraphNode = @analysis.CallGraphNode

///|
pub type CallGraph = @analysis.CallGraph

///|
/// Re-export analysis functions
pub fn is_terminator(inst : Instruction) -> Bool {
  @analysis.is_terminator(inst)
}

///|
pub fn get_branch_target(inst : Instruction) -> Int {
  @analysis.get_branch_target(inst)
}

///|
pub fn is_conditional_branch(inst : Instruction) -> Bool {
  @analysis.is_conditional_branch(inst)
}

///|
pub fn is_unconditional_jump(inst : Instruction) -> Bool {
  @analysis.is_unconditional_jump(inst)
}

///|
pub fn is_call(inst : Instruction) -> Bool {
  @analysis.is_call(inst)
}

///|
pub fn is_return(inst : Instruction) -> Bool {
  @analysis.is_return(inst)
}

///|
pub fn decode_instructions(
  bytes : FixedArray[Byte],
  start_addr : UInt,
) -> FixedArray[DecodedInst] {
  @analysis.decode_instructions(bytes, start_addr)
}

///|
pub fn build_cfg(
  instructions : FixedArray[DecodedInst],
  entry_addr : UInt,
) -> CFG {
  @analysis.build_cfg(instructions, entry_addr)
}

///|
pub fn analyze_code(bytes : FixedArray[Byte], start_addr : UInt) -> CFG {
  @analysis.analyze_code(bytes, start_addr)
}

///|
pub fn build_call_graph(
  instructions : FixedArray[DecodedInst],
  cfg : CFG,
) -> CallGraph {
  @analysis.build_call_graph(instructions, cfg)
}

///|
pub fn reachable_functions(cg : CallGraph) -> FixedArray[UInt] {
  @analysis.reachable_functions(cg)
}

///|
/// Re-export disasm module
pub fn disassemble(inst : Instruction) -> String {
  @disasm.disassemble(inst)
}

///|
pub fn disassemble_with_addr(inst : Instruction, addr : UInt) -> String {
  @disasm.disassemble_with_addr(inst, addr)
}

///|
/// Re-export format/elf module types and functions
pub type ElfFile = @format.ElfFile

///|
pub type ElfClass = @format.ElfClass

///|
pub type Symbol = @format.Symbol

///|
pub type SymbolType = @format.SymbolType

///|
pub type SymbolBinding = @format.SymbolBinding

///|
pub fn is_elf(bytes : FixedArray[Byte]) -> Bool {
  @format.is_elf(bytes)
}

///|
pub fn get_elf_class(bytes : FixedArray[Byte]) -> ElfClass {
  @format.get_elf_class(bytes)
}

///|
pub fn parse_elf(bytes : FixedArray[Byte]) -> ElfFile? {
  @format.parse_elf(bytes)
}

///|
/// High-level API: Analyze an ELF file and return CFG
pub fn analyze_elf(bytes : FixedArray[Byte]) -> CFG? {
  match parse_elf(bytes) {
    Some(elf) => {
      if !elf.is_riscv() {
        return None
      }
      let code_sections = elf.get_code_sections()
      if code_sections.length() == 0 {
        return None
      }
      // Analyze the first code section
      let (vaddr, code) = code_sections[0]
      Some(analyze_code(code, vaddr))
    }
    None => None
  }
}

///|
/// High-level API: Disassemble bytes to assembly string
pub fn disassemble_bytes(bytes : FixedArray[Byte], start_addr : UInt) -> String {
  let instructions = decode_instructions(bytes, start_addr)
  let mut result = ""
  for inst_info in instructions {
    let line = disassemble_with_addr(inst_info.inst, inst_info.addr)
    result = result + line + "\n"
  }
  result
}
