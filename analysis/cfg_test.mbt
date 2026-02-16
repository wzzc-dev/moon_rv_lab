///|
/// Tests for CFG (Control Flow Graph) analysis

///|
/// Create bytes for a 32-bit instruction
fn make_u32_bytes(code : UInt) -> FixedArray[Byte] {
  let bytes : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  bytes[0] = (code & 0xFFU).to_byte()
  bytes[1] = ((code >> 8) & 0xFFU).to_byte()
  bytes[2] = ((code >> 16) & 0xFFU).to_byte()
  bytes[3] = ((code >> 24) & 0xFFU).to_byte()
  bytes
}

///|
/// Create bytes for a 16-bit compressed instruction
fn make_u16_bytes(code : UInt) -> FixedArray[Byte] {
  let bytes : FixedArray[Byte] = FixedArray::make(2, b'\x00')
  bytes[0] = (code & 0xFFU).to_byte()
  bytes[1] = ((code >> 8) & 0xFFU).to_byte()
  bytes
}

///|
/// Combine multiple byte arrays
fn concat_bytes(arrays : Array[FixedArray[Byte]]) -> FixedArray[Byte] {
  let total_len = {
    let mut len = 0
    for arr in arrays {
      len = len + arr.length()
    }
    len
  }
  let result : FixedArray[Byte] = FixedArray::make(total_len, b'\x00')
  let mut offset = 0
  for arr in arrays {
    for i = 0; i < arr.length(); i = i + 1 {
      result[offset + i] = arr[i]
    }
    offset = offset + arr.length()
  }
  result
}

///|
test "decode_instructions_32bit" {
  // ADDI x5, x0, 100
  let code = 0x06400293U
  let bytes = make_u32_bytes(code)
  let instructions = decode_instructions(bytes, 0U)

  inspect(instructions.length(), content="1")
  inspect(instructions[0].addr, content="0")
  inspect(instructions[0].length, content="4")
}

///|
test "decode_instructions_compressed" {
  // C.NOP (0x0001)
  let code = 0x0001U
  let bytes = make_u16_bytes(code)
  let instructions = decode_instructions(bytes, 0U)

  inspect(instructions.length(), content="1")
  inspect(instructions[0].addr, content="0")
  inspect(instructions[0].length, content="2")
}

///|
test "decode_instructions_mixed" {
  // Mix of 16-bit and 32-bit instructions
  // C.NOP (0x0001) + ADDI x5, x0, 100 (0x06400293)
  let nop_bytes = make_u16_bytes(0x0001U)
  let addi_bytes = make_u32_bytes(0x06400293U)
  let bytes = concat_bytes([nop_bytes, addi_bytes])

  let instructions = decode_instructions(bytes, 0U)

  inspect(instructions.length(), content="2")
  // First instruction: C.NOP at address 0, length 2
  inspect(instructions[0].addr, content="0")
  inspect(instructions[0].length, content="2")
  // Second instruction: ADDI at address 2, length 4
  inspect(instructions[1].addr, content="2")
  inspect(instructions[1].length, content="4")
}

///|
test "is_terminator_branch" {
  // BEQ x1, x2, 8
  let code = 0x00208463U
  let @decode.DecodeResult(inst) = @decode.decode(code)
  assert_true(is_terminator(inst))
}

///|
test "is_terminator_jump" {
  // JAL x1, 256
  let code = 0x100000EFU
  let @decode.DecodeResult(inst) = @decode.decode(code)
  assert_true(is_terminator(inst))
}

///|
test "is_terminator_normal" {
  // ADD x5, x6, x7
  let code = 0x007302B3U
  let @decode.DecodeResult(inst) = @decode.decode(code)
  assert_false(is_terminator(inst))
}

///|
test "is_terminator_compressed_branch" {
  // C.BEQZ x8, 0
  // Format: 110 | imm[8|4:3] | rs1' | imm[7:6|2:1|5] | 01
  // For rs1' = 0 (x8): bits[9:7] = 000
  // For imm = 0: all imm bits = 0
  // Encoding: 110 00 000 00 000 01 = 0xC001
  let code = 0xC001U
  let @decode.DecodeResult(inst) = @decode.decode_compressed(code)
  assert_true(is_terminator(inst))
}

///|
test "is_terminator_compressed_jump" {
  // C.J offset
  // Format: 101 | imm[11|4|9:8|10|6|7|3:1|5] | 01
  // For imm = 0: all imm bits = 0
  // Encoding: 101 0000000000 01 = 0xA001
  let code = 0xA001U
  let @decode.DecodeResult(inst) = @decode.decode_compressed(code)
  assert_true(is_terminator(inst))
}

///|
test "is_conditional_branch" {
  // BEQ
  let beq_code = 0x00208463U
  let @decode.DecodeResult(beq_inst) = @decode.decode(beq_code)
  assert_true(is_conditional_branch(beq_inst))

  // JAL (not conditional)
  let jal_code = 0x100000EFU
  let @decode.DecodeResult(jal_inst) = @decode.decode(jal_code)
  assert_false(is_conditional_branch(jal_inst))
}

///|
test "is_unconditional_jump" {
  // JAL
  let jal_code = 0x100000EFU
  let @decode.DecodeResult(jal_inst) = @decode.decode(jal_code)
  assert_true(is_unconditional_jump(jal_inst))

  // BEQ (not unconditional)
  let beq_code = 0x00208463U
  let @decode.DecodeResult(beq_inst) = @decode.decode(beq_code)
  assert_false(is_unconditional_jump(beq_inst))
}

///|
test "is_call_detection" {
  // JAL ra, 256 (call)
  let jal_ra_code = 0x100000EFU // rd = 1 (ra)
  let @decode.DecodeResult(jal_ra_inst) = @decode.decode(jal_ra_code)
  assert_true(is_call(jal_ra_inst))

  // JAL x5, 256 (not call, rd != ra)
  let jal_t0_code = 0x100002EFU // rd = 5 (t0)
  let @decode.DecodeResult(jal_t0_inst) = @decode.decode(jal_t0_code)
  // t0 (x5) is also considered a call link register
  assert_true(is_call(jal_t0_inst))
}

///|
test "is_return_detection" {
  // JALR x0, ra, 0 (ret)
  let ret_code = 0x00008067U // rd=0, rs1=1
  let @decode.DecodeResult(ret_inst) = @decode.decode(ret_code)
  assert_true(is_return(ret_inst))

  // JALR x1, ra, 0 (not return, writes to ra)
  let jalr_code = 0x000080E7U // rd=1, rs1=1
  let @decode.DecodeResult(jalr_inst) = @decode.decode(jalr_code)
  assert_false(is_return(jalr_inst))
}

///|
test "build_cfg_empty" {
  let bytes : FixedArray[Byte] = FixedArray::make(0, b'\x00')
  let instructions = decode_instructions(bytes, 0U)
  let cfg = build_cfg(instructions, 0U)

  inspect(cfg.blocks.length(), content="0")
  inspect(cfg.edges.length(), content="0")
}

///|
test "build_cfg_single_block" {
  // Two non-terminator instructions
  // ADDI x5, x0, 100
  // ADD x5, x5, x6
  let addi_bytes = make_u32_bytes(0x06400293U)
  let add_bytes = make_u32_bytes(0x006282B3U)
  let bytes = concat_bytes([addi_bytes, add_bytes])

  let instructions = decode_instructions(bytes, 0U)
  let cfg = build_cfg(instructions, 0U)

  // Should have one basic block
  inspect(cfg.blocks.length(), content="1")
  inspect(cfg.blocks[0].start_addr, content="0")
  inspect(cfg.blocks[0].instruction_count, content="2")
  assert_false(cfg.blocks[0].is_terminated)
}

///|
test "build_cfg_with_branch" {
  // BEQ x1, x2, 8
  let beq_bytes = make_u32_bytes(0x00208463U)
  let bytes = beq_bytes

  let instructions = decode_instructions(bytes, 0U)
  let cfg = build_cfg(instructions, 0U)

  // Should have one block ending with terminator
  inspect(cfg.blocks.length(), content="1")
  assert_true(cfg.blocks[0].is_terminated)

  // Should have two edges: branch taken and not taken
  inspect(cfg.edges.length(), content="2")
}
