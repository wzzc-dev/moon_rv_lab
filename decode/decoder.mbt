///| RISC-V instruction decoder

///| Implements decoding logic for RV32I base instruction set

///|
/// Decode result type
pub struct DecodeResult(Instruction)

///|
/// Extract bits from a 32-bit instruction
fn extract_bits(code : UInt, hi : Int, lo : Int) -> UInt {
  let mask = (1U << (hi - lo + 1)) - 1U
  (code >> lo) & mask
}

///|
/// Sign extend a 12-bit value to signed Int
fn sign_extend_12(value : UInt) -> Int {
  let sign_bit = (value >> 11).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 4096
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Sign extend 13-bit value (for branch)
fn sign_extend_13(value : UInt) -> Int {
  let sign_bit = (value >> 12).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 8192
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Sign extend 20-bit value (for U-type immediate, as upper 20 bits)
fn _sign_extend_20(value : UInt) -> Int {
  let sign_bit = (value >> 19).reinterpret_as_int()
  if sign_bit == 1 {
    // Negative: set upper 12 bits to 1
    value.reinterpret_as_int() - 1048576
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Sign extend 21-bit value (for J-type)
fn sign_extend_21(value : UInt) -> Int {
  let sign_bit = (value >> 20).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 2097152
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Decode I-type immediate
fn decode_i_imm(code : UInt) -> Int {
  let imm = extract_bits(code, 31, 20)
  sign_extend_12(imm)
}

///|
/// Decode S-type immediate
fn decode_s_imm(code : UInt) -> Int {
  let imm_11_5 = extract_bits(code, 31, 25)
  let imm_4_0 = extract_bits(code, 11, 7)
  let imm = (imm_11_5 << 5) | imm_4_0
  sign_extend_12(imm)
}

///|
/// Decode B-type immediate
fn decode_b_imm(code : UInt) -> Int {
  let imm_12 = extract_bits(code, 31, 31)
  let imm_10_5 = extract_bits(code, 30, 25)
  let imm_4_1 = extract_bits(code, 11, 8)
  let imm_11 = extract_bits(code, 7, 7)
  let imm = (imm_12 << 12) | (imm_11 << 11) | (imm_10_5 << 5) | (imm_4_1 << 1)
  sign_extend_13(imm)
}

///| Decode U-type immediate

///|
/// The immediate is in bits [31:12], shifted left by 12 in the instruction
fn decode_u_imm(code : UInt) -> Int {
  // Extract bits [31:12] and shift left by 12 to get the final immediate
  // This gives a 32-bit value where bits [31:12] are the immediate
  let imm_high = code & 0xFFFFF000U
  // Now we need to interpret this as a signed 32-bit integer
  // If bit 31 is set, it's negative
  let sign_bit = (imm_high >> 31).reinterpret_as_int()
  if sign_bit == 1 {
    // For negative values, we need to sign extend
    // The value in imm_high has bit 31 set, so as unsigned it's >= 2^31
    // We need to convert it to a negative Int
    imm_high.reinterpret_as_int()
  } else {
    imm_high.reinterpret_as_int()
  }
}

///|
/// Decode J-type immediate
fn decode_j_imm(code : UInt) -> Int {
  let imm_20 = extract_bits(code, 31, 31)
  let imm_10_1 = extract_bits(code, 30, 21)
  let imm_11 = extract_bits(code, 20, 20)
  let imm_19_12 = extract_bits(code, 19, 12)
  let imm = (imm_20 << 20) |
    (imm_19_12 << 12) |
    (imm_11 << 11) |
    (imm_10_1 << 1)
  sign_extend_21(imm)
}

///|
/// Decode a 32-bit RISC-V instruction
pub fn decode(code : UInt) -> DecodeResult {
  let op = extract_bits(code, 6, 0)
  let rd = extract_bits(code, 11, 7)
  let f3 = extract_bits(code, 14, 12)
  let rs1 = extract_bits(code, 19, 15)
  let rs2 = extract_bits(code, 24, 20)
  let f7 = extract_bits(code, 31, 25)
  let csr = extract_bits(code, 31, 20) // CSR address for Zicsr instructions

  match op {
    // LUI
    0b0110111 => {
      let imm = decode_u_imm(code)
      DecodeResult(LUI(rd, imm))
    }
    // AUIPC
    0b0010111 => {
      let imm = decode_u_imm(code)
      DecodeResult(AUIPC(rd, imm))
    }
    // JAL
    0b1101111 => {
      let imm = decode_j_imm(code)
      DecodeResult(JAL(rd, imm))
    }
    // JALR
    0b1100111 => {
      let imm = decode_i_imm(code)
      DecodeResult(JALR(rd, rs1, imm))
    }
    // Branch
    0b1100011 => {
      let imm = decode_b_imm(code)
      match f3 {
        0b000 => DecodeResult(BEQ(rs1, rs2, imm))
        0b001 => DecodeResult(BNE(rs1, rs2, imm))
        0b100 => DecodeResult(BLT(rs1, rs2, imm))
        0b101 => DecodeResult(BGE(rs1, rs2, imm))
        0b110 => DecodeResult(BLTU(rs1, rs2, imm))
        0b111 => DecodeResult(BGEU(rs1, rs2, imm))
        _ => DecodeResult(Invalid(code))
      }
    }
    // Load
    0b0000011 => {
      let imm = decode_i_imm(code)
      match f3 {
        0b000 => DecodeResult(LB(rd, rs1, imm))
        0b001 => DecodeResult(LH(rd, rs1, imm))
        0b010 => DecodeResult(LW(rd, rs1, imm))
        0b011 => DecodeResult(LD(rd, rs1, imm)) // RV64I: load doubleword
        0b100 => DecodeResult(LBU(rd, rs1, imm))
        0b101 => DecodeResult(LHU(rd, rs1, imm))
        0b110 => DecodeResult(LWU(rd, rs1, imm)) // RV64I: load word unsigned
        _ => DecodeResult(Invalid(code))
      }
    }
    // LOAD-FP (RV32F/RV32D/RV32Q: floating-point load)
    0b0000111 => {
      let imm = decode_i_imm(code)
      match f3 {
        0b010 => DecodeResult(FLW(rd, rs1, imm)) // RV32F: load single
        0b011 => DecodeResult(FLD(rd, rs1, imm)) // RV32D: load double
        0b100 => DecodeResult(FLQ(rd, rs1, imm)) // RV32Q: load quad
        _ => DecodeResult(Invalid(code))
      }
    }
    // Store
    0b0100011 => {
      let imm = decode_s_imm(code)
      match f3 {
        0b000 => DecodeResult(SB(rs1, rs2, imm))
        0b001 => DecodeResult(SH(rs1, rs2, imm))
        0b010 => DecodeResult(SW(rs1, rs2, imm))
        0b011 => DecodeResult(SD(rs1, rs2, imm)) // RV64I: store doubleword
        _ => DecodeResult(Invalid(code))
      }
    }
    // STORE-FP (RV32F/RV32D/RV32Q: floating-point store)
    0b0100111 => {
      let imm = decode_s_imm(code)
      match f3 {
        0b010 => DecodeResult(FSW(rs1, rs2, imm)) // RV32F: store single
        0b011 => DecodeResult(FSD(rs1, rs2, imm)) // RV32D: store double
        0b100 => DecodeResult(FSQ(rs1, rs2, imm)) // RV32Q: store quad
        _ => DecodeResult(Invalid(code))
      }
    }
    // OP_IMM (Immediate arithmetic/logical) - includes Zbb/Zbs immediate extensions
    0b0010011 =>
      match f3 {
        0b000 => {
          let imm = decode_i_imm(code)
          DecodeResult(ADDI(rd, rs1, imm))
        }
        0b010 => {
          let imm = decode_i_imm(code)
          DecodeResult(SLTI(rd, rs1, imm))
        }
        0b011 => {
          let imm = decode_i_imm(code)
          DecodeResult(SLTIU(rd, rs1, imm))
        }
        0b100 => {
          let imm = decode_i_imm(code)
          DecodeResult(XORI(rd, rs1, imm))
        }
        0b110 => {
          let imm = decode_i_imm(code)
          DecodeResult(ORI(rd, rs1, imm))
        }
        0b111 => {
          let imm = decode_i_imm(code)
          DecodeResult(ANDI(rd, rs1, imm))
        }
        0b001 => {
          let shamt = extract_bits(code, 24, 20)
          match f7 {
            0b0000000 => DecodeResult(SLLI(rd, rs1, shamt))
            // Zbs: BSETI
            0b0010100 => DecodeResult(BSETI(rd, rs1, shamt))
            // Zbs: BCLRI
            0b0100100 => DecodeResult(BCLRI(rd, rs1, shamt))
            _ => DecodeResult(Invalid(code))
          }
        }
        0b101 => {
          let shamt = extract_bits(code, 24, 20)
          match f7 {
            0b0000000 => DecodeResult(SRLI(rd, rs1, shamt))
            0b0100000 => DecodeResult(SRAI(rd, rs1, shamt))
            // Zbb: RORI
            0b0110000 => DecodeResult(RORI(rd, rs1, shamt))
            // Zbs: BEXTI
            0b0100100 => DecodeResult(BEXTI(rd, rs1, shamt))
            // Zbs: BINVI
            0b0110100 => DecodeResult(BINVI(rd, rs1, shamt))
            _ => DecodeResult(Invalid(code))
          }
        }
        _ => DecodeResult(Invalid(code))
      }
    // OP (Register arithmetic/logical) - includes Zba/Zbb/Zbc/Zbs extensions
    0b0110011 =>
      match f3 {
        0b000 =>
          match f7 {
            0b0000000 => DecodeResult(ADD(rd, rs1, rs2))
            0b0100000 => DecodeResult(SUB(rd, rs1, rs2))
            0b0000001 => DecodeResult(MUL(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b001 =>
          match f7 {
            0b0000000 => DecodeResult(SLL(rd, rs1, rs2))
            0b0000001 => DecodeResult(MULH(rd, rs1, rs2))
            // Zbb: CLZ/CTZ/CPOP/ROL/SEXT_B/SEXT_H
            0b0110000 =>
              match rs2 {
                0b00000 => DecodeResult(CLZ(rd, rs1))
                0b00001 => DecodeResult(CTZ(rd, rs1))
                0b00010 => DecodeResult(CPOP(rd, rs1))
                0b00100 => DecodeResult(SEXT_B(rd, rs1))
                0b00101 => DecodeResult(SEXT_H(rd, rs1))
                _ => DecodeResult(ROL(rd, rs1, rs2))
              }
            // Zbc: CLMULR
            0b0000101 => DecodeResult(CLMULR(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b010 =>
          match f7 {
            0b0000000 => DecodeResult(SLT(rd, rs1, rs2))
            0b0000001 => DecodeResult(MULHSU(rd, rs1, rs2))
            // Zba: SH1ADD
            0b0010000 => DecodeResult(SH1ADD(rd, rs1, rs2))
            // Zbb: MIN
            0b0000101 => DecodeResult(MIN(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b011 =>
          match f7 {
            0b0000000 => DecodeResult(SLTU(rd, rs1, rs2))
            0b0000001 => DecodeResult(MULHU(rd, rs1, rs2))
            // Zbb: MINU
            0b0000101 => DecodeResult(MINU(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b100 =>
          match f7 {
            0b0000000 => DecodeResult(XOR(rd, rs1, rs2))
            0b0000001 => DecodeResult(DIV(rd, rs1, rs2))
            // Zba: SH2ADD
            0b0010000 => DecodeResult(SH2ADD(rd, rs1, rs2))
            // Zbb: ZEXT_H (rs2 = 0)
            0b0000100 =>
              if rs2 == 0U {
                DecodeResult(ZEXT_H(rd, rs1))
              } else {
                DecodeResult(Invalid(code))
              }
            // Zbb: XNOR
            0b0100000 => DecodeResult(XNOR(rd, rs1, rs2))
            // Zbc: CLMUL
            0b0000101 => DecodeResult(CLMUL(rd, rs1, rs2))
            // Zbs: BCLR
            0b0100100 => DecodeResult(BCLR(rd, rs1, rs2))
            // Zbs: BEXT
            0b0100101 => DecodeResult(BEXT(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b101 =>
          match f7 {
            0b0000000 => DecodeResult(SRL(rd, rs1, rs2))
            0b0100000 => DecodeResult(SRA(rd, rs1, rs2))
            0b0000001 => DecodeResult(DIVU(rd, rs1, rs2))
            // Zbb: ROR
            0b0110000 => DecodeResult(ROR(rd, rs1, rs2))
            // Zbc: CLMULH
            0b0000101 => DecodeResult(CLMULH(rd, rs1, rs2))
            // Zbs: BEXT
            0b0100101 => DecodeResult(BEXT(rd, rs1, rs2))
            // Zbs: BINV or Zbb: REV8 (rs2=11000=24)
            0b0110100 =>
              if rs2 == 0b11000U {
                DecodeResult(REV8(rd, rs1))
              } else {
                DecodeResult(BINV(rd, rs1, rs2))
              }
            // Zbs: BSET or Zbb: ORC_B (rs2=00111=7)
            0b0010100 =>
              if rs2 == 0b00111U {
                DecodeResult(ORC_B(rd, rs1))
              } else {
                DecodeResult(BSET(rd, rs1, rs2))
              }
            _ => DecodeResult(Invalid(code))
          }
        0b110 =>
          match f7 {
            0b0000000 => DecodeResult(OR(rd, rs1, rs2))
            0b0000001 => DecodeResult(REM(rd, rs1, rs2))
            // Zba: SH3ADD
            0b0010000 => DecodeResult(SH3ADD(rd, rs1, rs2))
            // Zbb: ORN
            0b0100000 => DecodeResult(ORN(rd, rs1, rs2))
            // Zbb: MAX
            0b0000101 => DecodeResult(MAX(rd, rs1, rs2))
            // Zbs: BSET
            0b0010100 => DecodeResult(BSET(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b111 =>
          match f7 {
            0b0000000 => DecodeResult(AND(rd, rs1, rs2))
            0b0000001 => DecodeResult(REMU(rd, rs1, rs2))
            // Zbb: ANDN
            0b0100000 => DecodeResult(ANDN(rd, rs1, rs2))
            // Zbb: MAXU
            0b0000101 => DecodeResult(MAXU(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        _ => DecodeResult(Invalid(code))
      }
    // MISC_MEM (Fence)
    0b0001111 =>
      match f3 {
        0b000 => {
          let pred = extract_bits(code, 27, 24)
          let succ = extract_bits(code, 23, 20)
          DecodeResult(FENCE(pred, succ))
        }
        0b001 => DecodeResult(FENCE_I)
        _ => DecodeResult(Invalid(code))
      }
    // OP_IMM_32 (RV64I: 32-bit immediate arithmetic)
    0b0011011 =>
      match f3 {
        0b000 => {
          let imm = decode_i_imm(code)
          DecodeResult(ADDIW(rd, rs1, imm))
        }
        0b001 => {
          let shamt = extract_bits(code, 24, 20)
          DecodeResult(SLLIW(rd, rs1, shamt))
        }
        0b101 => {
          let shamt = extract_bits(code, 24, 20)
          match f7 {
            0b0000000 => DecodeResult(SRLIW(rd, rs1, shamt))
            0b0100000 => DecodeResult(SRAIW(rd, rs1, shamt))
            _ => DecodeResult(Invalid(code))
          }
        }
        _ => DecodeResult(Invalid(code))
      }
    // OP_32 (RV64I/RV64M: 32-bit register arithmetic)
    0b0111011 =>
      match f3 {
        0b000 =>
          match f7 {
            0b0000000 => DecodeResult(ADDW(rd, rs1, rs2))
            0b0100000 => DecodeResult(SUBW(rd, rs1, rs2))
            0b0000001 => DecodeResult(MULW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b001 =>
          match f7 {
            0b0000000 => DecodeResult(SLLW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b100 =>
          match f7 {
            0b0000001 => DecodeResult(DIVW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b101 =>
          match f7 {
            0b0000000 => DecodeResult(SRLW(rd, rs1, rs2))
            0b0100000 => DecodeResult(SRAW(rd, rs1, rs2))
            0b0000001 => DecodeResult(DIVUW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b110 =>
          match f7 {
            0b0000001 => DecodeResult(REMW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b111 =>
          match f7 {
            0b0000001 => DecodeResult(REMUW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        _ => DecodeResult(Invalid(code))
      }
    // AMO (RV32A/RV64A: Atomic Memory Operations)
    0b0101111 => {
      // f7 = bits[31:25] = funct5[4:0] | aq | rl
      // funct5 = bits[31:27], aq = bit 26, rl = bit 25
      let f5 = f7 >> 2 // bits 31:27
      let aq = (f7 >> 1) & 0x1U // bit 26
      let rl = f7 & 0x1U // bit 25

      match f3 {
        // Word-size atomics (RV32A/RV64A)
        0b010 =>
          match f5 {
            // LR.W
            0b00010 => DecodeResult(LR_W(rd, rs1, aq, rl))
            // SC.W
            0b00011 => DecodeResult(SC_W(rd, rs1, rs2, aq, rl))
            // AMOSWAP.W
            0b00001 => DecodeResult(AMOSWAP_W(rd, rs1, rs2, aq, rl))
            // AMOADD.W
            0b00000 => DecodeResult(AMOADD_W(rd, rs1, rs2, aq, rl))
            // AMOXOR.W
            0b00100 => DecodeResult(AMOXOR_W(rd, rs1, rs2, aq, rl))
            // AMOAND.W
            0b01100 => DecodeResult(AMOAND_W(rd, rs1, rs2, aq, rl))
            // AMOOR.W
            0b01000 => DecodeResult(AMOOR_W(rd, rs1, rs2, aq, rl))
            // AMOMIN.W
            0b10000 => DecodeResult(AMOMIN_W(rd, rs1, rs2, aq, rl))
            // AMOMAX.W
            0b10100 => DecodeResult(AMOMAX_W(rd, rs1, rs2, aq, rl))
            // AMOMINU.W
            0b11000 => DecodeResult(AMOMINU_W(rd, rs1, rs2, aq, rl))
            // AMOMAXU.W
            0b11100 => DecodeResult(AMOMAXU_W(rd, rs1, rs2, aq, rl))
            _ => DecodeResult(Invalid(code))
          }
        // Doubleword-size atomics (RV64A only)
        0b011 =>
          match f5 {
            // LR.D
            0b00010 => DecodeResult(LR_D(rd, rs1, aq, rl))
            // SC.D
            0b00011 => DecodeResult(SC_D(rd, rs1, rs2, aq, rl))
            // AMOSWAP.D
            0b00001 => DecodeResult(AMOSWAP_D(rd, rs1, rs2, aq, rl))
            // AMOADD.D
            0b00000 => DecodeResult(AMOADD_D(rd, rs1, rs2, aq, rl))
            // AMOXOR.D
            0b00100 => DecodeResult(AMOXOR_D(rd, rs1, rs2, aq, rl))
            // AMOAND.D
            0b01100 => DecodeResult(AMOAND_D(rd, rs1, rs2, aq, rl))
            // AMOOR.D
            0b01000 => DecodeResult(AMOOR_D(rd, rs1, rs2, aq, rl))
            // AMOMIN.D
            0b10000 => DecodeResult(AMOMIN_D(rd, rs1, rs2, aq, rl))
            // AMOMAX.D
            0b10100 => DecodeResult(AMOMAX_D(rd, rs1, rs2, aq, rl))
            // AMOMINU.D
            0b11000 => DecodeResult(AMOMINU_D(rd, rs1, rs2, aq, rl))
            // AMOMAXU.D
            0b11100 => DecodeResult(AMOMAXU_D(rd, rs1, rs2, aq, rl))
            _ => DecodeResult(Invalid(code))
          }
        _ => DecodeResult(Invalid(code))
      }
    }
    // OP-FP (RV32F/RV32D: floating-point operations)
    // opcode = 0b1010011
    0b1010011 => {
      // For OP-FP, rm (rounding mode) is in f3
      // f7 determines the operation
      let rm = f3
      match f7 {
        // FADD.S
        0b0000000 => DecodeResult(FADD_S(rd, rs1, rs2))
        // FSUB.S
        0b0000100 => DecodeResult(FSUB_S(rd, rs1, rs2))
        // FMUL.S
        0b0001000 => DecodeResult(FMUL_S(rd, rs1, rs2))
        // FDIV_S
        0b0001100 => DecodeResult(FDIV_S(rd, rs1, rs2))
        // FADD.D
        0b0000001 => DecodeResult(FADD_D(rd, rs1, rs2))
        // FSUB.D
        0b0000101 => DecodeResult(FSUB_D(rd, rs1, rs2))
        // FMUL.D
        0b0001001 => DecodeResult(FMUL_D(rd, rs1, rs2))
        // FDIV.D
        0b0001101 => DecodeResult(FDIV_D(rd, rs1, rs2))
        // FADD.Q (quad-precision)
        0b0000011 => DecodeResult(FADD_Q(rd, rs1, rs2))
        // FSUB.Q
        0b0000111 => DecodeResult(FSUB_Q(rd, rs1, rs2))
        // FMUL.Q
        0b0001011 => DecodeResult(FMUL_Q(rd, rs1, rs2))
        // FDIV.Q
        0b0001111 => DecodeResult(FDIV_Q(rd, rs1, rs2))
        // FSQRT.S (rs2 must be 0)
        0b0101100 =>
          if rs2 == 0U {
            DecodeResult(FSQRT_S(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FSQRT.D (rs2 must be 0)
        0b0101101 =>
          if rs2 == 0U {
            DecodeResult(FSQRT_D(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FSQRT.Q (rs2 must be 0)
        0b0101111 =>
          if rs2 == 0U {
            DecodeResult(FSQRT_Q(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FSGNJ.S / FSGNJN.S / FSGNJX.S
        0b0010000 =>
          match rs2 {
            0b00000 => DecodeResult(FSGNJ_S(rd, rs1, rs2))
            0b00001 => DecodeResult(FSGNJN_S(rd, rs1, rs2))
            0b00010 => DecodeResult(FSGNJX_S(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FSGNJ.D / FSGNJN.D / FSGNJX.D
        0b0010001 =>
          match rs2 {
            0b00000 => DecodeResult(FSGNJ_D(rd, rs1, rs2))
            0b00001 => DecodeResult(FSGNJN_D(rd, rs1, rs2))
            0b00010 => DecodeResult(FSGNJX_D(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FSGNJ.Q / FSGNJN.Q / FSGNJX.Q
        0b0010011 =>
          match rs2 {
            0b00000 => DecodeResult(FSGNJ_Q(rd, rs1, rs2))
            0b00001 => DecodeResult(FSGNJN_Q(rd, rs1, rs2))
            0b00010 => DecodeResult(FSGNJX_Q(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FMIN.S / FMAX.S
        0b0010100 =>
          match rs2 {
            0b00000 => DecodeResult(FMIN_S(rd, rs1, rs2))
            0b00001 => DecodeResult(FMAX_S(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FMIN.D / FMAX.D
        0b0010101 =>
          match rs2 {
            0b00000 => DecodeResult(FMIN_D(rd, rs1, rs2))
            0b00001 => DecodeResult(FMAX_D(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FMIN.Q / FMAX.Q
        0b0010111 =>
          match rs2 {
            0b00000 => DecodeResult(FMIN_Q(rd, rs1, rs2))
            0b00001 => DecodeResult(FMAX_Q(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.W.S / FCVT.WU.S / FCVT.L.S / FCVT.LU.S (convert float to int)
        0b1100000 =>
          match rs2 {
            0b00000 => DecodeResult(FCVT_W_S(rd, rs1, rm))
            0b00001 => DecodeResult(FCVT_WU_S(rd, rs1, rm))
            0b00010 => DecodeResult(FCVT_L_S(rd, rs1, rm)) // RV64F
            0b00011 => DecodeResult(FCVT_LU_S(rd, rs1, rm)) // RV64F
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.W.D / FCVT.WU.D / FCVT.L.D / FCVT.LU.D
        0b1100001 =>
          match rs2 {
            0b00000 => DecodeResult(FCVT_W_D(rd, rs1, rm))
            0b00001 => DecodeResult(FCVT_WU_D(rd, rs1, rm))
            0b00010 => DecodeResult(FCVT_L_D(rd, rs1, rm)) // RV64D
            0b00011 => DecodeResult(FCVT_LU_D(rd, rs1, rm)) // RV64D
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.W.Q / FCVT.WU.Q / FCVT.L.Q / FCVT.LU.Q (convert quad to int)
        0b1100011 =>
          match rs2 {
            0b00000 => DecodeResult(FCVT_W_Q(rd, rs1, rm))
            0b00001 => DecodeResult(FCVT_WU_Q(rd, rs1, rm))
            0b00010 => DecodeResult(FCVT_L_Q(rd, rs1, rm)) // RV64Q
            0b00011 => DecodeResult(FCVT_LU_Q(rd, rs1, rm)) // RV64Q
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.S.W / FCVT.S.WU / FCVT.S.L / FCVT.S.LU (convert int to float)
        0b1101000 =>
          match rs2 {
            0b00000 => DecodeResult(FCVT_S_W(rd, rs1, rm))
            0b00001 => DecodeResult(FCVT_S_WU(rd, rs1, rm))
            0b00010 => DecodeResult(FCVT_S_L(rd, rs1, rm)) // RV64F
            0b00011 => DecodeResult(FCVT_S_LU(rd, rs1, rm)) // RV64F
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.D.W / FCVT.D.WU / FCVT.D.L / FCVT.D.LU
        0b1101001 =>
          match rs2 {
            0b00000 => DecodeResult(FCVT_D_W(rd, rs1, rm))
            0b00001 => DecodeResult(FCVT_D_WU(rd, rs1, rm))
            0b00010 => DecodeResult(FCVT_D_L(rd, rs1, rm)) // RV64D
            0b00011 => DecodeResult(FCVT_D_LU(rd, rs1, rm)) // RV64D
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.Q.W / FCVT.Q.WU / FCVT.Q.L / FCVT.Q.LU (convert int to quad)
        0b1101011 =>
          match rs2 {
            0b00000 => DecodeResult(FCVT_Q_W(rd, rs1, rm))
            0b00001 => DecodeResult(FCVT_Q_WU(rd, rs1, rm))
            0b00010 => DecodeResult(FCVT_Q_L(rd, rs1, rm)) // RV64Q
            0b00011 => DecodeResult(FCVT_Q_LU(rd, rs1, rm)) // RV64Q
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.S.D (convert double to single)
        0b0100000 =>
          if rs2 == 0b00001U {
            DecodeResult(FCVT_S_D(rd, rs1, rm))
          } else {
            DecodeResult(Invalid(code))
          }
        // FCVT.D.S (convert single to double)
        0b0100001 =>
          if rs2 == 0b00000U {
            DecodeResult(FCVT_D_S(rd, rs1, rm))
          } else {
            DecodeResult(Invalid(code))
          }
        // FCVT.S.Q (convert quad to single) / FCVT.Q.S (convert single to quad)
        0b0100011 =>
          match rs2 {
            0b00001 => DecodeResult(FCVT_S_Q(rd, rs1, rm))
            0b00000 => DecodeResult(FCVT_Q_S(rd, rs1, rm))
            _ => DecodeResult(Invalid(code))
          }
        // FCVT.D.Q (convert quad to double) / FCVT.Q.D (convert double to quad)
        0b0101011 =>
          match rs2 {
            0b00001 => DecodeResult(FCVT_D_Q(rd, rs1, rm))
            0b00000 => DecodeResult(FCVT_Q_D(rd, rs1, rm))
            _ => DecodeResult(Invalid(code))
          }
        // FEQ.S / FLT.S / FLE.S
        0b1010000 =>
          match rs2 {
            0b00010 => DecodeResult(FEQ_S(rd, rs1, rs2))
            0b00001 => DecodeResult(FLT_S(rd, rs1, rs2))
            0b00000 => DecodeResult(FLE_S(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FEQ.D / FLT.D / FLE.D
        0b1010001 =>
          match rs2 {
            0b00010 => DecodeResult(FEQ_D(rd, rs1, rs2))
            0b00001 => DecodeResult(FLT_D(rd, rs1, rs2))
            0b00000 => DecodeResult(FLE_D(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FEQ.Q / FLT.Q / FLE.Q
        0b1010011 =>
          match rs2 {
            0b00010 => DecodeResult(FEQ_Q(rd, rs1, rs2))
            0b00001 => DecodeResult(FLT_Q(rd, rs1, rs2))
            0b00000 => DecodeResult(FLE_Q(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // FCLASS.S / FMV.X.W
        0b1110000 =>
          match rs2 {
            0b00000 => DecodeResult(FCLASS_S(rd, rs1))
            0b10000 => DecodeResult(FMV_X_W(rd, rs1))
            _ => DecodeResult(Invalid(code))
          }
        // FCLASS.D / FMV.X.D
        0b1110001 =>
          match rs2 {
            0b00000 => DecodeResult(FCLASS_D(rd, rs1))
            0b10000 => DecodeResult(FMV_X_D(rd, rs1))
            _ => DecodeResult(Invalid(code))
          }
        // FCLASS.Q
        0b1110011 =>
          if rs2 == 0b00000U {
            DecodeResult(FCLASS_Q(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FMV.W.X
        0b1111000 =>
          if rs2 == 0b00000U {
            DecodeResult(FMV_W_X(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FMV.D.X
        0b1111001 =>
          if rs2 == 0b00000U {
            DecodeResult(FMV_D_X(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FMV.X.Q (RV64Q: move bits from quad to int)
        0b1111011 =>
          if rs2 == 0b00000U {
            DecodeResult(FMV_X_Q(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        // FMV.Q.X (RV64Q: move bits from int to quad)
        0b1111010 =>
          if rs2 == 0b00000U {
            DecodeResult(FMV_Q_X(rd, rs1))
          } else {
            DecodeResult(Invalid(code))
          }
        _ => DecodeResult(Invalid(code))
      }
    }
    // SYSTEM (including Zicsr)
    0b1110011 =>
      match f3 {
        0b000 =>
          if code == 0x00000073U {
            DecodeResult(ECALL)
          } else if code == 0x00100073U {
            DecodeResult(EBREAK)
          } else {
            DecodeResult(Invalid(code))
          }
        // Zicsr instructions
        0b001 => DecodeResult(CSRRW(rd, csr, rs1)) // CSRRW
        0b010 => DecodeResult(CSRRS(rd, csr, rs1)) // CSRRS
        0b011 => DecodeResult(CSRRC(rd, csr, rs1)) // CSRRC
        0b101 => DecodeResult(CSRRWI(rd, csr, rs1)) // CSRRWI (rs1 field is uimm)
        0b110 => DecodeResult(CSRRSI(rd, csr, rs1)) // CSRRSI (rs1 field is uimm)
        0b111 => DecodeResult(CSRRCI(rd, csr, rs1)) // CSRRCI (rs1 field is uimm)
        _ => DecodeResult(Invalid(code))
      }
    _ => DecodeResult(Invalid(code))
  }
}

///|
/// Decode instruction from bytes (little-endian)
pub fn decode_from_bytes(bytes : FixedArray[Byte]) -> DecodeResult? {
  if bytes.length() >= 4 {
    let code = bytes[0].to_uint() |
      (bytes[1].to_uint() << 8) |
      (bytes[2].to_uint() << 16) |
      (bytes[3].to_uint() << 24)
    Some(decode(code))
  } else {
    None
  }
}

///|
/// Check if instruction is compressed (16-bit)
pub fn is_compressed(code : UInt) -> Bool {
  (code & 0x3U) != 0x3U
}

///|
/// Get instruction length (16 or 32 bits)
pub fn instruction_length(code : UInt) -> Int {
  if is_compressed(code) {
    2
  } else {
    4
  }
}

///|
/// Convert compressed register index to full register index
/// Compressed registers: x8-x15 (s0-s1, a0-a5)
fn c_reg_to_full(reg : UInt) -> UInt {
  reg + 8U
}

///|
/// Sign extend a 6-bit value to signed Int
fn sign_extend_6(value : UInt) -> Int {
  let sign_bit = (value >> 5).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 64
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Sign extend a 8-bit value to signed Int
fn _sign_extend_8(value : UInt) -> Int {
  let sign_bit = (value >> 7).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 256
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Sign extend a 9-bit value to signed Int
fn sign_extend_9(value : UInt) -> Int {
  let sign_bit = (value >> 8).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 512
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Sign extend a 12-bit value to signed Int (for C.J/C.JAL)
fn sign_extend_12_c(value : UInt) -> Int {
  let sign_bit = (value >> 11).reinterpret_as_int()
  if sign_bit == 1 {
    value.reinterpret_as_int() - 4096
  } else {
    value.reinterpret_as_int()
  }
}

///|
/// Decode a 16-bit compressed instruction
pub fn decode_compressed(code16 : UInt) -> DecodeResult {
  // Quadrant is bits [1:0]
  let quadrant = code16 & 0x3U
  // funct3 is bits [15:13]
  let f3 = (code16 >> 13) & 0x7U

  match quadrant {
    // Quadrant 0
    0b00 =>
      match f3 {
        // C.ADDI4SPN
        0b000 => {
          let nzuimm = (((code16 >> 5) & 0x1U) << 3) |
            (((code16 >> 6) & 0x1U) << 2) |
            (((code16 >> 7) & 0x3U) << 6) |
            (((code16 >> 11) & 0x3U) << 4)
          let rd = c_reg_to_full((code16 >> 2) & 0x7U)
          if nzuimm == 0U {
            DecodeResult(Invalid(code16))
          } else {
            DecodeResult(C_ADDI4SPN(rd, nzuimm))
          }
        }
        // C.FLD (Zcd: load double)
        0b001 => {
          let rd = c_reg_to_full((code16 >> 2) & 0x7U)
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 10) & 0x3U) << 3) |
            (((code16 >> 6) & 0x1U) << 6) |
            (((code16 >> 5) & 0x1U) << 5)
          DecodeResult(C_FLD(rd, rs1, imm))
        }
        // C.LW
        0b010 => {
          let rd = c_reg_to_full((code16 >> 2) & 0x7U)
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 10) & 0x1U) << 2) |
            (((code16 >> 6) & 0x1U) << 6) |
            (((code16 >> 5) & 0x1U) << 5) |
            (((code16 >> 11) & 0x3U) << 3)
          DecodeResult(C_LW(rd, rs1, imm))
        }
        // C.FLW (Zcf: load single)
        0b011 => {
          let rd = c_reg_to_full((code16 >> 2) & 0x7U)
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 10) & 0x1U) << 2) |
            (((code16 >> 6) & 0x1U) << 6) |
            (((code16 >> 5) & 0x1U) << 5) |
            (((code16 >> 11) & 0x3U) << 3)
          DecodeResult(C_FLW(rd, rs1, imm))
        }
        // C.FSD (Zcd: store double)
        0b101 => {
          let rs2 = c_reg_to_full((code16 >> 2) & 0x7U)
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 10) & 0x3U) << 3) |
            (((code16 >> 6) & 0x1U) << 6) |
            (((code16 >> 5) & 0x1U) << 5)
          DecodeResult(C_FSD(rs2, rs1, imm))
        }
        // C.SW
        0b110 => {
          let rs2 = c_reg_to_full((code16 >> 2) & 0x7U)
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 10) & 0x1U) << 2) |
            (((code16 >> 6) & 0x1U) << 6) |
            (((code16 >> 5) & 0x1U) << 5) |
            (((code16 >> 11) & 0x3U) << 3)
          DecodeResult(C_SW(rs2, rs1, imm))
        }
        // C.FSW (Zcf: store single)
        0b111 => {
          let rs2 = c_reg_to_full((code16 >> 2) & 0x7U)
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 10) & 0x1U) << 2) |
            (((code16 >> 6) & 0x1U) << 6) |
            (((code16 >> 5) & 0x1U) << 5) |
            (((code16 >> 11) & 0x3U) << 3)
          DecodeResult(C_FSW(rs2, rs1, imm))
        }
        _ => DecodeResult(Invalid(code16))
      }
    // Quadrant 1
    0b01 =>
      match f3 {
        // C.ADDI / C.NOP
        0b000 => {
          let rd = (code16 >> 7) & 0x1FU
          let imm = (((code16 >> 12) & 0x1U) << 5) | ((code16 >> 2) & 0x1FU)
          let imm_signed = sign_extend_6(imm)
          if rd == 0U && imm_signed == 0 {
            DecodeResult(C_NOP)
          } else if rd == 0U {
            DecodeResult(Invalid(code16))
          } else {
            DecodeResult(C_ADDI(rd, imm_signed))
          }
        }
        // C.JAL
        0b001 => {
          let imm = (((code16 >> 12) & 0x1U) << 11) |
            (((code16 >> 11) & 0x1U) << 4) |
            (((code16 >> 9) & 0x3U) << 8) |
            (((code16 >> 8) & 0x1U) << 10) |
            (((code16 >> 7) & 0x1U) << 6) |
            (((code16 >> 6) & 0x1U) << 7) |
            (((code16 >> 3) & 0x3U) << 1) |
            (((code16 >> 2) & 0x1U) << 5)
          let imm_signed = sign_extend_12_c(imm)
          DecodeResult(C_JAL(imm_signed))
        }
        // C.LI
        0b010 => {
          let rd = (code16 >> 7) & 0x1FU
          let imm = (((code16 >> 12) & 0x1U) << 5) | ((code16 >> 2) & 0x1FU)
          let imm_signed = sign_extend_6(imm)
          DecodeResult(C_LI(rd, imm_signed))
        }
        // C.ADDI16SP / C.LUI
        0b011 => {
          let rd = (code16 >> 7) & 0x1FU
          let imm = (((code16 >> 12) & 0x1U) << 5) | ((code16 >> 2) & 0x1FU)
          let imm_signed = sign_extend_6(imm)
          if rd == 2U {
            // C.ADDI16SP
            let sp_imm = (((code16 >> 12) & 0x1U) << 9) |
              (((code16 >> 5) & 0x1U) << 4) |
              (((code16 >> 2) & 0x3U) << 6) |
              (((code16 >> 4) & 0x1U) << 5)
            let sp_imm_signed = sign_extend_9(sp_imm)
            if sp_imm_signed == 0 {
              DecodeResult(Invalid(code16))
            } else {
              DecodeResult(C_ADDI16SP(sp_imm_signed))
            }
          } else if rd != 0U && imm_signed != 0 {
            // C.LUI
            DecodeResult(C_LUI(rd, imm_signed))
          } else {
            DecodeResult(Invalid(code16))
          }
        }
        // C.SRLI, C.SRAI, C.ANDI, C.SUB, C.XOR, C.OR, C.AND
        0b100 => {
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let f2 = (code16 >> 10) & 0x3U
          match f2 {
            // C.SRLI
            0b00 => {
              let shamt = (((code16 >> 12) & 0x1U) << 5) |
                ((code16 >> 2) & 0x1FU)
              DecodeResult(C_SRLI(rs1, shamt))
            }
            // C.SRAI
            0b01 => {
              let shamt = (((code16 >> 12) & 0x1U) << 5) |
                ((code16 >> 2) & 0x1FU)
              DecodeResult(C_SRAI(rs1, shamt))
            }
            // C.ANDI
            0b10 => {
              let imm = (((code16 >> 12) & 0x1U) << 5) | ((code16 >> 2) & 0x1FU)
              let imm_signed = sign_extend_6(imm)
              DecodeResult(C_ANDI(rs1, imm_signed))
            }
            // C.SUB, C.XOR, C.OR, C.AND
            // Encoding: bit 12 and bit 5 determine the instruction
            // C.SUB: bit12=0, bit5=0
            // C.XOR: bit12=0, bit5=1
            // C.OR:  bit12=1, bit5=0
            // C.AND: bit12=1, bit5=1
            0b11 => {
              let rs2 = c_reg_to_full((code16 >> 2) & 0x7U)
              let bit12 = (code16 >> 12) & 0x1U
              let bit5 = (code16 >> 5) & 0x1U
              match (bit12, bit5) {
                (0b0, 0b0) => DecodeResult(C_SUB(rs1, rs2))
                (0b0, 0b1) => DecodeResult(C_XOR(rs1, rs2))
                (0b1, 0b0) => DecodeResult(C_OR(rs1, rs2))
                (0b1, 0b1) => DecodeResult(C_AND(rs1, rs2))
                _ => DecodeResult(Invalid(code16))
              }
            }
            _ => DecodeResult(Invalid(code16))
          }
        }
        // C.J
        0b101 => {
          let imm = (((code16 >> 12) & 0x1U) << 11) |
            (((code16 >> 11) & 0x1U) << 4) |
            (((code16 >> 9) & 0x3U) << 8) |
            (((code16 >> 8) & 0x1U) << 10) |
            (((code16 >> 7) & 0x1U) << 6) |
            (((code16 >> 6) & 0x1U) << 7) |
            (((code16 >> 3) & 0x3U) << 1) |
            (((code16 >> 2) & 0x1U) << 5)
          let imm_signed = sign_extend_12_c(imm)
          DecodeResult(C_J(imm_signed))
        }
        // C.BEQZ
        0b110 => {
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 12) & 0x1U) << 8) |
            (((code16 >> 10) & 0x3U) << 3) |
            (((code16 >> 5) & 0x1U) << 6) |
            (((code16 >> 3) & 0x3U) << 1) |
            (((code16 >> 2) & 0x1U) << 5)
          let imm_signed = sign_extend_9(imm)
          DecodeResult(C_BEQZ(rs1, imm_signed))
        }
        // C.BNEZ
        0b111 => {
          let rs1 = c_reg_to_full((code16 >> 7) & 0x7U)
          let imm = (((code16 >> 12) & 0x1U) << 8) |
            (((code16 >> 10) & 0x3U) << 3) |
            (((code16 >> 5) & 0x1U) << 6) |
            (((code16 >> 3) & 0x3U) << 1) |
            (((code16 >> 2) & 0x1U) << 5)
          let imm_signed = sign_extend_9(imm)
          DecodeResult(C_BNEZ(rs1, imm_signed))
        }
        _ => DecodeResult(Invalid(code16))
      }
    // Quadrant 2
    0b10 =>
      match f3 {
        // C.SLLI
        0b000 => {
          let rd = (code16 >> 7) & 0x1FU
          let shamt = (((code16 >> 12) & 0x1U) << 5) | ((code16 >> 2) & 0x1FU)
          DecodeResult(C_SLLI(rd, shamt))
        }
        // C.LWSP / C.FLWSP (Zcf)
        0b010 => {
          let rd = (code16 >> 7) & 0x1FU
          let imm = (((code16 >> 12) & 0x1U) << 5) |
            (((code16 >> 4) & 0x7U) << 2) |
            (((code16 >> 2) & 0x3U) << 6)
          // C.FLWSP: immediate must be non-zero (bits [12,6:2] != 0)
          // C.LWSP: immediate can be zero
          // Also check if it's actually a hint (rs1'=0 is reserved for hints)
          let rs1_prime = (code16 >> 7) & 0x7U // bits [9:7]
          if imm != 0U && rs1_prime != 0U {
            // Could be C.FLWSP - treat as C.FLWSP for floating point registers
            DecodeResult(C_FLWSP(rd, imm))
          } else {
            DecodeResult(C_LWSP(rd, imm))
          }
        }
        // C.FLDSP (Zcd: load double from SP)
        0b001 => {
          let rd = (code16 >> 7) & 0x1FU
          let imm = (((code16 >> 12) & 0x1U) << 5) |
            (((code16 >> 10) & 0x3U) << 3) |
            (((code16 >> 5) & 0x3U) << 6)
          if imm != 0U {
            DecodeResult(C_FLDSP(rd, imm))
          } else {
            DecodeResult(Invalid(code16))
          }
        }
        // C.JR, C.MV, C.EBREAK, C.JALR, C.ADD
        0b100 => {
          let rd = (code16 >> 7) & 0x1FU
          let rs2 = (code16 >> 2) & 0x1FU
          let bit12 = (code16 >> 12) & 0x1U
          if rs2 == 0U {
            // C.JR, C.JALR, or C.EBREAK
            if rd == 0U {
              DecodeResult(C_EBREAK)
            } else if bit12 == 0U {
              // C.JR: bit12=0, rs2=0, rd!=0
              DecodeResult(C_JR(rd))
            } else {
              // C.JALR: bit12=1, rs2=0, rd!=0
              DecodeResult(C_JALR(rd))
            }
            // C.MV or C.ADD
          } else if rd == 0U {
            DecodeResult(Invalid(code16))
          } else {
            match bit12 {
              0b0 => DecodeResult(C_MV(rd, rs2))
              0b1 => DecodeResult(C_ADD(rd, rs2))
              _ => DecodeResult(Invalid(code16))
            }
          }
        }
        // C.SWSP / C.FSWSP (Zcf)
        0b110 => {
          let rs2 = (code16 >> 2) & 0x1FU
          let imm = (((code16 >> 9) & 0x3FU) << 2) | ((code16 >> 7) & 0x3U)
          // C.FSWSP: rs2' (bits [4:2]) must be non-zero when rs2 in 8-15
          // C.SWSP: can have rs2'=0
          let rs2_prime = (code16 >> 2) & 0x7U // bits [4:2]
          if rs2 >= 8U && rs2 <= 15U && rs2_prime != 0U {
            // C.FSWSP
            DecodeResult(C_FSWSP(rs2, imm))
          } else {
            DecodeResult(C_SWSP(rs2, imm))
          }
        }
        // C.FSDSP (Zcd: store double to SP)
        0b011 => {
          let rs2 = (code16 >> 2) & 0x1FU
          let imm = (((code16 >> 10) & 0x7U) << 3) |
            (((code16 >> 7) & 0x7U) << 6)
          DecodeResult(C_FSDSP(rs2, imm))
        }
        _ => DecodeResult(Invalid(code16))
      }
    _ => DecodeResult(Invalid(code16))
  }
}

///|
/// Decode from 16-bit instruction bytes (little-endian)
pub fn decode_compressed_from_bytes(bytes : FixedArray[Byte]) -> DecodeResult? {
  if bytes.length() >= 2 {
    let code16 = bytes[0].to_uint() | (bytes[1].to_uint() << 8)
    Some(decode_compressed(code16))
  } else {
    None
  }
}

///|
/// Decode instruction from bytes, handling both 16-bit and 32-bit
pub fn decode_from_bytes_auto(bytes : FixedArray[Byte]) -> DecodeResult? {
  if bytes.length() < 2 {
    return None
  }
  let first_two = bytes[0].to_uint() | (bytes[1].to_uint() << 8)
  if is_compressed(first_two) {
    decode_compressed_from_bytes(bytes)
  } else if bytes.length() >= 4 {
    decode_from_bytes(bytes)
  } else {
    None
  }
}
