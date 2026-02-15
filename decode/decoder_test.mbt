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
