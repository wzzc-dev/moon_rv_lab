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
fn sign_extend_20(value : UInt) -> Int {
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
        0b100 => DecodeResult(LBU(rd, rs1, imm))
        0b101 => DecodeResult(LHU(rd, rs1, imm))
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
        _ => DecodeResult(Invalid(code))
      }
    }
    // OP_IMM (Immediate arithmetic/logical)
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
          DecodeResult(SLLI(rd, rs1, shamt))
        }
        0b101 => {
          let shamt = extract_bits(code, 24, 20)
          match f7 {
            0b0000000 => DecodeResult(SRLI(rd, rs1, shamt))
            0b0100000 => DecodeResult(SRAI(rd, rs1, shamt))
            _ => DecodeResult(Invalid(code))
          }
        }
        _ => DecodeResult(Invalid(code))
      }
    // OP (Register arithmetic/logical)
    0b0110011 =>
      match f3 {
        0b000 =>
          match f7 {
            0b0000000 => DecodeResult(ADD(rd, rs1, rs2))
            0b0100000 => DecodeResult(SUB(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b001 => DecodeResult(SLL(rd, rs1, rs2))
        0b010 => DecodeResult(SLT(rd, rs1, rs2))
        0b011 => DecodeResult(SLTU(rd, rs1, rs2))
        0b100 => DecodeResult(XOR(rd, rs1, rs2))
        0b101 =>
          match f7 {
            0b0000000 => DecodeResult(SRL(rd, rs1, rs2))
            0b0100000 => DecodeResult(SRA(rd, rs1, rs2))
            _ => DecodeResult(Invalid(code))
          }
        0b110 => DecodeResult(OR(rd, rs1, rs2))
        0b111 => DecodeResult(AND(rd, rs1, rs2))
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
    // SYSTEM
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
