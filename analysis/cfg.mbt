///| Control Flow Graph (CFG) analysis for RISC-V

///| Provides basic block identification and CFG construction

///|
/// A basic block is a sequence of instructions with a single entry and exit
pub struct BasicBlock {
  /// Starting address of the block
  start_addr : UInt
  /// Ending address of the block (address of last instruction)
  end_addr : UInt
  /// Number of instructions in this block
  instruction_count : Int
  /// Whether this block ends with a terminator (branch/jump)
  is_terminated : Bool
} derive(Show)

///|
/// Control flow edge type
pub enum EdgeType {
  /// Sequential fall-through
  FallThrough
  /// Unconditional jump
  Jump
  /// Conditional branch (taken)
  BranchTaken
  /// Conditional branch (not taken, fall-through)
  BranchNotTaken
  /// Function call
  Call
  /// Function return
  Return
} derive(Show, Eq)

///|
/// A control flow edge between basic blocks
pub struct Edge {
  from_block : UInt // Start address of source block
  to_block : UInt // Start address of target block
  edge_type : EdgeType
} derive(Show)

///|
/// Control Flow Graph
pub struct CFG {
  /// All basic blocks
  blocks : FixedArray[BasicBlock]
  /// All edges in the graph
  edges : FixedArray[Edge]
  /// Entry points (function starts)
  entry_points : FixedArray[UInt]
} derive(Show)

///|
/// Create an empty CFG
pub fn CFG::new() -> CFG {
  { blocks: [], edges: [], entry_points: [] }
}

///|
/// Check if an instruction is a basic block terminator
pub fn is_terminator(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.JAL(_, _) => true
    @decode.JALR(_, _, _) => true
    @decode.BEQ(_, _, _) => true
    @decode.BNE(_, _, _) => true
    @decode.BLT(_, _, _) => true
    @decode.BGE(_, _, _) => true
    @decode.BLTU(_, _, _) => true
    @decode.BGEU(_, _, _) => true
    @decode.ECALL => true
    @decode.EBREAK => true
    _ => false
  }
}

///|
/// Get branch target offset (relative offset)
pub fn get_branch_target(inst : @decode.Instruction) -> Int {
  match inst {
    @decode.BEQ(_, _, imm) => imm
    @decode.BNE(_, _, imm) => imm
    @decode.BLT(_, _, imm) => imm
    @decode.BGE(_, _, imm) => imm
    @decode.BLTU(_, _, imm) => imm
    @decode.BGEU(_, _, imm) => imm
    @decode.JAL(_, imm) => imm
    @decode.JALR(_, _, imm) => imm
    _ => 0
  }
}

///|
/// Check if instruction is a conditional branch
pub fn is_conditional_branch(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.BEQ(_, _, _) => true
    @decode.BNE(_, _, _) => true
    @decode.BLT(_, _, _) => true
    @decode.BGE(_, _, _) => true
    @decode.BLTU(_, _, _) => true
    @decode.BGEU(_, _, _) => true
    _ => false
  }
}

///|
/// Check if instruction is an unconditional jump
pub fn is_unconditional_jump(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.JAL(_, _) => true
    @decode.JALR(_, _, _) => true
    _ => false
  }
}

///|
/// Check if instruction is a function call (JAL/JALR with link register)
pub fn is_call(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.JAL(rd, _) => rd == 1U || rd == 5U // JAL ra or JAL t0
    @decode.JALR(rd, _, _) => rd == 1U || rd == 5U
    _ => false
  }
}

///|
/// Check if instruction is a function return
pub fn is_return(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.JALR(rd, rs1, _) => rd == 0U && rs1 == 1U // JALR x0, ra, 0 (ret)
    _ => false
  }
}
