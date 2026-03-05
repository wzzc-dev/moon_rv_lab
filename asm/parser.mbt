///| RISC-V Assembler Parser

///|
/// Parse a register name to register number
pub fn parse_reg(name : String) -> UInt? {
  // ABI names
  match name {
    "zero" => Some(0U)
    "ra" => Some(1U)
    "sp" => Some(2U)
    "gp" => Some(3U)
    "tp" => Some(4U)
    "t0" => Some(5U)
    "t1" => Some(6U)
    "t2" => Some(7U)
    "s0" | "fp" => Some(8U)
    "s1" => Some(9U)
    "a0" => Some(10U)
    "a1" => Some(11U)
    "a2" => Some(12U)
    "a3" => Some(13U)
    "a4" => Some(14U)
    "a5" => Some(15U)
    "a6" => Some(16U)
    "a7" => Some(17U)
    "s2" => Some(18U)
    "s3" => Some(19U)
    "s4" => Some(20U)
    "s5" => Some(21U)
    "s6" => Some(22U)
    "s7" => Some(23U)
    "s8" => Some(24U)
    "s9" => Some(25U)
    "s10" => Some(26U)
    "s11" => Some(27U)
    "t3" => Some(28U)
    "t4" => Some(29U)
    "t5" => Some(30U)
    "t6" => Some(31U)
    _ =>
      // x0-x31 format
      if name.length() >= 2 && name[0].unsafe_to_char() == 'x' {
        // Parse the number part
        let mut num : Int = 0
        let mut valid = true
        for i = 1; i < name.length(); i = i + 1 {
          let c = name[i].unsafe_to_char()
          if c >= '0' && c <= '9' {
            num = num * 10 + (c.to_int() - '0'.to_int())
          } else {
            valid = false
          }
        }
        if valid && num >= 0 && num <= 31 {
          Some(num.reinterpret_as_uint())
        } else {
          None
        }
      } else {
        None
      }
  }
}

///|
/// Parse an immediate value from token
pub fn parse_imm(token : Token) -> Int? {
  match token {
    Token::Imm(v) => Some(v)
    Token::HexImm(v) => Some(v.reinterpret_as_int())
    _ => None
  }
}

///|
/// Parse an immediate as UInt
pub fn parse_imm_uint(token : Token) -> UInt? {
  match token {
    Token::Imm(v) => Some(v.reinterpret_as_uint())
    Token::HexImm(v) => Some(v)
    _ => None
  }
}

///|
/// Instruction type category for parsing
enum InstType {
  UType // lui, auipc
  JType // jal
  ITypeJump // jalr
  ITypeLoad(Int) // lb, lh, lw, lbu, lhu, ld, lwu (width)
  ITypeArith(Int) // addi, slti, sltiu, xori, ori, andi, addiw (funct3)
  ITypeShift(UInt, UInt) // slli, srli, srai (funct7, funct3)
  SType(Int) // sb, sh, sw, sd (width)
  BType(Int) // beq, bne, blt, bge, bltu, bgeu (funct3)
  RType(UInt, UInt) // add, sub, sll, slt, sltu, xor, srl, sra, or, and (funct3, funct7)
  RTypeM(Int) // mul, mulh, mulhsu, mulhu, div, divu, rem, remu (funct3)
  RTypeMW(Int) // mulw, divw, divuw, remw, remuw (funct3)
  SystemEcall
  SystemEbreak
  Fence
  FenceI
  CsrRw(Int) // csrrw, csrrs, csrrc (funct3)
  CsrImm(Int) // csrrwi, csrrsi, csrrci (funct3)
  Zba(Int) // sh1add, sh2add, sh3add (funct3)
  ZbbArith(UInt, UInt) // andn, orn, xnor (funct3, funct7)
  ZbbUnary(UInt) // clz, ctz, cpop, sext.b, sext.h, zext.h, orc.b, rev8 (funct7)
  ZbbRType(UInt, UInt) // max, maxu, min, minu, rol, ror (funct3, funct7)
  ZbbShiftImm(UInt) // rori (funct7)
  Zbc(Int) // clmul, clmulh, clmulr (funct3)
  ZbsRType(Int) // bclr, bext, binv, bset (funct3)
  ZbsImm(Int) // bclri, bexti, binvi, bseti (funct3)
  CNop
  CEbreak
  CAddi
  CLi
  CLui
  CAddi16sp
  CJ
  CJal
  CJr
  CJalr
  CBeqz
  CBnez
  CMv
  CAdd
  CCrOp(UInt) // c.and, c.or, c.xor, c.sub (funct6 part)
}

///|
/// Parse a single assembly line
/// Returns the parsed instruction or None if invalid
pub fn parse_instruction(
  mnemonic : String,
  operands : Array[Token],
) -> @decode.Instruction? {
  // Determine instruction type and parse accordingly
  match mnemonic {
    // U-type
    "lui" => parse_and_build_u(operands, 0)
    "auipc" => parse_and_build_u(operands, 1)

    // J-type
    "jal" => parse_and_build_j(operands)

    // I-type (jumps and loads)
    "jalr" => parse_and_build_i_jalr(operands)
    "lb" => parse_and_build_load(operands, 0)
    "lh" => parse_and_build_load(operands, 1)
    "lw" => parse_and_build_load(operands, 2)
    "lbu" => parse_and_build_load(operands, 4)
    "lhu" => parse_and_build_load(operands, 5)
    "ld" => parse_and_build_load_64(operands, 3)
    "lwu" => parse_and_build_load_64(operands, 6)

    // I-type arithmetic
    "addi" => parse_and_build_i_arith(operands, 0)
    "slti" => parse_and_build_i_arith(operands, 2)
    "sltiu" => parse_and_build_i_arith(operands, 3)
    "xori" => parse_and_build_i_arith(operands, 4)
    "ori" => parse_and_build_i_arith(operands, 6)
    "andi" => parse_and_build_i_arith(operands, 7)
    "addiw" => parse_and_build_i_arith_w(operands, 0)

    // Shift immediate
    "slli" => parse_and_build_shift(operands, 0x0U, 0x1U)
    "srli" => parse_and_build_shift(operands, 0x0U, 0x5U)
    "srai" => parse_and_build_shift(operands, 0x20U, 0x5U)
    "slliw" => parse_and_build_shift_w(operands, 0x0U, 0x1U)
    "srliw" => parse_and_build_shift_w(operands, 0x0U, 0x5U)
    "sraiw" => parse_and_build_shift_w(operands, 0x20U, 0x5U)

    // S-type (stores)
    "sb" => parse_and_build_store(operands, 0)
    "sh" => parse_and_build_store(operands, 1)
    "sw" => parse_and_build_store(operands, 2)
    "sd" => parse_and_build_store_64(operands, 3)

    // B-type (branches)
    "beq" => parse_and_build_branch(operands, 0)
    "bne" => parse_and_build_branch(operands, 1)
    "blt" => parse_and_build_branch(operands, 4)
    "bge" => parse_and_build_branch(operands, 5)
    "bltu" => parse_and_build_branch(operands, 6)
    "bgeu" => parse_and_build_branch(operands, 7)

    // R-type (register arithmetic)
    "add" => parse_and_build_r(operands, 0x0U, 0x0U)
    "sub" => parse_and_build_r(operands, 0x0U, 0x20U)
    "sll" => parse_and_build_r(operands, 0x1U, 0x0U)
    "slt" => parse_and_build_r(operands, 0x2U, 0x0U)
    "sltu" => parse_and_build_r(operands, 0x3U, 0x0U)
    "xor" => parse_and_build_r(operands, 0x4U, 0x0U)
    "srl" => parse_and_build_r(operands, 0x5U, 0x0U)
    "sra" => parse_and_build_r(operands, 0x5U, 0x20U)
    "or" => parse_and_build_r(operands, 0x6U, 0x0U)
    "and" => parse_and_build_r(operands, 0x7U, 0x0U)
    "addw" => parse_and_build_r_w(operands, 0x0U, 0x0U)
    "subw" => parse_and_build_r_w(operands, 0x0U, 0x20U)
    "sllw" => parse_and_build_r_w(operands, 0x1U, 0x0U)
    "srlw" => parse_and_build_r_w(operands, 0x5U, 0x0U)
    "sraw" => parse_and_build_r_w(operands, 0x5U, 0x20U)

    // RV32M
    "mul" => parse_and_build_r_m(operands, 0)
    "mulh" => parse_and_build_r_m(operands, 1)
    "mulhsu" => parse_and_build_r_m(operands, 2)
    "mulhu" => parse_and_build_r_m(operands, 3)
    "div" => parse_and_build_r_m(operands, 4)
    "divu" => parse_and_build_r_m(operands, 5)
    "rem" => parse_and_build_r_m(operands, 6)
    "remu" => parse_and_build_r_m(operands, 7)
    "mulw" => parse_and_build_r_m_w(operands, 0)
    "divw" => parse_and_build_r_m_w(operands, 4)
    "divuw" => parse_and_build_r_m_w(operands, 5)
    "remw" => parse_and_build_r_m_w(operands, 6)
    "remuw" => parse_and_build_r_m_w(operands, 7)

    // System
    "ecall" => if operands.length() == 0 { Some(@decode.ECALL) } else { None }
    "ebreak" => if operands.length() == 0 { Some(@decode.EBREAK) } else { None }

    // Fence
    "fence" => Some(@decode.FENCE(0xFU, 0xFU))
    "fence.i" =>
      if operands.length() == 0 {
        Some(@decode.FENCE_I)
      } else {
        None
      }

    // CSR
    "csrrw" => parse_and_build_csr_rw(operands, 1)
    "csrrs" => parse_and_build_csr_rw(operands, 2)
    "csrrc" => parse_and_build_csr_rw(operands, 3)
    "csrrwi" => parse_and_build_csr_imm(operands, 5)
    "csrrsi" => parse_and_build_csr_imm(operands, 6)
    "csrrci" => parse_and_build_csr_imm(operands, 7)

    // Zba
    "sh1add" => parse_and_build_r_zba(operands, 2)
    "sh2add" => parse_and_build_r_zba(operands, 4)
    "sh3add" => parse_and_build_r_zba(operands, 6)

    // Zbb
    "andn" => parse_and_build_r_zbb(operands, 0x7U, 0x20U)
    "orn" => parse_and_build_r_zbb(operands, 0x6U, 0x20U)
    "xnor" => parse_and_build_r_zbb(operands, 0x4U, 0x20U)
    "clz" => parse_and_build_unary_zbb(operands, 0x60U)
    "ctz" => parse_and_build_unary_zbb(operands, 0x61U)
    "cpop" => parse_and_build_unary_zbb(operands, 0x62U)
    "sext.b" => parse_and_build_unary_zbb(operands, 0x64U)
    "sext.h" => parse_and_build_unary_zbb(operands, 0x65U)
    "zext.h" => parse_and_build_unary_zbb_w(operands, 0x0CU)
    "max" => parse_and_build_r_zbb(operands, 0x6U, 0x0U)
    "maxu" => parse_and_build_r_zbb(operands, 0x7U, 0x0U)
    "min" => parse_and_build_r_zbb(operands, 0x4U, 0x0U)
    "minu" => parse_and_build_r_zbb(operands, 0x5U, 0x0U)
    "rol" => parse_and_build_r_zbb(operands, 0x1U, 0x0U)
    "ror" => parse_and_build_r_zbb(operands, 0x5U, 0x20U)
    "rori" => parse_and_build_shift_zbb(operands, 0x5U)
    "orc.b" => parse_and_build_unary_zbb(operands, 0x67U)
    "rev8" => parse_and_build_unary_zbb(operands, 0x6BU)

    // Zbc
    "clmul" => parse_and_build_r_zbc(operands, 1)
    "clmulh" => parse_and_build_r_zbc(operands, 3)
    "clmulr" => parse_and_build_r_zbc(operands, 2)

    // Zbs
    "bclr" => parse_and_build_r_zbs(operands, 1)
    "bclri" => parse_and_build_imm_zbs(operands, 1)
    "bext" => parse_and_build_r_zbs(operands, 5)
    "bexti" => parse_and_build_imm_zbs(operands, 5)
    "binv" => parse_and_build_r_zbs(operands, 3)
    "binvi" => parse_and_build_imm_zbs(operands, 3)
    "bset" => parse_and_build_r_zbs(operands, 2)
    "bseti" => parse_and_build_imm_zbs(operands, 2)

    // Compressed instructions
    "c.nop" => if operands.length() == 0 { Some(@decode.C_NOP) } else { None }
    "c.ebreak" =>
      if operands.length() == 0 {
        Some(@decode.C_EBREAK)
      } else {
        None
      }
    "c.addi" => parse_c_addi(operands)
    "c.li" => parse_c_li(operands)
    "c.lui" => parse_c_lui(operands)
    "c.addi16sp" => parse_c_addi16sp(operands)
    "c.j" => parse_c_j(operands)
    "c.jal" => parse_c_jal(operands)
    "c.jr" => parse_c_jr(operands)
    "c.jalr" => parse_c_jalr(operands)
    "c.beqz" => parse_c_beqz(operands)
    "c.bnez" => parse_c_bnez(operands)
    "c.mv" => parse_c_mv(operands)
    "c.add" => parse_c_add(operands)
    "c.and" => parse_c_cr_op(operands, 0x23U)
    "c.or" => parse_c_cr_op(operands, 0x22U)
    "c.xor" => parse_c_cr_op(operands, 0x21U)
    "c.sub" => parse_c_cr_op(operands, 0x20U)

    // Pseudo-instructions
    // li rd, imm -> addi rd, x0, imm (for small immediates)
    // For larger immediates, use lui + addi (handled separately in assembler)
    "li" => parse_pseudo_li(operands)
    // mv rd, rs -> addi rd, rs, 0
    "mv" => parse_pseudo_mv(operands)
    // ret -> jalr x0, ra, 0
    "ret" =>
      if operands.length() == 0 {
        Some(@decode.JALR(0U, 1U, 0)) // jalr x0, ra, 0
      } else {
        None
      }
    // call symbol -> handled as pseudo-instruction in assembler
    "call" => parse_pseudo_call(operands)
    _ => None
  }
}

// ============================================================================
// Helper parsing functions
// ============================================================================

///|
/// Parse U-type instruction operands and build
fn parse_and_build_u(operands : Array[Token], op : Int) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rd, imm) {
    (Some(r), Some(i)) =>
      if op == 0 {
        Some(@decode.LUI(r, i))
      } else {
        Some(@decode.AUIPC(r, i))
      }
    _ => None
  }
}

///|
/// Parse J-type instruction (jal)
fn parse_and_build_j(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rd, imm) {
    (Some(r), Some(i)) => Some(@decode.JAL(r, i))
    _ => None
  }
}

///|
/// Parse I-type jump (jalr)
fn parse_and_build_i_jalr(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = if operands.length() >= 3 {
    parse_imm(operands[2])
  } else {
    Some(0)
  }

  match (rd, rs1, imm) {
    (Some(r), Some(s), Some(i)) => Some(@decode.JALR(r, s, i))
    _ => None
  }
}

///|
/// Parse load instruction (I-type with memory operand)
fn parse_and_build_load(
  operands : Array[Token],
  width : Int,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  // Memory operand: imm(rs1) or rs1 (default imm=0)
  let (imm, rs1) = parse_mem_operand(operands, 1)

  match (rd, rs1, imm) {
    (Some(r), Some(s), Some(i)) =>
      match width {
        0 => Some(@decode.LB(r, s, i))
        1 => Some(@decode.LH(r, s, i))
        2 => Some(@decode.LW(r, s, i))
        4 => Some(@decode.LBU(r, s, i))
        5 => Some(@decode.LHU(r, s, i))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse 64-bit load instruction
fn parse_and_build_load_64(
  operands : Array[Token],
  width : Int,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let (imm, rs1) = parse_mem_operand(operands, 1)

  match (rd, rs1, imm) {
    (Some(r), Some(s), Some(i)) =>
      if width == 3 {
        Some(@decode.LD(r, s, i))
      } else {
        Some(@decode.LWU(r, s, i))
      }
    _ => None
  }
}

///|
/// Parse I-type arithmetic
fn parse_and_build_i_arith(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[2])

  match (rd, rs1, imm) {
    (Some(r), Some(s), Some(i)) =>
      match funct3 {
        0 => Some(@decode.ADDI(r, s, i))
        2 => Some(@decode.SLTI(r, s, i))
        3 => Some(@decode.SLTIU(r, s, i))
        4 => Some(@decode.XORI(r, s, i))
        6 => Some(@decode.ORI(r, s, i))
        7 => Some(@decode.ANDI(r, s, i))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse I-type arithmetic word (RV64)
fn parse_and_build_i_arith_w(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[2])

  match (rd, rs1, imm) {
    (Some(r), Some(s), Some(i)) =>
      if funct3 == 0 {
        Some(@decode.ADDIW(r, s, i))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse shift immediate instruction
fn parse_and_build_shift(
  operands : Array[Token],
  funct7 : UInt,
  funct3 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let shamt = parse_imm_uint(operands[2])

  match (rd, rs1, shamt) {
    (Some(r), Some(s), Some(sh)) =>
      if funct7 == 0x0U && funct3 == 0x1U {
        Some(@decode.SLLI(r, s, sh))
      } else if funct7 == 0x0U && funct3 == 0x5U {
        Some(@decode.SRLI(r, s, sh))
      } else if funct7 == 0x20U && funct3 == 0x5U {
        Some(@decode.SRAI(r, s, sh))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse shift immediate word instruction (RV64)
fn parse_and_build_shift_w(
  operands : Array[Token],
  funct7 : UInt,
  funct3 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let shamt = parse_imm_uint(operands[2])

  match (rd, rs1, shamt) {
    (Some(r), Some(s), Some(sh)) =>
      if funct7 == 0x0U && funct3 == 0x1U {
        Some(@decode.SLLIW(r, s, sh))
      } else if funct7 == 0x0U && funct3 == 0x5U {
        Some(@decode.SRLIW(r, s, sh))
      } else if funct7 == 0x20U && funct3 == 0x5U {
        Some(@decode.SRAIW(r, s, sh))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse store instruction
fn parse_and_build_store(
  operands : Array[Token],
  width : Int,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rs2 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let (imm, rs1) = parse_mem_operand(operands, 1)

  match (rs1, rs2, imm) {
    (Some(s1), Some(s2), Some(i)) =>
      match width {
        0 => Some(@decode.SB(s1, s2, i))
        1 => Some(@decode.SH(s1, s2, i))
        2 => Some(@decode.SW(s1, s2, i))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse 64-bit store instruction
fn parse_and_build_store_64(
  operands : Array[Token],
  width : Int,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rs2 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let (imm, rs1) = parse_mem_operand(operands, 1)

  match (rs1, rs2, imm) {
    (Some(s1), Some(s2), Some(i)) => Some(@decode.SD(s1, s2, i))
    _ => None
  }
}

///|
/// Parse branch instruction
fn parse_and_build_branch(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rs1 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[2])

  match (rs1, rs2, imm) {
    (Some(s1), Some(s2), Some(i)) =>
      match funct3 {
        0 => Some(@decode.BEQ(s1, s2, i))
        1 => Some(@decode.BNE(s1, s2, i))
        4 => Some(@decode.BLT(s1, s2, i))
        5 => Some(@decode.BGE(s1, s2, i))
        6 => Some(@decode.BLTU(s1, s2, i))
        7 => Some(@decode.BGEU(s1, s2, i))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse R-type instruction
fn parse_and_build_r(
  operands : Array[Token],
  funct3 : UInt,
  funct7 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      if funct3 == 0x0U && funct7 == 0x0U {
        Some(@decode.ADD(r, s1, s2))
      } else if funct3 == 0x0U && funct7 == 0x20U {
        Some(@decode.SUB(r, s1, s2))
      } else if funct3 == 0x1U && funct7 == 0x0U {
        Some(@decode.SLL(r, s1, s2))
      } else if funct3 == 0x2U && funct7 == 0x0U {
        Some(@decode.SLT(r, s1, s2))
      } else if funct3 == 0x3U && funct7 == 0x0U {
        Some(@decode.SLTU(r, s1, s2))
      } else if funct3 == 0x4U && funct7 == 0x0U {
        Some(@decode.XOR(r, s1, s2))
      } else if funct3 == 0x5U && funct7 == 0x0U {
        Some(@decode.SRL(r, s1, s2))
      } else if funct3 == 0x5U && funct7 == 0x20U {
        Some(@decode.SRA(r, s1, s2))
      } else if funct3 == 0x6U && funct7 == 0x0U {
        Some(@decode.OR(r, s1, s2))
      } else if funct3 == 0x7U && funct7 == 0x0U {
        Some(@decode.AND(r, s1, s2))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse R-type word instruction (RV64)
fn parse_and_build_r_w(
  operands : Array[Token],
  funct3 : UInt,
  funct7 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      if funct3 == 0x0U && funct7 == 0x0U {
        Some(@decode.ADDW(r, s1, s2))
      } else if funct3 == 0x0U && funct7 == 0x20U {
        Some(@decode.SUBW(r, s1, s2))
      } else if funct3 == 0x1U && funct7 == 0x0U {
        Some(@decode.SLLW(r, s1, s2))
      } else if funct3 == 0x5U && funct7 == 0x0U {
        Some(@decode.SRLW(r, s1, s2))
      } else if funct3 == 0x5U && funct7 == 0x20U {
        Some(@decode.SRAW(r, s1, s2))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse R-type M extension instruction
fn parse_and_build_r_m(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      match funct3 {
        0 => Some(@decode.MUL(r, s1, s2))
        1 => Some(@decode.MULH(r, s1, s2))
        2 => Some(@decode.MULHSU(r, s1, s2))
        3 => Some(@decode.MULHU(r, s1, s2))
        4 => Some(@decode.DIV(r, s1, s2))
        5 => Some(@decode.DIVU(r, s1, s2))
        6 => Some(@decode.REM(r, s1, s2))
        7 => Some(@decode.REMU(r, s1, s2))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse R-type M extension word instruction (RV64)
fn parse_and_build_r_m_w(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      match funct3 {
        0 => Some(@decode.MULW(r, s1, s2))
        4 => Some(@decode.DIVW(r, s1, s2))
        5 => Some(@decode.DIVUW(r, s1, s2))
        6 => Some(@decode.REMW(r, s1, s2))
        7 => Some(@decode.REMUW(r, s1, s2))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse CSR read/write instruction
fn parse_and_build_csr_rw(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let csr = match operands[1] {
    Token::Imm(v) => Some(v.reinterpret_as_uint())
    Token::HexImm(v) => Some(v)
    _ => None
  }

  let rs1 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, csr, rs1) {
    (Some(r), Some(c), Some(s)) =>
      match funct3 {
        1 => Some(@decode.CSRRW(r, c, s))
        2 => Some(@decode.CSRRS(r, c, s))
        3 => Some(@decode.CSRRC(r, c, s))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse CSR immediate instruction
fn parse_and_build_csr_imm(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let csr = match operands[1] {
    Token::Imm(v) => Some(v.reinterpret_as_uint())
    Token::HexImm(v) => Some(v)
    _ => None
  }

  let uimm = match operands[2] {
    Token::Imm(v) => Some(v.reinterpret_as_uint())
    Token::HexImm(v) => Some(v)
    _ => None
  }

  match (rd, csr, uimm) {
    (Some(r), Some(c), Some(u)) =>
      match funct3 {
        5 => Some(@decode.CSRRWI(r, c, u))
        6 => Some(@decode.CSRRSI(r, c, u))
        7 => Some(@decode.CSRRCI(r, c, u))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse Zba R-type instruction
fn parse_and_build_r_zba(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      match funct3 {
        2 => Some(@decode.SH1ADD(r, s1, s2))
        4 => Some(@decode.SH2ADD(r, s1, s2))
        6 => Some(@decode.SH3ADD(r, s1, s2))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse Zbb R-type instruction
fn parse_and_build_r_zbb(
  operands : Array[Token],
  funct3 : UInt,
  funct7 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      if funct3 == 0x7U && funct7 == 0x20U {
        Some(@decode.ANDN(r, s1, s2))
      } else if funct3 == 0x6U && funct7 == 0x20U {
        Some(@decode.ORN(r, s1, s2))
      } else if funct3 == 0x4U && funct7 == 0x20U {
        Some(@decode.XNOR(r, s1, s2))
      } else if funct3 == 0x6U && funct7 == 0x0U {
        Some(@decode.MAX(r, s1, s2))
      } else if funct3 == 0x7U && funct7 == 0x0U {
        Some(@decode.MAXU(r, s1, s2))
      } else if funct3 == 0x4U && funct7 == 0x0U {
        Some(@decode.MIN(r, s1, s2))
      } else if funct3 == 0x5U && funct7 == 0x0U {
        Some(@decode.MINU(r, s1, s2))
      } else if funct3 == 0x1U && funct7 == 0x0U {
        Some(@decode.ROL(r, s1, s2))
      } else if funct3 == 0x5U && funct7 == 0x20U {
        Some(@decode.ROR(r, s1, s2))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse Zbb unary instruction
fn parse_and_build_unary_zbb(
  operands : Array[Token],
  funct7 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1) {
    (Some(r), Some(s)) =>
      if funct7 == 0x60U {
        Some(@decode.CLZ(r, s))
      } else if funct7 == 0x61U {
        Some(@decode.CTZ(r, s))
      } else if funct7 == 0x62U {
        Some(@decode.CPOP(r, s))
      } else if funct7 == 0x64U {
        Some(@decode.SEXT_B(r, s))
      } else if funct7 == 0x65U {
        Some(@decode.SEXT_H(r, s))
      } else if funct7 == 0x67U {
        Some(@decode.ORC_B(r, s))
      } else if funct7 == 0x6BU {
        Some(@decode.REV8(r, s))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse Zbb unary word instruction
fn parse_and_build_unary_zbb_w(
  operands : Array[Token],
  funct7 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1) {
    (Some(r), Some(s)) =>
      if funct7 == 0x0CU {
        Some(@decode.ZEXT_H(r, s))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse Zbb shift immediate instruction
fn parse_and_build_shift_zbb(
  operands : Array[Token],
  funct3 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let shamt = parse_imm_uint(operands[2])

  match (rd, rs1, shamt) {
    (Some(r), Some(s), Some(sh)) =>
      if funct3 == 0x5U {
        Some(@decode.RORI(r, s, sh))
      } else {
        None
      }
    _ => None
  }
}

///|
/// Parse Zbc R-type instruction
fn parse_and_build_r_zbc(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      match funct3 {
        1 => Some(@decode.CLMUL(r, s1, s2))
        2 => Some(@decode.CLMULR(r, s1, s2))
        3 => Some(@decode.CLMULH(r, s1, s2))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse Zbs R-type instruction
fn parse_and_build_r_zbs(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[2] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs1, rs2) {
    (Some(r), Some(s1), Some(s2)) =>
      match funct3 {
        1 => Some(@decode.BCLR(r, s1, s2))
        2 => Some(@decode.BSET(r, s1, s2))
        3 => Some(@decode.BINV(r, s1, s2))
        5 => Some(@decode.BEXT(r, s1, s2))
        _ => None
      }
    _ => None
  }
}

///|
/// Parse Zbs immediate instruction
fn parse_and_build_imm_zbs(
  operands : Array[Token],
  funct3 : Int,
) -> @decode.Instruction? {
  if operands.length() < 3 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs1 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let shamt = parse_imm_uint(operands[2])

  match (rd, rs1, shamt) {
    (Some(r), Some(s), Some(sh)) =>
      match funct3 {
        1 => Some(@decode.BCLRI(r, s, sh))
        2 => Some(@decode.BSETI(r, s, sh))
        3 => Some(@decode.BINVI(r, s, sh))
        5 => Some(@decode.BEXTI(r, s, sh))
        _ => None
      }
    _ => None
  }
}

// ============================================================================
// Memory operand parsing
// ============================================================================

///|
/// Parse memory operand: imm(rs1) or rs1
/// Returns (imm, rs1)
fn parse_mem_operand(operands : Array[Token], start : Int) -> (Int?, UInt?) {
  if start >= operands.length() {
    return (None, None)
  }

  // Check for imm(reg) format
  // Could be: Imm, LParen, Reg, RParen
  // Or: Reg (default imm=0)

  let first = operands[start]

  match first {
    Token::LParen =>
      // (rs1) format, imm=0
      if start + 2 < operands.length() {
        let rs1 = match operands[start + 1] {
          Token::Reg(r) => parse_reg(r)
          _ => None
        }
        let has_rparen = match operands[start + 2] {
          Token::RParen => true
          _ => false
        }
        if rs1.is_some() && has_rparen {
          (Some(0), rs1)
        } else {
          (None, None)
        }
      } else {
        (None, None)
      }
    Token::Imm(v) => {
      // imm(rs1) format
      let imm = Some(v)

      if start + 3 < operands.length() {
        let has_lparen = match operands[start + 1] {
          Token::LParen => true
          _ => false
        }
        let rs1 = match operands[start + 2] {
          Token::Reg(r) => parse_reg(r)
          _ => None
        }
        let has_rparen = match operands[start + 3] {
          Token::RParen => true
          _ => false
        }
        if imm.is_some() && has_lparen && rs1.is_some() && has_rparen {
          (imm, rs1)
        } else {
          (None, None)
        }
      } else {
        (None, None)
      }
    }
    Token::HexImm(v) => {
      // imm(rs1) format with hex immediate
      let imm = Some(v.reinterpret_as_int())

      if start + 3 < operands.length() {
        let has_lparen = match operands[start + 1] {
          Token::LParen => true
          _ => false
        }
        let rs1 = match operands[start + 2] {
          Token::Reg(r) => parse_reg(r)
          _ => None
        }
        let has_rparen = match operands[start + 3] {
          Token::RParen => true
          _ => false
        }
        if imm.is_some() && has_lparen && rs1.is_some() && has_rparen {
          (imm, rs1)
        } else {
          (None, None)
        }
      } else {
        (None, None)
      }
    }
    Token::Reg(r) =>
      // Just a register, imm=0
      (Some(0), parse_reg(r))
    _ => (None, None)
  }
}

// ============================================================================
// Compressed instruction parsing
// ============================================================================

///|
/// Parse c.addi
fn parse_c_addi(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rd, imm) {
    (Some(r), Some(i)) => Some(@decode.C_ADDI(r, i))
    _ => None
  }
}

///|
/// Parse c.li
fn parse_c_li(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rd, imm) {
    (Some(r), Some(i)) => Some(@decode.C_LI(r, i))
    _ => None
  }
}

///|
/// Parse c.lui
fn parse_c_lui(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rd, imm) {
    (Some(r), Some(i)) => Some(@decode.C_LUI(r, i))
    _ => None
  }
}

///|
/// Parse c.addi16sp
fn parse_c_addi16sp(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 1 {
    return None
  }

  let imm = parse_imm(operands[0])

  match imm {
    Some(i) => Some(@decode.C_ADDI16SP(i))
    _ => None
  }
}

///|
/// Parse c.j
fn parse_c_j(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 1 {
    return None
  }

  let imm = parse_imm(operands[0])

  match imm {
    Some(i) => Some(@decode.C_J(i))
    _ => None
  }
}

///|
/// Parse c.jal
fn parse_c_jal(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 1 {
    return None
  }

  let imm = parse_imm(operands[0])

  match imm {
    Some(i) => Some(@decode.C_JAL(i))
    _ => None
  }
}

///|
/// Parse c.jr
fn parse_c_jr(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 1 {
    return None
  }

  let rs1 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match rs1 {
    Some(s) => Some(@decode.C_JR(s))
    _ => None
  }
}

///|
/// Parse c.jalr
fn parse_c_jalr(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 1 {
    return None
  }

  let rs1 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match rs1 {
    Some(s) => Some(@decode.C_JALR(s))
    _ => None
  }
}

///|
/// Parse c.beqz
fn parse_c_beqz(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rs1 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rs1, imm) {
    (Some(s), Some(i)) => Some(@decode.C_BEQZ(s, i))
    _ => None
  }
}

///|
/// Parse c.bnez
fn parse_c_bnez(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rs1 = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rs1, imm) {
    (Some(s), Some(i)) => Some(@decode.C_BNEZ(s, i))
    _ => None
  }
}

///|
/// Parse c.mv
fn parse_c_mv(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs2) {
    (Some(r), Some(s)) => Some(@decode.C_MV(r, s))
    _ => None
  }
}

///|
/// Parse c.add
fn parse_c_add(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs2) {
    (Some(r), Some(s)) => Some(@decode.C_ADD(r, s))
    _ => None
  }
}

///|
/// Parse c.and/c.or/c.xor/c.sub
fn parse_c_cr_op(
  operands : Array[Token],
  funct6 : UInt,
) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs2 = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs2) {
    (Some(r), Some(s)) =>
      if funct6 == 0x23U {
        Some(@decode.C_AND(r, s))
      } else if funct6 == 0x22U {
        Some(@decode.C_OR(r, s))
      } else if funct6 == 0x21U {
        Some(@decode.C_XOR(r, s))
      } else if funct6 == 0x20U {
        Some(@decode.C_SUB(r, s))
      } else {
        None
      }
    _ => None
  }
}

// ============================================================================
// Assembly parsing
// ============================================================================

///|
/// Parse a complete assembly statement
pub fn parse_statement(tokens : Array[TokenWithPos]) -> AsmStatement {
  if tokens.length() == 0 {
    return AsmStatement::Empty
  }

  let first = tokens[0]

  match first.token {
    Token::Directive(d) => {
      // Parse directive
      let args : Array[Token] = []
      for i = 1; i < tokens.length(); i = i + 1 {
        if tokens[i].token is Token::Newline {
          break
        }
        args.push(tokens[i].token)
      }
      AsmStatement::Directive(d, args)
    }
    Token::Ident(name) => {
      // Check if it's a label (followed by colon)
      if tokens.length() >= 2 && tokens[1].token is Token::Colon {
        return AsmStatement::Label(name)
      }

      // Parse instruction - skip commas
      let operands : Array[Token] = []
      for i = 1; i < tokens.length(); i = i + 1 {
        let tok = tokens[i].token
        if tok is Token::Newline || tok is Token::Eof {
          break
        }
        // Skip commas
        if tok is Token::Comma {
          continue
        }
        operands.push(tok)
      }

      match parse_instruction(name, operands) {
        Some(inst) => AsmStatement::Instruction(inst)
        None =>
          AsmStatement::Error({
            message: "Invalid instruction: " + name,
            line: first.line,
            col: first.col,
          })
      }
    }
    Token::Newline => AsmStatement::Empty
    _ =>
      AsmStatement::Error({
        message: "Unexpected token",
        line: first.line,
        col: first.col,
      })
  }
}

///|
/// Parse assembly source code
pub fn parse(input : String) -> Array[AsmStatement] {
  let tokens = tokenize(input)
  let statements : Array[AsmStatement] = []

  let mut i = 0
  while i < tokens.length() {
    // Collect tokens until newline or EOF
    let line_tokens : Array[TokenWithPos] = []
    while i < tokens.length() {
      let token = tokens[i]
      i = i + 1
      line_tokens.push(token)
      if token.token is Token::Newline || token.token is Token::Eof {
        break
      }
    }

    let stmt = parse_statement(line_tokens)
    statements.push(stmt)
  }

  statements
}

///|
/// Convert assembly statements to instructions
pub fn assemble(input : String) -> Array[@decode.Instruction] {
  let statements = parse(input)
  let instructions : Array[@decode.Instruction] = []

  for stmt in statements {
    match stmt {
      AsmStatement::Instruction(inst) => instructions.push(inst)
      _ => continue
    }
  }

  instructions
}

// ============================================================================
// Pseudo-instruction parsing functions
// ============================================================================

///|
/// Parse li (load immediate) pseudo-instruction
/// li rd, imm -> addi rd, x0, imm (for small immediates: -2048 to 2047)
/// For larger immediates, returns lui + addi pair representation
fn parse_pseudo_li(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let imm = parse_imm(operands[1])

  match (rd, imm) {
    (Some(r), Some(i)) =>
      // Check if immediate fits in 12 bits (-2048 to 2047)
      if i >= -2048 && i <= 2047 {
        // Use addi rd, x0, imm
        Some(@decode.ADDI(r, 0U, i))
      } else {
        // For larger immediates, use lui + addi
        // lui loads upper 20 bits, addi adds lower 12 bits
        let imm_uint = if i < 0 {
          i.reinterpret_as_uint() & 0xFFFFFFFFU
        } else {
          i.reinterpret_as_uint()
        }
        let upper = (imm_uint >> 12).reinterpret_as_int()
        let lower = (imm_uint & 0xFFFU).reinterpret_as_int()
        // Adjust for sign extension: if lower is negative, add 1 to upper
        let adjusted_upper = if lower >= 2048 { upper + 1 } else { upper }
        let adjusted_lower = if lower >= 2048 { lower - 4096 } else { lower }
        // Return LUI for the upper part (assembler will need to handle the pair)
        // For now, just return LUI and let the assembler handle addi separately
        // This is a simplification - ideally we'd return both instructions
        Some(@decode.LUI(r, adjusted_upper))
      }
    _ => None
  }
}

///|
/// Parse mv (move) pseudo-instruction
/// mv rd, rs -> addi rd, rs, 0
fn parse_pseudo_mv(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 2 {
    return None
  }

  let rd = match operands[0] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  let rs = match operands[1] {
    Token::Reg(r) => parse_reg(r)
    _ => None
  }

  match (rd, rs) {
    (Some(r), Some(s)) => Some(@decode.ADDI(r, s, 0))
    _ => None
  }
}

///|
/// Parse call pseudo-instruction
/// call symbol -> auipc ra, %hi(symbol) + jalr ra, ra, %lo(symbol)
/// Returns a placeholder JAL instruction; the assembler will handle the expansion
fn parse_pseudo_call(operands : Array[Token]) -> @decode.Instruction? {
  if operands.length() < 1 {
    return None
  }

  // For now, return a placeholder JAL instruction
  // The assembler will need to expand this to auipc + jalr
  // We use JAL with rd=ra (x1) and imm=0 as placeholder
  match operands[0] {
    Token::Ident(_) => Some(@decode.JAL(1U, 0)) // jal ra, 0 (placeholder)
    _ => None
  }
}
