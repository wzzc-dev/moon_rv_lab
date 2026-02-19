// Blackbox tests run against the package's public API. Use `@riscv_analyzer` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
/// Test high-level decode API
test "decode_instruction" {
  let DecodeResult(inst) = @riscv_analyzer.decode(0x007302B3U)
  // Verify it's an ADD instruction
  assert_true(inst is ADD(_))
}

///|
/// Test high-level compressed decode API
test "decode_compressed_instruction" {
  let DecodeResult(inst) = @riscv_analyzer.decode_compressed(0x0505U)
  // Verify it's a C_ADDI instruction
  assert_true(inst is C_ADDI(_))
}

///|
/// Test is_compressed API
test "is_compressed_api" {
  assert_true(@riscv_analyzer.is_compressed(0x0001U))
  assert_false(@riscv_analyzer.is_compressed(0x00400013U))
}

///|
/// Test instruction_length API
test "instruction_length_api" {
  inspect(@riscv_analyzer.instruction_length(0x0001U), content="2")
  inspect(@riscv_analyzer.instruction_length(0x00400013U), content="4")
}

///|
/// Test reg_name API
test "reg_name_api" {
  inspect(@riscv_analyzer.reg_name(0U), content="zero")
  inspect(@riscv_analyzer.reg_name(1U), content="ra")
  inspect(@riscv_analyzer.reg_name(2U), content="sp")
  inspect(@riscv_analyzer.reg_name(10U), content="a0")
}

///|
/// Test disassemble API
test "disassemble_api" {
  let DecodeResult(inst) = @riscv_analyzer.decode(0x007302B3U)
  let result = @riscv_analyzer.disassemble(inst)
  inspect(result, content="add t0, t1, t2")
}

///|
/// Test disassemble_with_addr API
test "disassemble_with_addr_api" {
  let DecodeResult(inst) = @riscv_analyzer.decode(0x007302B3U)
  let result = @riscv_analyzer.disassemble_with_addr(inst, 0x1000U)
  inspect(result, content="0x1000: add t0, t1, t2")
}

///|
/// Test is_elf API
test "is_elf_api" {
  let elf_magic : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  elf_magic[0] = b'\x7f'
  elf_magic[1] = b'E'
  elf_magic[2] = b'L'
  elf_magic[3] = b'F'
  elf_magic[4] = b'\x01'
  assert_true(@riscv_analyzer.is_elf(elf_magic))

  let not_elf : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  assert_false(@riscv_analyzer.is_elf(not_elf))
}

///|
/// Test get_elf_class API
test "get_elf_class_api" {
  let elf32 : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  elf32[0] = b'\x7f'
  elf32[1] = b'E'
  elf32[2] = b'L'
  elf32[3] = b'F'
  elf32[4] = b'\x01'
  inspect(@riscv_analyzer.get_elf_class(elf32), content="Elf32")

  let elf64 : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  elf64[0] = b'\x7f'
  elf64[1] = b'E'
  elf64[2] = b'L'
  elf64[3] = b'F'
  elf64[4] = b'\x02'
  inspect(@riscv_analyzer.get_elf_class(elf64), content="Elf64")
}

///|
/// Test terminator detection API
test "is_terminator_api" {
  let DecodeResult(jal) = @riscv_analyzer.decode(0x100000EFU)
  assert_true(@riscv_analyzer.is_terminator(jal))

  let DecodeResult(add) = @riscv_analyzer.decode(0x007302B3U)
  assert_false(@riscv_analyzer.is_terminator(add))
}

///|
/// Test branch detection API
test "is_conditional_branch_api" {
  let DecodeResult(beq) = @riscv_analyzer.decode(0x00208463U)
  assert_true(@riscv_analyzer.is_conditional_branch(beq))

  let DecodeResult(jal) = @riscv_analyzer.decode(0x100000EFU)
  assert_false(@riscv_analyzer.is_conditional_branch(jal))
}

///|
/// Test unconditional jump detection API
test "is_unconditional_jump_api" {
  let DecodeResult(jal) = @riscv_analyzer.decode(0x100000EFU)
  assert_true(@riscv_analyzer.is_unconditional_jump(jal))

  let DecodeResult(beq) = @riscv_analyzer.decode(0x00208463U)
  assert_false(@riscv_analyzer.is_unconditional_jump(beq))
}

///|
/// Test call detection API
test "is_call_api" {
  // JAL ra, 256 (call)
  let DecodeResult(jal_ra) = @riscv_analyzer.decode(0x100000EFU)
  assert_true(@riscv_analyzer.is_call(jal_ra))

  // JAL x5, 256 (not call)
  let DecodeResult(jal_t0) = @riscv_analyzer.decode(0x100002EFU)
  // t0 is also considered a link register
  assert_true(@riscv_analyzer.is_call(jal_t0))
}

///|
/// Test return detection API
test "is_return_api" {
  // JALR x0, ra, 0 (ret)
  let DecodeResult(ret) = @riscv_analyzer.decode(0x00008067U)
  assert_true(@riscv_analyzer.is_return(ret))

  let DecodeResult(add) = @riscv_analyzer.decode(0x007302B3U)
  assert_false(@riscv_analyzer.is_return(add))
}

///|
/// Test get_branch_target API
test "get_branch_target_api" {
  let DecodeResult(beq) = @riscv_analyzer.decode(0x00208463U)
  inspect(@riscv_analyzer.get_branch_target(beq), content="8")

  let DecodeResult(add) = @riscv_analyzer.decode(0x007302B3U)
  inspect(@riscv_analyzer.get_branch_target(add), content="0")
}

///|
/// Test decode_instructions API
test "decode_instructions_api" {
  // ADDI x5, x0, 100 (0x06400293)
  let bytes : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  bytes[0] = 0x93U.to_byte()
  bytes[1] = 0x02U.to_byte()
  bytes[2] = 0x40U.to_byte()
  bytes[3] = 0x06U.to_byte()

  let instructions = @riscv_analyzer.decode_instructions(bytes, 0U)
  inspect(instructions.length(), content="1")
  inspect(instructions[0].addr, content="0")
  inspect(instructions[0].length, content="4")
}

///|
/// Test disassemble_bytes API
test "disassemble_bytes_api" {
  // ADDI x5, x0, 100 (0x06400293)
  let bytes : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  bytes[0] = 0x93U.to_byte()
  bytes[1] = 0x02U.to_byte()
  bytes[2] = 0x40U.to_byte()
  bytes[3] = 0x06U.to_byte()

  let result = @riscv_analyzer.disassemble_bytes(bytes, 0U)
  inspect(result, content="0x0: addi t0, zero, 100\n")
}

/// Test RISC-V Vector Extension - vle8.v instruction
test "decode_vle8_v" {
  // vle8.v v1, (x5)
  // opcode=0x07, f3=0b000, vm=0
  // vd=1, rs1=5, rs2=0, f7=0
  // code = 0 << 25 | 0 << 20 | 5 << 15 | 0 << 12 | 1 << 7 | 0x07 = 0x00028087
  let code = 0x00028087U
  let result = @riscv_analyzer.decode(code)
  match result {
    DecodeResult(inst) => {
      let s = @riscv_analyzer.disassemble(inst)
      println(s)
      assert_true(not(s.contains("invalid")))
    }
  }
}

/// Test vreg_name API
test "vreg_name_api" {
  inspect(@riscv_analyzer.vreg_name(0U), content="v0")
  inspect(@riscv_analyzer.vreg_name(1U), content="v1")
  inspect(@riscv_analyzer.vreg_name(10U), content="v10")
  inspect(@riscv_analyzer.vreg_name(31U), content="v31")
}
