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
/// Line number information container
pub struct LineNumberInfo {
  /// Line entries sorted by address
  entries : Array[LineEntry]
  /// File names indexed by file index
  file_names : Map[Int, String]
  /// Include directories indexed by directory index
  include_directories : Map[Int, String]
} derive(Show)

///|
/// Parse line number information from .debug_line section
pub fn parse_line_number_info(data : FixedArray[Byte]) -> LineNumberInfo {
  let entries : Array[LineEntry] = []
  let file_names : Map[Int, String] = {}
  let include_dirs : Map[Int, String] = {}

  // Parse line program header
  match parse_line_program_header(data) {
    Some(header) => {
      // Store file names and include directories
      for i = 0; i < header.file_names.length(); i = i + 1 {
        file_names[i + 1] = header.file_names[i].name
      }
      for i = 0; i < header.include_dirs.length(); i = i + 1 {
        include_dirs[i + 1] = header.include_dirs[i]
      }

      // Execute line number program
      let line_entries = execute_line_program(header, data)
      for entry in line_entries {
        entries.push(entry)
      }
    }
    None => ()
  }

  { entries, file_names, include_directories: include_dirs }
}

///|
/// Find line entry for address
pub fn find_line_entry(
  info : LineNumberInfo,
  address : UInt,
) -> SourceLocation? {
  let mut best : LineEntry? = None
  for entry in info.entries {
    if entry.address <= address && !entry.end_sequence {
      best = Some(entry)
    }
  }

  match best {
    Some(entry) => {
      let file_name = match info.file_names.get(entry.file) {
        Some(f) => f
        None => "unknown"
      }
      Some({
        address: entry.address,
        file: file_name,
        line: entry.line,
        column: entry.column,
      })
    }
    None => None
  }
}

///|
/// Source location information
pub struct SourceLocation {
  address : UInt
  file : String
  line : Int
  column : Int
} derive(Show)

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

///|
/// Parse abbreviation table from .debug_abbrev section
pub fn parse_abbrev_table(data : FixedArray[Byte]) -> Map[UInt, AbbrevEntry] {
  let table : Map[UInt, AbbrevEntry] = Map::new()
  let mut pos = 0

  let mut running = true
  while running {
    if pos >= data.length() {
      running = false
    } else {
      // Read abbreviation code
      match read_uleb128_at(data, pos) {
        Some((new_pos, code)) => {
          pos = new_pos
          if code == 0U {
            running = false
          } else {
            // Read tag
            match read_uleb128_at(data, pos) {
              Some((p2, tag_val)) => {
                pos = p2
                let tag = dw_tag_from_uint(tag_val)

                // Read has_children
                if pos >= data.length() {
                  running = false
                } else {
                  let has_children = data[pos] != b'\x00'
                  pos = pos + 1

                  // Read attribute specifications
                  let attrs : Array[AttrSpec] = []
                  let mut done_attrs = false
                  while !done_attrs {
                    match read_uleb128_at(data, pos) {
                      Some((p3, attr_name)) => {
                        pos = p3
                        match read_uleb128_at(data, pos) {
                          Some((p4, attr_form)) => {
                            pos = p4
                            if attr_name == 0U && attr_form == 0U {
                              done_attrs = true
                            } else {
                              attrs.push({
                                name: dw_attr_from_uint(attr_name),
                                form: dw_form_from_uint(attr_form),
                                implicit_const: 0,
                              })
                            }
                          }
                          None => done_attrs = true
                        }
                      }
                      None => done_attrs = true
                    }
                  }

                  table[code] = { code, tag, has_children, attrs }
                }
              }
              None => running = false
            }
          }
        }
        None => running = false
      }
    }
  }
  table
}

///|
/// Parse a single DIE from .debug_info
fn parse_die(
  data : FixedArray[Byte],
  pos : Int,
  abbrev_table : Map[UInt, AbbrevEntry],
  addr_size : Int,
) -> (Int, DIE)? {
  let offset = pos.reinterpret_as_uint()

  // Read abbreviation code
  match read_uleb128_at(data, pos) {
    Some((new_pos, abbrev_code)) => {
      let mut p = new_pos

      if abbrev_code == 0U {
        // Null DIE (end of children)
        return Some(
          (
            p,
            {
              offset,
              abbrev_code: 0U,
              tag: DWTag::Unknown,
              has_children: false,
              attrs: Map::new(),
              children: [],
            },
          ),
        )
      }

      // Get abbreviation entry
      match abbrev_table.get(abbrev_code) {
        Some(abbrev) => {
          // Parse attributes
          let attrs : Map[DWAttr, AttrValue] = Map::new()
          for attr_spec in abbrev.attrs {
            match parse_attr_value(data, p, attr_spec.form, addr_size) {
              Some((new_p, value)) => {
                p = new_p
                attrs[attr_spec.name] = value
              }
              None => return None
            }
          }

          Some(
            (
              p,
              {
                offset,
                abbrev_code,
                tag: abbrev.tag,
                has_children: abbrev.has_children,
                attrs,
                children: [],
              },
            ),
          )
        }
        None => None
      }
    }
    None => None
  }
}

///|
/// Parse attribute value based on form
fn parse_attr_value(
  data : FixedArray[Byte],
  pos : Int,
  form : DWForm,
  addr_size : Int,
) -> (Int, AttrValue)? {
  match form {
    DWForm::Addr =>
      if addr_size == 8 {
        match read_u64_at_data(data, pos) {
          Some((new_pos, val)) => Some((new_pos, AttrValue::Addr(val)))
          None => None
        }
      } else {
        let val = read_u32_at(data, pos)
        Some((pos + 4, AttrValue::Addr(val)))
      }
    DWForm::Data1 => {
      if pos >= data.length() {
        return None
      }
      Some((pos + 1, AttrValue::UData(data[pos].to_uint())))
    }
    DWForm::Data2 => {
      if pos + 1 >= data.length() {
        return None
      }
      let val = (data[pos + 1].to_uint() << 8) | data[pos].to_uint()
      Some((pos + 2, AttrValue::UData(val)))
    }
    DWForm::Data4 => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::UData(val)))
    }
    DWForm::Data8 =>
      match read_u64_at_data(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::UData(val)))
        None => None
      }
    DWForm::String => {
      // Read null-terminated string
      let mut result = ""
      let mut p = pos
      let mut done = false
      while !done {
        if p >= data.length() {
          done = true
        } else {
          let b = data[p]
          p = p + 1
          if b == b'\x00' {
            done = true
          } else {
            result = result + b.to_int().unsafe_to_char().to_string()
          }
        }
      }
      Some((p, AttrValue::String(result)))
    }
    DWForm::Flag => {
      if pos >= data.length() {
        return None
      }
      Some((pos + 1, AttrValue::Flag(data[pos] != b'\x00')))
    }
    DWForm::FlagPresent => Some((pos, AttrValue::Flag(true)))
    DWForm::Ref1 => {
      if pos >= data.length() {
        return None
      }
      Some((pos + 1, AttrValue::Ref(data[pos].to_uint())))
    }
    DWForm::Ref2 => {
      if pos + 1 >= data.length() {
        return None
      }
      let val = (data[pos + 1].to_uint() << 8) | data[pos].to_uint()
      Some((pos + 2, AttrValue::Ref(val)))
    }
    DWForm::Ref4 => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::Ref(val)))
    }
    DWForm::Ref8 =>
      match read_u64_at_data(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::Ref(val)))
        None => None
      }
    DWForm::UData =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::UData(val)))
        None => None
      }
    DWForm::SData =>
      match read_sleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::SData(val)))
        None => None
      }
    DWForm::SecOffset => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::SecOffset(val)))
    }
    DWForm::ExprLoc =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, len)) => {
          let length = len.reinterpret_as_int()
          if new_pos + length > data.length() {
            return None
          }
          let expr = FixedArray::make(length, b'\x00')
          for i in 0..<length {
            expr[i] = data[new_pos + i]
          }
          Some((new_pos + length, AttrValue::ExprLoc(expr)))
        }
        None => None
      }
    DWForm::Block1 => {
      if pos >= data.length() {
        return None
      }
      let length = data[pos].to_int()
      let block = FixedArray::make(length, b'\x00')
      for i in 0..<length {
        if pos + 1 + i >= data.length() {
          return None
        }
        block[i] = data[pos + 1 + i]
      }
      Some((pos + 1 + length, AttrValue::Block(block)))
    }
    DWForm::Block2 => {
      if pos + 1 >= data.length() {
        return None
      }
      let length = data[pos].to_int() | (data[pos + 1].to_int() << 8)
      let block = FixedArray::make(length, b'\x00')
      for i in 0..<length {
        if pos + 2 + i >= data.length() {
          return None
        }
        block[i] = data[pos + 2 + i]
      }
      Some((pos + 2 + length, AttrValue::Block(block)))
    }
    DWForm::Block4 => {
      let length = read_u32_at(data, pos).reinterpret_as_int()
      let block = FixedArray::make(length, b'\x00')
      for i in 0..<length {
        if pos + 4 + i >= data.length() {
          return None
        }
        block[i] = data[pos + 4 + i]
      }
      Some((pos + 4 + length, AttrValue::Block(block)))
    }
    DWForm::Block =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, len)) => {
          let length = len.reinterpret_as_int()
          let block = FixedArray::make(length, b'\x00')
          for i in 0..<length {
            if new_pos + i >= data.length() {
              return None
            }
            block[i] = data[new_pos + i]
          }
          Some((new_pos + length, AttrValue::Block(block)))
        }
        None => None
      }
    DWForm::StrP => {
      let offset = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::UData(offset))) // Will be resolved later
    }
    DWForm::RefAddr => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::Ref(val)))
    }
    DWForm::RefUData =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::Ref(val)))
        None => None
      }
    DWForm::Indirect =>
      // Read the actual form first
      match read_uleb128_at(data, pos) {
        Some((new_pos, actual_form_val)) => {
          let actual_form = dw_form_from_uint(actual_form_val)
          parse_attr_value(data, new_pos, actual_form, addr_size)
        }
        None => None
      }
    DWForm::RefSig8 =>
      match read_u64_at_data(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::Ref(val)))
        None => None
      }
    // DWARF 5 forms - simplified handling
    DWForm::StrX =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::UData(val)))
        None => None
      }
    DWForm::AddrX =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::UData(val)))
        None => None
      }
    DWForm::RefSup4 => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::Ref(val)))
    }
    DWForm::StrPSup => Some((pos, AttrValue::Unknown))
    DWForm::Data16 => {
      if pos + 15 >= data.length() {
        return None
      }
      Some((pos + 16, AttrValue::Unknown))
    }
    DWForm::LineStrP => {
      let offset = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::UData(offset)))
    }
    DWForm::ImplicitConst => Some((pos, AttrValue::Unknown))
    DWForm::LocListX =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::UData(val)))
        None => None
      }
    DWForm::RngListX =>
      match read_uleb128_at(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::UData(val)))
        None => None
      }
    DWForm::RefSup8 =>
      match read_u64_at_data(data, pos) {
        Some((new_pos, val)) => Some((new_pos, AttrValue::Ref(val)))
        None => None
      }
    DWForm::StrX1 => {
      if pos >= data.length() {
        return None
      }
      Some((pos + 1, AttrValue::UData(data[pos].to_uint())))
    }
    DWForm::StrX2 => {
      if pos + 1 >= data.length() {
        return None
      }
      let val = (data[pos + 1].to_uint() << 8) | data[pos].to_uint()
      Some((pos + 2, AttrValue::UData(val)))
    }
    DWForm::StrX3 => {
      if pos + 2 >= data.length() {
        return None
      }
      let val = data[pos].to_uint() |
        (data[pos + 1].to_uint() << 8) |
        (data[pos + 2].to_uint() << 16)
      Some((pos + 3, AttrValue::UData(val)))
    }
    DWForm::StrX4 => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::UData(val)))
    }
    DWForm::AddrX1 => {
      if pos >= data.length() {
        return None
      }
      Some((pos + 1, AttrValue::UData(data[pos].to_uint())))
    }
    DWForm::AddrX2 => {
      if pos + 1 >= data.length() {
        return None
      }
      let val = (data[pos + 1].to_uint() << 8) | data[pos].to_uint()
      Some((pos + 2, AttrValue::UData(val)))
    }
    DWForm::AddrX3 => {
      if pos + 2 >= data.length() {
        return None
      }
      let val = data[pos].to_uint() |
        (data[pos + 1].to_uint() << 8) |
        (data[pos + 2].to_uint() << 16)
      Some((pos + 3, AttrValue::UData(val)))
    }
    DWForm::AddrX4 => {
      let val = read_u32_at(data, pos)
      Some((pos + 4, AttrValue::UData(val)))
    }
    DWForm::Unknown => Some((pos, AttrValue::Unknown))
  }
}

///|
/// Read u64 from data array
fn read_u64_at_data(data : FixedArray[Byte], pos : Int) -> (Int, UInt)? {
  if pos + 7 >= data.length() {
    return None
  }
  let mut val : UInt = 0U
  for i in 0..<8 {
    val = val | (data[pos + i].to_int().reinterpret_as_uint() << (i * 8))
  }
  Some((pos + 8, val))
}

///|
/// Parse DIE tree from .debug_info section
pub fn parse_die_tree(
  info_data : FixedArray[Byte],
  abbrev_data : FixedArray[Byte],
) -> Array[DIE] {
  let abbrev_table = parse_abbrev_table(abbrev_data)
  let dies : Array[DIE] = []
  let mut pos = 0

  while pos < info_data.length() {
    // Parse compilation unit header first
    let cu = match parse_compilation_unit_header_at(info_data, pos) {
      Some((new_pos, header)) => {
        pos = new_pos
        header
      }
      None => break
    }

    // Parse DIEs in this compilation unit
    let cu_end = pos + cu.unit_length.reinterpret_as_int() - 4
    let root_die = match
      parse_die_tree_recursive(
        info_data,
        pos,
        cu_end,
        abbrev_table,
        cu.addr_size,
      ) {
      Some((new_pos, die)) => {
        pos = new_pos
        die
      }
      None => break
    }
    dies.push(root_die)
  }
  dies
}

///|
/// Parse compilation unit header at specific position
fn parse_compilation_unit_header_at(
  data : FixedArray[Byte],
  pos : Int,
) -> (Int, CompilationUnit)? {
  let p = DWARFParser::new(data)
  let parser = { data: p.data, pos, addr_size: p.addr_size, version: p.version }

  let (p1, unit_length) = match read_u32(parser) {
    Some((np, v)) => (np, v)
    None => return None
  }

  let (is_64bit, actual_length, p2) = if unit_length == 0xFFFFFFFFU {
    match read_u64(p1) {
      Some((p, len)) => (true, len, p)
      None => return None
    }
  } else {
    (false, unit_length, p1)
  }

  let (p3, version) = match read_u16(p2) {
    Some((p, v)) => (p, v)
    None => return None
  }

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
    Some((p, b)) => (p, b)
    None => return None
  }

  Some(
    (
      p5.pos,
      {
        unit_length: actual_length,
        version: version.reinterpret_as_int(),
        abbrev_offset,
        addr_size: addr_size_byte.to_int(),
        root: None,
      },
    ),
  )
}

///|
/// Parse DIE tree recursively
fn parse_die_tree_recursive(
  data : FixedArray[Byte],
  pos : Int,
  end_pos : Int,
  abbrev_table : Map[UInt, AbbrevEntry],
  addr_size : Int,
) -> (Int, DIE)? {
  if pos >= end_pos {
    return None
  }

  match parse_die(data, pos, abbrev_table, addr_size) {
    Some((new_pos, die)) => {
      let mut p = new_pos

      if die.abbrev_code == 0U {
        return Some((p, die))
      }

      if die.has_children {
        let children : Array[DIE] = []
        let mut done = false
        while !done {
          if p >= end_pos {
            done = true
          } else {
            match
              parse_die_tree_recursive(
                data, p, end_pos, abbrev_table, addr_size,
              ) {
              Some((new_p, child)) => {
                p = new_p
                if child.abbrev_code == 0U {
                  done = true
                } else {
                  children.push(child)
                }
              }
              None => done = true
            }
          }
        }
        // Create new DIE with children
        Some(
          (
            p,
            {
              offset: die.offset,
              abbrev_code: die.abbrev_code,
              tag: die.tag,
              has_children: die.has_children,
              attrs: die.attrs,
              children,
            },
          ),
        )
      } else {
        Some((p, die))
      }
    }
    None => None
  }
}

///|
/// Find DIE by offset
pub fn find_die_by_offset(dies : Array[DIE], offset : UInt) -> DIE? {
  for die in dies {
    if die.offset == offset {
      return Some(die)
    }
    if die.children.length() > 0 {
      match find_die_by_offset(die.children, offset) {
        Some(d) => return Some(d)
        None => ()
      }
    }
  }
  None
}

///|
/// Find DIEs by tag
pub fn find_dies_by_tag(dies : Array[DIE], tag : DWTag) -> Array[DIE] {
  let result : Array[DIE] = []
  for die in dies {
    if die.tag == tag {
      result.push(die)
    }
    if die.children.length() > 0 {
      let child_results = find_dies_by_tag(die.children, tag)
      for child in child_results {
        result.push(child)
      }
    }
  }
  result
}

///|
/// Get attribute value from DIE
pub fn get_die_attr(die : DIE, attr : DWAttr) -> AttrValue? {
  die.attrs.get(attr)
}

///|
/// Get string attribute from DIE
pub fn get_die_string(die : DIE, attr : DWAttr) -> String? {
  match die.attrs.get(attr) {
    Some(AttrValue::String(s)) => Some(s)
    Some(AttrValue::UData(_)) => Some("") // Would need .debug_str lookup
    _ => None
  }
}

///|
/// Get address attribute from DIE
pub fn get_die_address(die : DIE, attr : DWAttr) -> UInt? {
  match die.attrs.get(attr) {
    Some(AttrValue::Addr(a)) => Some(a)
    _ => None
  }
}
