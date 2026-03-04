///| RISC-V Assembler Lexer

///|
/// Lexer state
pub struct Lexer {
  input : String
  pos : Int
  line : Int
  col : Int
}

///|
/// Create a new lexer
pub fn new_lexer(input : String) -> Lexer {
  { input, pos: 0, line: 1, col: 1 }
}

///|
/// Check if at end of input
pub fn Lexer::is_at_end(self : Lexer) -> Bool {
  self.pos >= self.input.length()
}

///|
/// Peek current character
pub fn Lexer::peek(self : Lexer) -> Char {
  if self.is_at_end() {
    ' ' // return space as default
  } else {
    self.input[self.pos].unsafe_to_char()
  }
}

///|
/// Peek next character
pub fn Lexer::peek_next(self : Lexer) -> Char {
  if self.pos + 1 >= self.input.length() {
    ' ' // return space as default
  } else {
    self.input[self.pos + 1].unsafe_to_char()
  }
}

///|
/// Advance and return current character
pub fn Lexer::advance(self : Lexer) -> (Lexer, Char) {
  let c = self.peek()
  let new_lexer = if c == '\n' {
    { ..self, pos: self.pos + 1, line: self.line + 1, col: 1 }
  } else {
    { ..self, pos: self.pos + 1, col: self.col + 1 }
  }
  (new_lexer, c)
}

///|
/// Skip whitespace (but not newlines)
pub fn Lexer::skip_whitespace(self : Lexer) -> Lexer {
  let mut l = self
  while !l.is_at_end() &&
        (l.peek() == ' ' || l.peek() == '\t' || l.peek() == '\r') {
    let (new_l, _) = l.advance()
    l = new_l
  }
  l
}

///|
/// Skip comment (from # or ; to end of line)
pub fn Lexer::skip_comment(self : Lexer) -> Lexer {
  let mut l = self
  while !l.is_at_end() && l.peek() != '\n' {
    let (new_l, _) = l.advance()
    l = new_l
  }
  l
}

///|
/// Check if character is a digit
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Check if character is a hex digit
fn is_hex_digit(c : Char) -> Bool {
  is_digit(c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
/// Check if character is alphanumeric or underscore
fn is_alnum_underscore(c : Char) -> Bool {
  is_digit(c) || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
/// Check if character can start an identifier
fn is_ident_start(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '.'
}

///|
/// Read a number (decimal or hex)
fn read_number(lexer : Lexer) -> (Lexer, Token) {
  let mut l = lexer
  let mut is_negative = false
  let mut is_hex = false

  // Check for negative
  if l.peek() == '-' {
    let (new_l, _) = l.advance()
    l = new_l
    is_negative = true
  }

  // Check for hex prefix
  if l.peek() == '0' && (l.peek_next() == 'x' || l.peek_next() == 'X') {
    let (new_l, _) = l.advance() // consume '0'
    let (new_l2, _) = new_l.advance() // consume 'x'
    l = new_l2
    is_hex = true
  }

  if is_hex {
    // Read hex digits
    let mut value : UInt = 0U
    while is_hex_digit(l.peek()) {
      let (new_l, c) = l.advance()
      l = new_l
      let digit = if is_digit(c) {
        (c.to_int() - '0'.to_int()).reinterpret_as_uint()
      } else if c >= 'a' && c <= 'f' {
        (c.to_int() - 'a'.to_int() + 10).reinterpret_as_uint()
      } else {
        (c.to_int() - 'A'.to_int() + 10).reinterpret_as_uint()
      }
      value = value * 16U + digit
    }
    (l, Token::HexImm(value))
  } else {
    // Read decimal digits
    let mut value : Int = 0
    while is_digit(l.peek()) {
      let (new_l, c) = l.advance()
      l = new_l
      value = value * 10 + (c.to_int() - '0'.to_int())
    }
    if is_negative {
      value = -value
    }
    (l, Token::Imm(value))
  }
}

///|
/// Check if a string is a known ABI register name
fn is_abi_reg_name(name : String) -> Bool {
  match name {
    "zero" | "ra" | "sp" | "gp" | "tp" => true
    "t0" | "t1" | "t2" | "t3" | "t4" | "t5" | "t6" => true
    "s0"
    | "s1"
    | "s2"
    | "s3"
    | "s4"
    | "s5"
    | "s6"
    | "s7"
    | "s8"
    | "s9"
    | "s10"
    | "s11" => true
    "a0" | "a1" | "a2" | "a3" | "a4" | "a5" | "a6" | "a7" => true
    "fp" => true
    _ => false
  }
}

///|
/// Read an identifier or directive
fn read_ident(lexer : Lexer) -> (Lexer, Token) {
  let mut l = lexer
  let mut ident = ""

  while is_alnum_underscore(l.peek()) {
    let (new_l, c) = l.advance()
    l = new_l
    ident = ident + c.to_string()
  }

  // Check if it's a directive (starts with .)
  if ident.length() > 0 && ident[0] == '.' {
    (l, Token::Directive(ident))
  } else if is_abi_reg_name(ident) {
    // Check if it's an ABI register name
    (l, Token::Reg(ident))
  } else {
    (l, Token::Ident(ident))
  }
}

///|
/// Read a register name
fn read_register(lexer : Lexer) -> (Lexer, Token) {
  let mut l = lexer
  let mut reg = ""

  // Already consumed 'x' or first letter
  while is_alnum_underscore(l.peek()) {
    let (new_l, c) = l.advance()
    l = new_l
    reg = reg + c.to_string()
  }

  (l, Token::Reg(reg))
}

///|
/// Get the next token
pub fn Lexer::next_token(self : Lexer) -> (Lexer, TokenWithPos) {
  let l = self.skip_whitespace()

  let line = l.line
  let col = l.col

  if l.is_at_end() {
    return (l, { token: Token::Eof, line, col })
  }

  let c = l.peek()

  // Skip comments
  if c == '#' || c == ';' {
    let new_l = l.skip_comment()
    return new_l.next_token()
  }

  // Newline
  if c == '\n' {
    let (new_l, _) = l.advance()
    return (new_l, { token: Token::Newline, line, col })
  }

  // Punctuation
  if c == ',' {
    let (new_l, _) = l.advance()
    return (new_l, { token: Token::Comma, line, col })
  }
  if c == ':' {
    let (new_l, _) = l.advance()
    return (new_l, { token: Token::Colon, line, col })
  }
  if c == '(' {
    let (new_l, _) = l.advance()
    return (new_l, { token: Token::LParen, line, col })
  }
  if c == ')' {
    let (new_l, _) = l.advance()
    return (new_l, { token: Token::RParen, line, col })
  }
  if c == '+' {
    let (new_l, _) = l.advance()
    return (new_l, { token: Token::Plus, line, col })
  }
  if c == '-' {
    // Could be negative number or minus
    let (new_l, _) = l.advance()
    // Check if next char is digit
    if is_digit(new_l.peek()) {
      // Read as negative number - put back and read number
      let reverted = { ..new_l, pos: new_l.pos - 1, col: new_l.col - 1 }
      let (num_l, token) = read_number(reverted)
      return (num_l, { token, line, col })
    }
    return (new_l, { token: Token::Minus, line, col })
  }

  // Numbers
  if is_digit(c) {
    let (new_l, token) = read_number(l)
    return (new_l, { token, line, col })
  }

  // Register names (x0-x31) or identifiers
  if c == 'x' && is_digit(l.peek_next()) {
    let (new_l, token) = read_register(l)
    return (new_l, { token, line, col })
  }

  // Identifiers and directives
  if is_ident_start(c) {
    let (new_l, token) = read_ident(l)
    return (new_l, { token, line, col })
  }

  // Unknown character - skip it
  let (new_l, _) = l.advance()
  new_l.next_token()
}

///|
/// Tokenize entire input
pub fn tokenize(input : String) -> Array[TokenWithPos] {
  let mut lexer = new_lexer(input)
  let tokens : Array[TokenWithPos] = []

  let mut done = false
  while !done {
    let (new_lexer, token) = lexer.next_token()
    lexer = new_lexer
    tokens.push(token)
    if token.token is Token::Eof {
      done = true
    }
  }

  tokens
}
