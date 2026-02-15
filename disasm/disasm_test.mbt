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
