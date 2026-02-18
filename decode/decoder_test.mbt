///|
/// Tests for RISC-V instruction decoder
test "decode_lui" {
  // LUI x5, 0x12345
  // imm[31:12] = 0x12345, rd = 5
  // Expected immediate: 0x12345000 = 305418240
  let code = 0x123452B7U
  let DecodeResult(result) = decode(code)
  match result {
    LUI(rd, imm) => {
      inspect(rd, content="5")
      inspect(imm, content="305418240")
    }
    _ => inspect(result, content="LUI(_, _)")
  }
}

///|
test "decode_auipc" {
  // AUIPC x10, 0x10000
  // imm[31:12] = 0x10000, rd = 10
  // Expected immediate: 0x10000000 = 268435456
  let code = 0x00010517U
  let DecodeResult(result) = decode(code)
  match result {
    AUIPC(rd, imm) => {
      inspect(rd, content="10")
      inspect(imm, content="65536") // 0x10000 << 12 = 0x10000000
    }
    _ => inspect(result, content="AUIPC(_, _)")
  }
}

///|
test "decode_jal" {
  // JAL x1, 0x100
  let code = 0x100000EFU
  let DecodeResult(result) = decode(code)
  match result {
    JAL(rd, imm) => {
      inspect(rd, content="1")
      inspect(imm, content="256") // 0x100
    }
    _ => inspect(result, content="JAL(_, _)")
  }
}

///|
test "decode_jalr" {
  // JALR x1, x2, 8
  let code = 0x008100E7U
  let DecodeResult(result) = decode(code)
  match result {
    JALR(rd, rs1, imm) => {
      inspect(rd, content="1")
      inspect(rs1, content="2")
      inspect(imm, content="8")
    }
    _ => inspect(result, content="JALR(_, _, _)")
  }
}

///|
test "decode_beq" {
  // BEQ x1, x2, 16
  let code = 0x00208463U
  let DecodeResult(result) = decode(code)
  match result {
    BEQ(rs1, rs2, imm) => {
      inspect(rs1, content="1")
      inspect(rs2, content="2")
      inspect(imm, content="8")
    }
    _ => inspect(result, content="BEQ(_, _, _)")
  }
}

///|
test "decode_addi" {
  // ADDI x5, x6, 100
  let code = 0x06430293U
  let DecodeResult(result) = decode(code)
  match result {
    ADDI(rd, rs1, imm) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(imm, content="100")
    }
    _ => inspect(result, content="ADDI(_, _, _)")
  }
}

///|
test "decode_add" {
  // ADD x5, x6, x7
  let code = 0x007302B3U
  let DecodeResult(result) = decode(code)
  match result {
    ADD(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ADD(_, _, _)")
  }
}

///|
test "decode_sub" {
  // SUB x5, x6, x7
  let code = 0x407302B3U
  let DecodeResult(result) = decode(code)
  match result {
    SUB(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SUB(_, _, _)")
  }
}

///|
test "decode_lw" {
  // LW x5, 100(x6)
  let code = 0x06432283U
  let DecodeResult(result) = decode(code)
  match result {
    LW(rd, rs1, imm) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(imm, content="100")
    }
    _ => inspect(result, content="LW(_, _, _)")
  }
}

///|
test "decode_sw" {
  // SW x5, 100(x6)
  let code = 0x00532423U
  let DecodeResult(result) = decode(code)
  match result {
    SW(rs1, rs2, imm) => {
      inspect(rs1, content="6")
      inspect(rs2, content="5")
      inspect(imm, content="8")
    }
    _ => inspect(result, content="SW(_, _, _)")
  }
}

///|
test "decode_negative_imm" {
  // ADDI x5, x0, -1
  let code = 0xFFF00293U
  let DecodeResult(result) = decode(code)
  match result {
    ADDI(rd, rs1, imm) => {
      inspect(rd, content="5")
      inspect(rs1, content="0")
      inspect(imm, content="-1")
    }
    _ => inspect(result, content="ADDI(_, _, _)")
  }
}

///|
test "is_compressed" {
  // 16-bit instruction (C.ADDI)
  let compressed = 0x0001U
  let normal = 0x00400013U

  assert_true(is_compressed(compressed))
  assert_false(is_compressed(normal))
}

///|
test "instruction_category" {
  let DecodeResult(add_inst) = decode(0x007302B3U) // ADD
  let add_cat = add_inst.category()
  inspect(add_cat, content="Arithmetic")

  let DecodeResult(beq_inst) = decode(0x00208463U) // BEQ
  let beq_cat = beq_inst.category()
  inspect(beq_cat, content="Branch")

  let DecodeResult(lw_inst) = decode(0x06432283U) // LW
  let lw_cat = lw_inst.category()
  inspect(lw_cat, content="Load")
}

///|
test "reg_name" {
  inspect(reg_name(0U), content="zero")
  inspect(reg_name(1U), content="ra")
  inspect(reg_name(2U), content="sp")
  inspect(reg_name(10U), content="a0")
  inspect(reg_name(31U), content="t6")
}

// RV32C Compressed Instruction Tests

///|
test "decode_c_nop" {
  // C.NOP (0x0001) - Quadrant 1, C.ADDI with rd=0, imm=0
  let code = 0x0001U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_NOP => inspect(true, content="true")
    _ => inspect(result, content="C_NOP")
  }
}

///|
test "decode_c_addi" {
  // C.ADDI x5, 1 - Quadrant 1, f3=000, rd=5, imm=1
  // Encoding: 000 | 00001 | 00101 | 01 = 0x0505
  let code = 0x0505U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_ADDI(rd, imm) => {
      inspect(
        rd,
        content=(
          #|10
        ),
      )
      inspect(imm, content="1")
    }
    _ => inspect(result, content="C_ADDI(_, _)")
  }
}

///|
test "decode_c_li" {
  // C.LI x5, 1 - Quadrant 1, f3=010, rd=5, imm=1
  // Encoding: 010 | 00001 | 00101 | 01 = 0x4505
  let code = 0x4505U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_LI(rd, imm) => {
      inspect(
        rd,
        content=(
          #|10
        ),
      )
      inspect(imm, content="1")
    }
    _ => inspect(result, content="C_LI(_, _)")
  }
}

///|
test "decode_c_lw" {
  // C.LW x8, 0(x8) - Quadrant 0, f3=010
  // Encoding: 010 | 000 | 010 | 00 000 | 00 = 0x4000
  let code = 0x4000U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_LW(rd, rs1, imm) => {
      inspect(rd, content="8")
      inspect(rs1, content="8")
    }
    _ => inspect(result, content="C_LW(_, _, _)")
  }
}

///|
test "decode_c_sw" {
  // C.SW x8, 0(x8) - Quadrant 0, f3=110
  // Encoding: 110 | 000 | 010 | 00 000 | 00 = 0xC000
  let code = 0xC000U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_SW(rs2, rs1, imm) => {
      inspect(rs2, content="8")
      inspect(rs1, content="8")
    }
    _ => inspect(result, content="C_SW(_, _, _)")
  }
}

///|
test "decode_c_j" {
  // C.J with offset=0 - Quadrant 1, f3=101
  let code = 0xA001U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_J(imm) => inspect(imm, content="0")
    _ => inspect(result, content="C_J(_)")
  }
}

///|
test "decode_c_jal" {
  // C.JAL with offset=0 - Quadrant 1, f3=001
  let code = 0x2001U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_JAL(imm) => inspect(imm, content="0")
    _ => inspect(result, content="C_JAL(_)")
  }
}

///|
test "decode_c_beqz" {
  // C.BEQZ x8, 0 - Quadrant 1, f3=110
  let code = 0xC001U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_BEQZ(rs1, imm) => {
      inspect(rs1, content="8")
      inspect(imm, content="0")
    }
    _ => inspect(result, content="C_BEQZ(_, _)")
  }
}

///|
test "decode_c_bnez" {
  // C.BNEZ x8, 0 - Quadrant 1, f3=111
  let code = 0xE001U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_BNEZ(rs1, imm) => {
      inspect(rs1, content="8")
      inspect(imm, content="0")
    }
    _ => inspect(result, content="C_BNEZ(_, _)")
  }
}

///|
test "decode_c_mv" {
  // C.MV x5, x6 - Quadrant 2, f3=100, rd=5, rs2=6
  let code = 0x8532U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_MV(rd, rs2) => {
      inspect(
        rd,
        content=(
          #|10
        ),
      )
      inspect(
        rs2,
        content=(
          #|12
        ),
      )
    }
    _ => inspect(result, content="C_MV(_, _)")
  }
}

///|
test "decode_c_add" {
  // C.ADD x5, x6 - Quadrant 2, f3=100, rd=5, rs2=6, bit12=1
  let code = 0x9532U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_ADD(rd, rs2) => {
      inspect(
        rd,
        content=(
          #|10
        ),
      )
      inspect(
        rs2,
        content=(
          #|12
        ),
      )
    }
    _ => inspect(result, content="C_ADD(_, _)")
  }
}

///|
test "decode_c_jr" {
  // C.JR x1 (ra) - Quadrant 2, f3=100, rd=1, rs2=0
  let code = 0x8102U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_JR(rs1) =>
      inspect(
        rs1,
        content=(
          #|2
        ),
      )
    _ => inspect(result, content="C_JR(_)")
  }
}

///|
test "decode_c_jalr" {
  // C.JALR x2 (sp) - Quadrant 2, f3=100, rd=2, rs2=0, bit12=1
  // Encoding: |f3|b12|rd|rs2|q| = |100|1|00010|00000|10| = 0x9102
  let code = 0x9102U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_JALR(rs1) => inspect(rs1, content="2")
    _ => inspect(result, content="C_JALR(2)")
  }
}

///|
test "decode_c_ebreak" {
  // C.EBREAK - Quadrant 2, f3=100, rd=0, rs2=0, bit12=1
  let code = 0x9002U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_EBREAK => inspect(true, content="true")
    _ => inspect(result, content="C_EBREAK")
  }
}

///|
test "decode_c_lwsp" {
  // C.LWSP x5, 0(sp) - Quadrant 2, f3=010, rd=5
  let code = 0x4502U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_LWSP(rd, imm) =>
      inspect(
        rd,
        content=(
          #|10
        ),
      )
    _ => inspect(result, content="C_LWSP(_, _)")
  }
}

///|
test "decode_c_swsp" {
  // C.SWSP x2, 0(sp) - Quadrant 2, f3=110, rs2=2
  let code = 0xC002U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_SWSP(rs2, imm) =>
      inspect(
        rs2,
        content=(
          #|0
        ),
      )
    _ => inspect(result, content="C_SWSP(_, _)")
  }
}

///|
test "decode_c_andi" {
  // C.ANDI x8, 0 - Quadrant 1, f3=100, f2=10
  let code = 0x8801U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_ANDI(rd, imm) => {
      inspect(rd, content="8")
      inspect(imm, content="0")
    }
    _ => inspect(result, content="C_ANDI(_, _)")
  }
}

///|
test "decode_c_srli" {
  // C.SRLI x8, 0 - Quadrant 1, f3=100, f2=00
  let code = 0x8001U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_SRLI(rd, shamt) => {
      inspect(rd, content="8")
      inspect(shamt, content="0")
    }
    _ => inspect(result, content="C_SRLI(_, _)")
  }
}

///|
test "decode_c_srai" {
  // C.SRAI x8, 0 - Quadrant 1, f3=100, f2=01
  let code = 0x8401U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_SRAI(rd, shamt) => {
      inspect(rd, content="8")
      inspect(shamt, content="0")
    }
    _ => inspect(result, content="C_SRAI(_, _)")
  }
}

///|
test "decode_c_sub" {
  // C.SUB x8, x9 - Quadrant 1, f3=100, f2=11, bit12=0, bit5=0
  // Encoding: |f3|b12|f2|rs1'|b5|rs2'|q|
  //           |100|0|11|000|0|001|01| = 0x8C05
  let code = 0x8C05U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_SUB(rd, rs2) => {
      inspect(rd, content="8")
      inspect(rs2, content="9")
    }
    _ => inspect(result, content="C_SUB(8, 9)")
  }
}

///|
test "decode_c_xor" {
  // C.XOR x8, x9 - Quadrant 1, f3=100, f2=11, bit12=0, bit5=1
  // Encoding: |f3|b12|f2|rs1'|b5|rs2'|q|
  //           |100|0|11|000|1|001|01| = 0x8C25
  let code = 0x8C25U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_XOR(rd, rs2) => {
      inspect(rd, content="8")
      inspect(rs2, content="9")
    }
    _ => inspect(result, content="C_XOR(8, 9)")
  }
}

///|
test "decode_c_or" {
  // C.OR x8, x9 - Quadrant 1, f3=100, f2=11, bit12=1, bit5=0
  // Encoding: |f3|b12|f2|rs1'|b5|rs2'|q|
  //           |100|1|11|000|0|001|01| = 0x9C05
  let code = 0x9C05U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_OR(rd, rs2) => {
      inspect(rd, content="8")
      inspect(rs2, content="9")
    }
    _ => inspect(result, content="C_OR(8, 9)")
  }
}

///|
test "decode_c_and" {
  // C.AND x8, x9 - Quadrant 1, f3=100, f2=11, bit12=1, bit5=1
  // Encoding: |f3|b12|f2|rs1'|b5|rs2'|q|
  //           |100|1|11|000|1|001|01| = 0x9C25
  let code = 0x9C25U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_AND(rd, rs2) => {
      inspect(rd, content="8")
      inspect(rs2, content="9")
    }
    _ => inspect(result, content="C_AND(8, 9)")
  }
}

///|
test "decode_c_slli" {
  // C.SLLI x5, 0 - Quadrant 2, f3=000
  let code = 0x0502U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_SLLI(rd, shamt) => {
      inspect(
        rd,
        content=(
          #|10
        ),
      )
      inspect(shamt, content="0")
    }
    _ => inspect(result, content="C_SLLI(_, _)")
  }
}

///|
test "decode_c_addi16sp" {
  // C.ADDI16SP - Quadrant 1, f3=011, rd=2
  let code = 0x6101U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_ADDI16SP(imm) => inspect(true, content="true")
    _ =>
      inspect(
        result,
        content=(
          #|Invalid(24833)
        ),
      )
  }
}

///|
test "decode_c_addi4spn" {
  // C.ADDI4SPN x8, 4 - Quadrant 0, f3=000
  let code = 0x0008U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_ADDI4SPN(rd, imm) => {
      inspect(rd, content="8")
      inspect(true, content="true")
    }
    _ =>
      inspect(
        result,
        content=(
          #|Invalid(8)
        ),
      )
  }
}

///|
test "decode_c_lui" {
  // C.LUI x5, 1 - Quadrant 1, f3=011, rd=5
  let code = 0x6505U
  let DecodeResult(result) = decode_compressed(code)
  match result {
    C_LUI(rd, imm) => {
      inspect(
        rd,
        content=(
          #|10
        ),
      )
      inspect(true, content="true")
    }
    _ => inspect(result, content="C_LUI(_, _)")
  }
}

///|
test "instruction_length" {
  // 16-bit instruction
  inspect(instruction_length(0x0001U), content="2")
  // 32-bit instruction
  inspect(instruction_length(0x00400013U), content="4")
}

// ========== RV64I Instruction Tests ==========

///|
test "decode_ld" {
  // LD x5, 100(x6) - load doubleword
  // I-type: imm[11:0] | rs1 | funct3 | rd | opcode
  // imm=100=0x064, rs1=6, funct3=3 (LD), rd=5, opcode=0x03
  // Hex: 0x06433283
  let code = 0x06433283U
  let DecodeResult(result) = decode(code)
  match result {
    LD(rd, rs1, imm) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(imm, content="100")
    }
    _ => inspect(result, content="LD(_, _, _)")
  }
}

///|
test "decode_sd" {
  // SD x5, 100(x6) - store doubleword
  // S-type: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
  // Hex: 0x06533223
  let code = 0x06533223U
  let DecodeResult(result) = decode(code)
  match result {
    SD(rs1, rs2, imm) => {
      inspect(rs1, content="6")
      inspect(rs2, content="5")
      inspect(imm, content="100")
    }
    _ => inspect(result, content="SD(_, _, _)")
  }
}

///|
test "decode_lwu" {
  // LWU x13, 100(x12) - load word unsigned
  // I-type: imm=100, rs1=12, funct3=6 (LWU), rd=13, opcode=0x03
  // Hex: 0x06466683
  let code = 0x06466683U
  let DecodeResult(result) = decode(code)
  match result {
    LWU(rd, rs1, imm) => {
      inspect(rd, content="13")
      inspect(rs1, content="12")
      inspect(imm, content="100")
    }
    _ => inspect(result, content="LWU(_, _, _)")
  }
}

///|
test "decode_addiw" {
  // ADDIW x5, x6, 100 - add immediate word (RV64I)
  // I-type: imm=100, rs1=6, funct3=0, rd=5, opcode=0x1B (OP_IMM_32)
  // Hex: 0x0643029B
  let code = 0x0643029BU
  let DecodeResult(result) = decode(code)
  match result {
    ADDIW(rd, rs1, imm) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(imm, content="100")
    }
    _ => inspect(result, content="ADDIW(_, _, _)")
  }
}

///|
test "decode_slliw" {
  // SLLIW x5, x6, 5 - shift left logical immediate word
  // I-type: shamt=5, rs1=6, funct3=1, rd=5, opcode=0x1B
  // funct7=0x00 for SLLIW
  // Binary: 0000000 | 00101 | 00110 | 001 | 00101 | 0011011
  //         funct7   shamt   rs1     f3    rd      opcode
  // Hex: 0x0053129B
  let code = 0x0053129BU
  let DecodeResult(result) = decode(code)
  match result {
    SLLIW(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="SLLIW(_, _, _)")
  }
}

///|
test "decode_srliw" {
  // SRLIW x5, x6, 5 - shift right logical immediate word
  // I-type: shamt=5, rs1=6, funct3=5, rd=5, opcode=0x1B
  // funct7=0x00 for SRLIW
  // Binary: 0000000 | 00101 | 00110 | 101 | 00101 | 0011011
  // Hex: 0x0053529B
  let code = 0x0053529BU
  let DecodeResult(result) = decode(code)
  match result {
    SRLIW(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="SRLIW(_, _, _)")
  }
}

///|
test "decode_sraiw" {
  // SRAIW x5, x6, 5 - shift right arithmetic immediate word
  // funct7=0x20 for SRAIW
  // Binary: 0100000 | 00101 | 00110 | 101 | 00101 | 0011011
  // Hex: 0x4053529B
  let code = 0x4053529BU
  let DecodeResult(result) = decode(code)
  match result {
    SRAIW(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="SRAIW(_, _, _)")
  }
}

///|
test "decode_addw" {
  // ADDW x5, x6, x7 - add word (RV64I)
  // R-type: funct7=0x00, rs2=7, rs1=6, funct3=0, rd=5, opcode=0x3B (OP_32)
  // Binary: 0000000 | 00111 | 00110 | 000 | 00101 | 0111011
  // Hex: 0x007302BB
  let code = 0x007302BBU
  let DecodeResult(result) = decode(code)
  match result {
    ADDW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ADDW(_, _, _)")
  }
}

///|
test "decode_subw" {
  // SUBW x5, x6, x7 - subtract word
  // R-type: funct7=0x20 for SUBW
  // Binary: 0100000 | 00111 | 00110 | 000 | 00101 | 0111011
  // Hex: 0x407302BB
  let code = 0x407302BBU
  let DecodeResult(result) = decode(code)
  match result {
    SUBW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SUBW(_, _, _)")
  }
}

///|
test "decode_mulw" {
  // MULW x5, x6, x7 - multiply word (RV64M)
  // R-type: funct7=0x01 for MUL extension
  // Binary: 0000001 | 00111 | 00110 | 000 | 00101 | 0111011
  // Hex: 0x027302BB
  let code = 0x027302BBU
  let DecodeResult(result) = decode(code)
  match result {
    MULW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="MULW(_, _, _)")
  }
}

///|
test "decode_divw" {
  // DIVW x5, x6, x7 - divide word signed (RV64M)
  // R-type: funct7=0x01, funct3=4 for DIVW
  // Binary: 0000001 | 00111 | 00110 | 100 | 00101 | 0111011
  // Hex: 0x027342BB
  let code = 0x027342BBU
  let DecodeResult(result) = decode(code)
  match result {
    DIVW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="DIVW(_, _, _)")
  }
}

// ========== RV32A Atomic Instruction Tests ==========

///|
test "decode_lr_w" {
  // LR.W x5, (x6) - load-reserved word
  // R-type: funct5=0x02 (LR.W), aq=0, rl=0, rs2=0, rs1=6, funct3=2, rd=5, opcode=0x2F
  // Binary: 00010 | 0 | 0 | 00000 | 00110 | 010 | 00101 | 0101111
  //         f5     aq  rl  rs2     rs1     f3    rd      opcode
  // funct7 = 0b00010000 = 0x10
  // Hex: 0x100322AF
  let code = 0x100322AFU
  let DecodeResult(result) = decode(code)
  match result {
    LR_W(rd, rs1, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="LR_W(_, _, _, _)")
  }
}

///|
test "decode_lr_w_aqrl" {
  // LR.W.AQRL x5, (x6) - load-reserved word with aq=1, rl=1
  // funct7 = 0b00010110 = 0x16
  // Hex: 0x160322AF
  let code = 0x160322AFU
  let DecodeResult(result) = decode(code)
  match result {
    LR_W(rd, rs1, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(aq, content="1")
      inspect(rl, content="1")
    }
    _ => inspect(result, content="LR_W(_, _, _, _)")
  }
}

///|
test "decode_sc_w" {
  // SC.W x5, x7, (x6) - store-conditional word
  // R-type: funct5=0x03 (SC.W), aq=0, rl=0, rs2=7, rs1=6, funct3=2, rd=5
  // funct7 = 0b00011000 = 0x18
  // Binary: 00011 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x187322AF
  let code = 0x187322AFU
  let DecodeResult(result) = decode(code)
  match result {
    SC_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="SC_W(_, _, _, _, _)")
  }
}

///|
test "decode_amoswap_w" {
  // AMOSWAP.W x5, x7, (x6) - atomic swap word
  // funct5=0x01 (AMOSWAP), funct7 = 0b00001000 = 0x08
  // Binary: 00001 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x087322AF
  let code = 0x087322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOSWAP_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOSWAP_W(_, _, _, _, _)")
  }
}

///|
test "decode_amoadd_w" {
  // AMOADD.W x5, x7, (x6) - atomic add word
  // funct5=0x00 (AMOADD), funct7 = 0b00000000 = 0x00
  // Binary: 00000 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x007322AF
  let code = 0x007322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOADD_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOADD_W(_, _, _, _, _)")
  }
}

///|
test "decode_amoxor_w" {
  // AMOXOR.W x5, x7, (x6) - atomic xor word
  // funct5=0x04 (AMOXOR), funct7 = 0b00100000 = 0x20
  // Binary: 00100 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x207322AF
  let code = 0x207322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOXOR_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOXOR_W(_, _, _, _, _)")
  }
}

///|
test "decode_amoand_w" {
  // AMOAND.W x5, x7, (x6) - atomic and word
  // funct5=0x0C (AMOAND), funct7 = 0b01100000 = 0x60
  // Binary: 01100 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x607322AF
  let code = 0x607322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOAND_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOAND_W(_, _, _, _, _)")
  }
}

///|
test "decode_amoor_w" {
  // AMOOR.W x5, x7, (x6) - atomic or word
  // funct5=0x08 (AMOOR), funct7 = 0b01000000 = 0x40
  // Binary: 01000 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x407322AF
  let code = 0x407322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOOR_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOOR_W(_, _, _, _, _)")
  }
}

///|
test "decode_amomin_w" {
  // AMOMIN.W x5, x7, (x6) - atomic min word (signed)
  // funct5=0x10 (AMOMIN), funct7 = 0b10000000 = 0x80
  // Binary: 10000 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0x807322AF
  let code = 0x807322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOMIN_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOMIN_W(_, _, _, _, _)")
  }
}

///|
test "decode_amomax_w" {
  // AMOMAX.W x5, x7, (x6) - atomic max word (signed)
  // funct5=0x14 (AMOMAX), funct7 = 0b10100000 = 0xA0
  // Binary: 10100 | 0 | 0 | 00111 | 00110 | 010 | 00101 | 0101111
  // Hex: 0xA07322AF
  let code = 0xA07322AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOMAX_W(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOMAX_W(_, _, _, _, _)")
  }
}

// ========== RV64A Atomic Instruction Tests ==========

///|
test "decode_lr_d" {
  // LR.D x5, (x6) - load-reserved doubleword
  // funct5=0x02 (LR), funct3=3 (D), funct7 = 0b00010000 = 0x10
  // Binary: 00010 | 0 | 0 | 00000 | 00110 | 011 | 00101 | 0101111
  // Hex: 0x100332AF
  let code = 0x100332AFU
  let DecodeResult(result) = decode(code)
  match result {
    LR_D(rd, rs1, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="LR_D(_, _, _, _)")
  }
}

///|
test "decode_sc_d" {
  // SC.D x5, x7, (x6) - store-conditional doubleword
  // funct5=0x03 (SC), funct3=3 (D), funct7 = 0b00011000 = 0x18
  // Binary: 00011 | 0 | 0 | 00111 | 00110 | 011 | 00101 | 0101111
  // Hex: 0x187332AF
  let code = 0x187332AFU
  let DecodeResult(result) = decode(code)
  match result {
    SC_D(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="SC_D(_, _, _, _, _)")
  }
}

///|
test "decode_amoadd_d" {
  // AMOADD.D x5, x7, (x6) - atomic add doubleword
  // funct5=0x00 (AMOADD), funct3=3 (D), funct7 = 0x00
  // Binary: 00000 | 0 | 0 | 00111 | 00110 | 011 | 00101 | 0101111
  // Hex: 0x007332AF
  let code = 0x007332AFU
  let DecodeResult(result) = decode(code)
  match result {
    AMOADD_D(rd, rs1, rs2, aq, rl) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
      inspect(aq, content="0")
      inspect(rl, content="0")
    }
    _ => inspect(result, content="AMOADD_D(_, _, _, _, _)")
  }
}

///|
/// Tests for Zicsr instructions
test "decode_csrrw" {
  // CSRRW x5, 0x001 (fflags), x6 - f3=001
  // csr=0x001, rd=5, rs1=6
  let code = 0x001312F3U
  let DecodeResult(result) = decode(code)
  match result {
    CSRRW(rd, csr, rs1) => {
      inspect(rd, content="5")
      inspect(csr, content="1")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CSRRW(_, _, _)")
  }
}

///|
test "decode_csrrs" {
  // CSRRS x5, 0x001 (fflags), x6 - f3=010
  // Encoding: csr=1, rs1=6, f3=010, rd=5, opcode=0x73
  // Binary: csr[31:20] | rs1[19:15] | f3[14:12] | rd[11:7] | opcode[6:0]
  // = 0x001 << 20 | 6 << 15 | 2 << 12 | 5 << 7 | 0x73
  // = 0x100000 | 0x30000 | 0x2000 | 0x280 | 0x73 = 0x1322F3
  let code = 0x001322F3U
  let DecodeResult(result) = decode(code)
  match result {
    CSRRS(rd, csr, rs1) => {
      inspect(rd, content="5")
      inspect(csr, content="1")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CSRRS(_, _, _)")
  }
}

///|
test "decode_csrrc" {
  // CSRRC x5, 0x001 (fflags), x6 - f3=011
  // = 0x001 << 20 | 6 << 15 | 3 << 12 | 5 << 7 | 0x73 = 0x1332F3
  let code = 0x001332F3U
  let DecodeResult(result) = decode(code)
  match result {
    CSRRC(rd, csr, rs1) => {
      inspect(rd, content="5")
      inspect(csr, content="1")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CSRRC(_, _, _)")
  }
}

///|
test "decode_csrrwi" {
  // CSRRWI x5, 0x001 (fflags), 3 - f3=101
  let code = 0x0011D2F3U
  let DecodeResult(result) = decode(code)
  match result {
    CSRRWI(rd, csr, uimm) => {
      inspect(rd, content="5")
      inspect(csr, content="1")
      inspect(uimm, content="3")
    }
    _ => inspect(result, content="CSRRWI(_, _, _)")
  }
}

///|
/// Tests for Zba extension (address generation)
test "decode_sh1add" {
  // SH1ADD x5, x6, x7 - f3=010, f7=0010000
  // R-type: f7[31:25] | rs2[24:20] | rs1[19:15] | f3[14:12] | rd[11:7] | opcode[6:0]
  // = 16 << 25 | 7 << 20 | 6 << 15 | 2 << 12 | 5 << 7 | 0x33 = 0x207322B3
  let code = 0x207322B3U
  let DecodeResult(result) = decode(code)
  match result {
    SH1ADD(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SH1ADD(_, _, _)")
  }
}

///|
test "decode_sh2add" {
  // SH2ADD x5, x6, x7 - f3=100, f7=0010000
  // R-type: = 16 << 25 | 7 << 20 | 6 << 15 | 4 << 12 | 5 << 7 | 0x33 = 0x207342B3
  let code = 0x207342B3U
  let DecodeResult(result) = decode(code)
  match result {
    SH2ADD(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SH2ADD(_, _, _)")
  }
}

///|
test "decode_sh3add" {
  // SH3ADD x5, x6, x7 - f3=110, f7=0010000
  // R-type: = 16 << 25 | 7 << 20 | 6 << 15 | 6 << 12 | 5 << 7 | 0x33 = 0x207362B3
  let code = 0x207362B3U
  let DecodeResult(result) = decode(code)
  match result {
    SH3ADD(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SH3ADD(_, _, _)")
  }
}

///|
/// Tests for Zba RV64 extension (address generation 64-bit)
test "decode_sh1add_uw" {
  // SH1ADD.UW x5, x6, x7 - opcode=OP_32(0x3B), f3=010, f7=0010000
  // R-type: 16 << 25 | 7 << 20 | 6 << 15 | 2 << 12 | 5 << 7 | 0x3B = 0x207322BB
  let code = 0x207322BBU
  let DecodeResult(result) = decode(code)
  match result {
    SH1ADD_UW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SH1ADD_UW(_, _, _)")
  }
}

///|
test "decode_sh2add_uw" {
  // SH2ADD.UW x5, x6, x7 - opcode=OP_32(0x3B), f3=100, f7=0010000
  // R-type: 16 << 25 | 7 << 20 | 6 << 15 | 4 << 12 | 5 << 7 | 0x3B = 0x207342BB
  let code = 0x207342BBU
  let DecodeResult(result) = decode(code)
  match result {
    SH2ADD_UW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SH2ADD_UW(_, _, _)")
  }
}

///|
test "decode_sh3add_uw" {
  // SH3ADD.UW x5, x6, x7 - opcode=OP_32(0x3B), f3=110, f7=0010000
  // R-type: 16 << 25 | 7 << 20 | 6 << 15 | 6 << 12 | 5 << 7 | 0x3B = 0x207362BB
  let code = 0x207362BBU
  let DecodeResult(result) = decode(code)
  match result {
    SH3ADD_UW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="SH3ADD_UW(_, _, _)")
  }
}

///|
test "decode_add_uw" {
  // ADD.UW x5, x6, x7 - opcode=OP_32(0x3B), f3=000, f7=0000100
  // R-type: 4 << 25 | 7 << 20 | 6 << 15 | 0 << 12 | 5 << 7 | 0x3B = 0x087302BB
  let code = 0x087302BBU
  let DecodeResult(result) = decode(code)
  match result {
    ADD_UW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ADD_UW(_, _, _)")
  }
}

///|
test "decode_slli_uw" {
  // SLLI.UW x5, x6, 7 - opcode=OP_IMM_32(0x1B), f3=001, f7=0000100
  // I-type: 4 << 25 | 7 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x1B = 0x0873129B
  let code = 0x0873129BU
  let DecodeResult(result) = decode(code)
  match result {
    SLLI_UW(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="7")
    }
    _ => inspect(result, content="SLLI_UW(_, _, _)")
  }
}

///|
/// Tests for Zbb RV64 extension (basic bit manipulation 64-bit)
test "decode_clzw" {
  // CLZW x5, x6 - opcode=OP_32(0x3B), f3=001, f7=0110000, rs2=00000
  // R-type: 48 << 25 | 0 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x3B = 0x600312BB
  let code = 0x600312BBU
  let DecodeResult(result) = decode(code)
  match result {
    CLZW(rd, rs1) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CLZW(_, _)")
  }
}

///|
test "decode_ctzw" {
  // CTZW x5, x6 - opcode=OP_32(0x3B), f3=001, f7=0110000, rs2=00001
  // R-type: 48 << 25 | 1 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x3B = 0x601312BB
  let code = 0x601312BBU
  let DecodeResult(result) = decode(code)
  match result {
    CTZW(rd, rs1) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CTZW(_, _)")
  }
}

///|
test "decode_cpopw" {
  // CPOPW x5, x6 - opcode=OP_32(0x3B), f3=001, f7=0110000, rs2=00010
  // R-type: 48 << 25 | 2 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x3B = 0x602312BB
  let code = 0x602312BBU
  let DecodeResult(result) = decode(code)
  match result {
    CPOPW(rd, rs1) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CPOPW(_, _)")
  }
}

///|
test "decode_rolw" {
  // ROLW x5, x6, x7 - opcode=OP_32(0x3B), f3=001, f7=0110000
  // R-type: 48 << 25 | 7 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x3B = 0x607312BB
  let code = 0x607312BBU
  let DecodeResult(result) = decode(code)
  match result {
    ROLW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ROLW(_, _, _)")
  }
}

///|
test "decode_rorw" {
  // RORW x5, x6, x7 - opcode=OP_32(0x3B), f3=101, f7=0110000
  // R-type: 48 << 25 | 7 << 20 | 6 << 15 | 5 << 12 | 5 << 7 | 0x3B = 0x607352BB
  let code = 0x607352BBU
  let DecodeResult(result) = decode(code)
  match result {
    RORW(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="RORW(_, _, _)")
  }
}

///|
test "decode_roriw" {
  // RORIW x5, x6, 7 - opcode=OP_IMM_32(0x1B), f3=101, f7=0110000
  // I-type: 48 << 25 | 7 << 20 | 6 << 15 | 5 << 12 | 5 << 7 | 0x1B = 0x6073529B
  let code = 0x6073529BU
  let DecodeResult(result) = decode(code)
  match result {
    RORIW(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="7")
    }
    _ => inspect(result, content="RORIW(_, _, _)")
  }
}

///|
/// Tests for Zbb extension (basic bit manipulation)
test "decode_clz" {
  // CLZ x5, x6 - f3=001, f7=0110000, rs2=0
  // R-type: = 48 << 25 | 0 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x33 = 0x600312B3
  let code = 0x600312B3U
  let DecodeResult(result) = decode(code)
  match result {
    CLZ(rd, rs1) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CLZ(_, _)")
  }
}

///|
test "decode_ctz" {
  // CTZ x5, x6 - f3=001, f7=0110000, rs2=1
  // R-type: = 48 << 25 | 1 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x33 = 0x601312B3
  let code = 0x601312B3U
  let DecodeResult(result) = decode(code)
  match result {
    CTZ(rd, rs1) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CTZ(_, _)")
  }
}

///|
test "decode_cpop" {
  // CPOP x5, x6 - f3=001, f7=0110000, rs2=2
  // R-type: = 48 << 25 | 2 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x33 = 0x602312B3
  let code = 0x602312B3U
  let DecodeResult(result) = decode(code)
  match result {
    CPOP(rd, rs1) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
    }
    _ => inspect(result, content="CPOP(_, _)")
  }
}

///|
test "decode_andn" {
  // ANDN x5, x6, x7 - f3=111, f7=0100000
  // = 0x407372B3
  let code = 0x407372B3U
  let DecodeResult(result) = decode(code)
  match result {
    ANDN(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ANDN(_, _, _)")
  }
}

///|
test "decode_orn" {
  // ORN x5, x6, x7 - f3=110, f7=0100000
  // = 0x407362B3
  let code = 0x407362B3U
  let DecodeResult(result) = decode(code)
  match result {
    ORN(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ORN(_, _, _)")
  }
}

///|
test "decode_xnor" {
  // XNOR x5, x6, x7 - f3=100, f7=0100000
  // = 0x407342B3
  let code = 0x407342B3U
  let DecodeResult(result) = decode(code)
  match result {
    XNOR(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="XNOR(_, _, _)")
  }
}

///|
test "decode_min" {
  // MIN x5, x6, x7 - f3=010, f7=0000101
  // = 0x0A7322B3
  let code = 0x0A7322B3U
  let DecodeResult(result) = decode(code)
  match result {
    MIN(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="MIN(_, _, _)")
  }
}

///|
test "decode_max" {
  // MAX x5, x6, x7 - f3=110, f7=0000101
  // = 0x0A7362B3
  let code = 0x0A7362B3U
  let DecodeResult(result) = decode(code)
  match result {
    MAX(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="MAX(_, _, _)")
  }
}

///|
test "decode_minu" {
  // MINU x5, x6, x7 - f3=011, f7=0000101
  // = 0x0A7332B3
  let code = 0x0A7332B3U
  let DecodeResult(result) = decode(code)
  match result {
    MINU(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="MINU(_, _, _)")
  }
}

///|
test "decode_maxu" {
  // MAXU x5, x6, x7 - f3=111, f7=0000101
  // = 0x0A7372B3
  let code = 0x0A7372B3U
  let DecodeResult(result) = decode(code)
  match result {
    MAXU(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="MAXU(_, _, _)")
  }
}

///|
test "decode_rol" {
  // ROL x5, x6, x7 - f3=001, f7=0110000
  // R-type: = 48 << 25 | 7 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x33 = 0x607312B3
  let code = 0x607312B3U
  let DecodeResult(result) = decode(code)
  match result {
    ROL(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ROL(_, _, _)")
  }
}

///|
test "decode_ror" {
  // ROR x5, x6, x7 - f3=101, f7=0110000
  // = 0x607352B3
  let code = 0x607352B3U
  let DecodeResult(result) = decode(code)
  match result {
    ROR(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="ROR(_, _, _)")
  }
}

///|
test "decode_rori" {
  // RORI x5, x6, 5 - f3=101, f7=0110000, shamt=5
  // I-type: = 48 << 25 | 5 << 20 | 6 << 15 | 5 << 12 | 5 << 7 | 0x13 = 0x60535293
  let code = 0x60535293U
  let DecodeResult(result) = decode(code)
  match result {
    RORI(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="RORI(_, _, _)")
  }
}

///|
/// Tests for Zbs extension (single bit instructions)
test "decode_bset" {
  // BSET x5, x6, x7 - f3=110, f7=0010100
  // = 0x287362B3
  let code = 0x287362B3U
  let DecodeResult(result) = decode(code)
  match result {
    BSET(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="BSET(_, _, _)")
  }
}

///|
test "decode_bclr" {
  // BCLR x5, x6, x7 - f3=100, f7=0100100
  // = 0x487342B3
  let code = 0x487342B3U
  let DecodeResult(result) = decode(code)
  match result {
    BCLR(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="BCLR(_, _, _)")
  }
}

///|
test "decode_bext" {
  // BEXT x5, x6, x7 - f3=101, f7=0100101
  // = 0x4A7352B3
  let code = 0x4A7352B3U
  let DecodeResult(result) = decode(code)
  match result {
    BEXT(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="BEXT(_, _, _)")
  }
}

///|
test "decode_binv" {
  // BINV x5, x6, x7 - f3=101, f7=0110100
  // = 0x687352B3
  let code = 0x687352B3U
  let DecodeResult(result) = decode(code)
  match result {
    BINV(rd, rs1, rs2) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(rs2, content="7")
    }
    _ => inspect(result, content="BINV(_, _, _)")
  }
}

///|
test "decode_bseti" {
  // BSETI x5, x6, 5 - f3=001, f7=0010100, shamt=5
  // I-type: = 20 << 25 | 5 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x13 = 0x28531293
  let code = 0x28531293U
  let DecodeResult(result) = decode(code)
  match result {
    BSETI(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="BSETI(_, _, _)")
  }
}

///|
test "decode_bclri" {
  // BCLRI x5, x6, 5 - f3=001, f7=0100100, shamt=5
  // I-type: = 36 << 25 | 5 << 20 | 6 << 15 | 1 << 12 | 5 << 7 | 0x13 = 0x48531293
  let code = 0x48531293U
  let DecodeResult(result) = decode(code)
  match result {
    BCLRI(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="BCLRI(_, _, _)")
  }
}

///|
test "decode_bexti" {
  // BEXTI x5, x6, 5 - f3=101, f7=0100100, shamt=5
  // I-type: = 36 << 25 | 5 << 20 | 6 << 15 | 5 << 12 | 5 << 7 | 0x13 = 0x48535293
  let code = 0x48535293U
  let DecodeResult(result) = decode(code)
  match result {
    BEXTI(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="BEXTI(_, _, _)")
  }
}

///|
test "decode_binvi" {
  // BINVI x5, x6, 5 - f3=101, f7=0110100, shamt=5
  // I-type: = 52 << 25 | 5 << 20 | 6 << 15 | 5 << 12 | 5 << 7 | 0x13 = 0x68535293
  let code = 0x68535293U
  let DecodeResult(result) = decode(code)
  match result {
    BINVI(rd, rs1, shamt) => {
      inspect(rd, content="5")
      inspect(rs1, content="6")
      inspect(shamt, content="5")
    }
    _ => inspect(result, content="BINVI(_, _, _)")
  }
}
