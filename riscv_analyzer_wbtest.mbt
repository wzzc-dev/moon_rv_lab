// Whitebox tests run within the package scope.
// Use them to validate internal helpers or invariants.
// Keep them focused; public behavior belongs in `_test.mbt`.

///|
/// Test internal instruction category mapping
test "instruction_category_internal" {
  let DecodeResult(lui) = @decode.decode(0x123452B7U)
  inspect(lui.category(), content="Arithmetic")

  let DecodeResult(jal) = @decode.decode(0x100000EFU)
  inspect(jal.category(), content="Jump")

  let DecodeResult(beq) = @decode.decode(0x00208463U)
  inspect(beq.category(), content="Branch")

  let DecodeResult(lw) = @decode.decode(0x06432283U)
  inspect(lw.category(), content="Load")

  let DecodeResult(sw) = @decode.decode(0x00532423U)
  inspect(sw.category(), content="Store")

  let DecodeResult(ecall) = @decode.decode(0x00000073U)
  inspect(ecall.category(), content="System")
}

///|
/// Test compressed instruction category mapping
test "compressed_category_internal" {
  let DecodeResult(c_nop) = @decode.decode_compressed(0x0001U)
  inspect(c_nop.category(), content="Arithmetic")

  let DecodeResult(c_j) = @decode.decode_compressed(0xA001U)
  inspect(c_j.category(), content="Jump")

  let DecodeResult(c_beqz) = @decode.decode_compressed(0xC001U)
  inspect(c_beqz.category(), content="Branch")

  let DecodeResult(c_lw) = @decode.decode_compressed(0x4000U)
  inspect(c_lw.category(), content="Load")

  let DecodeResult(c_sw) = @decode.decode_compressed(0xC000U)
  inspect(c_sw.category(), content="Store")
}

///|
/// Test branch offset extraction
test "branch_offset_internal" {
  // BEQ with offset 8
  let DecodeResult(beq) = @decode.decode(0x00208463U)
  inspect(beq.branch_offset(), content="8")

  // JAL with offset 256
  let DecodeResult(jal) = @decode.decode(0x100000EFU)
  inspect(jal.branch_offset(), content="256")

  // ADD has no branch offset
  let DecodeResult(add) = @decode.decode(0x007302B3U)
  inspect(add.branch_offset(), content="0")
}

///|
/// Test is_branch and is_jump methods
test "is_branch_jump_internal" {
  let DecodeResult(beq) = @decode.decode(0x00208463U)
  assert_true(beq.is_branch())
  assert_false(beq.is_jump())

  let DecodeResult(jal) = @decode.decode(0x100000EFU)
  assert_false(jal.is_branch())
  assert_true(jal.is_jump())

  let DecodeResult(add) = @decode.decode(0x007302B3U)
  assert_false(add.is_branch())
  assert_false(add.is_jump())
}

///|
/// Test is_control_flow method
test "is_control_flow_internal" {
  let DecodeResult(beq) = @decode.decode(0x00208463U)
  assert_true(beq.is_control_flow())

  let DecodeResult(jal) = @decode.decode(0x100000EFU)
  assert_true(jal.is_control_flow())

  let DecodeResult(add) = @decode.decode(0x007302B3U)
  assert_false(add.is_control_flow())

  // Compressed instructions
  let DecodeResult(c_j) = @decode.decode_compressed(0xA001U)
  assert_true(c_j.is_control_flow())

  let DecodeResult(c_beqz) = @decode.decode_compressed(0xC001U)
  assert_true(c_beqz.is_control_flow())
}

///|
/// Test internal CFG analysis helpers
test "cfg_helpers_internal" {
  // Test empty bytes
  let empty_bytes : FixedArray[Byte] = FixedArray::make(0, b'\x00')
  let empty_cfg = @analysis.analyze_code(empty_bytes, 0U)
  inspect(empty_cfg.blocks.length(), content="0")

  // Test single instruction
  let addi_bytes : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  addi_bytes[0] = 0x93U.to_byte()
  addi_bytes[1] = 0x02U.to_byte()
  addi_bytes[2] = 0x40U.to_byte()
  addi_bytes[3] = 0x06U.to_byte()
  let single_cfg = @analysis.analyze_code(addi_bytes, 0U)
  inspect(single_cfg.blocks.length(), content="1")
  inspect(single_cfg.entry_points.length(), content="1")
  inspect(single_cfg.entry_points[0], content="0")
}

///|
/// Test ELF internal structures
test "elf_internal_parsing" {
  // Create minimal ELF32
  let elf32_bytes : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  elf32_bytes[0] = b'\x7f'
  elf32_bytes[1] = b'E'
  elf32_bytes[2] = b'L'
  elf32_bytes[3] = b'F'
  elf32_bytes[4] = b'\x01' // 32-bit
  elf32_bytes[5] = b'\x01' // Little endian
  elf32_bytes[16] = 0x02U.to_byte() // ET_EXEC
  elf32_bytes[17] = 0x00U.to_byte()
  elf32_bytes[18] = 0xF3U.to_byte() // EM_RISCV
  elf32_bytes[19] = 0x00U.to_byte()

  match @format.parse_elf(elf32_bytes) {
    Some(elf) => {
      assert_false(elf.is_64bit)
      assert_true(elf.is_riscv())
      inspect(elf.section_count(), content="0")
      inspect(elf.program_count(), content="0")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test instruction type variants
test "instruction_variants" {
  // Test all major instruction types are correctly decoded
  let DecodeResult(lui) = @decode.decode(0x123452B7U)
  assert_true(lui is LUI(_))

  let DecodeResult(auipc) = @decode.decode(0x00010517U)
  assert_true(auipc is AUIPC(_))

  let DecodeResult(add) = @decode.decode(0x007302B3U)
  assert_true(add is ADD(_))

  let DecodeResult(sub) = @decode.decode(0x407302B3U)
  assert_true(sub is SUB(_))

  let DecodeResult(addi) = @decode.decode(0x06430293U)
  assert_true(addi is ADDI(_))

  let DecodeResult(lw) = @decode.decode(0x06432283U)
  assert_true(lw is LW(_))

  let DecodeResult(sw) = @decode.decode(0x00532423U)
  assert_true(sw is SW(_))

  let DecodeResult(beq) = @decode.decode(0x00208463U)
  assert_true(beq is BEQ(_))

  let DecodeResult(jal) = @decode.decode(0x100000EFU)
  assert_true(jal is JAL(_))

  let DecodeResult(jalr) = @decode.decode(0x008100E7U)
  assert_true(jalr is JALR(_))

  let DecodeResult(ecall) = @decode.decode(0x00000073U)
  assert_true(ecall is ECALL)

  let DecodeResult(ebreak) = @decode.decode(0x00100073U)
  assert_true(ebreak is EBREAK)
}

///|
/// Test RV32M extension instructions
/// Encoding: funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
/// opcode = 0x33 (0110011), funct7 = 0x01 (0000001) for RV32M
/// MUL:   funct3=000, MULH:  funct3=001, MULHSU: funct3=010, MULHU: funct3=011
/// DIV:   funct3=100, DIVU:  funct3=101, REM:    funct3=110, REMU:  funct3=111
test "rv32m_instructions" {
  // MUL x5, x6, x7:  funct7=0x01, rs2=7, rs1=6, funct3=0, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 000 00101 0110011 = 0x027302B3
  let DecodeResult(mul) = @decode.decode(0x027302B3U)
  assert_true(mul is MUL(_))

  // MULH x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=1, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 001 00101 0110011 = 0x027312B3
  let DecodeResult(mulh) = @decode.decode(0x027312B3U)
  assert_true(mulh is MULH(_))

  // MULHSU x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=2, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 010 00101 0110011 = 0x027322B3
  let DecodeResult(mulhsu) = @decode.decode(0x027322B3U)
  assert_true(mulhsu is MULHSU(_))

  // MULHU x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=3, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 011 00101 0110011 = 0x027332B3
  let DecodeResult(mulhu) = @decode.decode(0x027332B3U)
  assert_true(mulhu is MULHU(_))

  // DIV x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=4, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 100 00101 0110011 = 0x027342B3
  let DecodeResult(div) = @decode.decode(0x027342B3U)
  assert_true(div is DIV(_))

  // DIVU x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=5, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 101 00101 0110011 = 0x027352B3
  let DecodeResult(divu) = @decode.decode(0x027352B3U)
  assert_true(divu is DIVU(_))

  // REM x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=6, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 110 00101 0110011 = 0x027362B3
  let DecodeResult(rem) = @decode.decode(0x027362B3U)
  assert_true(rem is REM(_))

  // REMU x5, x6, x7: funct7=0x01, rs2=7, rs1=6, funct3=7, rd=5, opcode=0x33
  // Binary: 0000001 00111 00110 111 00101 0110011 = 0x027372B3
  let DecodeResult(remu) = @decode.decode(0x027372B3U)
  assert_true(remu is REMU(_))
}

///|
/// Test edge cases in decoding
test "decode_edge_cases" {
  // Test negative immediate values
  let DecodeResult(addi_neg) = @decode.decode(0xFFF00293U)
  match addi_neg {
    ADDI(_, _, imm) => inspect(imm, content="-1")
    _ => inspect("wrong", content="ADDI")
  }

  // Test zero register
  let DecodeResult(addi_zero) = @decode.decode(0x00000093U)
  match addi_zero {
    ADDI(rd, rs1, _) => {
      inspect(rd, content="1")
      inspect(rs1, content="0")
    }
    _ => inspect("wrong", content="ADDI")
  }

  // Test all zeros (illegal instruction)
  let DecodeResult(illegal) = @decode.decode(0x00000000U)
  assert_true(illegal is Invalid(_))
}

///|
/// Test call graph building with empty data
test "call_graph_empty" {
  let empty_instructions : FixedArray[@analysis.DecodedInst] = []
  let empty_cfg = @analysis.CFG::new()
  let cg = @analysis.build_call_graph(empty_instructions, empty_cfg)
  inspect(cg.nodes.length(), content="0")
  inspect(cg.entry_point, content="0")
}

///|
/// Test reachable functions with empty call graph
test "reachable_functions_empty" {
  let empty_cg = @analysis.CallGraph::new()
  let reachable = @analysis.reachable_functions(empty_cg)
  inspect(
    reachable.length(),
    content=(
      #|1
    ),
  )
}
