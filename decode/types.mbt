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
  // Fence instructions
  FENCE(UInt, UInt) // pred, succ
  FENCE_I
  // System instructions
  ECALL
  EBREAK
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
    ADD(_, _, _) | SUB(_, _, _) | SLL(_, _, _) | SLT(_, _, _) | SLTU(_, _, _) =>
      InstructionCategory::Arithmetic
    XOR(_, _, _) | SRL(_, _, _) | SRA(_, _, _) | OR(_, _, _) | AND(_, _, _) =>
      InstructionCategory::Logical
    FENCE(_, _) | FENCE_I => InstructionCategory::System
    ECALL | EBREAK => InstructionCategory::System
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
    | BGEU(_, _, _) => true
    _ => false
  }
}

///|
/// Check if instruction is a jump
pub fn Instruction::is_jump(self : Instruction) -> Bool {
  match self {
    JAL(_, _) | JALR(_, _, _) => true
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
    BEQ(_, _, imm) => imm
    BNE(_, _, imm) => imm
    BLT(_, _, imm) => imm
    BGE(_, _, imm) => imm
    BLTU(_, _, imm) => imm
    BGEU(_, _, imm) => imm
    JAL(_, imm) => imm
    JALR(_, _, imm) => imm
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
