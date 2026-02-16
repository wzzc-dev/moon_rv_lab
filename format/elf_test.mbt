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
