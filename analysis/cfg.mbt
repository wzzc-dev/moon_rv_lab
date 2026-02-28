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
pub fn uint_to_hex(value : UInt) -> String {
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
pub fn format_hex_uint(value : UInt) -> String {
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

  // Build call graph nodes - first pass: create nodes with empty called_by
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

  // Build called_by relationships - second pass
  // Create a map from address to index for efficient lookup
  let addr_to_idx : Array[(UInt, Int)] = []
  for i = 0; i < nodes.length(); i = i + 1 {
    addr_to_idx.push((nodes[i].address, i))
  }

  // Collect called_by info for each node
  let called_by_map : Array[Array[UInt]] = []
  for i = 0; i < nodes.length(); i = i + 1 {
    called_by_map.push([])
  }

  for i = 0; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    for callee_addr in node.calls {
      // Find the callee node index
      for j = 0; j < nodes.length(); j = j + 1 {
        if nodes[j].address == callee_addr {
          called_by_map[j].push(node.address)
          break
        }
      }
    }
  }

  // Deduplicate and sort called_by arrays, then update nodes
  let final_nodes : Array[CallGraphNode] = []
  for i = 0; i < nodes.length(); i = i + 1 {
    let node = nodes[i]
    // Sort the called_by array
    let called_by_arr = called_by_map[i]
    called_by_arr.sort()
    // Deduplicate
    let unique_called_by : Array[UInt] = []
    let mut prev : UInt? = None
    for c in called_by_arr {
      match prev {
        Some(p) =>
          if c != p {
            unique_called_by.push(c)
            prev = Some(c)
          }
        None => {
          unique_called_by.push(c)
          prev = Some(c)
        }
      }
    }
    final_nodes.push(CallGraphNode::{
      address: node.address,
      name: node.name,
      size: node.size,
      calls: node.calls,
      called_by: FixedArray::from_array(unique_called_by),
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

  CallGraph::{ nodes: FixedArray::from_array(final_nodes), entry_point: entry }
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
    let _end_addr = format_hex_uint(block.end_addr)
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

// ============================================================================
// Indirect Jump Resolution
// ============================================================================

///|
/// Jump table type
pub enum JumpTableType {
  /// Simple table: each entry is a direct address
  Simple
  /// Relative table: each entry is offset from table base
  Relative
  /// PC-relative table: each entry is offset from its own address
  PCRelative
} derive(Show, Eq)

///|
/// Placeholder to suppress unused constructor warnings
fn _jump_table_type_placeholder() -> JumpTableType {
  let _ = Relative
  let _ = PCRelative
  Simple
}

///|
/// Jump table information
pub struct JumpTable {
  /// Base address of the jump table in memory
  base_addr : UInt
  /// Number of entries in the table
  entry_count : Int
  /// Size of each entry in bytes (typically 4 for 32-bit, 8 for 64-bit)
  entry_size : Int
  /// Type of jump table
  table_type : JumpTableType
  /// Calculated target addresses
  targets : FixedArray[UInt]
  /// Address of the instruction that uses this table
  jump_inst_addr : UInt
} derive(Show)

///|
/// Indirect call information
pub struct IndirectCall {
  /// Address of the indirect call instruction
  addr : UInt
  /// Register used for indirect call
  reg : UInt
  /// Possible target addresses (if resolvable)
  possible_targets : FixedArray[UInt]
  /// Source of the function pointer
  pointer_source : PointerSource
} derive(Show)

///|
/// Source of function pointer
pub enum PointerSource {
  /// Loaded from a global variable
  Global(UInt)
  /// Loaded from a virtual table
  VTable(UInt, Int) // vtable_addr, offset
  /// Passed as function argument
  Argument(Int) // argument index
  /// Return value from another function
  ReturnValue(UInt) // caller_addr
  /// Computed from register
  Register(UInt)
  /// Unknown source
  Unknown
} derive(Show, Eq)

///|
/// Placeholder to suppress unused constructor warnings
fn _pointer_source_placeholder() -> PointerSource {
  let _ = PointerSource::VTable(0U, 0)
  let _ = PointerSource::ReturnValue(0U)
  PointerSource::Unknown
}

///|
/// Tail call information
pub struct TailCall {
  /// Address of the tail call instruction
  addr : UInt
  /// Target function address (if resolvable)
  target : UInt?
  /// Whether this is a computed tail call
  is_indirect : Bool
  /// Register used for indirect tail call
  reg : UInt?
} derive(Show)

///|
/// Indirect jump resolution result
pub struct IndirectJumpInfo {
  /// Detected jump tables
  jump_tables : FixedArray[JumpTable]
  /// Detected indirect calls
  indirect_calls : FixedArray[IndirectCall]
  /// Detected tail calls
  tail_calls : FixedArray[TailCall]
} derive(Show)

///|
/// Pattern match result for jump table detection
/// Note: Currently used for future jump table pattern matching improvements
priv struct PatternMatch {
  table_base_reg : UInt
  index_reg : UInt
  scale : Int
  table_addr : UInt?
  found : Bool
}

///|
/// Placeholder to suppress unused type warning
fn _pattern_match_placeholder() -> PatternMatch {
  let pm = {
    table_base_reg: 0U,
    index_reg: 0U,
    scale: 0,
    table_addr: None,
    found: false,
  }
  // Use all fields to suppress warnings
  let _ = pm.table_base_reg
  let _ = pm.index_reg
  let _ = pm.scale
  let _ = pm.table_addr
  let _ = pm.found
  pm
}

///|
/// Detect jump table pattern in a sequence of instructions
/// 
/// Common RISC-V jump table patterns:
/// 1. Simple table:
///    la      t0, table_base
///    slli    t1, a0, 2        # index * 4
///    add     t0, t0, t1       # table_base + offset
///    lw      t0, 0(t0)        # load target
///    jr      t0               # jump to target
///
/// 2. AUIPC + ADD pattern:
///    auipc   t0, %pcrel_hi(table)
///    addi    t0, t0, %pcrel_lo(table)
///    ...
pub fn detect_jump_table_pattern(
  instructions : FixedArray[DecodedInst],
  jump_inst_idx : Int,
) -> JumpTable? {
  if jump_inst_idx < 2 {
    return None
  }

  // Get the jump instruction (JALR with rd=x0 or C.JR)
  let jump_inst = instructions[jump_inst_idx]
  let jump_reg = match jump_inst.inst {
    @decode.JALR(0U, rs1, 0) => rs1 // jr rs1
    @decode.C_JR(rs1) => rs1
    _ => return None
  }

  // Look backwards for table load pattern
  let mut table_base_addr : UInt? = None
  let mut scale = 4 // Default scale for 32-bit addresses
  let mut index_reg : UInt? = None
  let mut table_base_reg = jump_reg

  // Scan backwards from jump instruction
  let start_idx = if jump_inst_idx > 10 { jump_inst_idx - 10 } else { 0 }
  let mut i = start_idx
  while i < jump_inst_idx {
    let idx = jump_inst_idx - 1 - i
    if idx < 0 {
      break
    }
    let inst_info = instructions[idx]

    // Look for load from memory into jump register
    match inst_info.inst {
      // lw rd, offset(rs1) - load target from table
      @decode.LW(rd, rs1, _offset) | @decode.LD(rd, rs1, _offset) =>
        if rd == jump_reg {
          // Found load into jump register
          // rs1 should be the table address
          table_base_reg = rs1
        }
      // add rd, rs1, rs2 - calculate table entry address
      @decode.ADD(rd, rs1, rs2) => {
        if rd == jump_reg || rd == table_base_reg {
          // This might be: table_base + index * scale
          // Check if rs2 was computed from a shift
          table_base_reg = rs1
        }
        ignore(rs2)
      }
      // slli rd, rs1, shamt - scale the index
      @decode.SLLI(rd, rs1, shamt) =>
        if rd == jump_reg || rd == table_base_reg {
          scale = 1 << shamt.reinterpret_as_int()
          index_reg = Some(rs1)
        }
      // LUI + ADDI or AUIPC for address loading
      @decode.LUI(rd, imm) =>
        if rd == table_base_reg {
          let upper = (imm << 12).reinterpret_as_uint()
          table_base_addr = Some(upper)
        }
      @decode.AUIPC(rd, imm) =>
        if rd == table_base_reg {
          // PC-relative address
          let pc = inst_info.addr.reinterpret_as_int()
          let addr = (pc + (imm << 12)).reinterpret_as_uint()
          table_base_addr = Some(addr)
        }
      @decode.ADDI(rd, rs1, imm) =>
        // Complete the address calculation
        match table_base_addr {
          Some(base) =>
            if rd == table_base_reg && rs1 == table_base_reg {
              let final_addr = (base.reinterpret_as_int() + imm).reinterpret_as_uint()
              table_base_addr = Some(final_addr)
            }
          None => ()
        }
      _ => ()
    }
    i = i + 1
  }

  // If we found a potential table base address, try to resolve it
  match table_base_addr {
    Some(addr) =>
      Some(JumpTable::{
        base_addr: addr,
        entry_count: 0, // Will be determined by analyzing bounds check
        entry_size: scale,
        table_type: JumpTableType::Simple,
        targets: [],
        jump_inst_addr: jump_inst.addr,
      })
    None => None
  }
}

///|
/// Detect bounds check pattern before jump table
/// Returns (min_value, max_value) if found
pub fn detect_bounds_check(
  instructions : FixedArray[DecodedInst],
  jump_inst_idx : Int,
) -> (Int, Int)? {
  if jump_inst_idx < 3 {
    return None
  }

  // Look for common bounds check patterns:
  // 1. sltiu + beqz: sltiu t0, a0, count; beqz t0, default_case
  // 2. li + bltu: li t0, count; bltu a0, t0, in_range

  let start_idx = if jump_inst_idx > 8 { jump_inst_idx - 8 } else { 0 }

  let mut i = start_idx
  while i < jump_inst_idx {
    let inst_info = instructions[i]

    match inst_info.inst {
      // sltiu rd, rs1, imm - unsigned comparison with immediate
      @decode.SLTIU(_, _, imm) =>
        // Check if next instruction is beqz
        if i + 1 < jump_inst_idx {
          let next = instructions[i + 1]
          match next.inst {
            @decode.BEQ(_, _, _) | @decode.C_BEQZ(_, _) =>
              // Found bounds check: if index >= imm, go to default
              return Some((0, imm - 1))
            _ => ()
          }
        }
      // li rd, imm (actually addi rd, x0, imm or c.li)
      @decode.ADDI(rd, _, imm) | @decode.C_LI(rd, imm) =>
        if rd != 0U && i + 1 < jump_inst_idx {
          let next = instructions[i + 1]
          match next.inst {
            @decode.BLTU(_, rs2, _) | @decode.BGEU(_, rs2, _) =>
              // Found li + bltu pattern
              if rs2 == rd {
                return Some((0, imm - 1))
              }
            _ => ()
          }
        }
      _ => ()
    }
    i = i + 1
  }

  None
}

///|
/// Read a 32-bit value from byte array at given offset
fn read_u32_from_bytes(bytes : FixedArray[Byte], offset : Int) -> UInt {
  if offset + 3 >= bytes.length() {
    return 0U
  }
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24)
}

///|
/// Read a 64-bit value from byte array at given offset
fn read_u64_from_bytes(bytes : FixedArray[Byte], offset : Int) -> UInt {
  if offset + 7 >= bytes.length() {
    return 0U
  }
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24) |
  (bytes[offset + 4].to_uint() << 32) |
  (bytes[offset + 5].to_uint() << 40) |
  (bytes[offset + 6].to_uint() << 48) |
  (bytes[offset + 7].to_uint() << 56)
}

///|
/// Resolve jump table targets from memory content
pub fn resolve_jump_table_targets(
  table : JumpTable,
  memory : FixedArray[Byte],
  code_start : UInt,
  code_end : UInt,
) -> JumpTable {
  if table.entry_count == 0 || memory.length() == 0 {
    return table
  }

  let targets : Array[UInt] = []
  let table_offset = table.base_addr.reinterpret_as_int()

  for i = 0; i < table.entry_count; i = i + 1 {
    let entry_offset = table_offset + i * table.entry_size
    if entry_offset < 0 || entry_offset >= memory.length() {
      break
    }

    let target = if table.entry_size == 8 {
      read_u64_from_bytes(memory, entry_offset)
    } else {
      read_u32_from_bytes(memory, entry_offset)
    }

    // Validate target is within code range
    if target >= code_start && target < code_end {
      targets.push(target)
    } else {
      // Might be relative offset
      match table.table_type {
        JumpTableType::Relative => {
          let abs_target = table.base_addr.reinterpret_as_int() +
            target.reinterpret_as_int()
          let abs_addr = abs_target.reinterpret_as_uint()
          if abs_addr >= code_start && abs_addr < code_end {
            targets.push(abs_addr)
          }
        }
        _ => () // Skip invalid targets
      }
    }
  }

  JumpTable::{
    base_addr: table.base_addr,
    entry_count: targets.length(),
    entry_size: table.entry_size,
    table_type: table.table_type,
    targets: FixedArray::from_array(targets),
    jump_inst_addr: table.jump_inst_addr,
  }
}

///|
/// Detect tail call pattern
/// 
/// Tail call patterns in RISC-V:
/// 1. Direct: JAL x0, target (or C.J target)
/// 2. Indirect: JALR x0, rs1, 0 (or C.JR rs1) without saving ra
pub fn detect_tail_call(
  inst_info : DecodedInst,
  _prev_inst : DecodedInst?,
) -> TailCall? {
  match inst_info.inst {
    // Direct tail call: JAL x0, target
    @decode.JAL(0U, _imm) =>
      Some(TailCall::{
        addr: inst_info.addr,
        target: None, // Will be resolved by caller
        is_indirect: false,
        reg: None,
      })
    // C.J (compressed unconditional jump)
    @decode.C_J(_imm) =>
      Some(TailCall::{
        addr: inst_info.addr,
        target: None,
        is_indirect: false,
        reg: None,
      })
    // Indirect tail call: JALR x0, rs1, 0
    @decode.JALR(0U, rs1, 0) =>
      // Check if this looks like a tail call vs return
      // A return would be: JALR x0, ra, 0
      if rs1 == 1U {
        // JALR x0, ra, 0 is a return, not tail call
        None
      } else {
        Some(TailCall::{
          addr: inst_info.addr,
          target: None,
          is_indirect: true,
          reg: Some(rs1),
        })
      }
    // C.JR rs1 (compressed jump register)
    @decode.C_JR(rs1) =>
      if rs1 == 1U {
        // C.JR ra is a return
        None
      } else {
        Some(TailCall::{
          addr: inst_info.addr,
          target: None,
          is_indirect: true,
          reg: Some(rs1),
        })
      }
    _ => None
  }
}

///|
/// Analyze function pointer source
pub fn analyze_pointer_source(
  instructions : FixedArray[DecodedInst],
  load_inst_idx : Int,
  target_reg : UInt,
) -> PointerSource {
  if load_inst_idx < 1 {
    return PointerSource::Unknown
  }

  let load_inst = instructions[load_inst_idx]

  // Check the load instruction pattern
  match load_inst.inst {
    // Load from memory: lw/ld rd, offset(rs1)
    @decode.LW(rd, rs1, _offset) | @decode.LD(rd, rs1, _offset) => {
      if rd != target_reg {
        return PointerSource::Unknown
      }

      // Determine source based on base register
      match rs1 {
        2U =>
          // Loaded from stack - could be local function pointer
          // or argument passed on stack
          PointerSource::Argument(0) // Simplified
        3U =>
          // Loaded via gp (global pointer) - global variable
          PointerSource::Global(0U) // Offset needs to be resolved
        _ =>
          // Check if rs1 was loaded from somewhere else
          // Look backwards to trace the base address
          trace_register_source(instructions, load_inst_idx, rs1)
      }
    }
    // Move from another register: mv rd, rs1 (addi rd, rs1, 0)
    @decode.ADDI(rd, rs1, 0) | @decode.C_MV(rd, rs1) => {
      if rd != target_reg {
        return PointerSource::Unknown
      }
      // Trace the source register
      trace_register_source(instructions, load_inst_idx, rs1)
    }
    _ => PointerSource::Unknown
  }
}

///|
/// Trace the source of a register value
fn trace_register_source(
  instructions : FixedArray[DecodedInst],
  current_idx : Int,
  reg : UInt,
) -> PointerSource {
  if current_idx < 1 {
    return PointerSource::Register(reg)
  }

  // Look backwards for where this register was set
  let start_idx = if current_idx > 15 { current_idx - 15 } else { 0 }

  let mut i = start_idx
  while i < current_idx {
    let idx = current_idx - 1 - i
    let inst_info = instructions[idx]

    match inst_info.inst {
      @decode.LW(rd, _, _) | @decode.LD(rd, _, _) =>
        if rd == reg {
          return PointerSource::Global(0U) // Simplified
        }
      @decode.LUI(rd, _) | @decode.AUIPC(rd, _) =>
        if rd == reg {
          return PointerSource::Global(0U)
        }
      @decode.ADDI(rd, rs1, 0) | @decode.C_MV(rd, rs1) =>
        if rd == reg {
          return trace_register_source(instructions, idx, rs1)
        }
      @decode.C_LI(rd, _) | @decode.ADDI(rd, _, _) =>
        if rd == reg {
          return PointerSource::Register(rd)
        }
      _ => ()
    }
    i = i + 1
  }

  PointerSource::Register(reg)
}

///|
/// Detect indirect call pattern
pub fn detect_indirect_call(
  instructions : FixedArray[DecodedInst],
  call_inst_idx : Int,
) -> IndirectCall? {
  if call_inst_idx < 0 || call_inst_idx >= instructions.length() {
    return None
  }

  let call_inst = instructions[call_inst_idx]

  match call_inst.inst {
    // JALR rd, rs1, imm - check if this is an indirect call
    @decode.JALR(rd, rs1, imm) =>
      // A call writes to ra (x1) or t0 (x5)
      if rd == 1U || rd == 5U {
        // This is a call
        if imm == 0 && rs1 != 1U {
          // Indirect call via register
          let source = analyze_pointer_source(instructions, call_inst_idx, rs1)
          Some(IndirectCall::{
            addr: call_inst.addr,
            reg: rs1,
            possible_targets: [],
            pointer_source: source,
          })
        } else {
          None // Direct call
        }
      } else {
        None // Not a call
      }
    // C.JALR rs1 - compressed indirect call (always writes ra)
    @decode.C_JALR(rs1) =>
      if rs1 != 0U {
        let source = analyze_pointer_source(instructions, call_inst_idx, rs1)
        Some(IndirectCall::{
          addr: call_inst.addr,
          reg: rs1,
          possible_targets: [],
          pointer_source: source,
        })
      } else {
        None
      }
    _ => None
  }
}

///|
/// Analyze indirect jumps and calls in a function
pub fn analyze_indirect_jumps(
  instructions : FixedArray[DecodedInst],
  memory : FixedArray[Byte],
  code_start : UInt,
  code_end : UInt,
) -> IndirectJumpInfo {
  let jump_tables : Array[JumpTable] = []
  let indirect_calls : Array[IndirectCall] = []
  let tail_calls : Array[TailCall] = []

  for i = 0; i < instructions.length(); i = i + 1 {
    let inst_info = instructions[i]
    let prev_inst = if i > 0 { Some(instructions[i - 1]) } else { None }

    // Check for indirect jump (potential jump table)
    match inst_info.inst {
      @decode.JALR(0U, _, _) | @decode.C_JR(_) => {
        // Check if this is a return
        let is_return = match inst_info.inst {
          @decode.JALR(0U, rs1, _) => rs1 == 1U
          @decode.C_JR(rs1) => rs1 == 1U
          _ => false
        }

        if !is_return {
          // Try to detect jump table pattern
          match detect_jump_table_pattern(instructions, i) {
            Some(table) => {
              // Try to detect bounds check to determine entry count
              let final_table = match detect_bounds_check(instructions, i) {
                Some((_, max)) =>
                  JumpTable::{
                    base_addr: table.base_addr,
                    entry_count: max + 1,
                    entry_size: table.entry_size,
                    table_type: table.table_type,
                    targets: table.targets,
                    jump_inst_addr: table.jump_inst_addr,
                  }
                None => table
              }

              // Resolve targets if memory is available
              if memory.length() > 0 && final_table.entry_count > 0 {
                let resolved = resolve_jump_table_targets(
                  final_table, memory, code_start, code_end,
                )
                jump_tables.push(resolved)
              } else {
                jump_tables.push(final_table)
              }
            }
            None => ()
          }

          // Also check for tail call
          match detect_tail_call(inst_info, prev_inst) {
            Some(tc) => tail_calls.push(tc)
            None => ()
          }
        }
      }
      _ => ()
    }

    // Check for indirect call
    match detect_indirect_call(instructions, i) {
      Some(ic) => indirect_calls.push(ic)
      None => ()
    }

    // Check for direct tail calls (JAL x0 or C.J)
    match detect_tail_call(inst_info, prev_inst) {
      Some(tc) => tail_calls.push(tc)
      None => ()
    }
  }

  IndirectJumpInfo::{
    jump_tables: FixedArray::from_array(jump_tables),
    indirect_calls: FixedArray::from_array(indirect_calls),
    tail_calls: FixedArray::from_array(tail_calls),
  }
}

///|
/// Enhance CFG with resolved indirect jump targets
pub fn enhance_cfg_with_indirect_jumps(
  cfg : CFG,
  indirect_info : IndirectJumpInfo,
) -> CFG {
  let new_edges : Array[Edge] = []

  // Copy existing edges
  for edge in cfg.edges {
    new_edges.push(edge)
  }

  // Add edges from resolved jump tables
  for table in indirect_info.jump_tables {
    for target in table.targets {
      new_edges.push(Edge::{
        from_block: table.jump_inst_addr,
        to_block: target,
        edge_type: EdgeType::Jump,
      })
    }
  }

  // Add edges for indirect calls with known targets
  for call in indirect_info.indirect_calls {
    for target in call.possible_targets {
      new_edges.push(Edge::{
        from_block: call.addr,
        to_block: target,
        edge_type: EdgeType::Call,
      })
    }
  }

  { ..cfg, edges: FixedArray::from_array(new_edges) }
}

///|
/// Get string representation of jump table type
fn jump_table_type_to_string(ty : JumpTableType) -> String {
  match ty {
    JumpTableType::Simple => "Simple"
    JumpTableType::Relative => "Relative"
    JumpTableType::PCRelative => "PC-Relative"
  }
}

///|
/// Get string representation of pointer source
fn pointer_source_to_string(source : PointerSource) -> String {
  match source {
    PointerSource::Global(addr) => "Global(" + format_hex_uint(addr) + ")"
    PointerSource::VTable(addr, off) =>
      "VTable(" + format_hex_uint(addr) + ", " + off.to_string() + ")"
    PointerSource::Argument(idx) => "Argument(" + idx.to_string() + ")"
    PointerSource::ReturnValue(caller) =>
      "ReturnValue(" + format_hex_uint(caller) + ")"
    PointerSource::Register(reg) => "Register(" + @decode.reg_name(reg) + ")"
    PointerSource::Unknown => "Unknown"
  }
}

///|
/// Format jump table info for display
pub fn format_jump_table(table : JumpTable) -> String {
  let mut result = "Jump Table at " + format_hex_uint(table.base_addr) + "\n"
  result = result + "  Entries: " + table.entry_count.to_string() + "\n"
  result = result + "  Entry size: " + table.entry_size.to_string() + " bytes\n"
  result = result +
    "  Type: " +
    jump_table_type_to_string(table.table_type) +
    "\n"

  if table.targets.length() > 0 {
    result = result + "  Targets:\n"
    for i = 0; i < table.targets.length(); i = i + 1 {
      result = result +
        "    [" +
        i.to_string() +
        "] " +
        format_hex_uint(table.targets[i]) +
        "\n"
    }
  }

  result
}

///|
/// Format indirect call info for display
pub fn format_indirect_call(call : IndirectCall) -> String {
  let mut result = "Indirect Call at " + format_hex_uint(call.addr) + "\n"
  result = result + "  Register: " + @decode.reg_name(call.reg) + "\n"
  result = result +
    "  Source: " +
    pointer_source_to_string(call.pointer_source) +
    "\n"

  if call.possible_targets.length() > 0 {
    result = result + "  Possible targets:\n"
    for target in call.possible_targets {
      result = result + "    " + format_hex_uint(target) + "\n"
    }
  }

  result
}

///|
/// Format tail call info for display
pub fn format_tail_call(tc : TailCall) -> String {
  let mut result = "Tail Call at " + format_hex_uint(tc.addr) + "\n"
  result = result +
    "  Type: " +
    (if tc.is_indirect { "Indirect" } else { "Direct" }) +
    "\n"

  match tc.target {
    Some(addr) => result = result + "  Target: " + format_hex_uint(addr) + "\n"
    None => ()
  }

  match tc.reg {
    Some(reg) => result = result + "  Register: " + @decode.reg_name(reg) + "\n"
    None => ()
  }

  result
}

///|
/// Get JSON string for jump table type
fn jump_table_type_to_json_string(ty : JumpTableType) -> String {
  match ty {
    JumpTableType::Simple => "simple"
    JumpTableType::Relative => "relative"
    JumpTableType::PCRelative => "pc_relative"
  }
}

///|
/// Get JSON string for pointer source
fn pointer_source_to_json_string(source : PointerSource) -> String {
  match source {
    PointerSource::Global(addr) => "global:" + format_hex_uint(addr)
    PointerSource::VTable(addr, off) =>
      "vtable:" + format_hex_uint(addr) + ":" + off.to_string()
    PointerSource::Argument(idx) => "argument:" + idx.to_string()
    PointerSource::ReturnValue(caller) => "return:" + format_hex_uint(caller)
    PointerSource::Register(reg) => "register:" + @decode.reg_name(reg)
    PointerSource::Unknown => "unknown"
  }
}

///|
/// Generate JSON format for indirect jump info
pub fn indirect_jump_info_to_json(info : IndirectJumpInfo) -> String {
  let mut result = "{\n"

  // Jump tables
  result = result + "  \"jump_tables\": [\n"
  for i = 0; i < info.jump_tables.length(); i = i + 1 {
    if i > 0 {
      result = result + ",\n"
    }
    let table = info.jump_tables[i]
    result = result + "    {\n"
    result = result +
      "      \"base_addr\": \"" +
      format_hex_uint(table.base_addr) +
      "\",\n"
    result = result +
      "      \"entry_count\": " +
      table.entry_count.to_string() +
      ",\n"
    result = result +
      "      \"entry_size\": " +
      table.entry_size.to_string() +
      ",\n"
    result = result +
      "      \"type\": \"" +
      jump_table_type_to_json_string(table.table_type) +
      "\",\n"
    result = result + "      \"targets\": ["
    for j = 0; j < table.targets.length(); j = j + 1 {
      if j > 0 {
        result = result + ", "
      }
      result = result + "\"" + format_hex_uint(table.targets[j]) + "\""
    }
    result = result + "]\n"
    result = result + "    }"
  }
  result = result + "\n  ],\n"

  // Indirect calls
  result = result + "  \"indirect_calls\": [\n"
  for i = 0; i < info.indirect_calls.length(); i = i + 1 {
    if i > 0 {
      result = result + ",\n"
    }
    let call = info.indirect_calls[i]
    result = result + "    {\n"
    result = result +
      "      \"addr\": \"" +
      format_hex_uint(call.addr) +
      "\",\n"
    result = result +
      "      \"register\": \"" +
      @decode.reg_name(call.reg) +
      "\",\n"
    result = result +
      "      \"source\": \"" +
      pointer_source_to_json_string(call.pointer_source) +
      "\",\n"
    result = result + "      \"possible_targets\": ["
    for j = 0; j < call.possible_targets.length(); j = j + 1 {
      if j > 0 {
        result = result + ", "
      }
      result = result + "\"" + format_hex_uint(call.possible_targets[j]) + "\""
    }
    result = result + "]\n"
    result = result + "    }"
  }
  result = result + "\n  ],\n"

  // Tail calls
  result = result + "  \"tail_calls\": [\n"
  for i = 0; i < info.tail_calls.length(); i = i + 1 {
    if i > 0 {
      result = result + ",\n"
    }
    let tc = info.tail_calls[i]
    result = result + "    {\n"
    result = result + "      \"addr\": \"" + format_hex_uint(tc.addr) + "\",\n"
    result = result +
      "      \"is_indirect\": " +
      tc.is_indirect.to_string() +
      ""
    match tc.target {
      Some(addr) =>
        result = result +
          ",\n      \"target\": \"" +
          format_hex_uint(addr) +
          "\""
      None => ()
    }
    match tc.reg {
      Some(reg) =>
        result = result +
          ",\n      \"register\": \"" +
          @decode.reg_name(reg) +
          "\""
      None => ()
    }
    result = result + "\n    }"
  }
  result = result + "\n  ]\n"

  result = result + "}\n"
  result
}
