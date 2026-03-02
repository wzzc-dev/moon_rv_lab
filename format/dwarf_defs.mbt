///| DWARF debug information format definitions

///| Based on DWARF 4 Standard (http://dwarfstd.org/)

///|
/// DWARF section names
pub const DEBUG_INFO : String = ".debug_info"

///|
pub const DEBUG_ABBREV : String = ".debug_abbrev"

///|
pub const DEBUG_LINE : String = ".debug_line"

///|
pub const DEBUG_STR : String = ".debug_str"

///|
pub const DEBUG_RANGES : String = ".debug_ranges"

///|
pub const DEBUG_LOC : String = ".debug_loc"

///|
pub const DEBUG_FRAME : String = ".debug_frame"

///|
pub const DEBUG_ARANGES : String = ".debug_aranges"

///|
/// DWARF version
pub const DWARF_VERSION_2 : Int = 2

///|
pub const DWARF_VERSION_3 : Int = 3

///|
pub const DWARF_VERSION_4 : Int = 4

///|
pub const DWARF_VERSION_5 : Int = 5

///|
/// DWARF Tag (Debugging Information Entry tags)
pub enum DWTag {
  // Core tags
  CompileUnit = 0x11
  Subprogram = 0x2E
  FormalParameter = 0x05
  Variable = 0x34
  BaseType = 0x24
  PointerType = 0x0F
  ConstType = 0x26
  Typedef = 0x16
  StructureType = 0x13
  Member = 0x0D
  ArrayType = 0x01
  SubrangeType = 0x21
  EnumerationType = 0x04
  Enumerator = 0x28
  UnionType = 0x17
  // Additional tags
  Label = 0x0A
  LexicalBlock = 0x0B
  InlinedSubroutine = 0x1D
  // Unknown
  Unknown = 0x00
} derive(Show, Eq)

///|
/// DWARF Attribute names
pub enum DWAttr {
  // Core attributes
  Name = 0x03
  LowPc = 0x11
  HighPc = 0x12
  StmtList = 0x10
  CompDir = 0x1B
  Language = 0x13
  Producer = 0x25
  // Type attributes
  Encoding = 0x3E
  ByteSize = 0x0B
  BitSize = 0x0D
  Type = 0x49
  // Location attributes
  Location = 0x02
  FrameBase = 0x40
  DataMemberLocation = 0x38
  // Function attributes
  External = 0x3F
  Declaration = 0x3C
  Inline = 0x20
  // Unknown
  Unknown = 0x00
} derive(Show, Eq)

///|
/// DWARF Form (attribute value formats)
pub enum DWForm {
  Addr = 0x01
  Block2 = 0x03
  Block4 = 0x04
  Data2 = 0x05
  Data4 = 0x06
  Data8 = 0x07
  String = 0x08
  Block = 0x09
  Block1 = 0x0A
  Data1 = 0x0B
  Flag = 0x0C
  SData = 0x0D
  StrP = 0x0E
  UData = 0x0F
  RefAddr = 0x10
  Ref1 = 0x11
  Ref2 = 0x12
  Ref4 = 0x13
  Ref8 = 0x14
  RefUData = 0x15
  Indirect = 0x16
  SecOffset = 0x17
  ExprLoc = 0x18
  FlagPresent = 0x19
  RefSig8 = 0x20
  // DWARF 5 forms
  StrX = 0x1A
  AddrX = 0x1B
  RefSup4 = 0x1C
  StrPSup = 0x1D
  Data16 = 0x1E
  LineStrP = 0x1F
  ImplicitConst = 0x21
  LocListX = 0x22
  RngListX = 0x23
  RefSup8 = 0x24
  StrX1 = 0x25
  StrX2 = 0x26
  StrX3 = 0x27
  StrX4 = 0x28
  AddrX1 = 0x29
  AddrX2 = 0x2A
  AddrX3 = 0x2B
  AddrX4 = 0x2C
  // Unknown
  Unknown = 0x00
} derive(Show, Eq)

///|
/// DWARF base type encoding
pub enum DWATE {
  Address = 0x01
  Boolean = 0x02
  ComplexFloat = 0x03
  Float = 0x04
  Signed = 0x05
  SignedChar = 0x06
  Unsigned = 0x07
  UnsignedChar = 0x08
  // DWARF 4
  ImaginaryFloat = 0x09
  PackedDecimal = 0x0A
  NumericString = 0x0B
  Edited = 0x0C
  SignedFixed = 0x0D
  UnsignedFixed = 0x0E
  // DWARF 5
  UTF = 0x10
  // Unknown
  Unknown = 0x00
} derive(Show, Eq)

///|
/// DWARF language codes
pub enum DWLANG {
  C89 = 0x0001
  C = 0x0002
  Ada83 = 0x0003
  CPlusPlus = 0x0004
  Cobol74 = 0x0005
  Cobol85 = 0x0006
  Fortran77 = 0x0007
  Fortran90 = 0x0008
  Pascal83 = 0x0009
  Modula2 = 0x000A
  // DWARF 3
  Java = 0x000B
  C99 = 0x000C
  Ada95 = 0x000D
  Fortran95 = 0x000E
  PLI = 0x000F
  // DWARF 4
  ObjC = 0x0010
  ObjCPlusPlus = 0x0011
  UPC = 0x0012
  D = 0x0013
  // DWARF 5
  Python = 0x0014
  OpenCL = 0x0015
  Go = 0x0016
  Modula3 = 0x0017
  Haskell = 0x0018
  CPlusPlus03 = 0x0019
  CPlusPlus11 = 0x001A
  OCaml = 0x001B
  Rust = 0x001C
  C11 = 0x001D
  Swift = 0x001E
  Julia = 0x001F
  Dylan = 0x0020
  CPlusPlus14 = 0x0021
  Fortran03 = 0x0022
  Fortran08 = 0x0023
  RenderScript = 0x0024
  BLISS = 0x0025
  // Unknown
  Unknown = 0x0000
} derive(Show, Eq)

///|
/// Line number program opcodes
pub enum DWLNE {
  EndSequence = 0x01
  SetAddress = 0x02
  DefineFile = 0x03
  SetDiscriminator = 0x04
  // Unknown
  Unknown = 0x00
} derive(Show, Eq)

///|
/// Line number standard opcodes
pub enum DWLNS {
  Copy = 0x01
  AdvancePc = 0x02
  AdvanceLine = 0x03
  SetFile = 0x04
  SetColumn = 0x05
  NegateStmt = 0x06
  SetBasicBlock = 0x07
  ConstAddPc = 0x08
  FixedAdvancePc = 0x09
  SetPrologueEnd = 0x0A
  SetEpilogueBegin = 0x0B
  SetIsa = 0x0C
  // Unknown
  Unknown = 0x00
} derive(Show, Eq)

///|
/// Convert UInt to DWTag
pub fn dw_tag_from_uint(value : UInt) -> DWTag {
  match value {
    0x11U => DWTag::CompileUnit
    0x2EU => DWTag::Subprogram
    0x05U => DWTag::FormalParameter
    0x34U => DWTag::Variable
    0x24U => DWTag::BaseType
    0x0FU => DWTag::PointerType
    0x26U => DWTag::ConstType
    0x16U => DWTag::Typedef
    0x13U => DWTag::StructureType
    0x0DU => DWTag::Member
    0x01U => DWTag::ArrayType
    0x21U => DWTag::SubrangeType
    0x04U => DWTag::EnumerationType
    0x28U => DWTag::Enumerator
    0x17U => DWTag::UnionType
    0x0AU => DWTag::Label
    0x0BU => DWTag::LexicalBlock
    0x1DU => DWTag::InlinedSubroutine
    _ => DWTag::Unknown
  }
}

///|
/// Convert UInt to DWAttr
pub fn dw_attr_from_uint(value : UInt) -> DWAttr {
  match value {
    0x03U => DWAttr::Name
    0x11U => DWAttr::LowPc
    0x12U => DWAttr::HighPc
    0x10U => DWAttr::StmtList
    0x1BU => DWAttr::CompDir
    0x13U => DWAttr::Language
    0x25U => DWAttr::Producer
    0x3EU => DWAttr::Encoding
    0x0BU => DWAttr::ByteSize
    0x0DU => DWAttr::BitSize
    0x49U => DWAttr::Type
    0x02U => DWAttr::Location
    0x40U => DWAttr::FrameBase
    0x38U => DWAttr::DataMemberLocation
    0x3FU => DWAttr::External
    0x3CU => DWAttr::Declaration
    0x20U => DWAttr::Inline
    _ => DWAttr::Unknown
  }
}

///|
/// Convert UInt to DWForm
pub fn dw_form_from_uint(value : UInt) -> DWForm {
  match value {
    0x01U => DWForm::Addr
    0x03U => DWForm::Block2
    0x04U => DWForm::Block4
    0x05U => DWForm::Data2
    0x06U => DWForm::Data4
    0x07U => DWForm::Data8
    0x08U => DWForm::String
    0x09U => DWForm::Block
    0x0AU => DWForm::Block1
    0x0BU => DWForm::Data1
    0x0CU => DWForm::Flag
    0x0DU => DWForm::SData
    0x0EU => DWForm::StrP
    0x0FU => DWForm::UData
    0x10U => DWForm::RefAddr
    0x11U => DWForm::Ref1
    0x12U => DWForm::Ref2
    0x13U => DWForm::Ref4
    0x14U => DWForm::Ref8
    0x15U => DWForm::RefUData
    0x16U => DWForm::Indirect
    0x17U => DWForm::SecOffset
    0x18U => DWForm::ExprLoc
    0x19U => DWForm::FlagPresent
    0x20U => DWForm::RefSig8
    0x1AU => DWForm::StrX
    0x1BU => DWForm::AddrX
    0x1CU => DWForm::RefSup4
    0x1DU => DWForm::StrPSup
    0x1EU => DWForm::Data16
    0x1FU => DWForm::LineStrP
    0x21U => DWForm::ImplicitConst
    0x22U => DWForm::LocListX
    0x23U => DWForm::RngListX
    0x24U => DWForm::RefSup8
    0x25U => DWForm::StrX1
    0x26U => DWForm::StrX2
    0x27U => DWForm::StrX3
    0x28U => DWForm::StrX4
    0x29U => DWForm::AddrX1
    0x2AU => DWForm::AddrX2
    0x2BU => DWForm::AddrX3
    0x2CU => DWForm::AddrX4
    _ => DWForm::Unknown
  }
}

///|
/// Convert UInt to DWATE (base type encoding)
pub fn dw_ate_from_uint(value : UInt) -> DWATE {
  match value {
    0x01U => DWATE::Address
    0x02U => DWATE::Boolean
    0x03U => DWATE::ComplexFloat
    0x04U => DWATE::Float
    0x05U => DWATE::Signed
    0x06U => DWATE::SignedChar
    0x07U => DWATE::Unsigned
    0x08U => DWATE::UnsignedChar
    0x09U => DWATE::ImaginaryFloat
    0x0AU => DWATE::PackedDecimal
    0x0BU => DWATE::NumericString
    0x0CU => DWATE::Edited
    0x0DU => DWATE::SignedFixed
    0x0EU => DWATE::UnsignedFixed
    0x10U => DWATE::UTF
    _ => DWATE::Unknown
  }
}

///|
/// Convert UInt to DWLNE (line number extended opcode)
pub fn dw_lne_from_uint(value : UInt) -> DWLNE {
  match value {
    0x01U => DWLNE::EndSequence
    0x02U => DWLNE::SetAddress
    0x03U => DWLNE::DefineFile
    0x04U => DWLNE::SetDiscriminator
    _ => DWLNE::Unknown
  }
}

///|
/// Convert UInt to DWLNS (line number standard opcode)
pub fn dw_lns_from_uint(value : UInt) -> DWLNS {
  match value {
    0x01U => DWLNS::Copy
    0x02U => DWLNS::AdvancePc
    0x03U => DWLNS::AdvanceLine
    0x04U => DWLNS::SetFile
    0x05U => DWLNS::SetColumn
    0x06U => DWLNS::NegateStmt
    0x07U => DWLNS::SetBasicBlock
    0x08U => DWLNS::ConstAddPc
    0x09U => DWLNS::FixedAdvancePc
    0x0AU => DWLNS::SetPrologueEnd
    0x0BU => DWLNS::SetEpilogueBegin
    0x0CU => DWLNS::SetIsa
    _ => DWLNS::Unknown
  }
}
