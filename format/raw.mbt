///| Raw binary format support

///| Supports parsing raw RISC-V binaries without ELF headers

///|
/// Raw binary file representation
pub struct RawBinary {
  code : FixedArray[Byte]
  base_addr : UInt // Base address for disassembly
} derive(Show)

///|
/// Parse raw binary data with optional base address
pub fn parse_raw_binary(
  bytes : FixedArray[Byte],
  base_addr : UInt,
) -> RawBinary {
  { code: bytes, base_addr }
}

///|
/// Detect file format from magic bytes
pub enum BinaryFormat {
  ELF
  IHex
  RawBinary
  Unknown
} derive(Show, Eq)

///|
/// Detect binary format from content
pub fn detect_format(bytes : FixedArray[Byte]) -> BinaryFormat {
  // Check for ELF magic: 0x7F 'E' 'L' 'F'
  if bytes.length() >= 4 {
    if bytes[0] == b'\x7F' &&
      bytes[1] == b'E' &&
      bytes[2] == b'L' &&
      bytes[3] == b'F' {
      return BinaryFormat::ELF
    }
  }

  // Check for Intel HEX (starts with ':')
  if bytes.length() >= 1 && bytes[0] == b'\x3A' { // ':' is 0x3A
    return BinaryFormat::IHex
  }

  // Default to raw binary
  if bytes.length() > 0 {
    return BinaryFormat::RawBinary
  }

  BinaryFormat::Unknown
}

///|
/// Intel HEX record types
pub enum IHexRecordType {
  Data // 0x00: Data record
  EndOfFile // 0x01: End of file
  ExtendedSegAddr // 0x02: Extended segment address
  StartSegAddr // 0x03: Start segment address
  ExtendedLinAddr // 0x04: Extended linear address
  StartLinAddr // 0x05: Start linear address
  Invalid
} derive(Show, Eq)

///|
/// Intel HEX record (simplified)
pub struct IHexRecord {
  record_type : IHexRecordType
  address : UInt
  data : FixedArray[Byte]
} derive(Show)

///|
/// Parse a hex character to value
fn hex_char_to_val(c : Char) -> Int? {
  match c {
    '0' => Some(0)
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    '4' => Some(4)
    '5' => Some(5)
    '6' => Some(6)
    '7' => Some(7)
    '8' => Some(8)
    '9' => Some(9)
    'a' | 'A' => Some(10)
    'b' | 'B' => Some(11)
    'c' | 'C' => Some(12)
    'd' | 'D' => Some(13)
    'e' | 'E' => Some(14)
    'f' | 'F' => Some(15)
    _ => None
  }
}

///|
/// Parse two hex characters to a byte value (0-255)
fn hex_chars_to_byte_val(c1 : Char, c2 : Char) -> Int? {
  match (hex_char_to_val(c1), hex_char_to_val(c2)) {
    (Some(v1), Some(v2)) => Some((v1 << 4) | v2)
    _ => None
  }
}

///|
/// Parse a single Intel HEX record line
/// Returns None if the line is invalid
pub fn parse_ihex_line(line : String) -> IHexRecord? {
  let trimmed = line.trim()
  let len = trimmed.length()

  // Must start with ':' and have at least 11 chars
  if len < 11 || trimmed[0].unsafe_to_char() != ':' {
    return None
  }

  // Parse byte count
  let byte_count = match
    hex_chars_to_byte_val(
      trimmed[1].unsafe_to_char(),
      trimmed[2].unsafe_to_char(),
    ) {
    Some(v) => v
    None => return None
  }

  // Parse address
  let addr_hi = match
    hex_chars_to_byte_val(
      trimmed[3].unsafe_to_char(),
      trimmed[4].unsafe_to_char(),
    ) {
    Some(v) => v
    None => return None
  }
  let addr_lo = match
    hex_chars_to_byte_val(
      trimmed[5].unsafe_to_char(),
      trimmed[6].unsafe_to_char(),
    ) {
    Some(v) => v
    None => return None
  }
  let address = ((addr_hi << 8) | addr_lo).reinterpret_as_uint()

  // Parse record type
  let record_type_val = match
    hex_chars_to_byte_val(
      trimmed[7].unsafe_to_char(),
      trimmed[8].unsafe_to_char(),
    ) {
    Some(v) => v
    None => return None
  }
  let record_type = match record_type_val {
    0 => IHexRecordType::Data
    1 => IHexRecordType::EndOfFile
    2 => IHexRecordType::ExtendedSegAddr
    3 => IHexRecordType::StartSegAddr
    4 => IHexRecordType::ExtendedLinAddr
    5 => IHexRecordType::StartLinAddr
    _ => IHexRecordType::Invalid
  }

  // Parse data bytes
  let expected_len = 9 + byte_count * 2 + 2
  if len < expected_len {
    return None
  }

  let data_bytes : Array[Byte] = []
  let mut i = 0
  while i < byte_count {
    let data_pos = 9 + i * 2
    let byte_val = match
      hex_chars_to_byte_val(
        trimmed[data_pos].unsafe_to_char(),
        trimmed[data_pos + 1].unsafe_to_char(),
      ) {
      Some(v) => v.reinterpret_as_uint().to_byte()
      None => return None
    }
    data_bytes.push(byte_val)
    i = i + 1
  }

  Some({ record_type, address, data: FixedArray::from_array(data_bytes) })
}

///|
/// Check if a string looks like Intel HEX format
pub fn is_ihex_format(content : String) -> Bool {
  let trimmed = content.trim()
  trimmed.length() > 0 && trimmed[0].unsafe_to_char() == ':'
}
