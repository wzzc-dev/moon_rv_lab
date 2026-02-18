///| RISC-V instruction types and definitions

///| Based on RISC-V Specification Volume I: User-Level ISA

///|
/// RISC-V instruction enumeration
pub enum Instruction {
  // U-type instructions
  LUI(UInt, Int) // rd, imm
  AUIPC(UInt, Int) // rd, imm
  // J-type instructions
  JAL(UInt, Int) // rd, imm
  // I-type instructions
  JALR(UInt, UInt, Int) // rd, rs1, imm
  // Branch instructions (B-type)
  BEQ(UInt, UInt, Int) // rs1, rs2, imm
  BNE(UInt, UInt, Int) // rs1, rs2, imm
  BLT(UInt, UInt, Int) // rs1, rs2, imm
  BGE(UInt, UInt, Int) // rs1, rs2, imm
  BLTU(UInt, UInt, Int) // rs1, rs2, imm
  BGEU(UInt, UInt, Int) // rs1, rs2, imm
  // Load instructions (I-type)
  LB(UInt, UInt, Int) // rd, rs1, imm
  LH(UInt, UInt, Int) // rd, rs1, imm
  LW(UInt, UInt, Int) // rd, rs1, imm
  LBU(UInt, UInt, Int) // rd, rs1, imm
  LHU(UInt, UInt, Int) // rd, rs1, imm
  // Store instructions (S-type)
  SB(UInt, UInt, Int) // rs1, rs2, imm
  SH(UInt, UInt, Int) // rs1, rs2, imm
  SW(UInt, UInt, Int) // rs1, rs2, imm
  // Immediate arithmetic (I-type)
  ADDI(UInt, UInt, Int) // rd, rs1, imm
  SLTI(UInt, UInt, Int) // rd, rs1, imm
  SLTIU(UInt, UInt, Int) // rd, rs1, imm
  XORI(UInt, UInt, Int) // rd, rs1, imm
  ORI(UInt, UInt, Int) // rd, rs1, imm
  ANDI(UInt, UInt, Int) // rd, rs1, imm
  SLLI(UInt, UInt, UInt) // rd, rs1, shamt
  SRLI(UInt, UInt, UInt) // rd, rs1, shamt
  SRAI(UInt, UInt, UInt) // rd, rs1, shamt
  // Register arithmetic (R-type)
  ADD(UInt, UInt, UInt) // rd, rs1, rs2
  SUB(UInt, UInt, UInt) // rd, rs1, rs2
  SLL(UInt, UInt, UInt) // rd, rs1, rs2
  SLT(UInt, UInt, UInt) // rd, rs1, rs2
  SLTU(UInt, UInt, UInt) // rd, rs1, rs2
  XOR(UInt, UInt, UInt) // rd, rs1, rs2
  SRL(UInt, UInt, UInt) // rd, rs1, rs2
  SRA(UInt, UInt, UInt) // rd, rs1, rs2
  OR(UInt, UInt, UInt) // rd, rs1, rs2
  AND(UInt, UInt, UInt) // rd, rs1, rs2
  // RV32M extension (multiply/divide)
  MUL(UInt, UInt, UInt) // rd, rs1, rs2 - multiply lower
  MULH(UInt, UInt, UInt) // rd, rs1, rs2 - multiply upper (signed * signed)
  MULHSU(UInt, UInt, UInt) // rd, rs1, rs2 - multiply upper (signed * unsigned)
  MULHU(UInt, UInt, UInt) // rd, rs1, rs2 - multiply upper (unsigned * unsigned)
  DIV(UInt, UInt, UInt) // rd, rs1, rs2 - divide signed
  DIVU(UInt, UInt, UInt) // rd, rs1, rs2 - divide unsigned
  REM(UInt, UInt, UInt) // rd, rs1, rs2 - remainder signed
  REMU(UInt, UInt, UInt) // rd, rs1, rs2 - remainder unsigned
  // RV64I base instruction set (64-bit specific)
  // Load/Store 64-bit
  LD(UInt, UInt, Int) // rd, rs1, imm - load doubleword
  SD(UInt, UInt, Int) // rs1, rs2, imm - store doubleword
  LWU(UInt, UInt, Int) // rd, rs1, imm - load word unsigned
  // Immediate arithmetic 64-bit (W = word, 32-bit operations)
  ADDIW(UInt, UInt, Int) // rd, rs1, imm - add immediate word
  SLLIW(UInt, UInt, UInt) // rd, rs1, shamt - shift left logical immediate word
  SRLIW(UInt, UInt, UInt) // rd, rs1, shamt - shift right logical immediate word
  SRAIW(UInt, UInt, UInt) // rd, rs1, shamt - shift right arithmetic immediate word
  // Register arithmetic 64-bit (W = word, 32-bit operations)
  ADDW(UInt, UInt, UInt) // rd, rs1, rs2 - add word
  SUBW(UInt, UInt, UInt) // rd, rs1, rs2 - subtract word
  SLLW(UInt, UInt, UInt) // rd, rs1, rs2 - shift left logical word
  SRLW(UInt, UInt, UInt) // rd, rs1, rs2 - shift right logical word
  SRAW(UInt, UInt, UInt) // rd, rs1, rs2 - shift right arithmetic word
  // RV64M extension (multiply/divide word)
  MULW(UInt, UInt, UInt) // rd, rs1, rs2 - multiply word
  DIVW(UInt, UInt, UInt) // rd, rs1, rs2 - divide word signed
  DIVUW(UInt, UInt, UInt) // rd, rs1, rs2 - divide word unsigned
  REMW(UInt, UInt, UInt) // rd, rs1, rs2 - remainder word signed
  REMUW(UInt, UInt, UInt) // rd, rs1, rs2 - remainder word unsigned
  // RV32A extension (atomic operations)
  // Load-Reserved/Store-Conditional
  LR_W(UInt, UInt, UInt, UInt) // rd, rs1, aq, rl - load-reserved word
  SC_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl - store-conditional word
  // Atomic Memory Operations (AMO)
  AMOSWAP_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOADD_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOXOR_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOAND_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOOR_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMIN_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAX_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMINU_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAXU_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  // RV64A extension (64-bit atomic operations)
  LR_D(UInt, UInt, UInt, UInt) // rd, rs1, aq, rl - load-reserved doubleword
  SC_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl - store-conditional doubleword
  AMOSWAP_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOADD_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOXOR_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOAND_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOOR_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMIN_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAX_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMINU_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAXU_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  // Fence instructions
  FENCE(UInt, UInt) // pred, succ
  FENCE_I
  // System instructions
  ECALL
  EBREAK
  // RV32C compressed instructions (16-bit)
  C_ADDI4SPN(UInt, UInt) // rd', imm
  C_LW(UInt, UInt, UInt) // rd', rs1', imm
  C_SW(UInt, UInt, UInt) // rs2', rs1', imm
  C_NOP
  C_ADDI(UInt, Int) // rd, imm
  C_JAL(Int) // imm
  C_LI(UInt, Int) // rd, imm
  C_ADDI16SP(Int) // imm
  C_LUI(UInt, Int) // rd, imm
  C_SRLI(UInt, UInt) // rd', shamt
  C_SRAI(UInt, UInt) // rd', shamt
  C_ANDI(UInt, Int) // rd', imm
  C_SUB(UInt, UInt) // rd', rs2'
  C_XOR(UInt, UInt) // rd', rs2'
  C_OR(UInt, UInt) // rd', rs2'
  C_AND(UInt, UInt) // rd', rs2'
  C_J(Int) // imm
  C_BEQZ(UInt, Int) // rs1', imm
  C_BNEZ(UInt, Int) // rs1', imm
  C_SLLI(UInt, UInt) // rd, shamt
  C_LWSP(UInt, UInt) // rd, imm
  C_JR(UInt) // rs1
  C_MV(UInt, UInt) // rd, rs2
  C_EBREAK
  C_JALR(UInt) // rs1
  C_ADD(UInt, UInt) // rd, rs2
  C_SWSP(UInt, UInt) // rs2, imm
  // Zicsr extension (CSR instructions)
  CSRRW(UInt, UInt, UInt) // rd, csr, rs1 - CSR read/write
  CSRRS(UInt, UInt, UInt) // rd, csr, rs1 - CSR read/set
  CSRRC(UInt, UInt, UInt) // rd, csr, rs1 - CSR read/clear
  CSRRWI(UInt, UInt, UInt) // rd, csr, uimm - CSR read/write immediate
  CSRRSI(UInt, UInt, UInt) // rd, csr, uimm - CSR read/set immediate
  CSRRCI(UInt, UInt, UInt) // rd, csr, uimm - CSR read/clear immediate
  // Zba extension (address generation)
  SH1ADD(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 1 and add
  SH2ADD(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 2 and add
  SH3ADD(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 3 and add
  // Zbb extension (basic bit manipulation)
  ANDN(UInt, UInt, UInt) // rd, rs1, rs2 - AND with inverted rs2
  ORN(UInt, UInt, UInt) // rd, rs1, rs2 - OR with inverted rs2
  XNOR(UInt, UInt, UInt) // rd, rs1, rs2 - XNOR
  CLZ(UInt, UInt) // rd, rs1 - count leading zeros
  CTZ(UInt, UInt) // rd, rs1 - count trailing zeros
  CPOP(UInt, UInt) // rd, rs1 - count population (set bits)
  SEXT_B(UInt, UInt) // rd, rs1 - sign extend byte
  SEXT_H(UInt, UInt) // rd, rs1 - sign extend halfword
  ZEXT_H(UInt, UInt) // rd, rs1 - zero extend halfword (also in Zbb)
  MAX(UInt, UInt, UInt) // rd, rs1, rs2 - maximum (signed)
  MAXU(UInt, UInt, UInt) // rd, rs1, rs2 - maximum (unsigned)
  MIN(UInt, UInt, UInt) // rd, rs1, rs2 - minimum (signed)
  MINU(UInt, UInt, UInt) // rd, rs1, rs2 - minimum (unsigned)
  ROL(UInt, UInt, UInt) // rd, rs1, rs2 - rotate left
  ROR(UInt, UInt, UInt) // rd, rs1, rs2 - rotate right
  RORI(UInt, UInt, UInt) // rd, rs1, shamt - rotate right immediate
  ORC_B(UInt, UInt) // rd, rs1 - OR combine bytes
  REV8(UInt, UInt) // rd, rs1 - byte reverse
  // Zbc extension (carry-less multiplication)
  CLMUL(UInt, UInt, UInt) // rd, rs1, rs2 - carry-less multiply low
  CLMULH(UInt, UInt, UInt) // rd, rs1, rs2 - carry-less multiply high
  CLMULR(UInt, UInt, UInt) // rd, rs1, rs2 - carry-less multiply reversed
  // Zbs extension (single bit instructions)
  BCLR(UInt, UInt, UInt) // rd, rs1, rs2 - bit clear
  BCLRI(UInt, UInt, UInt) // rd, rs1, shamt - bit clear immediate
  BEXT(UInt, UInt, UInt) // rd, rs1, rs2 - bit extract
  BEXTI(UInt, UInt, UInt) // rd, rs1, shamt - bit extract immediate
  BINV(UInt, UInt, UInt) // rd, rs1, rs2 - bit invert
  BINVI(UInt, UInt, UInt) // rd, rs1, shamt - bit invert immediate
  BSET(UInt, UInt, UInt) // rd, rs1, rs2 - bit set
  BSETI(UInt, UInt, UInt) // rd, rs1, shamt - bit set immediate
  // Unknown/invalid instruction
  Invalid(UInt) // code
} derive(Show)

///|
/// Instruction category for analysis
pub enum InstructionCategory {
  Arithmetic
  Logical
  Compare
  Branch
  Jump
  Load
  Store
  System
  Unknown
} derive(Show, Eq)

///|
/// Get the category of an instruction
pub fn Instruction::category(self : Instruction) -> InstructionCategory {
  match self {
    LUI(_, _) => InstructionCategory::Arithmetic
    AUIPC(_, _) => InstructionCategory::Arithmetic
    JAL(_, _) => InstructionCategory::Jump
    JALR(_, _, _) => InstructionCategory::Jump
    BEQ(_, _, _)
    | BNE(_, _, _)
    | BLT(_, _, _)
    | BGE(_, _, _)
    | BLTU(_, _, _)
    | BGEU(_, _, _) => InstructionCategory::Branch
    LB(_, _, _) | LH(_, _, _) | LW(_, _, _) | LBU(_, _, _) | LHU(_, _, _) =>
      InstructionCategory::Load
    SB(_, _, _) | SH(_, _, _) | SW(_, _, _) => InstructionCategory::Store
    ADDI(_, _, _) | SLLI(_, _, _) | SRLI(_, _, _) | SRAI(_, _, _) =>
      InstructionCategory::Arithmetic
    SLTI(_, _, _) | SLTIU(_, _, _) => InstructionCategory::Compare
    XORI(_, _, _) | ORI(_, _, _) | ANDI(_, _, _) => InstructionCategory::Logical
    ADD(_, _, _)
    | SUB(_, _, _)
    | SLL(_, _, _)
    | MUL(_, _, _)
    | MULH(_, _, _)
    | MULHSU(_, _, _)
    | MULHU(_, _, _)
    | DIV(_, _, _)
    | DIVU(_, _, _)
    | REM(_, _, _)
    | REMU(_, _, _) => InstructionCategory::Arithmetic
    SLT(_, _, _) | SLTU(_, _, _) => InstructionCategory::Compare
    XOR(_, _, _) | SRL(_, _, _) | SRA(_, _, _) | OR(_, _, _) | AND(_, _, _) =>
      InstructionCategory::Logical
    // RV64I instructions
    LD(_, _, _) | LWU(_, _, _) => InstructionCategory::Load
    SD(_, _, _) => InstructionCategory::Store
    ADDIW(_, _, _)
    | SLLIW(_, _, _)
    | SRLIW(_, _, _)
    | SRAIW(_, _, _)
    | ADDW(_, _, _)
    | SUBW(_, _, _)
    | SLLW(_, _, _)
    | SRLW(_, _, _)
    | SRAW(_, _, _) => InstructionCategory::Arithmetic
    // RV64M instructions
    MULW(_, _, _)
    | DIVW(_, _, _)
    | DIVUW(_, _, _)
    | REMW(_, _, _)
    | REMUW(_, _, _) => InstructionCategory::Arithmetic
    // RV32A/RV64A atomic instructions
    LR_W(_, _, _, _) | LR_D(_, _, _, _) => InstructionCategory::Load
    SC_W(_, _, _, _, _) | SC_D(_, _, _, _, _) => InstructionCategory::Store
    AMOSWAP_W(_, _, _, _, _)
    | AMOADD_W(_, _, _, _, _)
    | AMOXOR_W(_, _, _, _, _)
    | AMOAND_W(_, _, _, _, _)
    | AMOOR_W(_, _, _, _, _)
    | AMOMIN_W(_, _, _, _, _)
    | AMOMAX_W(_, _, _, _, _)
    | AMOMINU_W(_, _, _, _, _)
    | AMOMAXU_W(_, _, _, _, _)
    | AMOSWAP_D(_, _, _, _, _)
    | AMOADD_D(_, _, _, _, _)
    | AMOXOR_D(_, _, _, _, _)
    | AMOAND_D(_, _, _, _, _)
    | AMOOR_D(_, _, _, _, _)
    | AMOMIN_D(_, _, _, _, _)
    | AMOMAX_D(_, _, _, _, _)
    | AMOMINU_D(_, _, _, _, _)
    | AMOMAXU_D(_, _, _, _, _) => InstructionCategory::Arithmetic
    FENCE(_, _) | FENCE_I => InstructionCategory::System
    ECALL | EBREAK => InstructionCategory::System
    // RV32C compressed instructions
    C_NOP
    | C_ADDI(_, _)
    | C_LI(_, _)
    | C_ADDI16SP(_)
    | C_LUI(_, _)
    | C_SRLI(_, _)
    | C_SRAI(_, _)
    | C_ADDI4SPN(_, _)
    | C_SLLI(_, _) => InstructionCategory::Arithmetic
    C_ANDI(_, _) | C_AND(_, _) | C_OR(_, _) | C_XOR(_, _) =>
      InstructionCategory::Logical
    C_J(_) | C_JAL(_) | C_JR(_) | C_JALR(_) => InstructionCategory::Jump
    C_BEQZ(_, _) | C_BNEZ(_, _) => InstructionCategory::Branch
    C_LW(_, _, _) | C_LWSP(_, _) => InstructionCategory::Load
    C_SW(_, _, _) | C_SWSP(_, _) => InstructionCategory::Store
    C_MV(_, _) => InstructionCategory::Arithmetic
    C_ADD(_, _) => InstructionCategory::Arithmetic
    C_SUB(_, _) => InstructionCategory::Arithmetic
    C_EBREAK => InstructionCategory::System
    // Zicsr instructions
    CSRRW(_, _, _)
    | CSRRS(_, _, _)
    | CSRRC(_, _, _)
    | CSRRWI(_, _, _)
    | CSRRSI(_, _, _)
    | CSRRCI(_, _, _) => InstructionCategory::System
    // Zba extension (address generation)
    SH1ADD(_, _, _) | SH2ADD(_, _, _) | SH3ADD(_, _, _) =>
      InstructionCategory::Arithmetic
    // Zbb extension (basic bit manipulation)
    ANDN(_, _, _)
    | ORN(_, _, _)
    | XNOR(_, _, _)
    | CLZ(_, _)
    | CTZ(_, _)
    | CPOP(_, _)
    | SEXT_B(_, _)
    | SEXT_H(_, _)
    | ZEXT_H(_, _)
    | MAX(_, _, _)
    | MAXU(_, _, _)
    | MIN(_, _, _)
    | MINU(_, _, _)
    | ROL(_, _, _)
    | ROR(_, _, _)
    | RORI(_, _, _)
    | ORC_B(_, _)
    | REV8(_, _) => InstructionCategory::Logical
    // Zbc extension (carry-less multiplication)
    CLMUL(_, _, _) | CLMULH(_, _, _) | CLMULR(_, _, _) =>
      InstructionCategory::Arithmetic
    // Zbs extension (single bit instructions)
    BCLR(_, _, _)
    | BCLRI(_, _, _)
    | BEXT(_, _, _)
    | BEXTI(_, _, _)
    | BINV(_, _, _)
    | BINVI(_, _, _)
    | BSET(_, _, _)
    | BSETI(_, _, _) => InstructionCategory::Logical
    Invalid(_) => InstructionCategory::Unknown
  }
}

///|
/// Check if instruction is a branch
pub fn Instruction::is_branch(self : Instruction) -> Bool {
  match self {
    BEQ(_, _, _)
    | BNE(_, _, _)
    | BLT(_, _, _)
    | BGE(_, _, _)
    | BLTU(_, _, _)
    | BGEU(_, _, _)
    | C_BEQZ(_, _)
    | C_BNEZ(_, _) => true
    _ => false
  }
}

///|
/// Check if instruction is a jump
pub fn Instruction::is_jump(self : Instruction) -> Bool {
  match self {
    JAL(_, _) | JALR(_, _, _) | C_J(_) | C_JAL(_) | C_JR(_) | C_JALR(_) => true
    _ => false
  }
}

///|
/// Check if instruction modifies control flow
pub fn Instruction::is_control_flow(self : Instruction) -> Bool {
  self.is_branch() || self.is_jump()
}

///|
/// Get branch target offset (returns 0 if not a branch)
pub fn Instruction::branch_offset(self : Instruction) -> Int {
  match self {
    // Standard branch instructions
    BEQ(_, _, imm) => imm
    BNE(_, _, imm) => imm
    BLT(_, _, imm) => imm
    BGE(_, _, imm) => imm
    BLTU(_, _, imm) => imm
    BGEU(_, _, imm) => imm
    // Standard jump instructions
    JAL(_, imm) => imm
    JALR(_, _, imm) => imm
    // Compressed jump instructions
    C_J(imm) => imm
    C_JAL(imm) => imm
    // Compressed branch instructions
    C_BEQZ(_, imm) => imm
    C_BNEZ(_, imm) => imm
    // Others
    _ => 0
  }
}

///|
/// Register name lookup
pub fn reg_name(reg : UInt) -> String {
  match reg {
    0U => "zero"
    1U => "ra"
    2U => "sp"
    3U => "gp"
    4U => "tp"
    5U => "t0"
    6U => "t1"
    7U => "t2"
    8U => "s0"
    9U => "s1"
    10U => "a0"
    11U => "a1"
    12U => "a2"
    13U => "a3"
    14U => "a4"
    15U => "a5"
    16U => "a6"
    17U => "a7"
    18U => "s2"
    19U => "s3"
    20U => "s4"
    21U => "s5"
    22U => "s6"
    23U => "s7"
    24U => "s8"
    25U => "s9"
    26U => "s10"
    27U => "s11"
    28U => "t3"
    29U => "t4"
    30U => "t5"
    31U => "t6"
    _ => "unknown"
  }
}
