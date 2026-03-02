///| DWARF debug information parser

///| Parses DWARF debug sections from ELF files

///|
/// DWARF abbreviation table entry
pub struct AbbrevEntry {
  /// Abbreviation code
  code : UInt
  /// Tag (type of DIE)
  tag : DWTag
  /// Has children
  has_children : Bool
  /// Attribute specifications
  attrs : Array[AttrSpec]
} derive(Show)

///|
/// Attribute specification
pub struct AttrSpec {
  /// Attribute name
  name : DWAttr
  /// Attribute form
  form : DWForm
  /// Implicit constant value (for DWARF 5)
  implicit_const : Int
} derive(Show)

///|
/// Debugging Information Entry (DIE)
pub struct DIE {
  /// Offset in .debug_info
  offset : UInt
  /// Abbreviation code
  abbrev_code : UInt
  /// Tag
  tag : DWTag
  /// Has children
  has_children : Bool
  /// Attributes
  attrs : Map[DWAttr, AttrValue]
  /// Children DIEs
  children : Array[DIE]
} derive(Show)

///|
/// Attribute value
pub enum AttrValue {
  Addr(UInt)
  Data(FixedArray[Byte])
  String(String)
  Ref(UInt)
  UData(UInt)
  SData(Int)
  Flag(Bool)
  Block(FixedArray[Byte])
  SecOffset(UInt)
  ExprLoc(FixedArray[Byte])
  Unknown
} derive(Show)

///|
/// Line number program header
pub struct LineNumberProgramHeader {
  /// Unit length
  unit_length : UInt
  /// DWARF version
  version : Int
  /// Header length
  header_length : UInt
  /// Minimum instruction length
  min_inst_length : Int
  /// Maximum operations per instruction (DWARF 4+)
  max_ops_per_inst : Int
  /// Default is_stmt
  default_is_stmt : Bool
  /// Line base
  line_base : Int
  /// Line range
  line_range : Int
  /// Opcode base
  opcode_base : Int
  /// Standard opcode lengths
  std_opcode_lengths : FixedArray[Int]
  /// Include directories
  include_dirs : Array[String]
  /// File names
  file_names : Array[FileInfo]
} derive(Show)

///|
/// File information
pub struct FileInfo {
  /// File name
  name : String
  /// Directory index
  dir_index : Int
  /// Modification time
  mod_time : UInt
  /// File size
  file_size : UInt
} derive(Show)

///|
/// Line number entry
pub struct LineEntry {
  /// Address
  address : UInt
  /// File index
  file : Int
  /// Line number
  line : Int
  /// Column
  column : Int
  /// Is statement
  is_stmt : Bool
  /// Is basic block start
  basic_block : Bool
  /// End of sequence
  end_sequence : Bool
  /// Prologue end
  prologue_end : Bool
  /// Epilogue begin
  epilogue_begin : Bool
  /// ISA
  isa : Int
  /// Discriminator
  discriminator : Int
} derive(Show)

///|
/// DWARF compilation unit
pub struct CompilationUnit {
  /// Unit length
  unit_length : UInt
  /// DWARF version
  version : Int
  /// Abbreviation offset
  abbrev_offset : UInt
  /// Address size
  addr_size : Int
  /// Root DIE
  root : DIE?
} derive(Show)

///|
/// DWARF debug information
pub struct DWARFInfo {
  /// Compilation units
  units : Array[CompilationUnit]
  /// Line number info
  line_info : Array[LineNumberProgram]
  /// Address to line mapping
  addr_to_line : Map[UInt, LineEntry]
} derive(Show)

///|
/// Line number program
pub struct LineNumberProgram {
  /// Header
  header : LineNumberProgramHeader
  /// Line entries
  entries : Array[LineEntry]
} derive(Show)

///|
/// DWARF parser state
pub struct DWARFParser {
  /// Raw data
  data : FixedArray[Byte]
  /// Current position
  pos : Int
  /// Address size (4 or 8)
  addr_size : Int
  /// DWARF version
  version : Int
} derive(Show)

///|
/// Create a new DWARF parser
pub fn DWARFParser::new(data : FixedArray[Byte]) -> DWARFParser {
  { data, pos: 0, addr_size: 4, version: 4 }
}

///|
/// Read a byte
pub fn read_u8(parser : DWARFParser) -> (DWARFParser, Byte)? {
  if parser.pos >= parser.data.length() {
    return None
  }
  let byte = parser.data[parser.pos]
  let new_parser = {
    data: parser.data,
    pos: parser.pos + 1,
    addr_size: parser.addr_size,
    version: parser.version,
  }
  Some((new_parser, byte))
}

///|
/// Read a 16-bit value (little endian)
pub fn read_u16(parser : DWARFParser) -> (DWARFParser, UInt)? {
  if parser.pos + 1 >= parser.data.length() {
    return None
  }
  let lo = parser.data[parser.pos].to_int()
  let hi = parser.data[parser.pos + 1].to_int()
  let value = ((hi << 8) | lo).reinterpret_as_uint()
  let new_parser = {
    data: parser.data,
    pos: parser.pos + 2,
    addr_size: parser.addr_size,
    version: parser.version,
  }
  Some((new_parser, value))
}

///|
/// Read a 32-bit value (little endian)
pub fn read_u32(parser : DWARFParser) -> (DWARFParser, UInt)? {
  if parser.pos + 3 >= parser.data.length() {
    return None
  }
  let b0 = parser.data[parser.pos].to_int()
  let b1 = parser.data[parser.pos + 1].to_int()
  let b2 = parser.data[parser.pos + 2].to_int()
  let b3 = parser.data[parser.pos + 3].to_int()
  let value = ((b3 << 24) | (b2 << 16) | (b1 << 8) | b0).reinterpret_as_uint()
  let new_parser = {
    data: parser.data,
    pos: parser.pos + 4,
    addr_size: parser.addr_size,
    version: parser.version,
  }
  Some((new_parser, value))
}

///|
/// Read a 64-bit value (little endian)
pub fn read_u64(parser : DWARFParser) -> (DWARFParser, UInt)? {
  if parser.pos + 7 >= parser.data.length() {
    return None
  }
  let mut value : UInt = 0U
  for i = 0; i < 8; i = i + 1 {
    let b = parser.data[parser.pos + i].to_int()
    value = value | (b.reinterpret_as_uint() << (i * 8))
  }
  let new_parser = {
    data: parser.data,
    pos: parser.pos + 8,
    addr_size: parser.addr_size,
    version: parser.version,
  }
  Some((new_parser, value))
}

///|
/// Read an address (size depends on addr_size)
pub fn read_addr(parser : DWARFParser) -> (DWARFParser, UInt)? {
  if parser.addr_size == 8 {
    read_u64(parser)
  } else {
    read_u32(parser)
  }
}

///|
/// Read an unsigned LEB128 value
pub fn read_uleb128(parser : DWARFParser) -> (DWARFParser, UInt)? {
  let mut result : UInt = 0U
  let mut shift = 0
  let mut p = parser
  let mut done = false

  while !done {
    match read_u8(p) {
      Some((new_p, byte)) => {
        p = new_p
        let b = byte.to_int()
        result = result | ((b & 0x7F).reinterpret_as_uint() << shift)
        if (b & 0x80) == 0 {
          done = true
        } else {
          shift = shift + 7
          if shift > 63 {
            return None // Overflow
          }
        }
      }
      None => return None
    }
  }
  Some((p, result))
}

///|
/// Read a signed LEB128 value
pub fn read_sleb128(parser : DWARFParser) -> (DWARFParser, Int)? {
  let mut result : Int = 0
  let mut shift = 0
  let mut p = parser
  let mut last_byte = 0
  let mut done = false

  while !done {
    match read_u8(p) {
      Some((new_p, byte)) => {
        p = new_p
        last_byte = byte.to_int()
        result = result | ((last_byte & 0x7F) << shift)
        if (last_byte & 0x80) == 0 {
          done = true
        } else {
          shift = shift + 7
          if shift > 63 {
            return None // Overflow
          }
        }
      }
      None => return None
    }
  }

  // Sign extend if negative
  if (last_byte & 0x40) != 0 && shift < 63 {
    result = result | -(1 << (shift + 7))
  }
  Some((p, result))
}

///|
/// Read a null-terminated string from parser
pub fn read_string_from_parser(parser : DWARFParser) -> (DWARFParser, String)? {
  let chars : Array[Char] = []
  let mut p = parser
  let mut done = false

  while !done {
    match read_u8(p) {
      Some((new_p, byte)) => {
        p = new_p
        if byte == b'\x00' {
          done = true
        } else {
          chars.push(byte.to_int().unsafe_to_char())
        }
      }
      None => return None
    }
  }

  let mut result = ""
  for c in chars {
    result = result + c.to_string()
  }
  Some((p, result))
}

///|
/// Read a string from .debug_str at given offset
pub fn read_debug_string(
  str_section : FixedArray[Byte],
  offset : UInt,
) -> String {
  let off = offset.reinterpret_as_int()
  if off >= str_section.length() {
    return ""
  }

  let mut result = ""
  let mut i = off
  while i < str_section.length() {
    let b = str_section[i]
    if b == b'\x00' {
      break
    }
    result = result + b.to_int().unsafe_to_char().to_string()
    i = i + 1
  }
  result
}

///|
/// Parse compilation unit header
pub fn parse_compilation_unit(data : FixedArray[Byte]) -> CompilationUnit? {
  let parser = DWARFParser::new(data)
  let (p1, unit_length) = match read_u32(parser) {
    Some((p, v)) => (p, v)
    None => return None
  }

  // Check for 64-bit DWARF format
  let (is_64bit, actual_length, p2) = if unit_length == 0xFFFFFFFFU {
    match read_u64(p1) {
      Some((p, len)) => (true, len, p)
      None => return None
    }
  } else {
    (false, unit_length, p1) // Use p1, not parser
  }

  let (p3, version) = match read_u16(p2) {
    Some((p, v)) => (p, v)
    None => return None
  }

  // Read abbrev_offset (32-bit or 64-bit)
  let (p4, abbrev_offset) = if is_64bit || version.reinterpret_as_int() >= 5 {
    match read_u64(p3) {
      Some((p, off)) => (p, off)
      None => return None
    }
  } else {
    match read_u32(p3) {
      Some((p, off)) => (p, off)
      None => return None
    }
  }

  let (p5, addr_size_byte) = match read_u8(p4) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let addr_size = addr_size_byte.to_int()

  Some({
    unit_length: actual_length,
    version: version.reinterpret_as_int(),
    abbrev_offset,
    addr_size,
    root: None,
  })
}

///|
/// Parse line number program header
pub fn parse_line_program_header(
  data : FixedArray[Byte],
) -> LineNumberProgramHeader? {
  let parser = DWARFParser::new(data)
  let (p1, unit_length) = match read_u32(parser) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let (p2, version) = match read_u16(p1) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let (p3, header_length) = match read_u32(p2) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let (p4, min_inst_length_byte) = match read_u8(p3) {
    Some((p, v)) => (p, v)
    None => return None
  }

  let (p5, max_ops_byte) = if version.reinterpret_as_int() >= 4 {
    match read_u8(p4) {
      Some((p, b)) => (p, b)
      None => return None
    }
  } else {
    (p4, b'\x01')
  }

  let (p6, default_is_stmt_byte) = match read_u8(p5) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let (p7, line_base_byte) = match read_u8(p6) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let (p8, line_range_byte) = match read_u8(p7) {
    Some((p, v)) => (p, v)
    None => return None
  }
  let (p9, opcode_base_byte) = match read_u8(p8) {
    Some((p, v)) => (p, v)
    None => return None
  }

  let opcode_base = opcode_base_byte.to_int()
  let version_int = version.reinterpret_as_int()

  // Read standard opcode lengths
  let std_opcode_lengths : FixedArray[Int] = FixedArray::make(
    opcode_base - 1,
    0,
  )
  let mut p = p9
  for i = 0; i < opcode_base - 1; i = i + 1 {
    match read_u8(p) {
      Some((new_p, len_byte)) => {
        p = new_p
        std_opcode_lengths[i] = len_byte.to_int()
      }
      None => break
    }
  }

  // Read include directories (DWARF 4 and earlier)
  let include_dirs : Array[String] = []
  if version_int < 5 {
    let mut done_dirs = false
    while !done_dirs {
      match read_string_from_parser(p) {
        Some((new_p, dir)) => {
          p = new_p
          if dir == "" {
            done_dirs = true
          } else {
            include_dirs.push(dir)
          }
        }
        None => done_dirs = true
      }
    }
  }

  // Read file names (DWARF 4 and earlier)
  let file_names : Array[FileInfo] = []
  if version_int < 5 {
    let mut done_files = false
    while !done_files {
      match read_string_from_parser(p) {
        Some((new_p, name)) => {
          p = new_p
          if name == "" {
            done_files = true
          } else {
            // Read dir_index, mod_time, file_size as ULEB128
            match read_uleb128(p) {
              Some((p2, dir_idx)) =>
                match read_uleb128(p2) {
                  Some((p3, mod_time)) =>
                    match read_uleb128(p3) {
                      Some((p4, file_size)) => {
                        p = p4
                        file_names.push({
                          name,
                          dir_index: dir_idx.reinterpret_as_int(),
                          mod_time,
                          file_size,
                        })
                      }
                      None => done_files = true
                    }
                  None => done_files = true
                }
              None => done_files = true
            }
          }
        }
        None => done_files = true
      }
    }
  }

  Some({
    unit_length,
    version: version_int,
    header_length,
    min_inst_length: min_inst_length_byte.to_int(),
    max_ops_per_inst: max_ops_byte.to_int(),
    default_is_stmt: default_is_stmt_byte != b'\x00',
    line_base: line_base_byte.to_int() - 128, // Signed
    line_range: line_range_byte.to_int(),
    opcode_base,
    std_opcode_lengths,
    include_dirs,
    file_names,
  })
}

///|
/// Lookup source line for address
pub fn lookup_line(entries : Array[LineEntry], address : UInt) -> LineEntry? {
  let mut best : LineEntry? = None
  for entry in entries {
    if entry.address <= address {
      best = Some(entry)
    } else {
      break
    }
  }
  best
}

///|
/// Get source location string
pub fn format_source_location(
  entry : LineEntry,
  files : Array[FileInfo],
) -> String {
  let file_name = if entry.file > 0 && entry.file <= files.length() {
    files[entry.file - 1].name
  } else {
    "unknown"
  }
  "\{file_name}:\{entry.line}"
}

// Placeholder functions to suppress unused warnings

///|
fn _dw_tag_placeholder() -> DWTag {
  let _ = DWTag::CompileUnit
  let _ = DWTag::Subprogram
  let _ = DWTag::FormalParameter
  let _ = DWTag::Variable
  let _ = DWTag::BaseType
  let _ = DWTag::PointerType
  let _ = DWTag::ConstType
  let _ = DWTag::Typedef
  let _ = DWTag::StructureType
  let _ = DWTag::Member
  let _ = DWTag::ArrayType
  let _ = DWTag::SubrangeType
  let _ = DWTag::EnumerationType
  let _ = DWTag::Enumerator
  let _ = DWTag::UnionType
  let _ = DWTag::Label
  let _ = DWTag::LexicalBlock
  let _ = DWTag::InlinedSubroutine
  DWTag::Unknown
}

///|
fn _dw_attr_placeholder() -> DWAttr {
  let _ = DWAttr::Name
  let _ = DWAttr::LowPc
  let _ = DWAttr::HighPc
  let _ = DWAttr::StmtList
  let _ = DWAttr::CompDir
  let _ = DWAttr::Language
  let _ = DWAttr::Producer
  let _ = DWAttr::Encoding
  let _ = DWAttr::ByteSize
  let _ = DWAttr::BitSize
  let _ = DWAttr::Type
  let _ = DWAttr::Location
  let _ = DWAttr::FrameBase
  let _ = DWAttr::DataMemberLocation
  let _ = DWAttr::External
  let _ = DWAttr::Declaration
  let _ = DWAttr::Inline
  DWAttr::Unknown
}

///|
fn _dw_form_placeholder() -> DWForm {
  let _ = DWForm::Addr
  let _ = DWForm::Block2
  let _ = DWForm::Block4
  let _ = DWForm::Data2
  let _ = DWForm::Data4
  let _ = DWForm::Data8
  let _ = DWForm::String
  let _ = DWForm::Block
  let _ = DWForm::Block1
  let _ = DWForm::Data1
  let _ = DWForm::Flag
  let _ = DWForm::SData
  let _ = DWForm::StrP
  let _ = DWForm::UData
  let _ = DWForm::RefAddr
  let _ = DWForm::Ref1
  let _ = DWForm::Ref2
  let _ = DWForm::Ref4
  let _ = DWForm::Ref8
  let _ = DWForm::RefUData
  let _ = DWForm::Indirect
  let _ = DWForm::SecOffset
  let _ = DWForm::ExprLoc
  let _ = DWForm::FlagPresent
  let _ = DWForm::RefSig8
  DWForm::Unknown
}

///|
fn _dw_ate_placeholder() -> DWATE {
  let _ = DWATE::Address
  let _ = DWATE::Boolean
  let _ = DWATE::ComplexFloat
  let _ = DWATE::Float
  let _ = DWATE::Signed
  let _ = DWATE::SignedChar
  let _ = DWATE::Unsigned
  let _ = DWATE::UnsignedChar
  DWATE::Unknown
}

///|
fn _dw_lang_placeholder() -> DWLANG {
  let _ = DWLANG::C
  let _ = DWLANG::C89
  let _ = DWLANG::CPlusPlus
  let _ = DWLANG::Rust
  let _ = DWLANG::Go
  let _ = DWLANG::Python
  DWLANG::Unknown
}

///|
fn _dw_lne_placeholder() -> DWLNE {
  let _ = DWLNE::EndSequence
  let _ = DWLNE::SetAddress
  let _ = DWLNE::DefineFile
  let _ = DWLNE::SetDiscriminator
  DWLNE::Unknown
}

///|
fn _dw_lns_placeholder() -> DWLNS {
  let _ = DWLNS::Copy
  let _ = DWLNS::AdvancePc
  let _ = DWLNS::AdvanceLine
  let _ = DWLNS::SetFile
  let _ = DWLNS::SetColumn
  let _ = DWLNS::NegateStmt
  let _ = DWLNS::SetBasicBlock
  let _ = DWLNS::ConstAddPc
  let _ = DWLNS::FixedAdvancePc
  let _ = DWLNS::SetPrologueEnd
  let _ = DWLNS::SetEpilogueBegin
  let _ = DWLNS::SetIsa
  DWLNS::Unknown
}

///|
fn _attr_value_placeholder() -> AttrValue {
  let _ = AttrValue::Addr(0U)
  let _ = AttrValue::Data(FixedArray::make(0, b'\x00'))
  let _ = AttrValue::String("")
  let _ = AttrValue::Ref(0U)
  let _ = AttrValue::UData(0U)
  let _ = AttrValue::SData(0)
  let _ = AttrValue::Flag(false)
  let _ = AttrValue::Block(FixedArray::make(0, b'\x00'))
  let _ = AttrValue::SecOffset(0U)
  let _ = AttrValue::ExprLoc(FixedArray::make(0, b'\x00'))
  AttrValue::Unknown
}

///|
/// Line number state machine state
pub struct LineNumberState {
  /// Current address
  address : UInt
  /// Current file index
  file : Int
  /// Current line number
  line : Int
  /// Current column
  column : Int
  /// Is statement
  is_stmt : Bool
  /// Is basic block start
  basic_block : Bool
  /// End of sequence
  end_sequence : Bool
  /// Prologue end
  prologue_end : Bool
  /// Epilogue begin
  epilogue_begin : Bool
  /// ISA
  isa : Int
  /// Discriminator
  discriminator : Int
} derive(Show)

///|
/// Create initial line number state
pub fn LineNumberState::init(
  header : LineNumberProgramHeader,
) -> LineNumberState {
  {
    address: 0U,
    file: 1,
    line: 1,
    column: 0,
    is_stmt: header.default_is_stmt,
    basic_block: false,
    end_sequence: false,
    prologue_end: false,
    epilogue_begin: false,
    isa: 0,
    discriminator: 0,
  }
}

///|
/// Execute line number program and generate line entries
pub fn execute_line_program(
  header : LineNumberProgramHeader,
  program_data : FixedArray[Byte],
) -> Array[LineEntry] {
  let entries : Array[LineEntry] = []
  let mut state = LineNumberState::init(header)
  let mut pos = header.header_length.reinterpret_as_int() +
    4 +
    (if header.version >= 4 { 1 } else { 0 }) +
    2 +
    4

  let mut running = true
  while running {
    if pos >= program_data.length() {
      running = false
    } else {
      let opcode = program_data[pos].to_int()
      pos = pos + 1

      if opcode == 0 {
        // Extended opcode
        if pos >= program_data.length() {
          running = false
        } else {
          match read_uleb128_at(program_data, pos) {
            Some((new_pos, ext_len)) => {
              pos = new_pos
              let ext_length = ext_len.reinterpret_as_int()
              if pos >= program_data.length() {
                running = false
              } else {
                let ext_opcode = program_data[pos].to_int()
                pos = pos + 1

                match dw_lne_from_uint(ext_opcode.reinterpret_as_uint()) {
                  DWLNE::EndSequence => {
                    state = update_state_end_seq(state, true)
                    entries.push(state_to_entry(state))
                    state = LineNumberState::init(header)
                  }
                  DWLNE::SetAddress =>
                    if pos + 3 < program_data.length() {
                      let addr = read_u32_at(program_data, pos)
                      state = update_state_address(state, addr)
                      pos = pos + 4
                    }
                  DWLNE::DefineFile => pos = pos + ext_length - 1
                  DWLNE::SetDiscriminator =>
                    match read_uleb128_at(program_data, pos) {
                      Some((new_pos, disc)) => {
                        state = update_state_discriminator(
                          state,
                          disc.reinterpret_as_int(),
                        )
                        pos = new_pos
                      }
                      None => running = false
                    }
                  DWLNE::Unknown => pos = pos + ext_length - 1
                }
              }
            }
            None => running = false
          }
        }
      } else if opcode < header.opcode_base {
        // Standard opcode
        match dw_lns_from_uint(opcode.reinterpret_as_uint()) {
          DWLNS::Copy => {
            entries.push(state_to_entry(state))
            state = reset_state_flags(state)
          }
          DWLNS::AdvancePc =>
            match read_uleb128_at(program_data, pos) {
              Some((new_pos, advance)) => {
                state = update_state_address(
                  state,
                  state.address +
                  advance * header.min_inst_length.reinterpret_as_uint(),
                )
                pos = new_pos
              }
              None => running = false
            }
          DWLNS::AdvanceLine =>
            match read_sleb128_at(program_data, pos) {
              Some((new_pos, advance)) => {
                state = update_state_line(state, state.line + advance)
                pos = new_pos
              }
              None => running = false
            }
          DWLNS::SetFile =>
            match read_uleb128_at(program_data, pos) {
              Some((new_pos, file_idx)) => {
                state = update_state_file(state, file_idx.reinterpret_as_int())
                pos = new_pos
              }
              None => running = false
            }
          DWLNS::SetColumn =>
            match read_uleb128_at(program_data, pos) {
              Some((new_pos, col)) => {
                state = update_state_column(state, col.reinterpret_as_int())
                pos = new_pos
              }
              None => running = false
            }
          DWLNS::NegateStmt =>
            state = update_state_is_stmt(state, !state.is_stmt)
          DWLNS::SetBasicBlock => state = update_state_basic_block(state, true)
          DWLNS::ConstAddPc => {
            let adjusted = (255 - header.opcode_base) / header.line_range
            let addr_advance = adjusted * header.min_inst_length
            state = update_state_address(
              state,
              state.address + addr_advance.reinterpret_as_uint(),
            )
          }
          DWLNS::FixedAdvancePc =>
            if pos + 1 < program_data.length() {
              let advance = (program_data[pos].to_int() |
              (program_data[pos + 1].to_int() << 8)).reinterpret_as_uint()
              state = update_state_address(state, state.address + advance)
              pos = pos + 2
            }
          DWLNS::SetPrologueEnd =>
            state = update_state_prologue_end(state, true)
          DWLNS::SetEpilogueBegin =>
            state = update_state_epilogue_begin(state, true)
          DWLNS::SetIsa =>
            match read_uleb128_at(program_data, pos) {
              Some((new_pos, isa_val)) => {
                state = update_state_isa(state, isa_val.reinterpret_as_int())
                pos = new_pos
              }
              None => running = false
            }
          DWLNS::Unknown =>
            // Skip operands
            if opcode - 1 < header.std_opcode_lengths.length() {
              let num_args = header.std_opcode_lengths[opcode - 1]
              for _ in 0..<num_args {
                match read_uleb128_at(program_data, pos) {
                  Some((new_pos, _)) => pos = new_pos
                  None => running = false
                }
              }
            }
        }
      } else {
        // Special opcode
        let adjusted = opcode - header.opcode_base
        let addr_advance = adjusted / header.line_range * header.min_inst_length
        let line_advance = header.line_base + adjusted % header.line_range
        state = update_state_address(
          state,
          state.address + addr_advance.reinterpret_as_uint(),
        )
        state = update_state_line(state, state.line + line_advance)
        entries.push(state_to_entry(state))
        state = reset_state_flags(state)
      }
    }
  }
  entries
}

///|
/// Helper functions to update LineNumberState
fn update_state_address(
  state : LineNumberState,
  address : UInt,
) -> LineNumberState {
  {
    address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_line(state : LineNumberState, line : Int) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_file(state : LineNumberState, file : Int) -> LineNumberState {
  {
    address: state.address,
    file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_column(
  state : LineNumberState,
  column : Int,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_is_stmt(
  state : LineNumberState,
  is_stmt : Bool,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_basic_block(
  state : LineNumberState,
  basic_block : Bool,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_end_seq(
  state : LineNumberState,
  end_sequence : Bool,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_prologue_end(
  state : LineNumberState,
  prologue_end : Bool,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_epilogue_begin(
  state : LineNumberState,
  epilogue_begin : Bool,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_isa(state : LineNumberState, isa : Int) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa,
    discriminator: state.discriminator,
  }
}

///|
fn update_state_discriminator(
  state : LineNumberState,
  discriminator : Int,
) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator,
  }
}

///|
fn reset_state_flags(state : LineNumberState) -> LineNumberState {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: false,
    end_sequence: false,
    prologue_end: false,
    epilogue_begin: false,
    isa: state.isa,
    discriminator: 0,
  }
}

///|
fn state_to_entry(state : LineNumberState) -> LineEntry {
  {
    address: state.address,
    file: state.file,
    line: state.line,
    column: state.column,
    is_stmt: state.is_stmt,
    basic_block: state.basic_block,
    end_sequence: state.end_sequence,
    prologue_end: state.prologue_end,
    epilogue_begin: state.epilogue_begin,
    isa: state.isa,
    discriminator: state.discriminator,
  }
}

///|
/// Read ULEB128 at a specific position in a byte array
pub fn read_uleb128_at(data : FixedArray[Byte], pos : Int) -> (Int, UInt)? {
  let mut result : UInt = 0U
  let mut shift = 0
  let mut p = pos

  let mut done = false
  while !done {
    if p >= data.length() {
      return None
    }
    let byte = data[p].to_int()
    p = p + 1
    result = result | ((byte & 0x7F).reinterpret_as_uint() << shift)
    if (byte & 0x80) == 0 {
      done = true
    } else {
      shift = shift + 7
      if shift > 63 {
        return None
      }
    }
  }
  Some((p, result))
}

///|
/// Read SLEB128 at a specific position in a byte array
pub fn read_sleb128_at(data : FixedArray[Byte], pos : Int) -> (Int, Int)? {
  let mut result : Int = 0
  let mut shift = 0
  let mut p = pos
  let mut last_byte = 0

  let mut done = false
  while !done {
    if p >= data.length() {
      return None
    }
    let byte = data[p].to_int()
    p = p + 1
    last_byte = byte
    result = result | ((byte & 0x7F) << shift)
    if (byte & 0x80) == 0 {
      done = true
    } else {
      shift = shift + 7
      if shift > 63 {
        return None
      }
    }
  }

  // Sign extend if negative
  if (last_byte & 0x40) != 0 && shift < 63 {
    result = result | -(1 << (shift + 7))
  }
  Some((p, result))
}

///|
/// Read u32 at a specific position in a byte array
pub fn read_u32_at(data : FixedArray[Byte], pos : Int) -> UInt {
  if pos + 3 >= data.length() {
    return 0U
  }
  let b0 = data[pos].to_int()
  let b1 = data[pos + 1].to_int()
  let b2 = data[pos + 2].to_int()
  let b3 = data[pos + 3].to_int()
  ((b3 << 24) | (b2 << 16) | (b1 << 8) | b0).reinterpret_as_uint()
}
