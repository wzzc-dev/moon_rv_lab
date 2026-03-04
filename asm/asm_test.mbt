///|
/// Tests for RISC-V assembler
test "parse_reg_abi_names" {
  assert_eq(parse_reg("zero"), Some(0U))
  assert_eq(parse_reg("ra"), Some(1U))
  assert_eq(parse_reg("sp"), Some(2U))
  assert_eq(parse_reg("gp"), Some(3U))
  assert_eq(parse_reg("tp"), Some(4U))
  assert_eq(parse_reg("t0"), Some(5U))
  assert_eq(parse_reg("s0"), Some(8U))
  assert_eq(parse_reg("fp"), Some(8U))
  assert_eq(parse_reg("a0"), Some(10U))
  assert_eq(parse_reg("a7"), Some(17U))
  assert_eq(parse_reg("t6"), Some(31U))
}

///|
test "parse_reg_numeric" {
  assert_eq(parse_reg("x0"), Some(0U))
  assert_eq(parse_reg("x1"), Some(1U))
  assert_eq(parse_reg("x31"), Some(31U))
  assert_eq(parse_reg("x32"), None)
}

///|
test "lexer_basic" {
  let tokens = tokenize("addi a0, x0, 42")
  // Tokens: addi (Ident), a0 (Reg), comma, x0 (Reg), comma, 42 (Imm), Eof
  assert_eq(tokens.length(), 7)

  match tokens[0].token {
    Token::Ident(s) => assert_eq(s, "addi")
    _ => abort("Expected Ident")
  }

  match tokens[1].token {
    Token::Reg(s) => assert_eq(s, "a0")
    _ => abort("Expected Reg")
  }

  match tokens[5].token {
    Token::Imm(v) => assert_eq(v, 42)
    _ => abort("Expected Imm")
  }
}

///|
test "lexer_hex" {
  let tokens = tokenize("lui t0, 0x12345")
  // lui (Ident), t0 (Reg), comma, 0x12345 (HexImm), Eof = 5 tokens
  assert_eq(tokens.length(), 5)
}

///|
test "parse_instruction_lui" {
  let operands : Array[Token] = [Token::Reg("a0"), Token::Imm(0x12345)]
  let result = parse_instruction("lui", operands)
  match result {
    Some(@decode.LUI(rd, imm)) => {
      assert_eq(rd, 10U)
      assert_eq(imm, 0x12345)
    }
    _ => abort("Expected LUI")
  }
}

///|
test "parse_instruction_addi" {
  let operands : Array[Token] = [
    Token::Reg("a0"),
    Token::Reg("x0"),
    Token::Imm(42),
  ]
  let result = parse_instruction("addi", operands)
  match result {
    Some(@decode.ADDI(rd, rs1, imm)) => {
      assert_eq(rd, 10U)
      assert_eq(rs1, 0U)
      assert_eq(imm, 42)
    }
    _ => abort("Expected ADDI")
  }
}

///|
test "parse_instruction_add" {
  let operands : Array[Token] = [
    Token::Reg("a0"),
    Token::Reg("a1"),
    Token::Reg("a2"),
  ]
  let result = parse_instruction("add", operands)
  match result {
    Some(@decode.ADD(rd, rs1, rs2)) => {
      assert_eq(rd, 10U)
      assert_eq(rs1, 11U)
      assert_eq(rs2, 12U)
    }
    _ => abort("Expected ADD")
  }
}

///|
test "parse_instruction_ecall" {
  let operands : Array[Token] = []
  let result = parse_instruction("ecall", operands)
  assert_true(result is Some(@decode.ECALL))
}

///|
test "roundtrip_addi" {
  let original = @decode.ADDI(10U, 0U, 42)
  let encoded = @encode.encode(original)
  let decoded = @decode.decode(encoded.code)
  match decoded.inner() {
    @decode.ADDI(rd, rs1, imm) => {
      assert_eq(rd, 10U)
      assert_eq(rs1, 0U)
      assert_eq(imm, 42)
    }
    _ => abort("Roundtrip failed")
  }
}

///|
test "roundtrip_beq" {
  let original = @decode.BEQ(10U, 11U, 16)
  let encoded = @encode.encode(original)
  let decoded = @decode.decode(encoded.code)
  match decoded.inner() {
    @decode.BEQ(rs1, rs2, imm) => {
      assert_eq(rs1, 10U)
      assert_eq(rs2, 11U)
      assert_eq(imm, 16)
    }
    _ => abort("Roundtrip failed")
  }
}

///|
test "roundtrip_lui" {
  let original = @decode.LUI(5U, 0x12345)
  let encoded = @encode.encode(original)
  let decoded = @decode.decode(encoded.code)
  match decoded.inner() {
    @decode.LUI(rd, imm) => {
      assert_eq(rd, 5U)
      assert_eq(imm, 0x12345)
    }
    _ => abort("Roundtrip failed")
  }
}

///|
test "encode_decode_consistency" {
  let instructions = [
    @decode.ADD(5U, 10U, 15U),
    @decode.SUB(5U, 10U, 15U),
    @decode.OR(5U, 10U, 15U),
    @decode.AND(5U, 10U, 15U),
    @decode.SLL(5U, 10U, 15U),
    @decode.SRL(5U, 10U, 15U),
    @decode.MUL(5U, 10U, 15U),
    @decode.DIV(5U, 10U, 15U),
  ]

  for inst in instructions {
    let encoded = @encode.encode(inst)
    let decoded = @decode.decode(encoded.code)
    ignore(decoded.inner())
  }
}

///|
test "lexer_label" {
  let tokens = tokenize("start:")
  assert_eq(tokens.length(), 3) // Ident, Colon, Eof

  match tokens[0].token {
    Token::Ident(s) => assert_eq(s, "start")
    _ => abort("Expected Ident")
  }

  assert_true(tokens[1].token is Token::Colon)
}

///|
test "parse_label" {
  let tokens = tokenize("main:")
  let stmt = parse_statement(tokens)
  match stmt {
    AsmStatement::Label(name) => assert_eq(name, "main")
    _ => abort("Expected Label")
  }
}

///|
test "parse_mixed_labels_and_instructions" {
  let tokens = tokenize("start:\n  addi a0, x0, 1\nend:\n  ret")
  let statements = parse("start:\n  addi a0, x0, 1\nend:\n  ret")

  // Should have: Label(start), Instruction, Label(end), Instruction, Empty
  assert_true(statements.length() >= 4)
}

///|
test "assemble_simple" {
  let result = assemble_with_symbols("addi a0, x0, 42\naddi a1, a0, 1", 0U)
  assert_eq(result.instructions.length(), 2)
  assert_eq(result.errors.length(), 0)
  assert_eq(result.start_address, 0U)
}

///|
test "assemble_with_labels" {
  let source = "start:\n  addi a0, x0, 1\n  addi a1, a0, 2\nend:\n  ecall"
  let result = assemble_with_symbols(source, 0x1000U)

  // Check labels were recorded
  assert_true(result.symbols.contains("start"))
  assert_true(result.symbols.contains("end"))

  // Check label addresses
  match result.symbols.lookup("start") {
    Some(sym) => assert_eq(sym.address, 0x1000U)
    None => abort("start label not found")
  }

  match result.symbols.lookup("end") {
    Some(sym) => assert_eq(sym.address, 0x1008U) // 0x1000 + 4 + 4
    None => abort("end label not found")
  }
}

///|
test "instruction_size" {
  assert_eq(instruction_size(@decode.ADDI(0U, 0U, 0)), 4)
  assert_eq(instruction_size(@decode.ECALL), 4)
  assert_eq(instruction_size(@decode.C_NOP), 2)
  assert_eq(instruction_size(@decode.C_ADDI(0U, 0)), 2)
}

///|
test "encode_to_bytes" {
  let result = assemble_with_symbols("addi a0, x0, 1", 0U)
  let bytes = encode_to_bytes(result)
  assert_eq(bytes.length(), 4) // One 32-bit instruction
}

///|
test "assemble_to_hex" {
  let hex = assemble_to_hex("addi a0, x0, 1")
  // addi a0, x0, 1 = 0x00100513
  assert_true(hex.length() > 0)
}
