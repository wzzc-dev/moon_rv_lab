///| RISC-V instruction encoder

///| Converts Instruction enum to binary machine code

///|
/// RISC-V opcode constants
const OP_LUI : UInt = 0x37U

///|
const OP_AUIPC : UInt = 0x17U

///|
const OP_JAL : UInt = 0x6FU

///|
const OP_JALR : UInt = 0x67U

///|
const OP_BRANCH : UInt = 0x63U

///|
const OP_LOAD : UInt = 0x03U

///|
const OP_STORE : UInt = 0x23U

///|
const OP_IMM : UInt = 0x13U

///|
const OP_REG : UInt = 0x33U

///|
const OP_SYSTEM : UInt = 0x73U

///|
const OP_AMO : UInt = 0x2FU

///|
const OP_FP_LOAD : UInt = 0x07U

///|
const OP_FP_STORE : UInt = 0x27U

///|
const OP_FP : UInt = 0x53U

///|
const OP_MADD : UInt = 0x43U

///|
const OP_MSUB : UInt = 0x47U

///|
const OP_NMSUB : UInt = 0x4BU

///|
const OP_NMADD : UInt = 0x4FU

///|
const OP_OP32 : UInt = 0x3BU // RV64 32-bit operations

///|
const OP_OP_IMM32 : UInt = 0x1BU // RV64 32-bit immediate operations

///|
/// Encode result type
pub struct EncodeResult {
  pub code : UInt
  pub is_compressed : Bool
}

///|
/// Encode a 32-bit instruction
pub fn encode(inst : @decode.Instruction) -> EncodeResult {
  let code = match inst {
    // U-type instructions
    @decode.LUI(rd, imm) => encode_u_type(rd, imm, OP_LUI)
    @decode.AUIPC(rd, imm) => encode_u_type(rd, imm, OP_AUIPC)

    // J-type instructions
    @decode.JAL(rd, imm) => encode_j_type(rd, imm)

    // I-type instructions (JALR)
    @decode.JALR(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x0U, OP_JALR)

    // Branch instructions (B-type)
    @decode.BEQ(rs1, rs2, imm) => encode_b_type(rs1, rs2, imm, 0x0U)
    @decode.BNE(rs1, rs2, imm) => encode_b_type(rs1, rs2, imm, 0x1U)
    @decode.BLT(rs1, rs2, imm) => encode_b_type(rs1, rs2, imm, 0x4U)
    @decode.BGE(rs1, rs2, imm) => encode_b_type(rs1, rs2, imm, 0x5U)
    @decode.BLTU(rs1, rs2, imm) => encode_b_type(rs1, rs2, imm, 0x6U)
    @decode.BGEU(rs1, rs2, imm) => encode_b_type(rs1, rs2, imm, 0x7U)

    // Load instructions (I-type)
    @decode.LB(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x0U, OP_LOAD)
    @decode.LH(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x1U, OP_LOAD)
    @decode.LW(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x2U, OP_LOAD)
    @decode.LBU(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x4U, OP_LOAD)
    @decode.LHU(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x5U, OP_LOAD)

    // Store instructions (S-type)
    @decode.SB(rs1, rs2, imm) => encode_s_type(rs1, rs2, imm, 0x0U)
    @decode.SH(rs1, rs2, imm) => encode_s_type(rs1, rs2, imm, 0x1U)
    @decode.SW(rs1, rs2, imm) => encode_s_type(rs1, rs2, imm, 0x2U)

    // Immediate arithmetic (I-type)
    @decode.ADDI(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x0U, OP_IMM)
    @decode.SLTI(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x2U, OP_IMM)
    @decode.SLTIU(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x3U, OP_IMM)
    @decode.XORI(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x4U, OP_IMM)
    @decode.ORI(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x6U, OP_IMM)
    @decode.ANDI(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x7U, OP_IMM)
    @decode.SLLI(rd, rs1, shamt) => encode_shift_imm(rd, rs1, shamt, 0x0U, 0x1U)
    @decode.SRLI(rd, rs1, shamt) => encode_shift_imm(rd, rs1, shamt, 0x0U, 0x5U)
    @decode.SRAI(rd, rs1, shamt) =>
      encode_shift_imm(rd, rs1, shamt, 0x20U, 0x1U)

    // Register arithmetic (R-type)
    @decode.ADD(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x0U, 0x0U)
    @decode.SUB(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x0U, 0x20U)
    @decode.SLL(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x1U, 0x0U)
    @decode.SLT(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x2U, 0x0U)
    @decode.SLTU(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x3U, 0x0U)
    @decode.XOR(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x4U, 0x0U)
    @decode.SRL(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x5U, 0x0U)
    @decode.SRA(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x5U, 0x20U)
    @decode.OR(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x6U, 0x0U)
    @decode.AND(rd, rs1, rs2) => encode_r_type(rd, rs1, rs2, 0x7U, 0x0U)

    // RV32M extension
    @decode.MUL(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x0U, 0x1U)
    @decode.MULH(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x1U, 0x1U)
    @decode.MULHSU(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x2U, 0x1U)
    @decode.MULHU(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x3U, 0x1U)
    @decode.DIV(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x4U, 0x1U)
    @decode.DIVU(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x5U, 0x1U)
    @decode.REM(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x6U, 0x1U)
    @decode.REMU(rd, rs1, rs2) => encode_r_type_ext(rd, rs1, rs2, 0x7U, 0x1U)

    // RV64I instructions
    @decode.LD(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x3U, OP_LOAD)
    @decode.SD(rs1, rs2, imm) => encode_s_type(rs1, rs2, imm, 0x3U)
    @decode.LWU(rd, rs1, imm) => encode_i_type(rd, rs1, imm, 0x6U, OP_LOAD)
    @decode.ADDIW(rd, rs1, imm) =>
      encode_i_type(rd, rs1, imm, 0x0U, OP_OP_IMM32)
    @decode.SLLIW(rd, rs1, shamt) => encode_shift_imm32(rd, rs1, shamt, 0x0U)
    @decode.SRLIW(rd, rs1, shamt) => encode_shift_imm32(rd, rs1, shamt, 0x1U)
    @decode.SRAIW(rd, rs1, shamt) => encode_shift_imm32(rd, rs1, shamt, 0x21U)
    @decode.ADDW(rd, rs1, rs2) => encode_r_type_32(rd, rs1, rs2, 0x0U, 0x0U)
    @decode.SUBW(rd, rs1, rs2) => encode_r_type_32(rd, rs1, rs2, 0x0U, 0x20U)
    @decode.SLLW(rd, rs1, rs2) => encode_r_type_32(rd, rs1, rs2, 0x1U, 0x0U)
    @decode.SRLW(rd, rs1, rs2) => encode_r_type_32(rd, rs1, rs2, 0x5U, 0x0U)
    @decode.SRAW(rd, rs1, rs2) => encode_r_type_32(rd, rs1, rs2, 0x5U, 0x20U)

    // RV64M extension
    @decode.MULW(rd, rs1, rs2) => encode_r_type_32_ext(rd, rs1, rs2, 0x0U)
    @decode.DIVW(rd, rs1, rs2) => encode_r_type_32_ext(rd, rs1, rs2, 0x4U)
    @decode.DIVUW(rd, rs1, rs2) => encode_r_type_32_ext(rd, rs1, rs2, 0x5U)
    @decode.REMW(rd, rs1, rs2) => encode_r_type_32_ext(rd, rs1, rs2, 0x6U)
    @decode.REMUW(rd, rs1, rs2) => encode_r_type_32_ext(rd, rs1, rs2, 0x7U)

    // Fence instructions
    @decode.FENCE(pred, succ) => encode_fence(pred, succ)
    @decode.FENCE_I => 0x0000100FU

    // System instructions
    @decode.ECALL => 0x00000073U
    @decode.EBREAK => 0x00100073U

    // Zicsr instructions
    @decode.CSRRW(rd, csr, rs1) => encode_csr(rd, csr, rs1, 0x1U)
    @decode.CSRRS(rd, csr, rs1) => encode_csr(rd, csr, rs1, 0x2U)
    @decode.CSRRC(rd, csr, rs1) => encode_csr(rd, csr, rs1, 0x3U)
    @decode.CSRRWI(rd, csr, uimm) => encode_csr_imm(rd, csr, uimm, 0x5U)
    @decode.CSRRSI(rd, csr, uimm) => encode_csr_imm(rd, csr, uimm, 0x6U)
    @decode.CSRRCI(rd, csr, uimm) => encode_csr_imm(rd, csr, uimm, 0x7U)

    // Zba extension
    @decode.SH1ADD(rd, rs1, rs2) => encode_r_type_zba(rd, rs1, rs2, 0x2U)
    @decode.SH2ADD(rd, rs1, rs2) => encode_r_type_zba(rd, rs1, rs2, 0x4U)
    @decode.SH3ADD(rd, rs1, rs2) => encode_r_type_zba(rd, rs1, rs2, 0x6U)
    @decode.SH1ADD_UW(rd, rs1, rs2) =>
      encode_r_type_zba64(rd, rs1, rs2, 0x10U, 0x2U)
    @decode.SH2ADD_UW(rd, rs1, rs2) =>
      encode_r_type_zba64(rd, rs1, rs2, 0x10U, 0x4U)
    @decode.SH3ADD_UW(rd, rs1, rs2) =>
      encode_r_type_zba64(rd, rs1, rs2, 0x10U, 0x6U)
    @decode.ADD_UW(rd, rs1, rs2) =>
      encode_r_type_zba64(rd, rs1, rs2, 0x4U, 0x0U)
    @decode.SLLI_UW(rd, rs1, shamt) => encode_shift_imm_uw(rd, rs1, shamt)

    // Zbb extension
    @decode.ANDN(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x20U, 0x7U)
    @decode.ORN(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x20U, 0x6U)
    @decode.XNOR(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x20U, 0x4U)
    @decode.CLZ(rd, rs1) => encode_unary_zbb(rd, rs1, 0x0U)
    @decode.CTZ(rd, rs1) => encode_unary_zbb(rd, rs1, 0x1U)
    @decode.CPOP(rd, rs1) => encode_unary_zbb(rd, rs1, 0x2U)
    @decode.SEXT_B(rd, rs1) => encode_unary_zbb(rd, rs1, 0x4U)
    @decode.SEXT_H(rd, rs1) => encode_unary_zbb(rd, rs1, 0x5U)
    @decode.ZEXT_H(rd, rs1) => encode_zext_h(rd, rs1)
    @decode.MAX(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x5U, 0x6U)
    @decode.MAXU(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x5U, 0x7U)
    @decode.MIN(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x5U, 0x2U)
    @decode.MINU(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x5U, 0x3U)
    @decode.ROL(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x30U, 0x1U)
    @decode.ROR(rd, rs1, rs2) => encode_r_type_zbb(rd, rs1, rs2, 0x30U, 0x5U)
    @decode.RORI(rd, rs1, shamt) => encode_rori(rd, rs1, shamt)
    @decode.ORC_B(rd, rs1) => encode_orc_b(rd, rs1)
    @decode.REV8(rd, rs1) => encode_rev8(rd, rs1)
    @decode.CLZW(rd, rs1) => encode_unary_zbb64(rd, rs1, 0x0U)
    @decode.CTZW(rd, rs1) => encode_unary_zbb64(rd, rs1, 0x1U)
    @decode.CPOPW(rd, rs1) => encode_unary_zbb64(rd, rs1, 0x2U)
    @decode.ROLW(rd, rs1, rs2) => encode_r_type_zbb64(rd, rs1, rs2, 0x30U, 0x1U)
    @decode.RORW(rd, rs1, rs2) => encode_r_type_zbb64(rd, rs1, rs2, 0x30U, 0x5U)
    @decode.RORIW(rd, rs1, shamt) => encode_roriw(rd, rs1, shamt)

    // Zbc extension
    @decode.CLMUL(rd, rs1, rs2) => encode_r_type_zbc(rd, rs1, rs2, 0x1U)
    @decode.CLMULH(rd, rs1, rs2) => encode_r_type_zbc(rd, rs1, rs2, 0x3U)
    @decode.CLMULR(rd, rs1, rs2) => encode_r_type_zbc(rd, rs1, rs2, 0x2U)

    // Zbs extension
    @decode.BCLR(rd, rs1, rs2) => encode_r_type_zbs(rd, rs1, rs2, 0x24U, 0x4U)
    @decode.BCLRI(rd, rs1, shamt) => encode_zbs_imm(rd, rs1, shamt, 0x24U, 0x1U)
    @decode.BEXT(rd, rs1, rs2) => encode_r_type_zbs(rd, rs1, rs2, 0x25U, 0x5U)
    @decode.BEXTI(rd, rs1, shamt) => encode_zbs_imm(rd, rs1, shamt, 0x24U, 0x5U)
    @decode.BINV(rd, rs1, rs2) => encode_r_type_zbs(rd, rs1, rs2, 0x34U, 0x5U)
    @decode.BINVI(rd, rs1, shamt) => encode_zbs_imm(rd, rs1, shamt, 0x34U, 0x5U)
    @decode.BSET(rd, rs1, rs2) => encode_r_type_zbs(rd, rs1, rs2, 0x14U, 0x6U)
    @decode.BSETI(rd, rs1, shamt) => encode_zbs_imm(rd, rs1, shamt, 0x14U, 0x1U)

    // RV32A extension
    @decode.LR_W(rd, rs1, aq, rl) => encode_lr_w(rd, rs1, aq, rl)
    @decode.SC_W(rd, rs1, rs2, aq, rl) => encode_sc_w(rd, rs1, rs2, aq, rl)
    @decode.AMOSWAP_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x1U)
    @decode.AMOADD_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x0U)
    @decode.AMOXOR_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x4U)
    @decode.AMOAND_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x0CU)
    @decode.AMOOR_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x08U)
    @decode.AMOMIN_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x10U)
    @decode.AMOMAX_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x14U)
    @decode.AMOMINU_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x18U)
    @decode.AMOMAXU_W(rd, rs1, rs2, aq, rl) =>
      encode_amo_w(rd, rs1, rs2, aq, rl, 0x1CU)

    // RV64A extension
    @decode.LR_D(rd, rs1, aq, rl) => encode_lr_d(rd, rs1, aq, rl)
    @decode.SC_D(rd, rs1, rs2, aq, rl) => encode_sc_d(rd, rs1, rs2, aq, rl)
    @decode.AMOSWAP_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x1U)
    @decode.AMOADD_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x0U)
    @decode.AMOXOR_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x4U)
    @decode.AMOAND_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x0CU)
    @decode.AMOOR_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x08U)
    @decode.AMOMIN_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x10U)
    @decode.AMOMAX_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x14U)
    @decode.AMOMINU_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x18U)
    @decode.AMOMAXU_D(rd, rs1, rs2, aq, rl) =>
      encode_amo_d(rd, rs1, rs2, aq, rl, 0x1CU)

    // Unknown instruction
    _ => 0x00000013U // NOP (addi x0, x0, 0)
  }
  { code, is_compressed: false }
}

///|
/// Encode a compressed (16-bit) instruction
pub fn encode_compressed(inst : @decode.Instruction) -> EncodeResult {
  let code = match inst {
    @decode.C_NOP => 0x0000U
    @decode.C_ADDI4SPN(rd, imm) => encode_c_addi4spn(rd, imm)
    @decode.C_LW(rd, rs1, imm) => encode_c_lw(rd, rs1, imm)
    @decode.C_SW(rs2, rs1, imm) => encode_c_sw(rs2, rs1, imm)
    @decode.C_ADDI(rd, imm) => encode_c_addi(rd, imm)
    @decode.C_JAL(imm) => encode_c_jal(imm)
    @decode.C_LI(rd, imm) => encode_c_li(rd, imm)
    @decode.C_ADDI16SP(imm) => encode_c_addi16sp(imm)
    @decode.C_LUI(rd, imm) => encode_c_lui(rd, imm)
    @decode.C_SRLI(rd, shamt) => encode_c_srli(rd, shamt)
    @decode.C_SRAI(rd, shamt) => encode_c_srai(rd, shamt)
    @decode.C_ANDI(rd, imm) => encode_c_andi(rd, imm)
    @decode.C_SUB(rd, rs2) => encode_c_sub(rd, rs2)
    @decode.C_XOR(rd, rs2) => encode_c_xor(rd, rs2)
    @decode.C_OR(rd, rs2) => encode_c_or(rd, rs2)
    @decode.C_AND(rd, rs2) => encode_c_and(rd, rs2)
    @decode.C_J(imm) => encode_c_j(imm)
    @decode.C_BEQZ(rs1, imm) => encode_c_beqz(rs1, imm)
    @decode.C_BNEZ(rs1, imm) => encode_c_bnez(rs1, imm)
    @decode.C_SLLI(rd, shamt) => encode_c_slli(rd, shamt)
    @decode.C_LWSP(rd, imm) => encode_c_lwsp(rd, imm)
    @decode.C_JR(rs1) => encode_c_jr(rs1)
    @decode.C_MV(rd, rs2) => encode_c_mv(rd, rs2)
    @decode.C_EBREAK => 0x9002U
    @decode.C_JALR(rs1) => encode_c_jalr(rs1)
    @decode.C_ADD(rd, rs2) => encode_c_add(rd, rs2)
    @decode.C_SWSP(rs2, imm) => encode_c_swsp(rs2, imm)
    _ => 0x0000U // Invalid compressed instruction
  }
  { code, is_compressed: true }
}

// ============================================================================
// 32-bit Instruction Encoding Helpers
// ============================================================================

///|
/// Encode R-type instruction
fn encode_r_type(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct3 : UInt,
  funct7 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode R-type instruction with extension (RV32M)
fn encode_r_type_ext(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct3 : UInt,
  funct7 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode R-type instruction for RV64 32-bit operations
fn encode_r_type_32(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct3 : UInt,
  funct7 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_OP32
}

///|
/// Encode R-type instruction for RV64M 32-bit operations
fn encode_r_type_32_ext(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct3 : UInt,
) -> UInt {
  (0x1U << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_OP32
}

///|
/// Encode I-type instruction
fn encode_i_type(
  rd : UInt,
  rs1 : UInt,
  imm : Int,
  funct3 : UInt,
  opcode : UInt,
) -> UInt {
  let imm_bits = imm.reinterpret_as_uint() & 0xFFFU
  (imm_bits << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
}

///|
/// Encode S-type instruction
fn encode_s_type(rs1 : UInt, rs2 : UInt, imm : Int, funct3 : UInt) -> UInt {
  let imm_bits = imm.reinterpret_as_uint()
  let imm_11_5 = (imm_bits >> 5) & 0x7FU
  let imm_4_0 = imm_bits & 0x1FU
  (imm_11_5 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (imm_4_0 << 7) |
  OP_STORE
}

///|
/// Encode B-type instruction
fn encode_b_type(rs1 : UInt, rs2 : UInt, imm : Int, funct3 : UInt) -> UInt {
  let imm_bits = imm.reinterpret_as_uint()
  let imm_12 = (imm_bits >> 12) & 0x1U
  let imm_11 = (imm_bits >> 11) & 0x1U
  let imm_10_5 = (imm_bits >> 5) & 0x3FU
  let imm_4_1 = (imm_bits >> 1) & 0xFU
  (imm_12 << 31) |
  (imm_10_5 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (imm_4_1 << 8) |
  (imm_11 << 7) |
  OP_BRANCH
}

///|
/// Encode U-type instruction
fn encode_u_type(rd : UInt, imm : Int, opcode : UInt) -> UInt {
  let imm_bits = imm.reinterpret_as_uint() & 0xFFFFFU
  (imm_bits << 12) | (rd << 7) | opcode
}

///|
/// Encode J-type instruction
fn encode_j_type(rd : UInt, imm : Int) -> UInt {
  let imm_bits = imm.reinterpret_as_uint()
  let imm_20 = (imm_bits >> 20) & 0x1U
  let imm_10_1 = (imm_bits >> 1) & 0x3FFU
  let imm_11 = (imm_bits >> 11) & 0x1U
  let imm_19_12 = (imm_bits >> 12) & 0xFFU
  let encoded = (imm_20 << 31) |
    (imm_10_1 << 21) |
    (imm_11 << 20) |
    (imm_19_12 << 12) |
    (rd << 7) |
    OP_JAL
  encoded
}

///|
/// Encode shift immediate instruction (SLLI, SRLI, SRAI)
fn encode_shift_imm(
  rd : UInt,
  rs1 : UInt,
  shamt : UInt,
  funct7 : UInt,
  funct3 : UInt,
) -> UInt {
  (funct7 << 25) |
  (shamt << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_IMM
}

///|
/// Encode shift immediate instruction for RV64 32-bit operations
fn encode_shift_imm32(
  rd : UInt,
  rs1 : UInt,
  shamt : UInt,
  funct7 : UInt,
) -> UInt {
  (funct7 << 25) |
  (shamt << 20) |
  (rs1 << 15) |
  (0x1U << 12) |
  (rd << 7) |
  OP_OP_IMM32
}

///|
/// Encode fence instruction
fn encode_fence(pred : UInt, succ : UInt) -> UInt {
  (0xFU << 28) | (pred << 24) | (succ << 20) | OP_MISC_MEM
}

///|
const OP_MISC_MEM : UInt = 0x0FU

///|
/// Encode CSR instruction
fn encode_csr(rd : UInt, csr : UInt, rs1 : UInt, funct3 : UInt) -> UInt {
  (csr << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP_SYSTEM
}

///|
/// Encode CSR immediate instruction
fn encode_csr_imm(rd : UInt, csr : UInt, uimm : UInt, funct3 : UInt) -> UInt {
  (csr << 20) | (uimm << 15) | (funct3 << 12) | (rd << 7) | OP_SYSTEM
}

// ============================================================================
// Zba/Zbb/Zbc/Zbs Encoding Helpers
// ============================================================================

///|
/// Encode Zba extension R-type instruction
fn encode_r_type_zba(rd : UInt, rs1 : UInt, rs2 : UInt, funct3 : UInt) -> UInt {
  (0x10U << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode Zba extension R-type instruction for RV64
fn encode_r_type_zba64(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct7 : UInt,
  funct3 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_OP32
}

///|
/// Encode SLLI_UW instruction
fn encode_shift_imm_uw(rd : UInt, rs1 : UInt, shamt : UInt) -> UInt {
  (0x4U << 25) |
  (shamt << 20) |
  (rs1 << 15) |
  (0x1U << 12) |
  (rd << 7) |
  OP_OP_IMM32
}

///|
/// Encode Zbb extension R-type instruction
fn encode_r_type_zbb(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct7 : UInt,
  funct3 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode unary Zbb instruction (CLZ, CTZ, CPOP, etc.)
fn encode_unary_zbb(rd : UInt, rs1 : UInt, funct5 : UInt) -> UInt {
  (0x30U << 25) |
  (funct5 << 20) |
  (rs1 << 15) |
  (0x1U << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode unary Zbb instruction for RV64
fn encode_unary_zbb64(rd : UInt, rs1 : UInt, funct5 : UInt) -> UInt {
  (0x30U << 25) |
  (funct5 << 20) |
  (rs1 << 15) |
  (0x1U << 12) |
  (rd << 7) |
  OP_OP32
}

///|
/// Encode RORI instruction
fn encode_rori(rd : UInt, rs1 : UInt, shamt : UInt) -> UInt {
  (0x30U << 25) |
  (shamt << 20) |
  (rs1 << 15) |
  (0x5U << 12) |
  (rd << 7) |
  OP_IMM
}

///|
/// Encode REV8 instruction
fn encode_rev8(rd : UInt, rs1 : UInt) -> UInt {
  (0x34U << 25) |
  (0x18U << 20) |
  (rs1 << 15) |
  (0x5U << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode Zbb extension R-type instruction for RV64
fn encode_r_type_zbb64(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct7 : UInt,
  funct3 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_OP32
}

///|
/// Encode RORIW instruction
fn encode_roriw(rd : UInt, rs1 : UInt, shamt : UInt) -> UInt {
  (0x30U << 25) |
  (shamt << 20) |
  (rs1 << 15) |
  (0x5U << 12) |
  (rd << 7) |
  OP_OP_IMM32
}

///|
fn encode_zext_h(rd : UInt, rs1 : UInt) -> UInt {
  (0x4U << 25) | (rs1 << 15) | (0x4U << 12) | (rd << 7) | OP_REG
}

///|
fn encode_orc_b(rd : UInt, rs1 : UInt) -> UInt {
  (0x14U << 25) | (0x7U << 20) | (rs1 << 15) | (0x5U << 12) | (rd << 7) | OP_REG
}

///|
/// Encode Zbc extension R-type instruction
fn encode_r_type_zbc(rd : UInt, rs1 : UInt, rs2 : UInt, funct3 : UInt) -> UInt {
  (0x5U << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | OP_REG
}

///|
/// Encode Zbs extension R-type instruction
fn encode_r_type_zbs(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  funct7 : UInt,
  funct3 : UInt,
) -> UInt {
  (funct7 << 25) |
  (rs2 << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_REG
}

///|
/// Encode Zbs extension immediate instruction
fn encode_zbs_imm(
  rd : UInt,
  rs1 : UInt,
  shamt : UInt,
  funct7 : UInt,
  funct3 : UInt,
) -> UInt {
  (funct7 << 25) |
  (shamt << 20) |
  (rs1 << 15) |
  (funct3 << 12) |
  (rd << 7) |
  OP_IMM
}

// ============================================================================
// Atomic (A extension) Encoding Helpers
// ============================================================================

///|
/// Encode LR.W instruction
fn encode_lr_w(rd : UInt, rs1 : UInt, aq : UInt, rl : UInt) -> UInt {
  let aq_rl = ((aq << 1) | rl) << 24
  aq_rl | (0x2U << 27) | (rs1 << 15) | (0x2U << 12) | (rd << 7) | OP_AMO
}

///|
/// Encode SC.W instruction
fn encode_sc_w(rd : UInt, rs1 : UInt, rs2 : UInt, aq : UInt, rl : UInt) -> UInt {
  let aq_rl = ((aq << 1) | rl) << 24
  aq_rl |
  (0x3U << 27) |
  (rs2 << 20) |
  (rs1 << 15) |
  (0x2U << 12) |
  (rd << 7) |
  OP_AMO
}

///|
/// Encode AMO.W instruction
fn encode_amo_w(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  aq : UInt,
  rl : UInt,
  funct5 : UInt,
) -> UInt {
  let aq_rl = ((aq << 1) | rl) << 24
  aq_rl |
  (funct5 << 27) |
  (rs2 << 20) |
  (rs1 << 15) |
  (0x2U << 12) |
  (rd << 7) |
  OP_AMO
}

///|
/// Encode LR.D instruction
fn encode_lr_d(rd : UInt, rs1 : UInt, aq : UInt, rl : UInt) -> UInt {
  let aq_rl = ((aq << 1) | rl) << 24
  aq_rl | (0x2U << 27) | (0x1U << 12) | (rs1 << 15) | (rd << 7) | OP_AMO
}

///|
/// Encode SC.D instruction
fn encode_sc_d(rd : UInt, rs1 : UInt, rs2 : UInt, aq : UInt, rl : UInt) -> UInt {
  let aq_rl = ((aq << 1) | rl) << 24
  aq_rl |
  (0x3U << 27) |
  (rs2 << 20) |
  (rs1 << 15) |
  (0x3U << 12) |
  (rd << 7) |
  OP_AMO
}

///|
/// Encode AMO.D instruction
fn encode_amo_d(
  rd : UInt,
  rs1 : UInt,
  rs2 : UInt,
  aq : UInt,
  rl : UInt,
  funct5 : UInt,
) -> UInt {
  let aq_rl = ((aq << 1) | rl) << 24
  aq_rl |
  (funct5 << 27) |
  (rs2 << 20) |
  (rs1 << 15) |
  (0x3U << 12) |
  (rd << 7) |
  OP_AMO
}

// ============================================================================
// Compressed (C extension) Encoding Helpers
// ============================================================================

///|
/// Encode C.ADDI4SPN
fn encode_c_addi4spn(rd : UInt, imm : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  let imm_5_4 = (imm >> 4) & 0x3U
  let imm_9_6 = (imm >> 6) & 0xFU
  let imm_2 = (imm >> 2) & 0x1U
  let imm_3 = (imm >> 3) & 0x1U
  (0x0U << 13) |
  (imm_5_4 << 11) |
  (imm_9_6 << 7) |
  (imm_2 << 6) |
  (imm_3 << 5) |
  (rd_prime << 2) |
  0x0U
}

///|
/// Encode C.LW
fn encode_c_lw(rd : UInt, rs1 : UInt, imm : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  let rs1_prime = rs1 & 0x7U
  let imm_6_6 = (imm >> 6) & 0x1U
  let imm_2_2 = (imm >> 2) & 0x1U
  let imm_5_3 = (imm >> 3) & 0x7U
  (0x2U << 13) |
  (imm_6_6 << 11) |
  (imm_2_2 << 10) |
  (imm_5_3 << 6) |
  (rs1_prime << 7) |
  (rd_prime << 2)
}

///|
/// Encode C.SW
fn encode_c_sw(rs2 : UInt, rs1 : UInt, imm : UInt) -> UInt {
  let rs2_prime = rs2 & 0x7U
  let rs1_prime = rs1 & 0x7U
  let imm_6_6 = (imm >> 6) & 0x1U
  let imm_2_2 = (imm >> 2) & 0x1U
  let imm_5_3 = (imm >> 3) & 0x7U
  (0x6U << 13) |
  (imm_6_6 << 11) |
  (imm_2_2 << 10) |
  (imm_5_3 << 6) |
  (rs1_prime << 7) |
  (rs2_prime << 2)
}

///|
/// Encode C.ADDI
fn encode_c_addi(rd : UInt, imm : Int) -> UInt {
  let rd_bits = rd & 0x1FU
  let imm_bits = imm.reinterpret_as_uint()
  let imm_5 = (imm_bits >> 5) & 0x1U
  let imm_4_0 = imm_bits & 0x1FU
  (0x0U << 13) | (imm_5 << 12) | (imm_4_0 << 7) | (rd_bits << 2) | 0x1U
}

///|
/// Encode C.JAL
fn encode_c_jal(imm : Int) -> UInt {
  let imm_bits = imm.reinterpret_as_uint()
  let imm_11 = (imm_bits >> 11) & 0x1U
  let imm_4 = (imm_bits >> 4) & 0x1U
  let imm_9_8 = (imm_bits >> 8) & 0x3U
  let imm_10 = (imm_bits >> 10) & 0x1U
  let imm_6 = (imm_bits >> 6) & 0x1U
  let imm_7 = (imm_bits >> 7) & 0x1U
  let imm_3_1 = (imm_bits >> 1) & 0x7U
  let imm_5 = (imm_bits >> 5) & 0x1U
  (0x1U << 13) |
  (imm_11 << 12) |
  (imm_4 << 11) |
  (imm_9_8 << 9) |
  (imm_10 << 8) |
  (imm_6 << 7) |
  (imm_7 << 6) |
  (imm_3_1 << 3) |
  (imm_5 << 2) |
  0x1U
}

///|
/// Encode C.LI
fn encode_c_li(rd : UInt, imm : Int) -> UInt {
  let rd_bits = rd & 0x1FU
  let imm_bits = imm.reinterpret_as_uint()
  let imm_5 = (imm_bits >> 5) & 0x1U
  let imm_4_0 = imm_bits & 0x1FU
  (0x2U << 13) | (imm_5 << 12) | (imm_4_0 << 7) | (rd_bits << 2) | 0x1U
}

///|
/// Encode C.ADDI16SP
fn encode_c_addi16sp(imm : Int) -> UInt {
  let imm_bits = imm.reinterpret_as_uint()
  let imm_9 = (imm_bits >> 9) & 0x1U
  let imm_4 = (imm_bits >> 4) & 0x1U
  let imm_6 = (imm_bits >> 6) & 0x1U
  let imm_8_7 = (imm_bits >> 7) & 0x3U
  let imm_5 = (imm_bits >> 5) & 0x1U
  (0x3U << 13) |
  (imm_9 << 12) |
  (0x2U << 7) |
  (imm_4 << 6) |
  (imm_6 << 5) |
  (imm_8_7 << 3) |
  (imm_5 << 2) |
  0x1U
}

///|
/// Encode C.LUI
fn encode_c_lui(rd : UInt, imm : Int) -> UInt {
  let rd_bits = rd & 0x1FU
  let imm_bits = imm.reinterpret_as_uint()
  let imm_5 = (imm_bits >> 5) & 0x1FU
  (0x3U << 13) | (imm_5 << 12) | (imm_5 << 7) | (rd_bits << 2) | 0x1U
}

///|
/// Encode C.SRLI
fn encode_c_srli(rd : UInt, shamt : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  (0x4U << 13) | (shamt << 7) | (rd_prime << 2) | 0x1U
}

///|
/// Encode C.SRAI
fn encode_c_srai(rd : UInt, shamt : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  (0x4U << 13) | (0x1U << 10) | (shamt << 7) | (rd_prime << 2) | 0x1U
}

///|
/// Encode C.ANDI
fn encode_c_andi(rd : UInt, imm : Int) -> UInt {
  let rd_prime = rd & 0x7U
  let imm_bits = imm.reinterpret_as_uint()
  let imm_5 = (imm_bits >> 5) & 0x1U
  let imm_4_0 = imm_bits & 0x1FU
  (0x4U << 13) |
  (imm_5 << 12) |
  (0x2U << 10) |
  (imm_4_0 << 7) |
  (rd_prime << 2) |
  0x1U
}

///|
/// Encode C.SUB
fn encode_c_sub(rd : UInt, rs2 : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  let rs2_prime = rs2 & 0x7U
  (0x4U << 13) | (0x3U << 10) | (rd_prime << 7) | (rs2_prime << 2) | 0x1U
}

///|
/// Encode C.XOR
fn encode_c_xor(rd : UInt, rs2 : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  let rs2_prime = rs2 & 0x7U
  (0x4U << 13) |
  (0x3U << 10) |
  (0x1U << 5) |
  (rd_prime << 7) |
  (rs2_prime << 2) |
  0x1U
}

///|
/// Encode C.OR
fn encode_c_or(rd : UInt, rs2 : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  let rs2_prime = rs2 & 0x7U
  (0x4U << 13) |
  (0x3U << 10) |
  (0x2U << 5) |
  (rd_prime << 7) |
  (rs2_prime << 2) |
  0x1U
}

///|
/// Encode C.AND
fn encode_c_and(rd : UInt, rs2 : UInt) -> UInt {
  let rd_prime = rd & 0x7U
  let rs2_prime = rs2 & 0x7U
  (0x4U << 13) |
  (0x3U << 10) |
  (0x3U << 5) |
  (rd_prime << 7) |
  (rs2_prime << 2) |
  0x1U
}

///|
/// Encode C.J
fn encode_c_j(imm : Int) -> UInt {
  let imm_bits = imm.reinterpret_as_uint()
  let imm_11 = (imm_bits >> 11) & 0x1U
  let imm_4 = (imm_bits >> 4) & 0x1U
  let imm_9_8 = (imm_bits >> 8) & 0x3U
  let imm_10 = (imm_bits >> 10) & 0x1U
  let imm_6 = (imm_bits >> 6) & 0x1U
  let imm_7 = (imm_bits >> 7) & 0x1U
  let imm_3_1 = (imm_bits >> 1) & 0x7U
  let imm_5 = (imm_bits >> 5) & 0x1U
  (0x5U << 13) |
  (imm_11 << 12) |
  (imm_4 << 11) |
  (imm_9_8 << 9) |
  (imm_10 << 8) |
  (imm_6 << 7) |
  (imm_7 << 6) |
  (imm_3_1 << 3) |
  (imm_5 << 2) |
  0x1U
}

///|
/// Encode C.BEQZ
fn encode_c_beqz(rs1 : UInt, imm : Int) -> UInt {
  let rs1_prime = rs1 & 0x7U
  let imm_bits = imm.reinterpret_as_uint()
  let imm_8 = (imm_bits >> 8) & 0x1U
  let imm_4_3 = (imm_bits >> 3) & 0x3U
  let imm_7_6 = (imm_bits >> 6) & 0x3U
  let imm_2_1 = (imm_bits >> 1) & 0x3U
  let imm_5 = (imm_bits >> 5) & 0x1U
  (0x6U << 13) |
  (imm_8 << 12) |
  (imm_4_3 << 10) |
  (imm_7_6 << 5) |
  (rs1_prime << 7) |
  (imm_2_1 << 3) |
  (imm_5 << 2) |
  0x1U
}

///|
/// Encode C.BNEZ
fn encode_c_bnez(rs1 : UInt, imm : Int) -> UInt {
  let rs1_prime = rs1 & 0x7U
  let imm_bits = imm.reinterpret_as_uint()
  let imm_8 = (imm_bits >> 8) & 0x1U
  let imm_4_3 = (imm_bits >> 3) & 0x3U
  let imm_7_6 = (imm_bits >> 6) & 0x3U
  let imm_2_1 = (imm_bits >> 1) & 0x3U
  let imm_5 = (imm_bits >> 5) & 0x1U
  (0x7U << 13) |
  (imm_8 << 12) |
  (imm_4_3 << 10) |
  (imm_7_6 << 5) |
  (rs1_prime << 7) |
  (imm_2_1 << 3) |
  (imm_5 << 2) |
  0x1U
}

///|
/// Encode C.SLLI
fn encode_c_slli(rd : UInt, shamt : UInt) -> UInt {
  let rd_bits = rd & 0x1FU
  (0x0U << 13) | (shamt << 7) | (rd_bits << 2) | 0x2U
}

///|
/// Encode C.LWSP
fn encode_c_lwsp(rd : UInt, imm : UInt) -> UInt {
  let rd_bits = rd & 0x1FU
  let imm_7_6 = (imm >> 6) & 0x3U
  let imm_2 = (imm >> 2) & 0x1U
  let imm_5_3 = (imm >> 3) & 0x7U
  (0x2U << 13) |
  (imm_7_6 << 11) |
  (imm_2 << 10) |
  (imm_5_3 << 6) |
  (rd_bits << 2) |
  0x2U
}

///|
/// Encode C.JR
fn encode_c_jr(rs1 : UInt) -> UInt {
  let rs1_bits = rs1 & 0x1FU
  (0x4U << 13) | (rs1_bits << 7) | 0x2U
}

///|
/// Encode C.MV
fn encode_c_mv(rd : UInt, rs2 : UInt) -> UInt {
  let rd_bits = rd & 0x1FU
  let rs2_bits = rs2 & 0x1FU
  (0x4U << 13) | (rs2_bits << 7) | (rd_bits << 2) | 0x2U
}

///|
/// Encode C.JALR
fn encode_c_jalr(rs1 : UInt) -> UInt {
  let rs1_bits = rs1 & 0x1FU
  (0x5U << 13) | (rs1_bits << 7) | 0x2U
}

///|
/// Encode C.ADD
fn encode_c_add(rd : UInt, rs2 : UInt) -> UInt {
  let rd_bits = rd & 0x1FU
  let rs2_bits = rs2 & 0x1FU
  (0x5U << 13) | (rs2_bits << 7) | (rd_bits << 2) | 0x2U
}

///|
/// Encode C.SWSP
fn encode_c_swsp(rs2 : UInt, imm : UInt) -> UInt {
  let rs2_bits = rs2 & 0x1FU
  let imm_7_6 = (imm >> 6) & 0x3U
  let imm_5_2 = (imm >> 2) & 0xFU
  (0x6U << 13) | (imm_7_6 << 11) | (imm_5_2 << 7) | (rs2_bits << 2) | 0x2U
}

///|
/// Convert instruction to bytes (little-endian)
pub fn encode_to_bytes(inst : @decode.Instruction) -> FixedArray[Byte] {
  let result = encode(inst)
  if result.is_compressed {
    let code = result.code
    let b0 = (code & 0xFFU).to_byte()
    let b1 = ((code >> 8) & 0xFFU).to_byte()
    let arr = FixedArray::make(2, b0)
    arr[1] = b1
    arr
  } else {
    let code = result.code
    let b0 = (code & 0xFFU).to_byte()
    let b1 = ((code >> 8) & 0xFFU).to_byte()
    let b2 = ((code >> 16) & 0xFFU).to_byte()
    let b3 = ((code >> 24) & 0xFFU).to_byte()
    let arr = FixedArray::make(4, b0)
    arr[1] = b1
    arr[2] = b2
    arr[3] = b3
    arr
  }
}
