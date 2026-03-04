///| RISC-V Assembler Types

///|
/// Assembler token types
pub(all) enum Token {
  // Identifiers and literals
  Ident(String) // identifier (instruction mnemonic, label, etc.)
  Reg(String) // register name (x0-x31, a0-a7, t0-t6, etc.)
  Imm(Int) // immediate value
  HexImm(UInt) // hexadecimal immediate

  // Punctuation
  Comma // ,
  Colon // :
  LParen // (
  RParen // )
  Plus // +
  Minus // -
  Newline // end of line

  // Directives
  Directive(String) // .text, .data, .word, .byte, etc.

  // End of file
  Eof
} derive(Show)

///|
/// Token with position info
pub struct TokenWithPos {
  token : Token
  line : Int
  col : Int
} derive(Show)

///|
/// Assembly statement types
pub(all) enum AsmStatement {
  Instruction(@decode.Instruction)
  Label(String)
  Directive(String, Array[Token]) // directive name and arguments
  Data(FixedArray[Byte])
  Empty
  Error(ParseError)
} derive(Show)

///|
/// Assembly directive
pub struct AsmDirective {
  name : String
  args : Array[String]
} derive(Show)

///|
/// Symbol for label/label reference
pub struct Symbol {
  name : String
  address : UInt
  is_global : Bool
  is_defined : Bool
} derive(Show)

///|
/// Symbol table
pub struct SymbolTable {
  symbols : Map[String, Symbol]
  current_address : UInt
}

///|
/// Unresolved reference (for forward references)
pub struct UnresolvedRef {
  name : String
  address : UInt // address where the reference is
  offset : Int // offset within the instruction
  width : Int // bit width (12, 20, etc.)
  is_relative : Bool // PC-relative or absolute
} derive(Show)

///|
/// Parse error
pub struct ParseError {
  message : String
  line : Int
  col : Int
} derive(Show)
