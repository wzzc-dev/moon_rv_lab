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

    // Zicsr instructions
    @decode.CSRRW(rd, csr, rs1) =>
      "csrrw \{@decode.reg_name(rd)}, \{csr.reinterpret_as_int()}, \{@decode.reg_name(rs1)}"
    @decode.CSRRS(rd, csr, rs1) =>
      "csrrs \{@decode.reg_name(rd)}, \{csr.reinterpret_as_int()}, \{@decode.reg_name(rs1)}"
    @decode.CSRRC(rd, csr, rs1) =>
      "csrrc \{@decode.reg_name(rd)}, \{csr.reinterpret_as_int()}, \{@decode.reg_name(rs1)}"
    @decode.CSRRWI(rd, csr, uimm) =>
      "csrrwi \{@decode.reg_name(rd)}, \{csr.reinterpret_as_int()}, \{uimm.reinterpret_as_int()}"
    @decode.CSRRSI(rd, csr, uimm) =>
      "csrrsi \{@decode.reg_name(rd)}, \{csr.reinterpret_as_int()}, \{uimm.reinterpret_as_int()}"
    @decode.CSRRCI(rd, csr, uimm) =>
      "csrrci \{@decode.reg_name(rd)}, \{csr.reinterpret_as_int()}, \{uimm.reinterpret_as_int()}"

    // Zba extension (address generation)
    @decode.SH1ADD(rd, rs1, rs2) =>
      "sh1add \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SH2ADD(rd, rs1, rs2) =>
      "sh2add \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SH3ADD(rd, rs1, rs2) =>
      "sh3add \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Zba RV64 extension (address generation 64-bit)
    @decode.SH1ADD_UW(rd, rs1, rs2) =>
      "sh1add.uw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SH2ADD_UW(rd, rs1, rs2) =>
      "sh2add.uw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SH3ADD_UW(rd, rs1, rs2) =>
      "sh3add.uw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.ADD_UW(rd, rs1, rs2) =>
      "add.uw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.SLLI_UW(rd, rs1, shamt) =>
      "slli.uw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"

    // Zbb extension (basic bit manipulation)
    @decode.ANDN(rd, rs1, rs2) =>
      "andn \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.ORN(rd, rs1, rs2) =>
      "orn \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.XNOR(rd, rs1, rs2) =>
      "xnor \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.CLZ(rd, rs1) =>
      "clz \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.CTZ(rd, rs1) =>
      "ctz \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.CPOP(rd, rs1) =>
      "cpop \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.SEXT_B(rd, rs1) =>
      "sext.b \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.SEXT_H(rd, rs1) =>
      "sext.h \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.ZEXT_H(rd, rs1) =>
      "zext.h \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.MAX(rd, rs1, rs2) =>
      "max \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.MAXU(rd, rs1, rs2) =>
      "maxu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.MIN(rd, rs1, rs2) =>
      "min \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.MINU(rd, rs1, rs2) =>
      "minu \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.ROL(rd, rs1, rs2) =>
      "rol \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.ROR(rd, rs1, rs2) =>
      "ror \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.RORI(rd, rs1, shamt) =>
      "rori \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.ORC_B(rd, rs1) =>
      "orc.b \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.REV8(rd, rs1) =>
      "rev8 \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"

    // Zbb RV64 extension (basic bit manipulation 64-bit)
    @decode.CLZW(rd, rs1) =>
      "clzw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.CTZW(rd, rs1) =>
      "ctzw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.CPOPW(rd, rs1) =>
      "cpopw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.ROLW(rd, rs1, rs2) =>
      "rolw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.RORW(rd, rs1, rs2) =>
      "rorw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.RORIW(rd, rs1, shamt) =>
      "roriw \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"

    // Zbc extension (carry-less multiplication)
    @decode.CLMUL(rd, rs1, rs2) =>
      "clmul \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.CLMULH(rd, rs1, rs2) =>
      "clmulh \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.CLMULR(rd, rs1, rs2) =>
      "clmulr \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Zbs extension (single bit instructions)
    @decode.BCLR(rd, rs1, rs2) =>
      "bclr \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.BCLRI(rd, rs1, shamt) =>
      "bclri \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.BEXT(rd, rs1, rs2) =>
      "bext \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.BEXTI(rd, rs1, shamt) =>
      "bexti \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.BINV(rd, rs1, rs2) =>
      "binv \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.BINVI(rd, rs1, shamt) =>
      "binvi \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"
    @decode.BSET(rd, rs1, rs2) =>
      "bset \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.BSETI(rd, rs1, shamt) =>
      "bseti \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{shamt.reinterpret_as_int()}"

    // RV32F extension (single-precision floating-point)
    @decode.FLW(rd, rs1, imm) =>
      "flw \{@decode.freg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.FSW(rs1, rs2, imm) =>
      "fsw \{@decode.freg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.FADD_S(rd, rs1, rs2) =>
      "fadd.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSUB_S(rd, rs1, rs2) =>
      "fsub.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMUL_S(rd, rs1, rs2) =>
      "fmul.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FDIV_S(rd, rs1, rs2) =>
      "fdiv.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSQRT_S(rd, rs1) =>
      "fsqrt.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FSGNJ_S(rd, rs1, rs2) =>
      "fsgnj.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSGNJN_S(rd, rs1, rs2) =>
      "fsgnjn.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSGNJX_S(rd, rs1, rs2) =>
      "fsgnjx.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMIN_S(rd, rs1, rs2) =>
      "fmin.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMAX_S(rd, rs1, rs2) =>
      "fmax.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FCVT_W_S(rd, rs1, rm) =>
      "fcvt.w.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_WU_S(rd, rs1, rm) =>
      "fcvt.wu.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FMV_X_W(rd, rs1) =>
      "fmv.x.w \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FEQ_S(rd, rs1, rs2) =>
      "feq.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FLT_S(rd, rs1, rs2) =>
      "flt.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FLE_S(rd, rs1, rs2) =>
      "fle.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FCLASS_S(rd, rs1) =>
      "fclass.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_S_W(rd, rs1, rm) =>
      "fcvt.s.w \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FCVT_S_WU(rd, rs1, rm) =>
      "fcvt.s.wu \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FMV_W_X(rd, rs1) =>
      "fmv.w.x \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    // RV64F
    @decode.FCVT_L_S(rd, rs1, rm) =>
      "fcvt.l.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_LU_S(rd, rs1, rm) =>
      "fcvt.lu.s \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_S_L(rd, rs1, rm) =>
      "fcvt.s.l \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FCVT_S_LU(rd, rs1, rm) =>
      "fcvt.s.lu \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"

    // RV32D extension (double-precision floating-point)
    @decode.FLD(rd, rs1, imm) =>
      "fld \{@decode.freg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.FSD(rs1, rs2, imm) =>
      "fsd \{@decode.freg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.FADD_D(rd, rs1, rs2) =>
      "fadd.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSUB_D(rd, rs1, rs2) =>
      "fsub.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMUL_D(rd, rs1, rs2) =>
      "fmul.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FDIV_D(rd, rs1, rs2) =>
      "fdiv.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSQRT_D(rd, rs1) =>
      "fsqrt.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FSGNJ_D(rd, rs1, rs2) =>
      "fsgnj.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSGNJN_D(rd, rs1, rs2) =>
      "fsgnjn.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSGNJX_D(rd, rs1, rs2) =>
      "fsgnjx.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMIN_D(rd, rs1, rs2) =>
      "fmin.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMAX_D(rd, rs1, rs2) =>
      "fmax.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FCVT_S_D(rd, rs1, rm) =>
      "fcvt.s.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_D_S(rd, rs1, rm) =>
      "fcvt.d.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FEQ_D(rd, rs1, rs2) =>
      "feq.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FLT_D(rd, rs1, rs2) =>
      "flt.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FLE_D(rd, rs1, rs2) =>
      "fle.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FCLASS_D(rd, rs1) =>
      "fclass.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_W_D(rd, rs1, rm) =>
      "fcvt.w.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_WU_D(rd, rs1, rm) =>
      "fcvt.wu.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_D_W(rd, rs1, rm) =>
      "fcvt.d.w \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FCVT_D_WU(rd, rs1, rm) =>
      "fcvt.d.wu \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    // RV64D
    @decode.FCVT_L_D(rd, rs1, rm) =>
      "fcvt.l.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_LU_D(rd, rs1, rm) =>
      "fcvt.lu.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FMV_X_D(rd, rs1) =>
      "fmv.x.d \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_D_L(rd, rs1, rm) =>
      "fcvt.d.l \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FCVT_D_LU(rd, rs1, rm) =>
      "fcvt.d.lu \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FMV_D_X(rd, rs1) =>
      "fmv.d.x \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"

    // RV32Q extension (quad-precision floating-point)
    @decode.FLQ(rd, rs1, imm) =>
      "flq \{@decode.freg_name(rd)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.FSQ(rs1, rs2, imm) =>
      "fsq \{@decode.freg_name(rs2)}, \{format_imm(imm)}(\{@decode.reg_name(rs1)})"
    @decode.FADD_Q(rd, rs1, rs2) =>
      "fadd.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSUB_Q(rd, rs1, rs2) =>
      "fsub.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMUL_Q(rd, rs1, rs2) =>
      "fmul.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FDIV_Q(rd, rs1, rs2) =>
      "fdiv.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSQRT_Q(rd, rs1) =>
      "fsqrt.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FSGNJ_Q(rd, rs1, rs2) =>
      "fsgnj.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSGNJN_Q(rd, rs1, rs2) =>
      "fsgnjn.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FSGNJX_Q(rd, rs1, rs2) =>
      "fsgnjx.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMIN_Q(rd, rs1, rs2) =>
      "fmin.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FMAX_Q(rd, rs1, rs2) =>
      "fmax.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FCVT_Q_S(rd, rs1, rm) =>
      "fcvt.q.s \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_S_Q(rd, rs1, rm) =>
      "fcvt.s.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_Q_D(rd, rs1, rm) =>
      "fcvt.q.d \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_D_Q(rd, rs1, rm) =>
      "fcvt.d.q \{@decode.freg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FEQ_Q(rd, rs1, rs2) =>
      "feq.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FLT_Q(rd, rs1, rs2) =>
      "flt.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FLE_Q(rd, rs1, rs2) =>
      "fle.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.FCLASS_Q(rd, rs1) =>
      "fclass.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_W_Q(rd, rs1, rm) =>
      "fcvt.w.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_WU_Q(rd, rs1, rm) =>
      "fcvt.wu.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_Q_W(rd, rs1, rm) =>
      "fcvt.q.w \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FCVT_Q_WU(rd, rs1, rm) =>
      "fcvt.q.wu \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FMV_X_Q(rd, rs1) =>
      "fmv.x.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FMV_Q_X(rd, rs1) =>
      "fmv.q.x \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    // RV64Q
    @decode.FCVT_L_Q(rd, rs1, rm) =>
      "fcvt.l.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_LU_Q(rd, rs1, rm) =>
      "fcvt.lu.q \{@decode.reg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.FCVT_Q_L(rd, rs1, rm) =>
      "fcvt.q.l \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.FCVT_Q_LU(rd, rs1, rm) =>
      "fcvt.q.lu \{@decode.freg_name(rd)}, \{@decode.reg_name(rs1)}"

    // Zcf/Zcd compressed floating point (also used for RV64C integer load/store)
    // In RV64C: C_FLD/C_FSD are C.LD/C.SD (64-bit integer load/store)
    // In RV32DC/RV64DC: C_FLD/C_FSD are floating-point load/store
    @decode.C_FLD(rd, rs1, imm) =>
      "c.ld \{@decode.creg_name(rd)}, \{format_imm(imm.reinterpret_as_int())}(\{@decode.reg_name(rs1)})"
    @decode.C_FSD(rs1, rs2, imm) =>
      "c.sd \{@decode.creg_name(rs2)}, \{format_imm(imm.reinterpret_as_int())}(\{@decode.reg_name(rs1)})"
    @decode.C_FLW(rd, rs1, imm) =>
      "c.flw \{@decode.creg_name(rd)}, \{format_imm(imm.reinterpret_as_int())}(\{@decode.reg_name(rs1)})"
    @decode.C_FSW(rs1, rs2, imm) =>
      "c.fsw \{@decode.creg_name(rs2)}, \{format_imm(imm.reinterpret_as_int())}(\{@decode.reg_name(rs1)})"
    // In RV64C: C_FLDSP/C_FSDSP are C.LDSP/C.SDSP (64-bit integer load/store from SP)
    @decode.C_FLDSP(rd, imm) =>
      "c.ldsp \{@decode.reg_name(rd)}, \{format_imm(imm.reinterpret_as_int())}(sp)"
    @decode.C_FSDSP(rs2, imm) =>
      "c.sdsp \{@decode.reg_name(rs2)}, \{format_imm(imm.reinterpret_as_int())}(sp)"
    @decode.C_FLWSP(rd, imm) =>
      "c.flwsp \{@decode.freg_name(rd)}, \{format_imm(imm.reinterpret_as_int())}(sp)"
    @decode.C_FSWSP(rs2, imm) =>
      "c.fswsp \{@decode.freg_name(rs2)}, \{format_imm(imm.reinterpret_as_int())}(sp)"

    // RVV Vector Extension
    // Configuration
    @decode.VSETVLI(rd, rs1, avl) =>
      "vsetvli \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, avl=\{@decode.reg_name(avl)}"
    @decode.VSETIVLI(rd, uimm, avl) =>
      "vsetivli \{@decode.reg_name(rd)}, \{uimm}, avl=\{@decode.reg_name(avl)}"
    @decode.VSETVL(rd, rs1, rs2) =>
      "vsetvl \{@decode.reg_name(rd)}, \{@decode.reg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector loads
    @decode.VLE8_V(rd, rs1, vm) =>
      "vle8.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VLE16_V(rd, rs1, vm) =>
      "vle16.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VLE32_V(rd, rs1, vm) =>
      "vle32.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VLE64_V(rd, rs1, vm) =>
      "vle64.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VLSE8_V(rd, rs1, rs2, vm) =>
      "vlse8.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs2)}"
    @decode.VLSE16_V(rd, rs1, rs2, vm) =>
      "vlse16.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs2)}"
    @decode.VLSE32_V(rd, rs1, rs2, vm) =>
      "vlse32.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs2)}"
    @decode.VLSE64_V(rd, rs1, rs2, vm) =>
      "vlse64.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs2)}"

    // Vector stores
    @decode.VSE8_V(rs2, rs1, vm) =>
      "vse8.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VSE16_V(rs2, rs1, vm) =>
      "vse16.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VSE32_V(rs2, rs1, vm) =>
      "vse32.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VSE64_V(rs2, rs1, vm) =>
      "vse64.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VSSE8_V(rs2, rs1, rs3, vm) =>
      "vsse8.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs3)}"
    @decode.VSSE16_V(rs2, rs1, rs3, vm) =>
      "vsse16.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs3)}"
    @decode.VSSE32_V(rs2, rs1, rs3, vm) =>
      "vsse32.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs3)}"
    @decode.VSSE64_V(rs2, rs1, rs3, vm) =>
      "vsse64.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)}), \{@decode.reg_name(rs3)}"

    // Vector indexed load
    @decode.VLUXEI8_V(rd, rs1, vs2, vm) =>
      "vluxei8.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VLUXEI16_V(rd, rs1, vs2, vm) =>
      "vluxei16.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VLUXEI32_V(rd, rs1, vs2, vm) =>
      "vluxei32.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VLUXEI64_V(rd, rs1, vs2, vm) =>
      "vluxei64.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"

    // Vector indexed store
    @decode.VSUXEI8_V(vs3, rs1, vs2, vm) =>
      "vsuxei8.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VSUXEI16_V(vs3, rs1, vs2, vm) =>
      "vsuxei16.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VSUXEI32_V(vs3, rs1, vs2, vm) =>
      "vsuxei32.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VSUXEI64_V(vs3, rs1, vs2, vm) =>
      "vsuxei64.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"

    // Vector integer arithmetic
    @decode.VADD_VV(rd, rs1, rs2, vm) =>
      "vadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VADD_VX(rd, rs1, rs2, vm) =>
      "vadd.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSUB_VV(rd, rs1, rs2, vm) =>
      "vsub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VRSUB_VX(rd, rs1, rs2, vm) =>
      "vrsub.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VAND_VV(rd, rs1, rs2, vm) =>
      "vand.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VOR_VV(rd, rs1, rs2, vm) =>
      "vor.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VXOR_VV(rd, rs1, rs2, vm) =>
      "vxor.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSLL_VV(rd, rs1, rs2, vm) =>
      "vsll.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSRL_VV(rd, rs1, rs2, vm) =>
      "vsrl.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSRA_VV(rd, rs1, rs2, vm) =>
      "vsra.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector integer multiply/divide
    @decode.VMUL_VV(rd, rs1, rs2, vm) =>
      "vmul.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMULH_VV(rd, rs1, rs2, vm) =>
      "vmulh.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMULHU_VV(rd, rs1, rs2, vm) =>
      "vmulhu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMULHSU_VV(rd, rs1, rs2, vm) =>
      "vmulhsu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VDIV_VV(rd, rs1, rs2, vm) =>
      "vdiv.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VDIVU_VV(rd, rs1, rs2, vm) =>
      "vdivu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREM_VV(rd, rs1, rs2, vm) =>
      "vrem.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREMU_VV(rd, rs1, rs2, vm) =>
      "vremu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector min/max
    @decode.VMINU_VV(rd, rs1, rs2, vm) =>
      "vminu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMIN_VV(rd, rs1, rs2, vm) =>
      "vmin.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMAXU_VV(rd, rs1, rs2, vm) =>
      "vmaxu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMAX_VV(rd, rs1, rs2, vm) =>
      "vmax.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector compare
    @decode.VMSEQ_VV(rd, rs1, rs2, vm) =>
      "vmseq.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSNE_VV(rd, rs1, rs2, vm) =>
      "vmsne.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLTU_VV(rd, rs1, rs2, vm) =>
      "vmsltu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLT_VV(rd, rs1, rs2, vm) =>
      "vmslt.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLEU_VV(rd, rs1, rs2, vm) =>
      "vmsleu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLE_VV(rd, rs1, rs2, vm) =>
      "vmsle.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector reduction
    @decode.VREDSUM_VS(rd, rs1, rs2, vm) =>
      "vredsum.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDAND_VS(rd, rs1, rs2, vm) =>
      "vredand.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDOR_VS(rd, rs1, rs2, vm) =>
      "vredor.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDXOR_VS(rd, rs1, rs2, vm) =>
      "vredxor.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDMINU_VS(rd, rs1, rs2, vm) =>
      "vredminu.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDMIN_VS(rd, rs1, rs2, vm) =>
      "vredmin.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDMAXU_VS(rd, rs1, rs2, vm) =>
      "vredmaxu.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREDMAX_VS(rd, rs1, rs2, vm) =>
      "vredmax.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector mask
    @decode.VMAND_MM(rd, rs1, rs2, vm) =>
      "vmand.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMOR_MM(rd, rs1, rs2, vm) =>
      "vmor.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMXOR_MM(rd, rs1, rs2, vm) =>
      "vmxor.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMANDN_MM(rd, rs1, rs2, vm) =>
      "vmandn.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector merge/move
    @decode.VMERGE_VVM(rd, rs1, rs2, vm) =>
      "vmerge.vvm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMERGE_VXM(rd, rs1, rs2, vm) =>
      "vmerge.vxm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMV_V_V(rd, rs1, vm) =>
      "vmv.v.v \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}"
    @decode.VMV_V_X(rd, rs1, vm) =>
      "vmv.v.x \{@decode.vreg_name(rd)}, \{@decode.reg_name(rs1)}"

    // Vector floating-point arithmetic
    @decode.VFADD_VV(rd, rs1, rs2, vm) =>
      "vfadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFADD_VF(rd, rs1, rs2, vm) =>
      "vfadd.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFSUB_VF(rd, rs1, rs2, vm) =>
      "vfsub.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFRSUB_VF(rd, rs1, rs2, vm) =>
      "vfrsub.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFMUL_VF(rd, rs1, rs2, vm) =>
      "vfmul.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFDIV_VF(rd, rs1, rs2, vm) =>
      "vfdiv.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFRDIV_VF(rd, rs1, rs2, vm) =>
      "vfrdiv.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"

    // Vector floating-point reduction
    @decode.VFREDOSUM_VS(rd, rs1, rs2, vm) =>
      "vfredosum.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFREDSUM_VS(rd, rs1, rs2, vm) =>
      "vfredsum.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFREDMAX_VS(rd, rs1, rs2, vm) =>
      "vfredmax.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFREDMIN_VS(rd, rs1, rs2, vm) =>
      "vfredmin.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector sign/zero extension
    @decode.VSEXT_VF2(rd, rs2, vm) =>
      "vsext.vf2 \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VSEXT_VF4(rd, rs2, vm) =>
      "vsext.vf4 \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VZEXT_VF2(rd, rs2, vm) =>
      "vzext.vf2 \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VZEXT_VF4(rd, rs2, vm) =>
      "vzext.vf4 \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"

    // Vector slide
    @decode.VSLIDEUP_VX(rd, rs1, rs2, vm) =>
      "vslideup.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSLIDEUP_VI(rd, rs1, uimm, vm) =>
      "vslideup.vi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"
    @decode.VSLIDEDOWN_VX(rd, rs1, rs2, vm) =>
      "vslidedown.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSLIDEDOWN_VI(rd, rs1, uimm, vm) =>
      "vslidedown.vi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"
    @decode.VSLIDE1UP_VX(rd, rs1, rs2, vm) =>
      "vslide1up.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSLIDE1DOWN_VX(rd, rs1, rs2, vm) =>
      "vslide1down.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector gather (rgather)
    @decode.VRGATHER_VV(rd, rs1, rs2, vm) =>
      "vrgather.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VRGATHER_VX(rd, rs1, rs2, vm) =>
      "vrgather.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VRGATHER_VI(rd, rs1, uimm, vm) =>
      "vrgather.vi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"

    // Vector compress
    @decode.VCOMPRESS_VM(rd, rs1, rs2, vm) =>
      "vcompress.vm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector whole register load/store
    @decode.VL1RE8_V(rd, rs1) =>
      "vl1re8.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VL1RE16_V(rd, rs1) =>
      "vl1re16.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VL1RE32_V(rd, rs1) =>
      "vl1re32.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VL1RE64_V(rd, rs1) =>
      "vl1re64.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)})"
    @decode.VS1R_V(rs2, rs1) =>
      "vs1r.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VS2R_V(rs2, rs1) =>
      "vs2r.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VS4R_V(rs2, rs1) =>
      "vs4r.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"
    @decode.VS8R_V(rs2, rs1) =>
      "vs8r.v \{@decode.vreg_name(rs2)}, (\{@decode.reg_name(rs1)})"

    // Vector saturating add/sub
    @decode.VSADD_VV(rd, rs1, rs2, vm) =>
      "vsadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSADD_VX(rd, rs1, rs2, vm) =>
      "vsadd.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSADDU_VV(rd, rs1, rs2, vm) =>
      "vsaddu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSADDU_VX(rd, rs1, rs2, vm) =>
      "vsaddu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSSUB_VV(rd, rs1, rs2, vm) =>
      "vssub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSSUB_VX(rd, rs1, rs2, vm) =>
      "vssub.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSSUBU_VV(rd, rs1, rs2, vm) =>
      "vssubu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSSUBU_VX(rd, rs1, rs2, vm) =>
      "vssubu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector average
    @decode.VAADD_VX(rd, rs1, rs2, vm) =>
      "vaadd.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VAADD_VV(rd, rs1, rs2, vm) =>
      "vaadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VASUB_VX(rd, rs1, rs2, vm) =>
      "vasub.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VASUB_VV(rd, rs1, rs2, vm) =>
      "vasub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector shift right rounded
    @decode.VSSRA_VV(rd, rs1, rs2, vm) =>
      "vssra.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSSRA_VX(rd, rs1, rs2, vm) =>
      "vssra.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSSRA_VI(rd, rs1, uimm, vm) =>
      "vssra.vi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"
    @decode.VSSRL_VV(rd, rs1, rs2, vm) =>
      "vssrl.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSSRL_VX(rd, rs1, rs2, vm) =>
      "vssrl.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSSRL_VI(rd, rs1, uimm, vm) =>
      "vssrl.vi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"

    // Vector narrowing clip
    @decode.VNCLIP_WV(rd, rs1, rs2, vm) =>
      "vnclip.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VNCLIP_WX(rd, rs1, rs2, vm) =>
      "vnclip.wx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VNCLIPU_WV(rd, rs1, rs2, vm) =>
      "vnclipu.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VNCLIPU_WX(rd, rs1, rs2, vm) =>
      "vnclipu.wx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VNCLIPU_WI(rd, rs1, uimm, vm) =>
      "vnclipu.wi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"
    @decode.VNCLIP_WI(rd, rs1, uimm, vm) =>
      "vnclip.wi \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{uimm}"

    // Vector add/sub
    @decode.VADD_VV(rd, rs1, rs2, vm) =>
      "vadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VADD_VX(rd, rs1, rs2, vm) =>
      "vadd.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VADD_VI(rd, rs1, rs2, vm) =>
      "vadd.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VSUB_VV(rd, rs1, rs2, vm) =>
      "vsub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSUB_VX(rd, rs1, rs2, vm) =>
      "vsub.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VRSUB_VI(rd, rs1, rs2, vm) =>
      "vrsub.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector bitwise
    @decode.VAND_VV(rd, rs1, rs2, vm) =>
      "vand.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VAND_VX(rd, rs1, rs2, vm) =>
      "vand.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VAND_VI(rd, rs1, rs2, vm) =>
      "vand.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VOR_VV(rd, rs1, rs2, vm) =>
      "vor.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VOR_VX(rd, rs1, rs2, vm) =>
      "vor.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VOR_VI(rd, rs1, rs2, vm) =>
      "vor.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VXOR_VV(rd, rs1, rs2, vm) =>
      "vxor.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VXOR_VX(rd, rs1, rs2, vm) =>
      "vxor.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VXOR_VI(rd, rs1, rs2, vm) =>
      "vxor.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector widening reduction
    @decode.VWREDSUM_VS(rd, rs1, rs2, vm) =>
      "vwredsum.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWREDSUMU_VS(rd, rs1, rs2, vm) =>
      "vwredsumu.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector widening float reduction
    @decode.VFWREDSUM_VS(rd, rs1, rs2, vm) =>
      "vfwredsum.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFWREDOSUM_VS(rd, rs1, rs2, vm) =>
      "vfwredosum.vs \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector widening float mul
    @decode.VFWMUL_VF(rd, rs1, rs2, vm) =>
      "vfwmul.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFWMUL_VV(rd, rs1, rs2, vm) =>
      "vfwmul.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector widening float add/sub
    @decode.VFWADD_VV(rd, rs1, rs2, vm) =>
      "vfwadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFWADD_VF(rd, rs1, rs2, vm) =>
      "vfwadd.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFWADD_WV(rd, rs1, rs2, vm) =>
      "vfwadd.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFWADD_WF(rd, rs1, rs2, vm) =>
      "vfwadd.wf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFWSUB_VV(rd, rs1, rs2, vm) =>
      "vfwsub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFWSUB_VF(rd, rs1, rs2, vm) =>
      "vfwsub.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFWSUB_WV(rd, rs1, rs2, vm) =>
      "vfwsub.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFWSUB_WF(rd, rs1, rs2, vm) =>
      "vfwsub.wf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"

    // Vector mask register operations
    @decode.VPOPC_M(rd, rs1, rs2, vm) =>
      "vpopc.m \{@decode.reg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VFIRST_M(rd, rs1, rs2, vm) =>
      "vfirst.m \{@decode.reg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSBF_M(rd, rs1, rs2, vm) =>
      "vmsbf.m \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSIF_M(rd, rs1, rs2, vm) =>
      "vmsif.m \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSOF_M(rd, rs1, rs2, vm) =>
      "vmsof.m \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VIOTA_M(rd, rs1, rs2, vm) =>
      "viota.m \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VID_V(rd, rs1, vm) => "vid.v \{@decode.vreg_name(rd)}"

    // Vector mask logical (extra)
    @decode.VMORN_MM(rd, rs1, rs2, vm) =>
      "vmorn.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMNAND_MM(rd, rs1, rs2, vm) =>
      "vmnand.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMNOR_MM(rd, rs1, rs2, vm) =>
      "vmnor.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMXNOR_MM(rd, rs1, rs2, vm) =>
      "vmxnor.mm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector floating-point move
    @decode.VFMV_S_F(rd, rs1) =>
      "vfmv.s.f \{@decode.vreg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.VFMV_F_S(rd, rs1) =>
      "vfmv.f.s \{@decode.freg_name(rd)}, \{@decode.vreg_name(rs1)}"
    @decode.VFMV_S_F(_, _) => ".reserved"
    @decode.VFMV_F_S(_, _) => ".reserved"
    @decode.VFMV_V_F(rd, rs1, vm) =>
      "vfmv.v.f \{@decode.vreg_name(rd)}, \{@decode.freg_name(rs1)}"
    @decode.VFMERGE_VFM(rd, rs1, rs2, vm) =>
      "vmerge.vfm \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"

    // Vector floating-point classify
    @decode.VFCLASS_V(rd, rs2, vm) =>
      "vclassify.v \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"

    // Vector floating-point compare
    @decode.VMFGE_VF(rd, rs1, rs2, vm) =>
      "vmfge.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VMFGT_VF(rd, rs1, rs2, vm) =>
      "vmfgt.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VMFLE_VF(rd, rs1, rs2, vm) =>
      "vmfle.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VMFLT_VF(rd, rs1, rs2, vm) =>
      "vmflt.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VMFLE_VV(rd, rs1, rs2, vm) =>
      "vmfle.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMFLT_VV(rd, rs1, rs2, vm) =>
      "vmflt.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector floating-point compare (more)
    @decode.VMFEQ_VF(rd, rs1, rs2, vm) =>
      "vmfeq.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VMFNE_VF(rd, rs1, rs2, vm) =>
      "vmfne.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VMFEQ_VV(rd, rs1, rs2, vm) =>
      "vmfeq.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMFNE_VV(rd, rs1, rs2, vm) =>
      "vmfne.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector saturating add immediate
    @decode.VSADD_VI(rd, _, _, _) =>
      "vsadd.vi \{@decode.vreg_name(rd)}, <dest>, <imm>"
    @decode.VSADDU_VI(rd, _, _, _) =>
      "vsaddu.vi \{@decode.vreg_name(rd)}, <dest>, <imm>"

    // Vector floating-point sign inject
    @decode.VFSGNJX_VF(rd, rs1, rs2, vm) =>
      "vfsgnjx.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFSGNJX_VV(rd, rs1, rs2, vm) =>
      "vfsgnjx.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector floating-point sign inject (more)
    @decode.VFSGNJ_VF(rd, rs1, rs2, vm) =>
      "vfsgnj.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFSGNJ_VV(rd, rs1, rs2, vm) =>
      "vfsgnj.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFSGNJN_VF(rd, rs1, rs2, vm) =>
      "vfsgnjn.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFSGNJN_VV(rd, rs1, rs2, vm) =>
      "vfsgnjn.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector floating-point arithmetic (more)
    @decode.VFSQRT_V(rd, rs2, vm) =>
      "vfsqrt.v \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VFMAX_VF(rd, rs1, rs2, vm) =>
      "vfmax.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFMAX_VV(rd, rs1, rs2, vm) =>
      "vfmax.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFMIN_VF(rd, rs1, rs2, vm) =>
      "vfmin.vf \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.freg_name(rs2)}"
    @decode.VFMIN_VV(rd, rs1, rs2, vm) =>
      "vfmin.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFDIV_VV(rd, rs1, rs2, vm) =>
      "vfdiv.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFMUL_VV(rd, rs1, rs2, vm) =>
      "vfmul.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VFSUB_VV(rd, rs1, rs2, vm) =>
      "vfsub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Vector indexed load (ordered)
    @decode.VLOXEI8_V(rd, rs1, vs2, vm) =>
      "vloxei8.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VLOXEI16_V(rd, rs1, vs2, vm) =>
      "vloxei16.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VLOXEI32_V(rd, rs1, vs2, vm) =>
      "vloxei32.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VLOXEI64_V(rd, rs1, vs2, vm) =>
      "vloxei64.v \{@decode.vreg_name(rd)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"

    // Vector indexed store (ordered)
    @decode.VSOXEI8_V(vs3, rs1, vs2, vm) =>
      "vsoxei8.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VSOXEI16_V(vs3, rs1, vs2, vm) =>
      "vsoxei16.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VSOXEI32_V(vs3, rs1, vs2, vm) =>
      "vsoxei32.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"
    @decode.VSOXEI64_V(vs3, rs1, vs2, vm) =>
      "vsoxei64.v \{@decode.vreg_name(vs3)}, (\{@decode.reg_name(rs1)}), \{@decode.vreg_name(vs2)}"

    // Vector extension
    @decode.VSEXT_VF8(rd, rs2, vm) =>
      "vsext.vf8 \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"
    @decode.VZEXT_VF8(rd, rs2, vm) =>
      "vzext.vf8 \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs2)}"

    // Vector move (more)
    @decode.VMV_S_X(rd, rs1) =>
      "vmv.s.x \{@decode.vreg_name(rd)}, \{@decode.reg_name(rs1)}"
    @decode.VMV_X_S(rd, rs1) =>
      "vmv.x.s \{@decode.reg_name(rd)}, \{@decode.vreg_name(rs1)}"
    @decode.VMV_V_I(rd, _, _) => "vmv.v.i \{@decode.vreg_name(rd)}, <imm>"
    @decode.VMERGE_VIM(rd, _, _, _) =>
      "vmerge.vim \{@decode.vreg_name(rd)}, <src>, <imm>"

    // Vector widening multiply
    @decode.VWMULU_VX(rd, rs1, rs2, vm) =>
      "vwmulu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWMULU_VV(rd, rs1, rs2, vm) =>
      "vwmulu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWMULSU_VX(rd, rs1, rs2, vm) =>
      "vwmulsu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWMULSU_VV(rd, rs1, rs2, vm) =>
      "vwmulsu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // VMULH instructions
    @decode.VMULH_VV(rd, rs1, rs2, vm) =>
      "vmulh.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMULH_VX(rd, rs1, rs2, vm) =>
      "vmulh.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMULHU_VV(rd, rs1, rs2, vm) =>
      "vmulhu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMULHU_VX(rd, rs1, rs2, vm) =>
      "vmulhu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMULHSU_VV(rd, rs1, rs2, vm) =>
      "vmulhsu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMULHSU_VX(rd, rs1, rs2, vm) =>
      "vmulhsu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // VDIV instructions
    @decode.VDIV_VV(rd, rs1, rs2, vm) =>
      "vdiv.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VDIV_VX(rd, rs1, rs2, vm) =>
      "vdiv.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VDIVU_VV(rd, rs1, rs2, vm) =>
      "vdivu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VDIVU_VX(rd, rs1, rs2, vm) =>
      "vdivu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // VREM instructions
    @decode.VREM_VV(rd, rs1, rs2, vm) =>
      "vrem.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREM_VX(rd, rs1, rs2, vm) =>
      "vrem.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VREMU_VV(rd, rs1, rs2, vm) =>
      "vremu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VREMU_VX(rd, rs1, rs2, vm) =>
      "vremu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // VWADD instructions
    @decode.VWADD_VV(rd, rs1, rs2, vm) =>
      "vwadd.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWADD_VX(rd, rs1, rs2, vm) =>
      "vwadd.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWADDU_VV(rd, rs1, rs2, vm) =>
      "vwaddu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWADDU_VX(rd, rs1, rs2, vm) =>
      "vwaddu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWADD_WV(rd, rs1, rs2, vm) =>
      "vwadd.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWADD_WX(rd, rs1, rs2, vm) =>
      "vwadd.wx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWADDU_WV(rd, rs1, rs2, vm) =>
      "vwaddu.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWADDU_WX(rd, rs1, rs2, vm) =>
      "vwaddu.wx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // VWSUB instructions
    @decode.VWSUB_VV(rd, rs1, rs2, vm) =>
      "vwsub.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWSUB_VX(rd, rs1, rs2, vm) =>
      "vwsub.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWSUBU_VV(rd, rs1, rs2, vm) =>
      "vwsubu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWSUBU_VX(rd, rs1, rs2, vm) =>
      "vwsubu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWSUB_WV(rd, rs1, rs2, vm) =>
      "vwsub.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWSUB_WX(rd, rs1, rs2, vm) =>
      "vwsub.wx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWSUBU_WV(rd, rs1, rs2, vm) =>
      "vwsubu.wv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VWSUBU_WX(rd, rs1, rs2, vm) =>
      "vwsubu.wx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector multiply
    @decode.VMUL_VV(rd, rs1, rs2, vm) =>
      "vmul.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMUL_VX(rd, rs1, rs2, vm) =>
      "vmul.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector min/max
    @decode.VMIN_VV(rd, rs1, rs2, vm) =>
      "vmin.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMIN_VX(rd, rs1, rs2, vm) =>
      "vmin.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMINU_VV(rd, rs1, rs2, vm) =>
      "vminu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMINU_VX(rd, rs1, rs2, vm) =>
      "vminu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMAX_VV(rd, rs1, rs2, vm) =>
      "vmax.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMAX_VX(rd, rs1, rs2, vm) =>
      "vmax.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMAXU_VV(rd, rs1, rs2, vm) =>
      "vmaxu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMAXU_VX(rd, rs1, rs2, vm) =>
      "vmaxu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector shift
    @decode.VSLL_VV(rd, rs1, rs2, vm) =>
      "vsll.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSLL_VX(rd, rs1, rs2, vm) =>
      "vsll.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSLL_VI(rd, rs1, rs2, vm) =>
      "vsll.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VSRL_VV(rd, rs1, rs2, vm) =>
      "vsrl.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSRL_VX(rd, rs1, rs2, vm) =>
      "vsrl.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSRL_VI(rd, rs1, rs2, vm) =>
      "vsrl.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VSRA_VV(rd, rs1, rs2, vm) =>
      "vsra.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VSRA_VX(rd, rs1, rs2, vm) =>
      "vsra.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VSRA_VI(rd, rs1, rs2, vm) =>
      "vsra.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Narrowing shift
    @decode.VNSRL_VV(rd, rs1, rs2, vm) =>
      "vnsrl.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VNSRL_VX(rd, rs1, rs2, vm) =>
      "vnsrl.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VNSRL_VI(rd, rs1, rs2, vm) =>
      "vnsrl.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VNSRA_VV(rd, rs1, rs2, vm) =>
      "vnsra.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VNSRA_VX(rd, rs1, rs2, vm) =>
      "vnsra.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VNSRA_VI(rd, rs1, rs2, vm) =>
      "vnsra.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector mask compare - equal
    @decode.VMSEQ_VV(rd, rs1, rs2, vm) =>
      "vmseq.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSEQ_VX(rd, rs1, rs2, vm) =>
      "vmseq.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSEQ_VI(rd, rs1, rs2, vm) =>
      "vmseq.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector mask compare - not equal
    @decode.VMSNE_VV(rd, rs1, rs2, vm) =>
      "vmsne.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSNE_VX(rd, rs1, rs2, vm) =>
      "vmsne.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSNE_VI(rd, rs1, rs2, vm) =>
      "vmsne.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector mask compare - less than
    @decode.VMSLT_VV(rd, rs1, rs2, vm) =>
      "vmslt.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLT_VX(rd, rs1, rs2, vm) =>
      "vmslt.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSLTU_VV(rd, rs1, rs2, vm) =>
      "vmsltu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLTU_VX(rd, rs1, rs2, vm) =>
      "vmsltu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"

    // Vector mask compare - less than or equal
    @decode.VMSLE_VV(rd, rs1, rs2, vm) =>
      "vmsle.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLE_VX(rd, rs1, rs2, vm) =>
      "vmsle.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSLE_VI(rd, rs1, rs2, vm) =>
      "vmsle.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLEU_VV(rd, rs1, rs2, vm) =>
      "vmsleu.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"
    @decode.VMSLEU_VX(rd, rs1, rs2, vm) =>
      "vmsleu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSLEU_VI(rd, rs1, rs2, vm) =>
      "vmsleu.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector mask compare - greater than
    @decode.VMSGT_VX(rd, rs1, rs2, vm) =>
      "vmsgt.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSGT_VI(rd, rs1, rs2, vm) =>
      "vmsgt.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"
    @decode.VMSGTU_VX(rd, rs1, rs2, vm) =>
      "vmsgtu.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VMSGTU_VI(rd, rs1, rs2, vm) =>
      "vmsgtu.vi \{@decode.vreg_name(rd)}, \{rs1.to_string()}, \{@decode.vreg_name(rs2)}"

    // Vector widening multiply (more)
    @decode.VWMUL_VX(rd, rs1, rs2, vm) =>
      "vwmul.vx \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.reg_name(rs2)}"
    @decode.VWMUL_VV(rd, rs1, rs2, vm) =>
      "vwmul.vv \{@decode.vreg_name(rd)}, \{@decode.vreg_name(rs1)}, \{@decode.vreg_name(rs2)}"

    // Invalid instruction
    @decode.Invalid(code) => ".invalid \{format_hex_uint(code)}"
  }
}

///|
/// Disassemble with address prefix
pub fn disassemble_with_addr(inst : @decode.Instruction, addr : UInt) -> String {
  "\{format_hex_uint(addr)}: \{disassemble(inst)}"
}
