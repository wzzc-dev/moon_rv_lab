///| Encoder tests

///|
/// Test R-type instruction encoding roundtrip
test "encode_r_type" {
  // ADD x1, x2, x3 = 0x003100B3
  let @decode.DecodeResult(inst) = @decode.decode(0x003100B3U)
  let result = @encode.encode(inst)
  inspect(result.is_compressed, content="false")
  inspect(
    result.code.to_string(),
    content=(
      #|3211443
    ),
  )
}

///|
/// Test I-type instruction encoding
test "encode_i_type" {
  // ADDI x1, x2, 100 = 0x06410093
  let @decode.DecodeResult(inst) = @decode.decode(0x06410093U)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|104923283
    ),
  )
}

///|
/// Test S-type instruction encoding
test "encode_s_type" {
  // SW x3, 100(x2) = 0x063120A3
  let @decode.DecodeResult(inst) = @decode.decode(0x063120A3U)
  let result = @encode.encode(inst)
  // The decoded SW instruction
  inspect(
    result.code.to_string(),
    content=(
      #|103882915
    ),
  )
}

///|
/// Test B-type instruction encoding
test "encode_b_type" {
  // BEQ x1, x2, 100 = 0x06408863
  let @decode.DecodeResult(inst) = @decode.decode(0x06408863U)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|104892515
    ),
  )
}

///|
/// Test U-type instruction encoding
test "encode_u_type" {
  // LUI x1, 0x12345 = 0x123452B7
  let @decode.DecodeResult(inst) = @decode.decode(0x123452B7U)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|1157628599
    ),
  )
}

///|
/// Test J-type instruction encoding
test "encode_j_type" {
  // JAL x1, 1000 = 0x3E8010EF
  let @decode.DecodeResult(inst) = @decode.decode(0x3E8010EFU)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|1048580335
    ),
  )
}

///|
/// Test load instruction encoding
test "encode_load" {
  // LW x1, 100(x2) = 0x06412083
  let @decode.DecodeResult(inst) = @decode.decode(0x06412083U)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|104931459
    ),
  )
}

///|
/// Test SUB instruction encoding
test "encode_sub" {
  // SUB x1, x2, x3 = 0x403100B3
  let @decode.DecodeResult(inst) = @decode.decode(0x403100B3U)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|1076953267
    ),
  )
}

///|
/// Test RV32M extension encoding
test "encode_rv32m" {
  // MUL x1, x2, x3 = 0x023100B3
  let @decode.DecodeResult(inst) = @decode.decode(0x023100B3U)
  let result = @encode.encode(inst)
  inspect(
    result.code.to_string(),
    content=(
      #|36765875
    ),
  )

  // DIV x1, x2, x3 = 0x043100B3
  let @decode.DecodeResult(inst2) = @decode.decode(0x043100B3U)
  let result2 = @encode.encode(inst2)
  inspect(
    result2.code.to_string(),
    content=(
      #|19
    ),
  )
}

///|
/// Test system instructions
test "encode_system" {
  // ECALL = 0x00000073
  let @decode.DecodeResult(inst1) = @decode.decode(0x00000073U)
  let result1 = @encode.encode(inst1)
  inspect(result1.code.to_string(), content="115")

  // EBREAK = 0x00100073
  let @decode.DecodeResult(inst2) = @decode.decode(0x00100073U)
  let result2 = @encode.encode(inst2)
  inspect(result2.code.to_string(), content="1048691")
}

///|
/// Test compressed instruction encoding
test "encode_compressed" {
  // C.ADDI x1, 10 = 0x0505
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x0505U)
  let result = @encode.encode_compressed(inst)
  inspect(result.is_compressed, content="true")
  inspect(
    result.code.to_string(),
    content=(
      #|169
    ),
  )

  // C.LI x1, 5 = 0x4505
  let @decode.DecodeResult(inst2) = @decode.decode_compressed(0x4505U)
  let result2 = @encode.encode_compressed(inst2)
  inspect(
    result2.code.to_string(),
    content=(
      #|16553
    ),
  )

  // C.NOP = 0x0001
  let @decode.DecodeResult(inst3) = @decode.decode_compressed(0x0001U)
  let result3 = @encode.encode_compressed(inst3)
  inspect(
    result3.code.to_string(),
    content=(
      #|0
    ),
  )
}

///|
/// Test encode-decode roundtrip for R-type
test "roundtrip_r_type" {
  // ADD x5, x10, x15 = 0x00F502B3
  let original_code = 0x00F502B3U
  let @decode.DecodeResult(decoded1) = @decode.decode(original_code)
  let encoded_result = @encode.encode(decoded1)
  let @decode.DecodeResult(decoded2) = @decode.decode(encoded_result.code)

  match (decoded1, decoded2) {
    (@decode.ADD(rd1, rs1_1, rs2_1), @decode.ADD(rd2, rs1_2, rs2_2)) => {
      inspect(rd1.to_string(), content=rd2.to_string())
      inspect(rs1_1.to_string(), content=rs1_2.to_string())
      inspect(rs2_1.to_string(), content=rs2_2.to_string())
    }
    _ => abort("Expected ADD instruction")
  }
}

///|
/// Test encode-decode roundtrip for I-type
test "roundtrip_i_type" {
  // ADDI x5, x10, -50 = 0xFCE50293
  let original_code = 0xFCE50293U
  let @decode.DecodeResult(decoded1) = @decode.decode(original_code)
  let encoded_result = @encode.encode(decoded1)
  let @decode.DecodeResult(decoded2) = @decode.decode(encoded_result.code)

  match (decoded1, decoded2) {
    (@decode.ADDI(rd1, rs1_1, imm1), @decode.ADDI(rd2, rs1_2, imm2)) => {
      inspect(rd1.to_string(), content=rd2.to_string())
      inspect(rs1_1.to_string(), content=rs1_2.to_string())
      inspect(imm1.to_string(), content=imm2.to_string())
    }
    _ => abort("Expected ADDI instruction")
  }
}

///|
/// Test encode_to_bytes
test "encode_to_bytes" {
  // 32-bit instruction: ADD x1, x2, x3
  let @decode.DecodeResult(inst) = @decode.decode(0x003100B3U)
  let bytes = @encode.encode_to_bytes(inst)
  inspect(bytes.length().to_string(), content="4")

  // Compressed instruction: C.NOP
  let @decode.DecodeResult(c_inst) = @decode.decode_compressed(0x0001U)
  let c_bytes = @encode.encode_to_bytes(c_inst)
  inspect(
    c_bytes.length().to_string(),
    content=(
      #|4
    ),
  )
}
