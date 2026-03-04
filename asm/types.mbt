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
/// Symbol table (using Array for simplicity)
pub struct SymbolTable {
  entries : Array[(String, Symbol)]
} derive(Show)

///|
/// Create a new symbol table
pub fn SymbolTable::new() -> SymbolTable {
  { entries: [] }
}

///|
/// Add a symbol to the table (returns new table with the symbol added)
pub fn SymbolTable::add(
  self : SymbolTable,
  name : String,
  address : UInt,
  is_global : Bool,
) -> SymbolTable {
  let sym = { name, address, is_global, is_defined: true }
  let new_entries = self.entries.copy()
  new_entries.push((name, sym))
  { entries: new_entries }
}

///|
/// Look up a symbol by name
pub fn SymbolTable::lookup(self : SymbolTable, name : String) -> Symbol? {
  for entry in self.entries {
    let (n, sym) = entry
    if n == name {
      return Some(sym)
    }
  }
  None
}

///|
/// Check if a symbol exists
pub fn SymbolTable::contains(self : SymbolTable, name : String) -> Bool {
  for entry in self.entries {
    let (n, _) = entry
    if n == name {
      return true
    }
  }
  false
}

///|
/// Unresolved reference (for forward references)
pub struct UnresolvedRef {
  name : String
  address : UInt // address where the reference is
  inst_index : Int // index of instruction in the instruction list
  ref_type : RefType
} derive(Show)

///|
/// Type of reference (different relocation types)
pub enum RefType {
  Branch // PC-relative, 12-bit, for B-type
  Jump // PC-relative, 20-bit, for J-type
  Jalr // PC-relative, 12-bit, for I-type jump
  UType // Absolute, 20-bit upper, for LUI/AUIPC
  Call // Pseudo-instruction call, needs auipc+jalr pair
} derive(Show)

///|
/// Assembled instruction with address
pub struct AssembledInst {
  instruction : @decode.Instruction
  address : UInt
  size : Int // 2 for compressed, 4 for regular
} derive(Show)

///|
/// Assembly result
pub struct AssemblyResult {
  instructions : Array[AssembledInst]
  symbols : SymbolTable
  errors : Array[AsmError]
  start_address : UInt
}

///|
/// Assembly error
pub struct AsmError {
  message : String
  line : Int
  col : Int
} derive(Show)

///|
/// Parse error
pub struct ParseError {
  message : String
  line : Int
  col : Int
} derive(Show)
