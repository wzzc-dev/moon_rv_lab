///|
/// Tests for RISC-V disassembler
test "disassemble_lui" {
  let @decode.DecodeResult(inst) = @decode.decode(0x123452B7U)
  let result = disassemble(inst)
  inspect(result, content="lui t0, 0x12345")
}

///|
test "disassemble_add" {
  let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
  let result = disassemble(inst)
  inspect(result, content="add t0, t1, t2")
}

///|
test "disassemble_addi" {
  let @decode.DecodeResult(inst) = @decode.decode(0x06430293U)
  let result = disassemble(inst)
  inspect(result, content="addi t0, t1, 100")
}

///|
test "disassemble_addi_negative" {
  let @decode.DecodeResult(inst) = @decode.decode(0xFFF00293U)
  let result = disassemble(inst)
  inspect(result, content="addi t0, zero, -1")
}

///|
test "disassemble_lw" {
  let @decode.DecodeResult(inst) = @decode.decode(0x06432283U)
  let result = disassemble(inst)
  inspect(result, content="lw t0, 100(t1)")
}

///|
test "disassemble_sw" {
  let @decode.DecodeResult(inst) = @decode.decode(0x00532423U)
  let result = disassemble(inst)
  inspect(result, content="sw t0, 8(t1)")
}

///|
test "disassemble_beq" {
  let @decode.DecodeResult(inst) = @decode.decode(0x00208463U)
  let result = disassemble(inst)
  inspect(result, content="beq ra, sp, 0x8")
}

///|
test "disassemble_jal" {
  let @decode.DecodeResult(inst) = @decode.decode(0x100000EFU)
  let result = disassemble(inst)
  inspect(result, content="jal ra, 0x100")
}

///|
test "disassemble_ecall" {
  let @decode.DecodeResult(inst) = @decode.decode(0x00000073U)
  let result = disassemble(inst)
  inspect(result, content="ecall")
}

///|
test "disassemble_with_addr" {
  let @decode.DecodeResult(inst) = @decode.decode(0x007302B3U)
  let result = disassemble_with_addr(inst, 0x1000U)
  inspect(result, content="0x1000: add t0, t1, t2")
}

// RV32C Compressed Instruction Disassembly Tests

///|
test "disassemble_c_nop" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x0001U)
  let result = disassemble(inst)
  inspect(result, content="c.nop")
}

///|
test "disassemble_c_addi" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x0505U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.addi a0, 1
    ),
  )
}

///|
test "disassemble_c_li" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x4505U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.li a0, 1
    ),
  )
}

///|
test "disassemble_c_lw" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x4000U)
  let result = disassemble(inst)
  inspect(result, content="c.lw s0, 0(s0)")
}

///|
test "disassemble_c_sw" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0xC000U)
  let result = disassemble(inst)
  inspect(result, content="c.sw s0, 0(s0)")
}

///|
test "disassemble_c_j" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0xA001U)
  let result = disassemble(inst)
  inspect(result, content="c.j 0x0")
}

///|
test "disassemble_c_jal" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x2001U)
  let result = disassemble(inst)
  inspect(result, content="c.jal 0x0")
}

///|
test "disassemble_c_beqz" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0xC001U)
  let result = disassemble(inst)
  inspect(result, content="c.beqz s0, 0x0")
}

///|
test "disassemble_c_bnez" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0xE001U)
  let result = disassemble(inst)
  inspect(result, content="c.bnez s0, 0x0")
}

///|
test "disassemble_c_mv" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8532U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.mv a0, a2
    ),
  )
}

///|
test "disassemble_c_add" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x9532U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.add a0, a2
    ),
  )
}

///|
test "disassemble_c_jr" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8102U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.jr sp
    ),
  )
}

///|
test "disassemble_c_jalr" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x9102U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.jr sp
    ),
  )
}

///|
test "disassemble_c_ebreak" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x9002U)
  let result = disassemble(inst)
  inspect(result, content="c.ebreak")
}

///|
test "disassemble_c_lwsp" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x4502U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.lwsp a0, 0(sp)
    ),
  )
}

///|
test "disassemble_c_swsp" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0xC002U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.swsp zero, 128(sp)
    ),
  )
}

///|
test "disassemble_c_srli" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8001U)
  let result = disassemble(inst)
  inspect(result, content="c.srli s0, 0")
}

///|
test "disassemble_c_srai" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8401U)
  let result = disassemble(inst)
  inspect(result, content="c.srai s0, 0")
}

///|
test "disassemble_c_andi" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8801U)
  let result = disassemble(inst)
  inspect(result, content="c.andi s0, 0")
}

///|
test "disassemble_c_sub" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8C01U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.sub s0, s0
    ),
  )
}

///|
test "disassemble_c_xor" {
  // C.XOR x8, x8 (s0, s0) - 0x8C21
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x8C21U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.xor s0, s0
    ),
  )
}

///|
test "disassemble_c_slli" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x0502U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.slli a0, 0
    ),
  )
}

///|
test "disassemble_c_addi4spn" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x0008U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|.invalid 0x8
    ),
  )
}

///|
test "disassemble_c_addi16sp" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x6101U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|.invalid 0x6101
    ),
  )
}

///|
test "disassemble_c_lui" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x6505U)
  let result = disassemble(inst)
  inspect(
    result,
    content=(
      #|c.lui a0, 0x1
    ),
  )
}

///|
test "disassemble_compressed_with_addr" {
  let @decode.DecodeResult(inst) = @decode.decode_compressed(0x0505U)
  let result = disassemble_with_addr(inst, 0x1000U)
  inspect(
    result,
    content=(
      #|0x1000: c.addi a0, 1
    ),
  )
}

///|
test "disassemble_invalid" {
  let @decode.DecodeResult(inst) = @decode.decode(0xFFFFFFFFU)
  let result = disassemble(inst)
  inspect(result, content=".invalid 0xffffffff")
}
