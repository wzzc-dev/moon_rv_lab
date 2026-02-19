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
    // LOAD-FP (0x07): Floating-point load OR Vector load
    // Vector loads have funct6=0 (f7[6:1]=0), while FP loads have arbitrary immediate in f7
    0b0000111 => {
      let funct6 = f7 >> 1
      if funct6 == 0U {
        // Vector load (VLE8/VLE16/VLE32/VLE64)
        let vm = (f7 & 0x1U) != 0U
        match f3 {
          0b000 => DecodeResult(VLE8_V(rd, rs1, vm)) // vle8.v
          0b001 => DecodeResult(VLE16_V(rd, rs1, vm)) // vle16.v
          0b010 => DecodeResult(VLE32_V(rd, rs1, vm)) // vle32.v
          0b011 => DecodeResult(VLE64_V(rd, rs1, vm)) // vle64.v
          _ => DecodeResult(Invalid(code))
        }
      } else {
        // Floating-point load (FLW/FLD/FLQ)
        let imm = decode_i_imm(code)
        match f3 {
          0b010 => DecodeResult(FLW(rd, rs1, imm)) // RV32F: load single
          0b011 => DecodeResult(FLD(rd, rs1, imm)) // RV32D: load double
          0b100 => DecodeResult(FLQ(rd, rs1, imm)) // RV32Q: load quad
          _ => DecodeResult(Invalid(code))
        }
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
    // STORE-FP (0x27): Floating-point store OR Vector store
    // Vector stores have funct6=0 (f7[6:1]=0), while FP stores have arbitrary immediate in f7
    0b0100111 => {
      let funct6 = f7 >> 1
      if funct6 == 0U {
        // Vector store (VSE8/VSE16/VSE32/VSE64)
        let vm = (f7 & 0x1U) != 0U
        match f3 {
          0b000 => DecodeResult(VSE8_V(rs2, rs1, vm)) // vse8.v
          0b001 => DecodeResult(VSE16_V(rs2, rs1, vm)) // vse16.v
          0b010 => DecodeResult(VSE32_V(rs2, rs1, vm)) // vse32.v
          0b011 => DecodeResult(VSE64_V(rs2, rs1, vm)) // vse64.v
          _ => DecodeResult(Invalid(code))
        }
      } else {
        // Floating-point store (FSW/FSD/FSQ)
        let imm = decode_s_imm(code)
        match f3 {
          0b010 => DecodeResult(FSW(rs1, rs2, imm)) // RV32F: store single
          0b011 => DecodeResult(FSD(rs1, rs2, imm)) // RV32D: store double
          0b100 => DecodeResult(FSQ(rs1, rs2, imm)) // RV32Q: store quad
          _ => DecodeResult(Invalid(code))
        }
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
          match f7 {
            0b0000000 => DecodeResult(SLLIW(rd, rs1, shamt))
            // Zba RV64: SLLI.UW
            0b0000100 => DecodeResult(SLLI_UW(rd, rs1, shamt))
            _ => DecodeResult(Invalid(code))
          }
        }
        0b101 => {
          let shamt = extract_bits(code, 24, 20)
          match f7 {
            0b0000000 => DecodeResult(SRLIW(rd, rs1, shamt))
            0b0100000 => DecodeResult(SRAIW(rd, rs1, shamt))
            // Zbb RV64: RORIW
            0b0110000 => DecodeResult(RORIW(rd, rs1, shamt))
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
            // Zba RV64: ADD.UW
            0b0000100 => DecodeResult(ADD_UW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b001 =>
          match f7 {
            0b0000000 => DecodeResult(SLLW(rd, rs1, rs2))
            // Zbb RV64: CLZW/CTZW/CPOPW/ROLW
            0b0110000 =>
              match rs2 {
                0b00000 => DecodeResult(CLZW(rd, rs1))
                0b00001 => DecodeResult(CTZW(rd, rs1))
                0b00010 => DecodeResult(CPOPW(rd, rs1))
                _ => DecodeResult(ROLW(rd, rs1, rs2))
              }
            _ => DecodeResult(Invalid(code))
          }
        0b010 =>
          match f7 {
            // Zba RV64: SH1ADD.UW
            0b0010000 => DecodeResult(SH1ADD_UW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b011 => DecodeResult(Invalid(code))
        0b100 =>
          match f7 {
            0b0000001 => DecodeResult(DIVW(rd, rs1, rs2))
            // Zba RV64: SH2ADD.UW
            0b0010000 => DecodeResult(SH2ADD_UW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b101 =>
          match f7 {
            0b0000000 => DecodeResult(SRLW(rd, rs1, rs2))
            0b0100000 => DecodeResult(SRAW(rd, rs1, rs2))
            0b0000001 => DecodeResult(DIVUW(rd, rs1, rs2))
            // Zbb RV64: RORW
            0b0110000 => DecodeResult(RORW(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b110 =>
          match f7 {
            0b0000001 => DecodeResult(REMW(rd, rs1, rs2))
            // Zba RV64: SH3ADD.UW
            0b0010000 => DecodeResult(SH3ADD_UW(rd, rs1, rs2))
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
        0b111 => DecodeResult(CSRRCI(rd, csr, rs1)) // CSRRCi (rs1 field is uimm)
        _ => DecodeResult(Invalid(code))
      }
    // OP-V (0x57): Vector arithmetic and configuration
    0b1010111 => {
      // Vector instructions encoding:
      // funct6 = bits[31:26], vm = bit[25]
      // For OPIVV/OPIVX/OPIVI: rs2 = vs2, rs1 = vs1/rs1/simm
      let funct6 = extract_bits(code, 31, 26)
      let vm_bit = extract_bits(code, 25, 25)
      let vm_bool = vm_bit != 0U
      match funct6 {
        // ===== Vector configuration instructions (f3=111) =====
        // VSETVLI: funct6=0b100000
        0b100000 =>
          match f3 {
            0b111 => DecodeResult(VSETVLI(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // VSETIVLI: funct6=0b100001
        0b100001 =>
          match f3 {
            0b111 => DecodeResult(VSETIVLI(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // VSETVL: funct6=0b100010
        0b100010 =>
          match f3 {
            0b111 => DecodeResult(VSETVL(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        // ===== OPIVV/OPIVX/OPIVI - Vector integer add/sub =====
        // VADD: funct6=0b000000
        0b000000 =>
          match f3 {
            0b000 => DecodeResult(VADD_VV(rd, rs1, rs2, vm_bool)) // vadd.vv
            0b001 => DecodeResult(VADD_VX(rd, rs1, rs2, vm_bool)) // vadd.vx
            0b011 =>
              DecodeResult(VADD_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vadd.vi
            _ => DecodeResult(Invalid(code))
          }
        // VSUB: funct6=0b000010
        0b000010 =>
          match f3 {
            0b000 => DecodeResult(VSUB_VV(rd, rs1, rs2, vm_bool)) // vsub.vv
            0b001 => DecodeResult(VSUB_VX(rd, rs1, rs2, vm_bool)) // vsub.vx
            _ => DecodeResult(Invalid(code))
          }
        // VRSUB / VFREDOSUM/VFREDSUM/VFREDMAX/VFREDMIN: funct6=0b000011
        // Note: vfredmin.vs and vrsub.vi share f3=011, distinguished by rs1:
        //   - rs1=0 (vs1=v0) -> vfredmin.vs
        //   - rs1!=0 -> vrsub.vi
        0b000011 =>
          match f3 {
            0b000 => DecodeResult(VFREDOSUM_VS(rd, rs1, rs2, vm_bool)) // vfredosum.vs
            0b001 => DecodeResult(VRSUB_VX(rd, rs1, rs2, vm_bool)) // vrsub.vx (vfrecsum.vs is reserved)
            0b010 => DecodeResult(VFREDMAX_VS(rd, rs1, rs2, vm_bool)) // vfredmax.vs
            0b011 =>
              // rs1=0 (vs1=v0) indicates vfredmin.vs, otherwise vrsub.vi
              if rs1 == 0U {
                DecodeResult(VFREDMIN_VS(rd, rs1, rs2, vm_bool)) // vfredmin.vs
              } else {
                DecodeResult(
                  VRSUB_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool),
                ) // vrsub.vi
              }
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector min/max: funct6=0b000100 =====
        0b000100 =>
          match f3 {
            0b000 => DecodeResult(VMINU_VV(rd, rs1, rs2, vm_bool)) // vminu.vv
            0b001 => DecodeResult(VMINU_VX(rd, rs1, rs2, vm_bool)) // vminu.vx
            0b010 => DecodeResult(VMIN_VV(rd, rs1, rs2, vm_bool)) // vmin.vv
            0b011 => DecodeResult(VMIN_VX(rd, rs1, rs2, vm_bool)) // vmin.vx
            0b100 => DecodeResult(VMAXU_VV(rd, rs1, rs2, vm_bool)) // vmaxu.vv
            0b101 => DecodeResult(VMAXU_VX(rd, rs1, rs2, vm_bool)) // vmaxu.vx
            0b110 => DecodeResult(VMAX_VV(rd, rs1, rs2, vm_bool)) // vmax.vv
            0b111 => DecodeResult(VMAX_VX(rd, rs1, rs2, vm_bool)) // vmax.vx
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector bitwise AND/OR/XOR: funct6=0b000101 =====
        0b000101 =>
          match f3 {
            0b000 => DecodeResult(VAND_VV(rd, rs1, rs2, vm_bool)) // vand.vv
            0b001 => DecodeResult(VAND_VX(rd, rs1, rs2, vm_bool)) // vand.vx
            0b011 =>
              DecodeResult(VAND_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vand.vi
            0b010 => DecodeResult(VOR_VV(rd, rs1, rs2, vm_bool)) // vor.vv
            0b100 => DecodeResult(VOR_VX(rd, rs1, rs2, vm_bool)) // vor.vx
            0b110 =>
              DecodeResult(VOR_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vor.vi
            0b101 => DecodeResult(VXOR_VV(rd, rs1, rs2, vm_bool)) // vxor.vv
            0b111 => DecodeResult(VXOR_VX(rd, rs1, rs2, vm_bool)) // vxor.vx
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector reduction: funct6=0b000001 =====
        0b000001 =>
          match f3 {
            0b000 => DecodeResult(VREDSUM_VS(rd, rs1, rs2, vm_bool)) // vredsum.vs
            0b001 => DecodeResult(VREDAND_VS(rd, rs1, rs2, vm_bool)) // vredand.vs
            0b010 => DecodeResult(VREDOR_VS(rd, rs1, rs2, vm_bool)) // vredor.vs
            0b011 => DecodeResult(VREDXOR_VS(rd, rs1, rs2, vm_bool)) // vredxor.vs
            0b100 => DecodeResult(VREDMINU_VS(rd, rs1, rs2, vm_bool)) // vredminu.vs
            0b101 => DecodeResult(VREDMIN_VS(rd, rs1, rs2, vm_bool)) // vredmin.vs
            0b110 => DecodeResult(VREDMAXU_VS(rd, rs1, rs2, vm_bool)) // vredmaxu.vs
            0b111 => DecodeResult(VREDMAX_VS(rd, rs1, rs2, vm_bool)) // vredmax.vs
            _ => DecodeResult(Invalid(code))
          }
        // ===== OPMVV/OPMVX/OPFVF - Vector multiply/divide =====
        // VMUL/VDIV/VFMUL/VFDIV: funct6=0b100101
        // Note: Integer multiply/divide and floating-point multiply/divide share the same funct6.
        // They are distinguished by SEW (Selected Element Width) at runtime.
        0b100101 =>
          match f3 {
            // Integer: vmul.vv / Floating: vfmul.vv
            0b000 => DecodeResult(VMUL_VV(rd, rs1, rs2, vm_bool)) // vmul.vv / vfmul.vv
            // Integer: vmul.vx / Floating: vfmul.vf
            0b001 => DecodeResult(VMUL_VX(rd, rs1, rs2, vm_bool)) // vmul.vx / vfmul.vf
            // Integer: vdiv.vv / Floating: vfdiv.vv
            0b010 => DecodeResult(VFDIV_VV(rd, rs1, rs2, vm_bool)) // vdiv.vv / vfdiv.vv
            // Integer: vdiv.vx / Floating: vfdiv.vf
            0b011 => DecodeResult(VFDIV_VF(rd, rs1, rs2, vm_bool)) // vdiv.vx / vfdiv.vf
            // Integer: vremu.vv (no float equivalent)
            0b100 => DecodeResult(VREMU_VV(rd, rs1, rs2, vm_bool)) // vremu.vv
            // Integer: vremu.vx / Floating: vfrdiv.vf
            0b101 => DecodeResult(VFRDIV_VF(rd, rs1, rs2, vm_bool)) // vremu.vx / vfrdiv.vf
            // Integer: vrem.vv (no float equivalent)
            0b110 => DecodeResult(VREM_VV(rd, rs1, rs2, vm_bool)) // vrem.vv
            // Integer: vrem.vx (no float equivalent)
            0b111 => DecodeResult(VREM_VX(rd, rs1, rs2, vm_bool)) // vrem.vx
            _ => DecodeResult(Invalid(code))
          }
        // VFMIN/VFMAX: funct6=0b000110
        0b000110 =>
          match f3 {
            0b000 => DecodeResult(VFMIN_VV(rd, rs1, rs2, vm_bool)) // vfmin.vv
            0b001 => DecodeResult(VFMIN_VF(rd, rs1, rs2, vm_bool)) // vfmin.vf
            0b010 => DecodeResult(VFMAX_VV(rd, rs1, rs2, vm_bool)) // vfmax.vv
            0b011 => DecodeResult(VFMAX_VF(rd, rs1, rs2, vm_bool)) // vfmax.vf
            _ => DecodeResult(Invalid(code))
          }
        // VMULH: funct6=0b100110
        0b100110 =>
          match f3 {
            0b000 => DecodeResult(VMULH_VV(rd, rs1, rs2, vm_bool)) // vmulh.vv
            0b001 => DecodeResult(VMULH_VX(rd, rs1, rs2, vm_bool)) // vmulh.vx
            _ => DecodeResult(Invalid(code))
          }
        // VMULHU: funct6=0b100111
        0b100111 =>
          match f3 {
            0b000 => DecodeResult(VMULHU_VV(rd, rs1, rs2, vm_bool)) // vmulhu.vv
            0b001 => DecodeResult(VMULHU_VX(rd, rs1, rs2, vm_bool)) // vmulhu.vx
            _ => DecodeResult(Invalid(code))
          }
        // VMULHSU: funct6=0b101000
        0b101000 =>
          match f3 {
            0b000 => DecodeResult(VMULHSU_VV(rd, rs1, rs2, vm_bool)) // vmulhsu.vv
            0b001 => DecodeResult(VMULHSU_VX(rd, rs1, rs2, vm_bool)) // vmulhsu.vx
            _ => DecodeResult(Invalid(code))
          }
        // VDIVU/VDIV/VREMU/VREM: funct6=0b100011
        0b100011 =>
          match f3 {
            0b010 => DecodeResult(VDIVU_VV(rd, rs1, rs2, vm_bool)) // vdivu.vv
            0b011 => DecodeResult(VDIVU_VX(rd, rs1, rs2, vm_bool)) // vdivu.vx
            0b000 => DecodeResult(VDIV_VV(rd, rs1, rs2, vm_bool)) // vdiv.vv
            0b001 => DecodeResult(VDIV_VX(rd, rs1, rs2, vm_bool)) // vdiv.vx
            0b110 => DecodeResult(VREMU_VV(rd, rs1, rs2, vm_bool)) // vremu.vv
            0b111 => DecodeResult(VREMU_VX(rd, rs1, rs2, vm_bool)) // vremu.vx
            0b100 => DecodeResult(VREM_VV(rd, rs1, rs2, vm_bool)) // vrem.vv
            0b101 => DecodeResult(VREM_VX(rd, rs1, rs2, vm_bool)) // vrem.vx
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector shift operations =====
        // VSLL: funct6=0b101001
        0b101001 =>
          match f3 {
            0b000 => DecodeResult(VSLL_VV(rd, rs1, rs2, vm_bool)) // vsll.vv
            0b001 => DecodeResult(VSLL_VX(rd, rs1, rs2, vm_bool)) // vsll.vx
            0b011 => DecodeResult(VSLL_VI(rd, rs1, rs2, vm_bool)) // vsll.vi
            _ => DecodeResult(Invalid(code))
          }
        // VSRL/VSRA: funct6=0b101010
        0b101010 =>
          match f3 {
            0b000 => DecodeResult(VSRL_VV(rd, rs1, rs2, vm_bool)) // vsrl.vv
            0b001 => DecodeResult(VSRL_VX(rd, rs1, rs2, vm_bool)) // vsrl.vx
            0b011 => DecodeResult(VSRL_VI(rd, rs1, rs2, vm_bool)) // vsrl.vi
            0b010 => DecodeResult(VSRA_VV(rd, rs1, rs2, vm_bool)) // vsra.vv
            0b100 => DecodeResult(VSRA_VX(rd, rs1, rs2, vm_bool)) // vsra.vx
            0b110 => DecodeResult(VSRA_VI(rd, rs1, rs2, vm_bool)) // vsra.vi
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector comparison =====
        // VMSEQ/VMSNE: funct6=0b011011
        0b011011 =>
          match f3 {
            0b000 => DecodeResult(VMSEQ_VV(rd, rs1, rs2, vm_bool)) // vmseq.vv
            0b001 => DecodeResult(VMSEQ_VX(rd, rs1, rs2, vm_bool)) // vmseq.vx
            0b011 =>
              DecodeResult(VMSEQ_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vmseq.vi
            0b010 => DecodeResult(VMSNE_VV(rd, rs1, rs2, vm_bool)) // vmsne.vv
            0b100 => DecodeResult(VMSNE_VX(rd, rs1, rs2, vm_bool)) // vmsne.vx
            0b110 =>
              DecodeResult(VMSNE_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vmsne.vi
            _ => DecodeResult(Invalid(code))
          }
        // VMSLTU/VMSLT: funct6=0b011100
        0b011100 =>
          match f3 {
            0b000 => DecodeResult(VMSLTU_VV(rd, rs1, rs2, vm_bool)) // vmsltu.vv
            0b001 => DecodeResult(VMSLTU_VX(rd, rs1, rs2, vm_bool)) // vmsltu.vx
            0b010 => DecodeResult(VMSLT_VV(rd, rs1, rs2, vm_bool)) // vmslt.vv
            0b011 => DecodeResult(VMSLT_VX(rd, rs1, rs2, vm_bool)) // vmslt.vx
            _ => DecodeResult(Invalid(code))
          }
        // VMSLEU/VMSLE/VMSGTU/VMSGT: funct6=0b011101
        0b011101 =>
          match f3 {
            0b000 => DecodeResult(VMSLEU_VV(rd, rs1, rs2, vm_bool)) // vmsleu.vv
            0b001 => DecodeResult(VMSLEU_VX(rd, rs1, rs2, vm_bool)) // vmsleu.vx
            0b011 =>
              DecodeResult(
                VMSLEU_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool),
              ) // vmsleu.vi
            0b010 => DecodeResult(VMSLE_VV(rd, rs1, rs2, vm_bool)) // vmsle.vv
            0b100 => DecodeResult(VMSLE_VX(rd, rs1, rs2, vm_bool)) // vmsle.vx
            0b110 =>
              DecodeResult(VMSLE_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vmsle.vi
            0b101 => DecodeResult(VMSGTU_VX(rd, rs1, rs2, vm_bool)) // vmsgtu.vx
            0b111 =>
              DecodeResult(
                VMSGTU_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool),
              ) // vmsgtu.vi
            _ => DecodeResult(Invalid(code))
          }
        // VMSGT: funct6=0b011110
        0b011110 =>
          match f3 {
            0b000 => DecodeResult(VMSGT_VX(rd, rs1, rs2, vm_bool)) // vmsgt.vx
            0b010 =>
              DecodeResult(VMSGT_VI(rd, rs1.reinterpret_as_int(), rs2, vm_bool)) // vmsgt.vi
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector widening integer arithmetic =====
        // VWADDU: funct6=0b110000
        0b110000 =>
          match f3 {
            0b000 => DecodeResult(VWADDU_VV(rd, rs1, rs2, vm_bool)) // vwaddu.vv
            0b001 => DecodeResult(VWADDU_VX(rd, rs1, rs2, vm_bool)) // vwaddu.vx
            _ => DecodeResult(Invalid(code))
          }
        // VWADD: funct6=0b110001
        0b110001 =>
          match f3 {
            0b000 => DecodeResult(VWADD_VV(rd, rs1, rs2, vm_bool)) // vwadd.vv
            0b001 => DecodeResult(VWADD_VX(rd, rs1, rs2, vm_bool)) // vwadd.vx
            _ => DecodeResult(Invalid(code))
          }
        // VWSUBU: funct6=0b110010
        0b110010 =>
          match f3 {
            0b000 => DecodeResult(VWSUBU_VV(rd, rs1, rs2, vm_bool)) // vwsubu.vv
            0b001 => DecodeResult(VWSUBU_VX(rd, rs1, rs2, vm_bool)) // vwsubu.vx
            _ => DecodeResult(Invalid(code))
          }
        // VWSUB: funct6=0b110011
        0b110011 =>
          match f3 {
            0b000 => DecodeResult(VWSUB_VV(rd, rs1, rs2, vm_bool)) // vwsub.vv
            0b001 => DecodeResult(VWSUB_VX(rd, rs1, rs2, vm_bool)) // vwsub.vx
            _ => DecodeResult(Invalid(code))
          }
        // VWADDU.W: funct6=0b110100
        0b110100 =>
          match f3 {
            0b000 => DecodeResult(VWADDU_WV(rd, rs1, rs2, vm_bool)) // vwaddu.wv
            0b001 => DecodeResult(VWADDU_WX(rd, rs1, rs2, vm_bool)) // vwaddu.wx
            _ => DecodeResult(Invalid(code))
          }
        // VWADD.W: funct6=0b110101
        0b110101 =>
          match f3 {
            0b000 => DecodeResult(VWADD_WV(rd, rs1, rs2, vm_bool)) // vwadd.wv
            0b001 => DecodeResult(VWADD_WX(rd, rs1, rs2, vm_bool)) // vwadd.wx
            _ => DecodeResult(Invalid(code))
          }
        // VWSUBU.W: funct6=0b110110
        0b110110 =>
          match f3 {
            0b000 => DecodeResult(VWSUBU_WV(rd, rs1, rs2, vm_bool)) // vwsubu.wv
            0b001 => DecodeResult(VWSUBU_WX(rd, rs1, rs2, vm_bool)) // vwsubu.wx
            _ => DecodeResult(Invalid(code))
          }
        // VWSUB.W: funct6=0b110111
        0b110111 =>
          match f3 {
            0b000 => DecodeResult(VWSUB_WV(rd, rs1, rs2, vm_bool)) // vwsub.wv
            0b001 => DecodeResult(VWSUB_WX(rd, rs1, rs2, vm_bool)) // vwsub.wx
            _ => DecodeResult(Invalid(code))
          }
        // VWMUL: funct6=0b111000
        0b111000 =>
          match f3 {
            0b000 => DecodeResult(VWMUL_VV(rd, rs1, rs2, vm_bool)) // vwmul.vv
            0b001 => DecodeResult(VWMUL_VX(rd, rs1, rs2, vm_bool)) // vwmul.vx
            _ => DecodeResult(Invalid(code))
          }
        // VWMULU: funct6=0b111001
        0b111001 =>
          match f3 {
            0b000 => DecodeResult(VWMULU_VV(rd, rs1, rs2, vm_bool)) // vwmulu.vv
            0b001 => DecodeResult(VWMULU_VX(rd, rs1, rs2, vm_bool)) // vwmulu.vx
            _ => DecodeResult(Invalid(code))
          }
        // VWMULSU: funct6=0b111010
        0b111010 =>
          match f3 {
            0b000 => DecodeResult(VWMULSU_VV(rd, rs1, rs2, vm_bool)) // vwmulsu.vv
            0b001 => DecodeResult(VWMULSU_VX(rd, rs1, rs2, vm_bool)) // vwmulsu.vx
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector merge/move =====
        // VMERGE: funct6=0b010111 (vm=0 for merge)
        0b010111 =>
          match f3 {
            0b000 => DecodeResult(VMERGE_VVM(rd, rs1, rs2, vm_bool)) // vmerge.vvm
            0b001 => DecodeResult(VMERGE_VXM(rd, rs1, rs2, vm_bool)) // vmerge.vxm
            0b011 =>
              DecodeResult(
                VMERGE_VIM(rd, rs1.reinterpret_as_int(), rs2, vm_bool),
              ) // vmerge.vim
            _ => DecodeResult(Invalid(code))
          }
        // VMV: funct6=0b010111 (vm=1 for move) - same as merge with vm=1
        // VMV.X.S/VMV.S.X: funct6=0b010000
        0b010000 =>
          match f3 {
            0b100 => DecodeResult(VMV_X_S(rd, rs2)) // vmv.x.s
            0b101 => DecodeResult(VMV_S_X(rd, rs1)) // vmv.s.x
            _ => DecodeResult(Invalid(code))
          }
        // VMV.V.V/VMV.V.X/VMV.V.I: funct6=0b010111 with vm=1
        // ===== Vector integer extension =====
        // VZEXT/VSEXT: funct6=0b010010
        0b010010 =>
          match f3 {
            0b010 => DecodeResult(VZEXT_VF2(rd, rs2, vm_bool)) // vzext.vf2
            0b011 => DecodeResult(VSEXT_VF2(rd, rs2, vm_bool)) // vsext.vf2
            0b100 => DecodeResult(VZEXT_VF4(rd, rs2, vm_bool)) // vzext.vf4
            0b101 => DecodeResult(VSEXT_VF4(rd, rs2, vm_bool)) // vsext.vf4
            0b110 => DecodeResult(VZEXT_VF8(rd, rs2, vm_bool)) // vzext.vf8
            0b111 => DecodeResult(VSEXT_VF8(rd, rs2, vm_bool)) // vsext.vf8
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector mask operations =====
        // VMAND/VMNAND/VMANDN/VMOR/VMNOR/VMORN/VMXOR/VMXNOR: funct6=0b011001
        0b011001 =>
          match f3 {
            0b000 => DecodeResult(VMAND_MM(rd, rs1, rs2, vm_bool)) // vmand.mm
            0b001 => DecodeResult(VMNAND_MM(rd, rs1, rs2, vm_bool)) // vmnand.mm
            0b010 => DecodeResult(VMANDN_MM(rd, rs1, rs2, vm_bool)) // vmandn.mm
            0b011 => DecodeResult(VMOR_MM(rd, rs1, rs2, vm_bool)) // vmor.mm
            0b100 => DecodeResult(VMNOR_MM(rd, rs1, rs2, vm_bool)) // vmnor.mm
            0b101 => DecodeResult(VMORN_MM(rd, rs1, rs2, vm_bool)) // vmorn.mm
            0b110 => DecodeResult(VMXOR_MM(rd, rs1, rs2, vm_bool)) // vmxor.mm
            0b111 => DecodeResult(VMXNOR_MM(rd, rs1, rs2, vm_bool)) // vmxnor.mm
            _ => DecodeResult(Invalid(code))
          }
        // ===== Vector floating-point =====
        // VFADD/VFSUB: funct6=0b001000
        0b001000 =>
          match f3 {
            0b000 => DecodeResult(VFADD_VV(rd, rs1, rs2, vm_bool)) // vfadd.vv
            0b001 => DecodeResult(VFADD_VF(rd, rs1, rs2, vm_bool)) // vfadd.vf
            0b010 => DecodeResult(VFSUB_VV(rd, rs1, rs2, vm_bool)) // vfsub.vv
            0b011 => DecodeResult(VFSUB_VF(rd, rs1, rs2, vm_bool)) // vfsub.vf
            _ => DecodeResult(Invalid(code))
          }
        // VFRSUB: funct6=0b000111
        0b000111 =>
          match f3 {
            0b001 => DecodeResult(VFRSUB_VF(rd, rs1, rs2, vm_bool)) // vfrsub.vf
            _ => DecodeResult(Invalid(code))
          }
        // VFSGNJ/VFSGNJN/VFSGNJX: funct6=0b001001
        0b001001 =>
          match f3 {
            0b000 => DecodeResult(VFSGNJ_VV(rd, rs1, rs2, vm_bool)) // vfsgnj.vv
            0b001 => DecodeResult(VFSGNJ_VF(rd, rs1, rs2, vm_bool)) // vfsgnj.vf
            0b010 => DecodeResult(VFSGNJN_VV(rd, rs1, rs2, vm_bool)) // vfsgnjn.vv
            0b011 => DecodeResult(VFSGNJN_VF(rd, rs1, rs2, vm_bool)) // vfsgnjn.vf
            0b100 => DecodeResult(VFSGNJX_VV(rd, rs1, rs2, vm_bool)) // vfsgnjx.vv
            0b101 => DecodeResult(VFSGNJX_VF(rd, rs1, rs2, vm_bool)) // vfsgnjx.vf
            _ => DecodeResult(Invalid(code))
          }
        // VFSQRT: funct6=0b010001
        0b010001 =>
          match f3 {
            0b000 => DecodeResult(VFSQRT_V(rd, rs2, vm_bool)) // vfsqrt.v
            _ => DecodeResult(Invalid(code))
          }
        // VFCLASS: funct6=0b010011
        0b010011 =>
          match f3 {
            0b000 => DecodeResult(VFCLASS_V(rd, rs2, vm_bool)) // vfclass.v
            _ => DecodeResult(Invalid(code))
          }
        // VMFEQ/VMFNE/VMFLT/VMFLE: funct6=0b011000
        0b011000 =>
          match f3 {
            0b000 => DecodeResult(VMFEQ_VV(rd, rs1, rs2, vm_bool)) // vmfeq.vv
            0b001 => DecodeResult(VMFEQ_VF(rd, rs1, rs2, vm_bool)) // vmfeq.vf
            0b010 => DecodeResult(VMFNE_VV(rd, rs1, rs2, vm_bool)) // vmfne.vv
            0b011 => DecodeResult(VMFNE_VF(rd, rs1, rs2, vm_bool)) // vmfne.vf
            0b100 => DecodeResult(VMFLT_VV(rd, rs1, rs2, vm_bool)) // vmflt.vv
            0b101 => DecodeResult(VMFLT_VF(rd, rs1, rs2, vm_bool)) // vmflt.vf
            0b110 => DecodeResult(VMFLE_VV(rd, rs1, rs2, vm_bool)) // vmfle.vv
            0b111 => DecodeResult(VMFLE_VF(rd, rs1, rs2, vm_bool)) // vmfle.vf
            _ => DecodeResult(Invalid(code))
          }
        // VMFGT/VMFGE: funct6=0b011010
        0b011010 =>
          match f3 {
            0b000 => DecodeResult(VMFGT_VF(rd, rs1, rs2, vm_bool)) // vmfgt.vf
            0b010 => DecodeResult(VMFGE_VF(rd, rs1, rs2, vm_bool)) // vmfge.vf
            _ => DecodeResult(Invalid(code))
          }

        // ===== Vector narrowing =====
        // VNSRL/VNSRA: funct6=0b101100
        0b101100 =>
          match f3 {
            0b000 => DecodeResult(VNSRL_VV(rd, rs1, rs2, vm_bool)) // vnsrl.vv
            0b001 => DecodeResult(VNSRL_VX(rd, rs1, rs2, vm_bool)) // vnsrl.vx
            0b011 => DecodeResult(VNSRL_VI(rd, rs1, rs2, vm_bool)) // vnsrl.vi
            0b010 => DecodeResult(VNSRA_VV(rd, rs1, rs2, vm_bool)) // vnsra.vv
            0b100 => DecodeResult(VNSRA_VX(rd, rs1, rs2, vm_bool)) // vnsra.vx
            0b110 => DecodeResult(VNSRA_VI(rd, rs1, rs2, vm_bool)) // vnsra.vi
            _ => DecodeResult(Invalid(code))
          }
        _ => DecodeResult(Invalid(code))
      }
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
