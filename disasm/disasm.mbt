///| RISC-V disassembler engine

///| Converts decoded instructions to assembly text

///|
/// Format an immediate value for display
fn format_imm(imm : Int) -> String {
  imm.to_string()
}

///|
/// Convert a single hex digit to character
fn hex_digit(d : Int) -> Char {
  if d < 10 {
    (d + 48).unsafe_to_char() // '0' is 48
  } else {
    (d + 87).unsafe_to_char() // 'a' is 97, so d - 10 + 97 = d + 87
  }
}

///|
/// Convert Int to hex string (without 0x prefix)
fn int_to_hex(value : Int) -> String {
  if value == 0 {
    "0"
  } else if value < 0 {
    let abs_val = -value
    let mut result = ""
    let mut v = abs_val
    while v > 0 {
      let digit = v % 16
      result = hex_digit(digit).to_string() + result
      v = v / 16
    }
    result
  } else {
    let mut result = ""
    let mut v = value
    while v > 0 {
      let digit = v % 16
      result = hex_digit(digit).to_string() + result
      v = v / 16
    }
    result
  }
}

///|
/// Convert UInt to hex string (without 0x prefix)
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut v = value
    while v > 0U {
      let digit = (v % 16U).reinterpret_as_int()
      result = hex_digit(digit).to_string() + result
      v = v / 16U
    }
    result
  }
}

///|
/// Format a hex immediate value
fn format_hex_imm(imm : Int) -> String {
  if imm < 0 {
    "-0x" + int_to_hex(-imm)
  } else {
    "0x" + int_to_hex(imm)
  }
}

///|
/// Format a UInt as hex
fn format_hex_uint(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
/// Disassemble a single instruction to string
pub fn disassemble(inst : @decode.Instruction) -> String {
  match inst {
    // U-type instructions
    @decode.LUI(rd, imm) =>
      "lui \{@decode.reg_name(rd)}, \{format_hex_imm(imm >> 12)}"
    @decode.AUIPC(rd, imm) =>
      "auipc \{@decode.reg_name(rd)}, \{format_hex_imm(imm >> 12)}"

    // J-type instructions
    @decode.JAL(rd, imm) =>
      "jal \{@decode.reg_name(rd)}, \{format_hex_imm(imm)}"

    // I-type instructions
    @decode.JALR(rd, rs1, imm) =>
      "jalr \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"

    // Branch instructions
    @decode.BEQ(rs1, rs2, imm) =>
      "beq \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}, \{format_hex_imm(imm)}"
    @decode.BNE(rs1, rs2, imm) =>
      "bne \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}, \{format_hex_imm(imm)}"
    @decode.BLT(rs1, rs2, imm) =>
      "blt \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}, \{format_hex_imm(imm)}"
    @decode.BGE(rs1, rs2, imm) =>
      "bge \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}, \{format_hex_imm(imm)}"
    @decode.BLTU(rs1, rs2, imm) =>
      "bltu \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}, \{format_hex_imm(imm)}"
    @decode.BGEU(rs1, rs2, imm) =>
      "bgeu \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}, \{format_hex_imm(imm)}"

    // Load instructions
    @decode.LB(rd, rs1, imm) =>
      "lb \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.LH(rd, rs1, imm) =>
      "lh \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.LW(rd, rs1, imm) =>
      "lw \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.LBU(rd, rs1, imm) =>
      "lbu \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.LHU(rd, rs1, imm) =>
      "lhu \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"

    // Store instructions
    @decode.SB(rs1, rs2, imm) =>
      "sb \{@decode.reg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.SH(rs1, rs2, imm) =>
      "sh \{@decode.reg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.SW(rs1, rs2, imm) =>
      "sw \{@decode.reg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"

    // Immediate arithmetic
    @decode.ADDI(rd, rs1, imm) =>
      "addi \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.SLTI(rd, rs1, imm) =>
      "slti \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.SLTIU(rd, rs1, imm) =>
      "sltiu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.XORI(rd, rs1, imm) =>
      "xori \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.ORI(rd, rs1, imm) =>
      "ori \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.ANDI(rd, rs1, imm) =>
      "andi \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.SLLI(rd, rs1, shamt) =>
      "slli \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.SRLI(rd, rs1, shamt) =>
      "srli \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.SRAI(rd, rs1, shamt) =>
      "srai \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"

    // Register arithmetic
    @decode.ADD(rd, rs1, rs2) =>
      "add \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SUB(rd, rs1, rs2) =>
      "sub \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SLL(rd, rs1, rs2) =>
      "sll \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SLT(rd, rs1, rs2) =>
      "slt \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SLTU(rd, rs1, rs2) =>
      "sltu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.XOR(rd, rs1, rs2) =>
      "xor \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SRL(rd, rs1, rs2) =>
      "srl \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SRA(rd, rs1, rs2) =>
      "sra \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.OR(rd, rs1, rs2) =>
      "or \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.AND(rd, rs1, rs2) =>
      "and \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Fence instructions
    @decode.FENCE(pred, succ) =>
      "fence \{pred.reinterpret_as_int()}, \{succ.reinterpret_as_int()}"
    @decode.FENCE_I => "fence.i"

    // System instructions
    @decode.ECALL => "ecall"
    @decode.EBREAK => "ebreak"

    // Invalid instruction
    @decode.Invalid(code) => ".invalid \{format_hex_uint(code)}"
  }
}

///|
/// Disassemble with address prefix
pub fn disassemble_with_addr(inst : @decode.Instruction, addr : UInt) -> String {
  "\{format_hex_uint(addr)}: \{disassemble(inst)}"
}
