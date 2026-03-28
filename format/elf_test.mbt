///|
/// Tests for ELF parser

///|
/// Create a minimal valid ELF32 header bytes
fn make_minimal_elf32_header() -> FixedArray[Byte] {
  // ELF32 header is 52 bytes
  let bytes : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  // ELF magic
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'
  // Class: 32-bit
  bytes[4] = b'\x01'
  // Data: Little endian
  bytes[5] = b'\x01'
  // Version
  bytes[6] = b'\x01'
  // Type: ET_EXEC (2)
  bytes[16] = b'\x02'
  bytes[17] = b'\x00'
  // Machine: EM_RISCV (243 = 0xF3)
  bytes[18] = b'\xF3'
  bytes[19] = b'\x00'
  // Entry point: 0x1000 (little endian)
  bytes[24] = b'\x00'
  bytes[25] = b'\x10'
  bytes[26] = b'\x00'
  bytes[27] = b'\x00'
  bytes
}

///|
/// Create a minimal valid ELF64 header bytes
fn make_minimal_elf64_header() -> FixedArray[Byte] {
  // ELF64 header is 64 bytes
  let bytes : FixedArray[Byte] = FixedArray::make(72, b'\x00')
  // ELF magic
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'
  // Class: 64-bit
  bytes[4] = b'\x02'
  // Data: Little endian
  bytes[5] = b'\x01'
  // Version
  bytes[6] = b'\x01'
  // Type: ET_EXEC (2)
  bytes[16] = b'\x02'
  bytes[17] = b'\x00'
  // Machine: EM_RISCV (243 = 0xF3)
  bytes[18] = b'\xF3'
  bytes[19] = b'\x00'
  // Entry point: 0x10000 (little endian, 64-bit)
  bytes[24] = b'\x00'
  bytes[25] = b'\x00'
  bytes[26] = b'\x01'
  bytes[27] = b'\x00'
  bytes
}

///|
test "is_elf_valid" {
  let bytes = make_minimal_elf32_header()
  assert_true(is_elf(bytes))
}

///|
test "is_elf_invalid" {
  let bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  assert_false(is_elf(bytes))
}

///|
test "is_elf_too_short" {
  let bytes : FixedArray[Byte] = FixedArray::make(10, b'\x00')
  assert_false(is_elf(bytes))
}

///|
test "get_elf_class_32bit" {
  let bytes = make_minimal_elf32_header()
  let elf_class = get_elf_class(bytes)
  inspect(elf_class, content="Elf32")
}

///|
test "get_elf_class_64bit" {
  let bytes = make_minimal_elf64_header()
  let elf_class = get_elf_class(bytes)
  inspect(elf_class, content="Elf64")
}

///|
test "parse_elf32_header" {
  let bytes = make_minimal_elf32_header()
  match parse_elf(bytes) {
    Some(elf) => {
      assert_false(elf.is_64bit)
      let entry = elf.entry_point()
      inspect(entry, content="4096") // 0x1000
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
test "parse_elf64_header" {
  let bytes = make_minimal_elf64_header()
  match parse_elf(bytes) {
    Some(elf) => {
      assert_true(elf.is_64bit)
      let entry = elf.entry_point()
      inspect(entry, content="65536") // 0x10000
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
test "is_riscv_elf" {
  let bytes = make_minimal_elf32_header()
  match parse_elf(bytes) {
    Some(elf) => assert_true(elf.is_riscv())
    None => inspect("failed", content="should_not_fail")
  }
}

///|
test "symbol_type_from_info" {
  inspect(Symbol::type_from_info(b'\x00'), content="NoType")
  inspect(Symbol::type_from_info(b'\x01'), content="Object")
  inspect(Symbol::type_from_info(b'\x02'), content="Func")
  inspect(Symbol::type_from_info(b'\x03'), content="Section")
  inspect(Symbol::type_from_info(b'\x04'), content="File")
  inspect(Symbol::type_from_info(b'\x12'), content="Func") // STT_FUNC with binding
}

///|
test "symbol_binding_from_info" {
  inspect(Symbol::binding_from_info(b'\x00'), content="Local")
  inspect(Symbol::binding_from_info(b'\x10'), content="Global")
  inspect(Symbol::binding_from_info(b'\x20'), content="Weak")
}

///|
/// Test ELF with program headers (code sections)
test "parse_elf_with_code_section" {
  // Create ELF32 with a program header for executable segment
  let bytes : FixedArray[Byte] = FixedArray::make(128, b'\x00')
  // ELF header
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'
  bytes[4] = b'\x01' // 32-bit
  bytes[5] = b'\x01' // Little endian
  bytes[6] = b'\x01' // Version
  // e_type = ET_EXEC (2)
  bytes[16] = 0x02U.to_byte()
  bytes[17] = 0x00U.to_byte()
  // e_machine = EM_RISCV (243 = 0xF3)
  bytes[18] = 0xF3U.to_byte()
  bytes[19] = 0x00U.to_byte()
  // e_version = 1
  bytes[20] = 0x01U.to_byte()
  bytes[21] = 0x00U.to_byte()
  bytes[22] = 0x00U.to_byte()
  bytes[23] = 0x00U.to_byte()
  // e_entry = 0x1000
  bytes[24] = 0x00U.to_byte()
  bytes[25] = 0x10U.to_byte()
  bytes[26] = 0x00U.to_byte()
  bytes[27] = 0x00U.to_byte()
  // e_phoff = 52 (program header offset, right after ELF header)
  bytes[28] = 0x34U.to_byte()
  bytes[29] = 0x00U.to_byte()
  bytes[30] = 0x00U.to_byte()
  bytes[31] = 0x00U.to_byte()
  // e_shoff = 0 (no section headers for now)
  // e_flags = 0
  // e_ehsize = 52
  bytes[40] = 0x34U.to_byte()
  bytes[41] = 0x00U.to_byte()
  // e_phentsize = 32
  bytes[42] = 0x20U.to_byte()
  bytes[43] = 0x00U.to_byte()
  // e_phnum = 1
  bytes[44] = 0x01U.to_byte()
  bytes[45] = 0x00U.to_byte()

  // Program header at offset 52 (PT_LOAD, executable)
  // p_type = PT_LOAD (1)
  bytes[52] = 0x01U.to_byte()
  bytes[53] = 0x00U.to_byte()
  bytes[54] = 0x00U.to_byte()
  bytes[55] = 0x00U.to_byte()
  // p_offset = 0x1000 (where code starts in file)
  bytes[56] = 0x00U.to_byte()
  bytes[57] = 0x10U.to_byte()
  bytes[58] = 0x00U.to_byte()
  bytes[59] = 0x00U.to_byte()
  // p_vaddr = 0x1000 (virtual address)
  bytes[60] = 0x00U.to_byte()
  bytes[61] = 0x10U.to_byte()
  bytes[62] = 0x00U.to_byte()
  bytes[63] = 0x00U.to_byte()
  // p_paddr = 0x1000 (physical address)
  bytes[64] = 0x00U.to_byte()
  bytes[65] = 0x10U.to_byte()
  bytes[66] = 0x00U.to_byte()
  bytes[67] = 0x00U.to_byte()
  // p_filesz = 4 (4 bytes of code)
  bytes[68] = 0x04U.to_byte()
  bytes[69] = 0x00U.to_byte()
  bytes[70] = 0x00U.to_byte()
  bytes[71] = 0x00U.to_byte()
  // p_memsz = 4
  bytes[72] = 0x04U.to_byte()
  bytes[73] = 0x00U.to_byte()
  bytes[74] = 0x00U.to_byte()
  bytes[75] = 0x00U.to_byte()
  // p_flags = PF_X (1) - executable
  bytes[76] = 0x01U.to_byte()
  bytes[77] = 0x00U.to_byte()
  bytes[78] = 0x00U.to_byte()
  bytes[79] = 0x00U.to_byte()
  // p_align = 0x1000
  bytes[80] = 0x00U.to_byte()
  bytes[81] = 0x10U.to_byte()
  bytes[82] = 0x00U.to_byte()
  bytes[83] = 0x00U.to_byte()

  // Code at offset 0x1000 (4096) - but our buffer is only 128 bytes
  // Let's adjust: put code right after program headers
  // Change p_offset to 84 (after program header)
  bytes[56] = 0x54U.to_byte() // 84
  bytes[57] = 0x00U.to_byte()
  bytes[58] = 0x00U.to_byte()
  bytes[59] = 0x00U.to_byte()

  // Code: NOP (ADDI x0, x0, 0) = 0x00000013
  bytes[84] = 0x13U.to_byte()
  bytes[85] = 0x00U.to_byte()
  bytes[86] = 0x00U.to_byte()
  bytes[87] = 0x00U.to_byte()

  match parse_elf(bytes) {
    Some(elf) => {
      assert_false(elf.is_64bit)
      assert_true(elf.is_riscv())
      inspect(elf.program_count(), content="1")

      // Get code sections
      let code_sections = elf.get_code_sections()
      inspect(code_sections.length(), content="1")

      // Check the code section
      let (vaddr, code) = code_sections[0]
      inspect(vaddr, content="4096")
      inspect(code.length(), content="4")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test ELF file with no code sections
test "parse_elf_no_code_sections" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let code_sections = elf.get_code_sections()
      inspect(code_sections.length(), content="0")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test non-RISC-V ELF
test "parse_elf_non_riscv" {
  let bytes : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  // ELF magic
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'
  bytes[4] = b'\x01' // 32-bit
  bytes[5] = b'\x01' // Little endian
  // e_type = ET_EXEC
  bytes[16] = 0x02U.to_byte()
  bytes[17] = 0x00U.to_byte()
  // e_machine = x86 (3) instead of RISC-V
  bytes[18] = 0x03U.to_byte()
  bytes[19] = 0x00U.to_byte()

  match parse_elf(bytes) {
    Some(elf) => assert_false(elf.is_riscv())
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test ELF64 entry point parsing
test "parse_elf64_entry_point" {
  let bytes = make_minimal_elf64_header()

  match parse_elf(bytes) {
    Some(elf) => {
      assert_true(elf.is_64bit)
      let entry = elf.entry_point()
      // Entry point should be 0x10000 (65536)
      inspect(entry, content="65536")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test invalid ELF (wrong magic)
test "parse_invalid_elf_magic" {
  let bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  // Wrong byte - should be 'F'
  bytes[3] = b'G'

  let result = parse_elf(bytes)
  inspect(result, content="None")
}

///|
/// Test ELF with unknown class
test "parse_elf_unknown_class" {
  let bytes : FixedArray[Byte] = FixedArray::make(16, b'\x00')
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'
  bytes[4] = b'\x03' // Unknown class (not 1 or 2)

  let result = parse_elf(bytes)
  inspect(result, content="None")
}

///|
/// Test section count with no sections
test "elf_section_count_empty" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => inspect(elf.section_count(), content="0")
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test get_section with invalid index
test "elf_get_section_invalid" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let section = elf.get_section(0)
      inspect(section, content="None")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test extract_bytes API
test "elf_extract_bytes" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      // Extract first 4 bytes
      match elf.extract_bytes(0U, 4U) {
        Some(data) => {
          inspect(data.length(), content="4")
          // Should be ELF magic
          inspect(
            data[0],
            content=(
              #|b'\x7F'
            ),
          ) // 0x7f
          inspect(
            data[1],
            content=(
              #|b'\x45'
            ),
          ) // 'E'
          inspect(
            data[2],
            content=(
              #|b'\x4C'
            ),
          ) // 'L'
          inspect(
            data[3],
            content=(
              #|b'\x46'
            ),
          ) // 'F'
        }
        None => inspect("failed", content="should_not_fail")
      }

      // Try to extract beyond file size
      let beyond = elf.extract_bytes(1000U, 4U)
      inspect(beyond, content="None")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test empty bytes handling
test "is_elf_empty" {
  let empty : FixedArray[Byte] = FixedArray::make(0, b'\x00')
  assert_false(is_elf(empty))
}

///|
/// Test short bytes handling
test "is_elf_too_short_for_class" {
  // is_elf requires at least 16 bytes, so 4 bytes should return false
  let short : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  short[0] = b'\x7f'
  short[1] = b'E'
  short[2] = b'L'
  short[3] = b'F'
  // Too short to be a valid ELF
  assert_false(is_elf(short))

  // But get_elf_class only needs 5 bytes
  let enough_for_class : FixedArray[Byte] = FixedArray::make(5, b'\x00')
  enough_for_class[0] = b'\x7f'
  enough_for_class[1] = b'E'
  enough_for_class[2] = b'L'
  enough_for_class[3] = b'F'
  enough_for_class[4] = b'\x00' // Invalid class
  inspect(get_elf_class(enough_for_class), content="Unknown")
}

///|
/// Test parse_elf with truncated header
test "parse_elf_truncated_header" {
  // Create bytes that are too short for ELF32 header (52 bytes)
  let short : FixedArray[Byte] = FixedArray::make(30, b'\x00')
  short[0] = b'\x7f'
  short[1] = b'E'
  short[2] = b'L'
  short[3] = b'F'
  short[4] = b'\x01' // 32-bit

  let result = parse_elf(short)
  inspect(result, content="None")
}

///|
/// Test parse_elf with corrupted program header offset
test "parse_elf_bad_phoff" {
  let bytes = make_minimal_elf32_header()
  // Set program header offset beyond file size
  bytes[28] = 0xFFU.to_byte()
  bytes[29] = 0xFFU.to_byte()
  bytes[30] = 0xFFU.to_byte()
  bytes[31] = 0xFFU.to_byte()
  // Set e_phnum to 1
  bytes[44] = 0x01U.to_byte()

  // Should still parse the header, but fail on program headers
  match parse_elf(bytes) {
    Some(elf) =>
      // Should have parsed the header
      assert_true(elf.is_riscv())
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test parse_elf with big endian (may or may not be supported)
test "parse_elf_big_endian" {
  let bytes : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  bytes[0] = b'\x7f'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'
  bytes[4] = b'\x01' // 32-bit
  bytes[5] = b'\x02' // Big endian

  // Big endian may be parsed, but values will be interpreted differently
  // The parser should handle it gracefully
  match parse_elf(bytes) {
    Some(elf) =>
      // Parser accepted it (values may be wrong due to endianness)
      assert_false(elf.is_64bit)
    None =>
      // Or it may be rejected - either is acceptable
      ignore(())
  }
}

///|
/// Test get_function_symbols with empty symbol table
test "elf_get_function_symbols_empty" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let funcs = elf.get_function_symbols()
      inspect(funcs.length(), content="0")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test get_symbols with no symbol table
test "elf_get_symbols_empty" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let symbols = elf.get_symbols()
      inspect(symbols.length(), content="0")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test get_section_name with invalid index
test "elf_get_section_name_invalid" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let name = elf.get_section_name(0)
      inspect(name, content="")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test find_section_by_name when no sections exist
test "elf_find_section_by_name_empty" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let idx = elf.find_section_by_name(".text")
      inspect(idx, content="-1")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test get_rodata_section when no .rodata exists
test "elf_get_rodata_section_none" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let rodata = elf.get_rodata_section()
      inspect(rodata, content="None")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
/// Test extract_strings with no .rodata
test "elf_extract_strings_none" {
  let bytes = make_minimal_elf32_header()

  match parse_elf(bytes) {
    Some(elf) => {
      let strings = elf.extract_strings()
      inspect(strings.length(), content="0")
    }
    None => inspect("failed", content="should_not_fail")
  }
}

///|
test "write_elf32_executable" {
  // Create simple code: addi a0, x0, 42
  let code : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  code[0] = 0x13U.to_byte()
  code[1] = 0x05U.to_byte()
  code[2] = 0x20U.to_byte()
  code[3] = 0x02U.to_byte()

  let elf = write_elf32_executable(code, 0x10000U, 0x10000U)

  // Verify ELF magic
  assert_true(elf[0] == b'\x7f')
  assert_true(elf[1] == b'E')
  assert_true(elf[2] == b'L')
  assert_true(elf[3] == b'F')

  // Verify 32-bit
  assert_true(elf[4] == b'\x01')

  // Verify little endian
  assert_true(elf[5] == b'\x01')

  // Verify RISC-V machine
  assert_true(elf[18] == 0xF3U.to_byte())
}

///|
test "write_elf64_executable" {
  let code : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  code[0] = 0x13U.to_byte()
  code[1] = 0x05U.to_byte()
  code[2] = 0x20U.to_byte()
  code[3] = 0x02U.to_byte()

  let elf = write_elf64_executable(code, 0x10000U, 0x10000U)

  assert_true(elf[0] == b'\x7f')
  assert_true(elf[1] == b'E')
  assert_true(elf[2] == b'L')
  assert_true(elf[3] == b'F')
  assert_true(elf[4] == b'\x02')
  assert_true(elf[5] == b'\x01')
  assert_true(elf[18] == 0xF3U.to_byte())

  match parse_elf(elf) {
    Some(parsed) => {
      assert_true(parsed.is_64bit)
      assert_true(parsed.is_riscv())
      assert_eq(parsed.entry_point(), 0x10000U)
    }
    None => abort("expected parseable ELF64 output")
  }
}

///|
test "assemble_to_elf32" {
  let code : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  code[0] = 0x13U.to_byte()
  code[1] = 0x05U.to_byte()
  code[2] = 0x20U.to_byte()
  code[3] = 0x02U.to_byte()

  let elf = assemble_to_elf32(code, 0x10000U)

  assert_true(is_elf(elf))
  match parse_elf(elf) {
    Some(parsed) => assert_false(parsed.is_64bit)
    None => abort("expected parseable ELF32 output")
  }
}

///|
test "assemble_to_elf" {
  // Create simple code
  let code : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  code[0] = 0x13U.to_byte()
  code[1] = 0x05U.to_byte()
  code[2] = 0x20U.to_byte()
  code[3] = 0x02U.to_byte()

  let elf = assemble_to_elf(code, 0x10000U)

  // Should be parseable
  assert_true(is_elf(elf))
  match parse_elf(elf) {
    Some(parsed) => assert_true(parsed.is_64bit)
    None => abort("expected parseable ELF64 output")
  }
}
