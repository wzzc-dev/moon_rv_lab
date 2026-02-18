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
    // Standard instructions
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
    // Compressed instructions
    @decode.C_J(_) => true
    @decode.C_JAL(_) => true
    @decode.C_JR(_) => true
    @decode.C_JALR(_) => true
    @decode.C_BEQZ(_, _) => true
    @decode.C_BNEZ(_, _) => true
    @decode.C_EBREAK => true
    _ => false
  }
}

///|
/// Get branch target offset (relative offset)
pub fn get_branch_target(inst : @decode.Instruction) -> Int {
  match inst {
    // Standard branch/jump instructions
    @decode.BEQ(_, _, imm) => imm
    @decode.BNE(_, _, imm) => imm
    @decode.BLT(_, _, imm) => imm
    @decode.BGE(_, _, imm) => imm
    @decode.BLTU(_, _, imm) => imm
    @decode.BGEU(_, _, imm) => imm
    @decode.JAL(_, imm) => imm
    @decode.JALR(_, _, imm) => imm
    // Compressed branch/jump instructions
    @decode.C_J(imm) => imm
    @decode.C_JAL(imm) => imm
    @decode.C_BEQZ(_, imm) => imm
    @decode.C_BNEZ(_, imm) => imm
    _ => 0
  }
}

///|
/// Check if instruction is a conditional branch
pub fn is_conditional_branch(inst : @decode.Instruction) -> Bool {
  match inst {
    // Standard conditional branches
    @decode.BEQ(_, _, _) => true
    @decode.BNE(_, _, _) => true
    @decode.BLT(_, _, _) => true
    @decode.BGE(_, _, _) => true
    @decode.BLTU(_, _, _) => true
    @decode.BGEU(_, _, _) => true
    // Compressed conditional branches
    @decode.C_BEQZ(_, _) => true
    @decode.C_BNEZ(_, _) => true
    _ => false
  }
}

///|
/// Check if instruction is an unconditional jump
pub fn is_unconditional_jump(inst : @decode.Instruction) -> Bool {
  match inst {
    // Standard unconditional jumps
    @decode.JAL(_, _) => true
    @decode.JALR(_, _, _) => true
    // Compressed unconditional jumps
    @decode.C_J(_) => true
    @decode.C_JAL(_) => true
    @decode.C_JR(_) => true
    @decode.C_JALR(_) => true
    _ => false
  }
}

///|
/// Check if instruction is a function call (JAL/JALR with link register)
pub fn is_call(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.JAL(rd, _) => rd == 1U || rd == 5U // JAL ra or JAL t0
    @decode.JALR(rd, _, _) => rd == 1U || rd == 5U
    @decode.C_JAL(_) => true // C.JAL always writes to ra
    @decode.C_JALR(rs1) => rs1 != 0U // C.JALR (not C.JR)
    _ => false
  }
}

///|
/// Check if instruction is a function return
pub fn is_return(inst : @decode.Instruction) -> Bool {
  match inst {
    @decode.JALR(rd, rs1, _) => rd == 0U && rs1 == 1U // JALR x0, ra, 0 (ret)
    @decode.C_JR(rs1) => rs1 == 1U // C.JR ra (ret)
    _ => false
  }
}

///|
/// A decoded instruction with its address
pub struct DecodedInst {
  addr : UInt
  inst : @decode.Instruction
  code : UInt
  /// Instruction length in bytes (2 for compressed, 4 for standard)
  length : Int
} derive(Show)

///|
/// Decode instructions from bytes starting at a given address
/// Supports both 16-bit compressed (RV32C) and 32-bit standard instructions
pub fn decode_instructions(
  bytes : FixedArray[Byte],
  start_addr : UInt,
) -> FixedArray[DecodedInst] {
  let result : Array[DecodedInst] = []
  let len = bytes.length()
  let mut addr = start_addr
  let mut i = 0
  while i < len {
    // Check if this is a compressed instruction (16-bit)
    // Compressed instructions have lowest 2 bits != 0b11
    if i + 1 < len {
      let low_byte = bytes[i].to_uint()
      let quadrant = low_byte & 0x3U

      if quadrant != 0x3U {
        // Compressed instruction (16-bit)
        let code16 = bytes[i].to_uint() | (bytes[i + 1].to_uint() << 8)
        let @decode.DecodeResult(inst) = @decode.decode_compressed(code16)
        result.push(DecodedInst::{ addr, inst, code: code16, length: 2 })
        i = i + 2
        addr = addr + 2U
      } else if i + 3 < len {
        // Standard instruction (32-bit)
        let code = bytes[i].to_uint() |
          (bytes[i + 1].to_uint() << 8) |
          (bytes[i + 2].to_uint() << 16) |
          (bytes[i + 3].to_uint() << 24)
        let @decode.DecodeResult(inst) = @decode.decode(code)
        result.push(DecodedInst::{ addr, inst, code, length: 4 })
        i = i + 4
        addr = addr + 4U
      } else {
        // Not enough bytes for 32-bit instruction
        break
      }
    } else {
      break
    }
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
      let inst_len = inst_info.length.reinterpret_as_uint()
      let next_addr = addr + inst_len
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
    // Find the end of this block (next leader - instruction_size or terminator)
    // We'll find the actual end while scanning instructions
    let max_end_addr = if i + 1 < sorted_leaders.length() {
      sorted_leaders[i + 1] - 2U // Minimum instruction size is 2 bytes
    } else {
      instructions[instructions.length() - 1].addr +
      instructions[instructions.length() - 1].length.reinterpret_as_uint() -
      1U
    }

    // Find instructions in this block
    let mut inst_count = 0
    let mut is_terminated = false
    let mut actual_end = start_addr

    for inst_info in instructions {
      if inst_info.addr >= start_addr && inst_info.addr <= max_end_addr {
        inst_count = inst_count + 1
        actual_end = inst_info.addr
        if is_terminator(inst_info.inst) {
          is_terminated = true
          let inst_len = inst_info.length.reinterpret_as_uint()
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
            let fallthrough_addr = inst_info.addr + inst_len
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
/// Pad a string with leading zeros to reach target length
fn pad_zero(s : String, target_len : Int) -> String {
  let current_len = s.length()
  if current_len >= target_len {
    s
  } else {
    let mut result = ""
    let mut i = 0
    while i < target_len - current_len {
      result = result + "0"
      i = i + 1
    }
    result + s
  }
}

///|
/// Escape a string for JSON output
/// Handles: backslash, double quote, and control characters
fn json_escape(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '\\' => result = result + "\\\\"
      '"' => result = result + "\\\""
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => {
        // Handle other control characters
        let code = c.to_int()
        if code < 32 {
          result = result +
            "\\u" +
            pad_zero(uint_to_hex(code.reinterpret_as_uint()), 4)
        } else {
          result = result + c.to_string()
        }
      }
    }
  } nobreak {
    ignore(())
  }
  result
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

///|
/// Function call graph node
pub struct CallGraphNode {
  /// Function address (entry point)
  address : UInt
  /// Function name (if known)
  name : String
  /// Size of function in bytes
  size : UInt
  /// Addresses of functions called by this function
  calls : FixedArray[UInt]
  /// Addresses of functions that call this function
  called_by : FixedArray[UInt]
} derive(Show)

///|
/// Function call graph
pub struct CallGraph {
  /// All function nodes
  nodes : FixedArray[CallGraphNode]
  /// Entry point address
  entry_point : UInt
} derive(Show)

///|
/// Create an empty call graph
pub fn CallGraph::new() -> CallGraph {
  { nodes: [], entry_point: 0U }
}

///|
/// Function info from analysis
priv struct FuncInfo {
  addr : UInt
  name : String
  size : UInt
  calls : Array[UInt]
}

///|
/// Build call graph from CFG and decoded instructions
pub fn build_call_graph(
  instructions : FixedArray[DecodedInst],
  cfg : CFG,
) -> CallGraph {
  // Find all call edges
  let call_edges : Array[(UInt, UInt)] = [] // (caller_addr, callee_addr)
  let func_starts : Array[UInt] = []

  // Use CFG entry points as function starts
  for addr in cfg.entry_points {
    func_starts.push(addr)
  }

  // Collect call targets from CFG edges
  for edge in cfg.edges {
    if edge.edge_type == EdgeType::Call {
      call_edges.push((edge.from_block, edge.to_block))
      func_starts.push(edge.to_block)
    }
  }

  // Also consider JAL/JALR instructions that look like calls
  for inst_info in instructions {
    if is_call(inst_info.inst) {
      let target_offset = get_branch_target(inst_info.inst)
      let target_addr = compute_target_addr(inst_info.addr, target_offset)
      call_edges.push((inst_info.addr, target_addr))
      func_starts.push(target_addr)
    }
  }

  // Deduplicate function starts
  func_starts.sort()
  let unique_starts : Array[UInt] = []
  let mut prev : UInt? = None
  for addr in func_starts {
    match prev {
      Some(p) =>
        if addr != p {
          unique_starts.push(addr)
          prev = Some(addr)
        }
      None => {
        unique_starts.push(addr)
        prev = Some(addr)
      }
    }
  }

  // Build function info
  let func_infos : Array[FuncInfo] = []
  for i = 0; i < unique_starts.length(); i = i + 1 {
    let addr = unique_starts[i]
    let next_addr = if i + 1 < unique_starts.length() {
      unique_starts[i + 1]
    } else {
      let last_inst = instructions[instructions.length() - 1]
      last_inst.addr + last_inst.length.reinterpret_as_uint()
    }

    // Find symbol name
    let name = format_hex_uint(addr)

    // Find calls from this function
    let calls : Array[UInt] = []
    for edge in call_edges {
      let caller = edge.0
      let callee = edge.1
      if caller >= addr && caller < next_addr && callee != 0U {
        calls.push(callee)
      }
    }

    func_infos.push(FuncInfo::{ addr, name, size: next_addr - addr, calls })
  }

  // Build call graph nodes
  let nodes : Array[CallGraphNode] = []
  for info in func_infos {
    // Deduplicate calls
    let sorted_calls = info.calls
    let unique_calls : Array[UInt] = []
    let mut prev_call : UInt? = None
    for c in sorted_calls {
      match prev_call {
        Some(p) =>
          if c != p {
            unique_calls.push(c)
            prev_call = Some(c)
          }
        None => {
          unique_calls.push(c)
          prev_call = Some(c)
        }
      }
    }

    nodes.push(CallGraphNode::{
      address: info.addr,
      name: info.name,
      size: info.size,
      calls: FixedArray::from_array(unique_calls),
      called_by: [],
    })
  }

  // Find entry point
  let entry = if cfg.entry_points.length() > 0 {
    cfg.entry_points[0]
  } else if nodes.length() > 0 {
    nodes[0].address
  } else {
    0U
  }

  CallGraph::{ nodes: FixedArray::from_array(nodes), entry_point: entry }
}

///|
/// Print call graph for debugging
pub fn print_call_graph(cg : CallGraph) -> Unit {
  println("=== Call Graph ===")
  println("Entry Point: \{format_hex_uint(cg.entry_point)}")
  println("Functions: \{cg.nodes.length()}")
  for node in cg.nodes {
    println(
      "  \{node.name} (\{format_hex_uint(node.address)}, size=\{node.size.reinterpret_as_int()})",
    )
    if node.calls.length() > 0 {
      let mut calls_str = "    calls: "
      for i = 0; i < node.calls.length(); i = i + 1 {
        if i > 0 {
          calls_str = calls_str + ", "
        }
        calls_str = calls_str + format_hex_uint(node.calls[i])
      }
      println(calls_str)
    }
    if node.called_by.length() > 0 {
      let mut called_by_str = "    called_by: "
      for i = 0; i < node.called_by.length(); i = i + 1 {
        if i > 0 {
          called_by_str = called_by_str + ", "
        }
        called_by_str = called_by_str + format_hex_uint(node.called_by[i])
      }
      println(called_by_str)
    }
  }
}

///|
/// Find all functions reachable from entry point
pub fn reachable_functions(cg : CallGraph) -> FixedArray[UInt] {
  let visited : Array[UInt] = []
  let stack : Array[UInt] = [cg.entry_point]

  while stack.length() > 0 {
    match stack.pop() {
      Some(addr) => {
        let mut already_visited = false
        for v in visited {
          if v == addr {
            already_visited = true
            break
          }
        }
        if already_visited {
          continue
        }
        visited.push(addr)

        // Find node and add its calls to stack
        for node in cg.nodes {
          if node.address == addr {
            for callee in node.calls {
              stack.push(callee)
            }
            break
          }
        }
      }
      None => ignore(())
    }
  }

  visited.sort()
  FixedArray::from_array(visited)
}

///|
/// Generate DOT format for CFG visualization
pub fn cfg_to_dot(cfg : CFG, name : String) -> String {
  let escaped_name = json_escape(name)
  let mut result = "digraph \"\{escaped_name}\" {\n"
  result = result + "  rankdir=TB;\n"
  result = result + "  node [shape=box];\n"
  result = result + "  edge [fontsize=10];\n\n"

  // Generate nodes (basic blocks)
  result = result + "  // Basic blocks\n"
  for block in cfg.blocks {
    let addr = format_hex_uint(block.start_addr)
    let end_addr = format_hex_uint(block.end_addr)
    let label = "\{addr}\\n\{block.instruction_count} insts"
    result = result + "  bb_\{addr} [label=\"\{label}\""
    // Mark entry blocks
    let mut is_entry = false
    for entry in cfg.entry_points {
      if entry == block.start_addr {
        is_entry = true
        break
      }
    }
    if is_entry {
      result = result + ", style=filled, fillcolor=lightgreen"
    }
    result = result + "];\n"
  }

  result = result + "\n  // Edges\n"
  for edge in cfg.edges {
    let from_addr = format_hex_uint(edge.from_block)
    let to_addr = format_hex_uint(edge.to_block)
    let (style, color, label) = match edge.edge_type {
      EdgeType::FallThrough => ("solid", "black", "fall")
      EdgeType::Jump => ("solid", "blue", "jmp")
      EdgeType::BranchTaken => ("solid", "green", "taken")
      EdgeType::BranchNotTaken => ("solid", "red", "not taken")
      EdgeType::Call => ("dashed", "purple", "call")
      EdgeType::Return => ("dotted", "gray", "ret")
    }
    result = result +
      "  bb_\{from_addr} -> bb_\{to_addr} [style=\{style}, color=\{color}, label=\"\{label}\"];\n"
  }

  result = result + "}\n"
  result
}

///|
/// Generate DOT format for call graph visualization
pub fn callgraph_to_dot(cg : CallGraph, name : String) -> String {
  let escaped_name = json_escape(name)
  let mut result = "digraph \"\{escaped_name}_callgraph\" {\n"
  result = result + "  rankdir=LR;\n"
  result = result + "  node [shape=ellipse];\n"
  result = result + "  edge [fontsize=10];\n\n"

  // Generate nodes (functions)
  result = result + "  // Functions\n"
  for node in cg.nodes {
    let addr = format_hex_uint(node.address)
    let escaped_node_name = json_escape(node.name)
    let label = if node.name == addr {
      "func_\{addr}"
    } else {
      escaped_node_name
    }
    result = result + "  func_\{addr} [label=\"\{label}\""
    // Mark entry point
    if node.address == cg.entry_point {
      result = result + ", style=filled, fillcolor=lightgreen"
    }
    result = result + "];\n"
  }

  result = result + "\n  // Call edges\n"
  for node in cg.nodes {
    let caller_addr = format_hex_uint(node.address)
    for callee in node.calls {
      let callee_addr = format_hex_uint(callee)
      result = result + "  func_\{caller_addr} -> func_\{callee_addr};\n"
    }
  }

  result = result + "}\n"
  result
}

///|
/// Generate JSON format for CFG
pub fn cfg_to_json(cfg : CFG) -> String {
  let mut result = "{\n"
  result = result + "  \"blocks\": [\n"

  for i = 0; i < cfg.blocks.length(); i = i + 1 {
    let block = cfg.blocks[i]
    if i > 0 {
      result = result + ",\n"
    }
    result = result + "    {\n"
    result = result +
      "      \"start_addr\": \"\{format_hex_uint(block.start_addr)}\",\n"
    result = result +
      "      \"end_addr\": \"\{format_hex_uint(block.end_addr)}\",\n"
    result = result +
      "      \"instruction_count\": \{block.instruction_count},\n"
    result = result + "      \"is_terminated\": \{block.is_terminated}\n"
    result = result + "    }"
  }

  result = result + "\n  ],\n"
  result = result + "  \"edges\": [\n"

  for i = 0; i < cfg.edges.length(); i = i + 1 {
    let edge = cfg.edges[i]
    if i > 0 {
      result = result + ",\n"
    }
    let type_str = match edge.edge_type {
      EdgeType::FallThrough => "FallThrough"
      EdgeType::Jump => "Jump"
      EdgeType::BranchTaken => "BranchTaken"
      EdgeType::BranchNotTaken => "BranchNotTaken"
      EdgeType::Call => "Call"
      EdgeType::Return => "Return"
    }
    result = result + "    {\n"
    result = result +
      "      \"from\": \"\{format_hex_uint(edge.from_block)}\",\n"
    result = result + "      \"to\": \"\{format_hex_uint(edge.to_block)}\",\n"
    result = result + "      \"type\": \"\{type_str}\"\n"
    result = result + "    }"
  }

  result = result + "\n  ],\n"
  result = result + "  \"entry_points\": [\n"

  for i = 0; i < cfg.entry_points.length(); i = i + 1 {
    if i > 0 {
      result = result + ", "
    }
    result = result + "\"\{format_hex_uint(cfg.entry_points[i])}\""
  }

  result = result + "\n  ]\n"
  result = result + "}\n"
  result
}

///|
/// Generate JSON format for call graph
pub fn callgraph_to_json(cg : CallGraph) -> String {
  let mut result = "{\n"
  result = result +
    "  \"entry_point\": \"\{format_hex_uint(cg.entry_point)}\",\n"
  result = result + "  \"functions\": [\n"

  for i = 0; i < cg.nodes.length(); i = i + 1 {
    let node = cg.nodes[i]
    if i > 0 {
      result = result + ",\n"
    }
    result = result + "    {\n"
    result = result +
      "      \"address\": \"\{format_hex_uint(node.address)}\",\n"
    result = result + "      \"name\": \"\{json_escape(node.name)}\",\n"
    result = result + "      \"size\": \{node.size.reinterpret_as_int()},\n"
    result = result + "      \"calls\": ["

    for j = 0; j < node.calls.length(); j = j + 1 {
      if j > 0 {
        result = result + ", "
      }
      result = result + "\"\{format_hex_uint(node.calls[j])}\""
    }

    result = result + "],\n"
    result = result + "      \"called_by\": ["

    for j = 0; j < node.called_by.length(); j = j + 1 {
      if j > 0 {
        result = result + ", "
      }
      result = result + "\"\{format_hex_uint(node.called_by[j])}\""
    }

    result = result + "]\n"
    result = result + "    }"
  }

  result = result + "\n  ]\n"
  result = result + "}\n"
  result
}
