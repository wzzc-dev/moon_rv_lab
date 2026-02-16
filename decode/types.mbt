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
    ADDI(_, _, _)
    | SLTI(_, _, _)
    | SLTIU(_, _, _)
    | SLLI(_, _, _)
    | SRLI(_, _, _)
    | SRAI(_, _, _) => InstructionCategory::Arithmetic
    XORI(_, _, _) | ORI(_, _, _) | ANDI(_, _, _) => InstructionCategory::Logical
    ADD(_, _, _)
    | SUB(_, _, _)
    | SLL(_, _, _)
    | SLT(_, _, _)
    | SLTU(_, _, _)
    | MUL(_, _, _)
    | MULH(_, _, _)
    | MULHSU(_, _, _)
    | MULHU(_, _, _)
    | DIV(_, _, _)
    | DIVU(_, _, _)
    | REM(_, _, _)
    | REMU(_, _, _) => InstructionCategory::Arithmetic
    XOR(_, _, _) | SRL(_, _, _) | SRA(_, _, _) | OR(_, _, _) | AND(_, _, _) =>
      InstructionCategory::Logical
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
