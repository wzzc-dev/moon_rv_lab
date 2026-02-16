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

///|
/// A decoded instruction with its address
pub struct DecodedInst {
  addr : UInt
  inst : @decode.Instruction
  code : UInt
} derive(Show)

///|
/// Decode instructions from bytes starting at a given address
pub fn decode_instructions(
  bytes : FixedArray[Byte],
  start_addr : UInt,
) -> FixedArray[DecodedInst] {
  let result : Array[DecodedInst] = []
  let len = bytes.length()
  let mut addr = start_addr
  let mut i = 0
  while i + 3 < len {
    // Read 4 bytes as little-endian 32-bit instruction
    let code = bytes[i].to_uint() |
      (bytes[i + 1].to_uint() << 8) |
      (bytes[i + 2].to_uint() << 16) |
      (bytes[i + 3].to_uint() << 24)
    let @decode.DecodeResult(inst) = @decode.decode(code)
    result.push(DecodedInst::{ addr, inst, code })
    i = i + 4
    addr = addr + 4U
  }
  FixedArray::from_array(result)
}

///|
/// Sort and deduplicate an array of UInts
fn sort_dedup(arr : Array[UInt]) -> Array[UInt] {
  arr.sort()
  if arr.length() == 0 {
    return arr
  }
  let result : Array[UInt] = []
  let mut prev : UInt? = None
  for v in arr {
    match prev {
      Some(p) =>
        if v != p {
          result.push(v)
          prev = Some(v)
        }
      None => {
        result.push(v)
        prev = Some(v)
      }
    }
  }
  result
}

///|
/// Compute branch target address
fn compute_target_addr(addr : UInt, offset : Int) -> UInt {
  // Convert UInt to Int for signed arithmetic
  let addr_int = addr.reinterpret_as_int()
  let target = addr_int + offset
  // Convert back to UInt
  target.reinterpret_as_uint()
}

///|
/// Build CFG from decoded instructions
pub fn build_cfg(
  instructions : FixedArray[DecodedInst],
  entry_addr : UInt,
) -> CFG {
  if instructions.length() == 0 {
    return { blocks: [], edges: [], entry_points: [entry_addr] }
  }

  // Find basic block leaders (entry points and branch targets)
  let leaders : Array[UInt] = []
  leaders.push(entry_addr)

  for inst_info in instructions {
    let addr = inst_info.addr
    if is_terminator(inst_info.inst) {
      // The instruction after a terminator starts a new block
      let next_addr = addr + 4U
      leaders.push(next_addr)
      // Branch target is also a leader
      if is_conditional_branch(inst_info.inst) ||
        is_unconditional_jump(inst_info.inst) {
        let target_offset = get_branch_target(inst_info.inst)
        let target_addr = compute_target_addr(addr, target_offset)
        leaders.push(target_addr)
      }
    }
  }

  // Sort and deduplicate leaders
  let sorted_leaders = sort_dedup(leaders)

  // Build basic blocks
  let blocks : Array[BasicBlock] = []
  let edges : Array[Edge] = []

  for i = 0; i < sorted_leaders.length(); i = i + 1 {
    let start_addr = sorted_leaders[i]
    // Find the end of this block (next leader - 4 or terminator)
    let end_addr = if i + 1 < sorted_leaders.length() {
      sorted_leaders[i + 1] - 4U
    } else {
      instructions[instructions.length() - 1].addr
    }

    // Find instructions in this block
    let mut inst_count = 0
    let mut is_terminated = false
    let mut actual_end = start_addr

    for inst_info in instructions {
      if inst_info.addr >= start_addr && inst_info.addr <= end_addr {
        inst_count = inst_count + 1
        actual_end = inst_info.addr
        if is_terminator(inst_info.inst) {
          is_terminated = true
          // Add edges based on terminator type
          if is_conditional_branch(inst_info.inst) {
            let target_offset = get_branch_target(inst_info.inst)
            let target_addr = compute_target_addr(inst_info.addr, target_offset)
            edges.push(Edge::{
              from_block: start_addr,
              to_block: target_addr,
              edge_type: EdgeType::BranchTaken,
            })
            // Fall-through edge
            let fallthrough_addr = inst_info.addr + 4U
            edges.push(Edge::{
              from_block: start_addr,
              to_block: fallthrough_addr,
              edge_type: EdgeType::BranchNotTaken,
            })
          } else if is_unconditional_jump(inst_info.inst) {
            let target_offset = get_branch_target(inst_info.inst)
            let target_addr = compute_target_addr(inst_info.addr, target_offset)
            if is_call(inst_info.inst) {
              edges.push(Edge::{
                from_block: start_addr,
                to_block: target_addr,
                edge_type: EdgeType::Call,
              })
            } else {
              edges.push(Edge::{
                from_block: start_addr,
                to_block: target_addr,
                edge_type: EdgeType::Jump,
              })
            }
          } else if is_return(inst_info.inst) {
            edges.push(Edge::{
              from_block: start_addr,
              to_block: 0U,
              edge_type: EdgeType::Return,
            })
          }
          break
        }
      }
    }

    if inst_count > 0 {
      blocks.push(BasicBlock::{
        start_addr,
        end_addr: actual_end,
        instruction_count: inst_count,
        is_terminated,
      })
    }
  }

  {
    blocks: FixedArray::from_array(blocks),
    edges: FixedArray::from_array(edges),
    entry_points: [entry_addr],
  }
}

///|
/// Analyze a binary code buffer and return CFG
pub fn analyze_code(bytes : FixedArray[Byte], start_addr : UInt) -> CFG {
  let instructions = decode_instructions(bytes, start_addr)
  build_cfg(instructions, start_addr)
}

///|
/// Convert UInt to hex string (without 0x prefix)
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut v = value
    while v > 0U {
      let digit = (v % 16U).reinterpret_as_int()
      let c = if digit < 10 {
        (digit + 48).unsafe_to_char() // '0' is 48
      } else {
        (digit + 87).unsafe_to_char() // 'a' is 97, so digit - 10 + 97 = digit + 87
      }
      result = c.to_string() + result
      v = v / 16U
    }
    result
  }
}

///|
/// Format a UInt as hex string
fn format_hex_uint(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
/// Find all function entry points (potential function starts)
pub fn find_entry_points(cfg : CFG) -> FixedArray[UInt] {
  // Entry points are blocks with no incoming edges or marked as entry
  // Collect all block start addresses
  let block_starts : Array[UInt] = []
  for block in cfg.blocks {
    block_starts.push(block.start_addr)
  }
  // Collect all edge targets
  let edge_targets : Array[UInt] = []
  for edge in cfg.edges {
    edge_targets.push(edge.to_block)
  }
  // Find blocks that are not targets of any edge
  let entries : Array[UInt] = []
  for addr in block_starts {
    let mut is_target = false
    for target in edge_targets {
      if target == addr {
        is_target = true
      }
    }
    if !is_target {
      entries.push(addr)
    }
  }
  entries.sort()
  FixedArray::from_array(entries)
}

///|
/// Print CFG for debugging
pub fn print_cfg(cfg : CFG) -> Unit {
  println("=== Control Flow Graph ===")
  println("Basic Blocks: \{cfg.blocks.length()}")
  for block in cfg.blocks {
    println(
      "  [\{format_hex_uint(block.start_addr)} - \{format_hex_uint(block.end_addr)}] \{block.instruction_count} instructions, terminated: \{block.is_terminated}",
    )
  }
  println("Edges: \{cfg.edges.length()}")
  for edge in cfg.edges {
    let type_str = match edge.edge_type {
      FallThrough => "FallThrough"
      Jump => "Jump"
      BranchTaken => "BranchTaken"
      BranchNotTaken => "BranchNotTaken"
      Call => "Call"
      Return => "Return"
    }
    println(
      "  \{format_hex_uint(edge.from_block)} -> \{format_hex_uint(edge.to_block)} (\{type_str})",
    )
  }
}
