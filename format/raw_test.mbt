///| Tests for raw binary format support

///|
test "parse_raw_binary" {
  let bytes = FixedArray::make(4, b'\x00')
  let binary = parse_raw_binary(bytes, 0x8000U)
  inspect(binary.base_addr, content="32768")
  inspect(binary.code.length(), content="4")
}

///|
test "detect_elf_format" {
  // ELF magic: 0x7F 'E' 'L' 'F'
  let bytes = FixedArray::make(16, b'\x00')
  bytes[0] = b'\x7F'
  bytes[1] = b'E'
  bytes[2] = b'L'
  bytes[3] = b'F'

  inspect(detect_format(bytes), content="ELF")
}

///|
test "detect_ihex_format" {
  let bytes = FixedArray::make(16, b'\x00')
  bytes[0] = b'\x3A' // ':' is 0x3A for Intel HEX

  inspect(detect_format(bytes), content="IHex")
}

///|
test "detect_raw_binary" {
  let bytes = FixedArray::make(4, b'\x13') // ADDI instruction pattern
  inspect(detect_format(bytes), content="RawBinary")
}

///|
test "parse_ihex_line_data" {
  // :0400000001020304F2 (Data: 01 02 03 04 at address 0x0000)
  let line = ":0400000001020304F2"
  let result = parse_ihex_line(line)

  match result {
    Some(record) => {
      inspect(record.record_type, content="Data")
      inspect(record.address, content="0")
      inspect(record.data.length(), content="4")
    }
    None => inspect("failed", content="Some(_)")
  }
}

///|
test "parse_ihex_line_eof" {
  // :00000001FF (End of file)
  let line = ":00000001FF"
  let result = parse_ihex_line(line)

  match result {
    Some(record) => inspect(record.record_type, content="EndOfFile")
    None => inspect("failed", content="Some(_)")
  }
}

///|
test "is_ihex_format" {
  let hex_content = ":020000040000FA"
  inspect(is_ihex_format(hex_content), content="true")

  let other_content = "some random text"
  inspect(is_ihex_format(other_content), content="false")
}
