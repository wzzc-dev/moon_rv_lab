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
/// Format AMO instruction suffix based on aq/rl bits
fn format_amo_suffix(aq : UInt, rl : UInt) -> String {
  let aq_int = aq.reinterpret_as_int()
  let rl_int = rl.reinterpret_as_int()
  if aq_int == 1 && rl_int == 1 {
    ".aqrl"
  } else if aq_int == 1 {
    ".aq"
  } else if rl_int == 1 {
    ".rl"
  } else {
    ""
  }
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

    // RV32M extension (multiply/divide)
    @decode.MUL(rd, rs1, rs2) =>
      "mul \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.MULH(rd, rs1, rs2) =>
      "mulh \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.MULHSU(rd, rs1, rs2) =>
      "mulhsu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.MULHU(rd, rs1, rs2) =>
      "mulhu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.DIV(rd, rs1, rs2) =>
      "div \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.DIVU(rd, rs1, rs2) =>
      "divu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.REM(rd, rs1, rs2) =>
      "rem \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.REMU(rd, rs1, rs2) =>
      "remu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // RV64I Load/Store 64-bit
    @decode.LD(rd, rs1, imm) =>
      "ld \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.SD(rs1, rs2, imm) =>
      "sd \{@decode.reg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.LWU(rd, rs1, imm) =>
      "lwu \{@decode.reg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"

    // RV64I Immediate arithmetic 32-bit
    @decode.ADDIW(rd, rs1, imm) =>
      "addiw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{format_imm(imm)}"
    @decode.SLLIW(rd, rs1, shamt) =>
      "slliw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.SRLIW(rd, rs1, shamt) =>
      "srliw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.SRAIW(rd, rs1, shamt) =>
      "sraiw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"

    // RV64I Register arithmetic 32-bit
    @decode.ADDW(rd, rs1, rs2) =>
      "addw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SUBW(rd, rs1, rs2) =>
      "subw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SLLW(rd, rs1, rs2) =>
      "sllw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SRLW(rd, rs1, rs2) =>
      "srlw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SRAW(rd, rs1, rs2) =>
      "sraw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // RV64M extension (multiply/divide word)
    @decode.MULW(rd, rs1, rs2) =>
      "mulw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.DIVW(rd, rs1, rs2) =>
      "divw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.DIVUW(rd, rs1, rs2) =>
      "divuw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.REMW(rd, rs1, rs2) =>
      "remw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.REMUW(rd, rs1, rs2) =>
      "remuw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // RV32A Atomic - Load-Reserved/Store-Conditional
    @decode.LR_W(rd, rs1, aq, rl) =>
      "lr.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.SC_W(rd, rs1, rs2, aq, rl) =>
      "sc.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"

    // RV32A Atomic Memory Operations
    @decode.AMOSWAP_W(rd, rs1, rs2, aq, rl) =>
      "amoswap.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOADD_W(rd, rs1, rs2, aq, rl) =>
      "amoadd.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOXOR_W(rd, rs1, rs2, aq, rl) =>
      "amoxor.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOAND_W(rd, rs1, rs2, aq, rl) =>
      "amoand.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOOR_W(rd, rs1, rs2, aq, rl) =>
      "amoor.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMIN_W(rd, rs1, rs2, aq, rl) =>
      "amomin.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMAX_W(rd, rs1, rs2, aq, rl) =>
      "amomax.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMINU_W(rd, rs1, rs2, aq, rl) =>
      "amominu.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMAXU_W(rd, rs1, rs2, aq, rl) =>
      "amomaxu.w\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"

    // RV64A Atomic - Load-Reserved/Store-Conditional (64-bit)
    @decode.LR_D(rd, rs1, aq, rl) =>
      "lr.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.SC_D(rd, rs1, rs2, aq, rl) =>
      "sc.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"

    // RV64A Atomic Memory Operations (64-bit)
    @decode.AMOSWAP_D(rd, rs1, rs2, aq, rl) =>
      "amoswap.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOADD_D(rd, rs1, rs2, aq, rl) =>
      "amoadd.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOXOR_D(rd, rs1, rs2, aq, rl) =>
      "amoxor.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOAND_D(rd, rs1, rs2, aq, rl) =>
      "amoand.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOOR_D(rd, rs1, rs2, aq, rl) =>
      "amoor.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMIN_D(rd, rs1, rs2, aq, rl) =>
      "amomin.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMAX_D(rd, rs1, rs2, aq, rl) =>
      "amomax.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMINU_D(rd, rs1, rs2, aq, rl) =>
      "amominu.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.AMOMAXU_D(rd, rs1, rs2, aq, rl) =>
      "amomaxu.d\{format_amo_suffix(aq, rl)} \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}, (\{@decode.reg_name(rs1)})"

    // Fence instructions
    @decode.FENCE(pred, succ) =>
      "fence \{pred.reinterpret_as_int()}, \{succ.reinterpret_as_int()}"
    @decode.FENCE_I => "fence.i"

    // System instructions
    @decode.ECALL => "ecall"
    @decode.EBREAK => "ebreak"

    // RV32C compressed instructions
    @decode.C_NOP => "c.nop"
    @decode.C_ADDI4SPN(rd, imm) =>
      "c.addi4spn \{@decode.reg_name(rd)}, sp, \{imm}"
    @decode.C_LW(rd, rs1, imm) =>
      "c.lw \{@decode.reg_name(rd)}, \{imm}(\{@decode.reg_name(rs1)})"
    @decode.C_SW(rs2, rs1, imm) =>
      "c.sw \{@decode.reg_name(rs2)}, \{imm}(\{@decode.reg_name(rs1)})"
    @decode.C_ADDI(rd, imm) =>
      "c.addi \{@decode.reg_name(rd)}, \{format_imm(imm)}"
    @decode.C_JAL(imm) => "c.jal \{format_hex_imm(imm)}"
    @decode.C_LI(rd, imm) => "c.li \{@decode.reg_name(rd)}, \{format_imm(imm)}"
    @decode.C_ADDI16SP(imm) => "c.addi16sp \{format_imm(imm)}"
    @decode.C_LUI(rd, imm) =>
      "c.lui \{@decode.reg_name(rd)}, \{format_hex_imm(imm)}"
    @decode.C_SRLI(rd, shamt) =>
      "c.srli \{@decode.reg_name(rd)}, \{shamt.reinterpret_as_int()}"
    @decode.C_SRAI(rd, shamt) =>
      "c.srai \{@decode.reg_name(rd)}, \{shamt.reinterpret_as_int()}"
    @decode.C_ANDI(rd, imm) =>
      "c.andi \{@decode.reg_name(rd)}, \{format_imm(imm)}"
    @decode.C_SUB(rd, rs2) =>
      "c.sub \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}"
    @decode.C_XOR(rd, rs2) =>
      "c.xor \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}"
    @decode.C_OR(rd, rs2) =>
      "c.or \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}"
    @decode.C_AND(rd, rs2) =>
      "c.and \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}"
    @decode.C_J(imm) => "c.j \{format_hex_imm(imm)}"
    @decode.C_BEQZ(rs1, imm) =>
      "c.beqz \{@decode.reg_name(rs1)}, \{format_hex_imm(imm)}"
    @decode.C_BNEZ(rs1, imm) =>
      "c.bnez \{@decode.reg_name(rs1)}, \{format_hex_imm(imm)}"
    @decode.C_SLLI(rd, shamt) =>
      "c.slli \{@decode.reg_name(rd)}, \{shamt.reinterpret_as_int()}"
    @decode.C_LWSP(rd, imm) => "c.lwsp \{@decode.reg_name(rd)}, \{imm}(sp)"
    @decode.C_JR(rs1) => "c.jr \{@decode.reg_name(rs1)}"
    @decode.C_MV(rd, rs2) =>
      "c.mv \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}"
    @decode.C_EBREAK => "c.ebreak"
    @decode.C_JALR(rs1) => "c.jalr \{@decode.reg_name(rs1)}"
    @decode.C_ADD(rd, rs2) =>
      "c.add \{@decode.reg_name(rd)}, \{@decode.reg_name(rs2)}"
    @decode.C_SWSP(rs2, imm) => "c.swsp \{@decode.reg_name(rs2)}, \{imm}(sp)"

    // Invalid instruction
    @decode.Invalid(code) => ".invalid \{format_hex_uint(code)}"
  }
}

///|
/// Disassemble with address prefix
pub fn disassemble_with_addr(inst : @decode.Instruction, addr : UInt) -> String {
  "\{format_hex_uint(addr)}: \{disassemble(inst)}"
}
