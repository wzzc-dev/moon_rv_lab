///| Decompiler module - Converts RISC-V machine code to structured pseudo-code

///|
/// Statement types for high-level code recovery  
pub enum Statement {
  Assign(String, String)
  BinOp(String, String, BinOp, String)
  Load(String, String, String?)
  Store(String, String, String?)
  Call(String, Array[String])
  Return(String?)
  StackOp(StackOpType, String?, Int)
  Comment(String)
  Raw(String)
  /// Variable declaration with inferred type
  VarDecl(String, String, String) // name, type, initial_value
  /// Break statement for loop exit
  Break
  /// Continue statement for loop continuation
  Continue
  /// Label for switch cases
  Label(String)
  /// Goto for unstructured control flow
  Goto(String)
} derive(Show)

///|
/// Binary operations
pub enum BinOp {
  Add
  Sub
  And
  Or
  Xor
  Shl
  Shr
  Mul
  Div
  Mod
} derive(Show)

///|
/// Stack operation types
pub enum StackOpType {
  Push
  Pop
  Adjust
} derive(Show)

///|
/// Control structure types
pub enum ControlStructure {
  /// Sequence of control structures
  Sequence(Array[ControlStructure])
  /// If-then-else: condition, then_body, else_body (optional)
  IfThenElse(ConditionExpr, ControlStructure, ControlStructure?)
  /// While loop: condition, body (condition checked before body)
  WhileLoop(ConditionExpr, ControlStructure)
  /// Do-while loop: condition, body (condition checked after body)
  DoWhileLoop(ConditionExpr, ControlStructure)
  /// For loop: init, condition, update, body
  ForLoop(ForInit, ConditionExpr, ForUpdate, ControlStructure)
  /// Switch statement: expression, cases, default_body
  Switch(String, Array[SwitchCase], ControlStructure?)
  /// Basic block: start_addr, end_addr, statements
  BasicBlock(UInt, UInt, Array[Statement])
  /// Function call (standalone, not part of expression)
  Call(String)
  /// Return statement
  Return(String?)
  /// Break statement
  Break
  /// Continue statement
  Continue
  /// Unknown/unstructured control flow
  Unknown(String)
  /// Empty/no-op
  Empty
} derive(Show)

///|
/// Switch case
pub struct SwitchCase {
  /// Case value (can be single value or range)
  values : Array[Int]
  /// Body of this case
  body : ControlStructure
  /// Whether this case falls through to next
  fallthrough : Bool
} derive(Show)

///|
/// For loop initialization
pub enum ForInit {
  /// Variable declaration: name, type, initial_value
  VarDecl(String, String, String)
  /// Assignment: target, value
  Assign(String, String)
  /// No initialization
  None
} derive(Show, Eq)

///|
/// For loop update expression
pub enum ForUpdate {
  /// Single expression statement
  Expr(Statement)
  /// Multiple statements
  Multi(Array[Statement])
  /// No update
  None
} derive(Show)

///|
/// Condition expression
pub enum ConditionExpr {
  /// Binary comparison: op, left, right
  Compare(CompareOp, String, String)
  /// Single expression (non-zero is true)
  Single(String)
  /// Always true (for infinite loops)
  True
  /// Always false
  False
  /// Negated condition
  Not(ConditionExpr)
  /// Logical AND of two conditions
  And(ConditionExpr, ConditionExpr)
  /// Logical OR of two conditions
  Or(ConditionExpr, ConditionExpr)
} derive(Show)

///|
/// Compare operations
pub enum CompareOp {
  Eq
  Ne
  Lt
  Le
  Gt
  Ge
  /// Unsigned less than
  Ltu
  /// Unsigned greater or equal
  Geu
} derive(Show, Eq)

///|
/// Dominator tree for control flow analysis
pub struct DominatorTree {
  /// Immediate dominator for each block (block_addr -> idom_addr)
  idom : Map[UInt, UInt]
  /// Children in dominator tree
  dom_children : Map[UInt, Array[UInt]]
  /// Dominance frontier for each block
  dom_frontier : Map[UInt, Array[UInt]]
  /// Post-dominator info
  post_idom : Map[UInt, UInt]
} derive(Show)

///|
/// Natural loop information
pub struct NaturalLoop {
  /// Loop header address
  header : UInt
  /// Back edge source blocks
  back_edges : Array[UInt]
  /// All blocks in the loop body
  body : Array[UInt]
  /// Nesting depth (1 = outermost)
  depth : Int
  /// Parent loop (if nested)
  parent : UInt?
  /// Loop type
  loop_type : LoopType
} derive(Show)

///|
/// Loop type classification
pub enum LoopType {
  /// while(cond) { body }
  While
  /// do { body } while(cond)
  DoWhile
  /// for(init; cond; update) { body }
  For
  /// Infinite loop (no exit condition)
  Infinite
  /// Unknown structure
  Unknown
} derive(Show, Eq)

///|
/// Loop nesting information
pub struct LoopInfo {
  /// All detected loops
  loops : Array[NaturalLoop]
  /// Map from block address to containing loops (innermost first)
  block_to_loops : Map[UInt, Array[Int]] // block_addr -> loop indices
  /// Maximum nesting depth
  max_depth : Int
} derive(Show)

///|
/// Structured control flow analysis result
pub struct StructuredCFG {
  /// Original CFG
  cfg : CFG
  /// Dominator tree
  dom_tree : DominatorTree
  /// Loop information
  loop_info : LoopInfo
  /// Structured control flow (root of the structure tree)
  structure : ControlStructure
} derive(Show)

///|
/// Register value tracking
pub enum RegValue {
  Unknown
  Constant(Int)
  StringAddr(String)
  Address(UInt)
  Expression(String)
} derive(Show)

///|
/// Decompilation context
pub struct DecompileContext {
  symbol_map : Map[UInt, String]
  string_map : Map[UInt, String]
  reg_values : Map[UInt, RegValue] // Track register values
} derive(Show)

///|
/// Initialize context
fn DecompileContext::new(
  symbol_map : Map[UInt, String],
  string_map : Map[UInt, String],
) -> DecompileContext {
  { symbol_map, string_map, reg_values: Map::new() }
}

///|
/// Get register value
fn get_reg_value(ctx : DecompileContext, reg : UInt) -> RegValue {
  ctx.reg_values.get(reg).or(Unknown)
}

///|
/// Set register value
fn set_reg_value(ctx : DecompileContext, reg : UInt, value : RegValue) -> Unit {
  if reg != 0U { // x0 is always 0
    ctx.reg_values[reg] = value
  }
}

///|
/// Format register value for display
fn format_reg_value(value : RegValue) -> String {
  match value {
    Unknown => "?"
    Constant(c) => c.to_string()
    StringAddr(s) => "\"" + s + "\""
    Address(a) => "0x" + uint_to_hex(a)
    Expression(e) => e
  }
}

///|
/// Decompile a function to pseudo-code
pub fn decompile(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
  symbol_map : Map[UInt, String],
  string_map : Map[UInt, String],
) -> String {
  if cfg.blocks.length() == 0 {
    return "// No code blocks found\n"
  }

  let ctx = DecompileContext::new(symbol_map, string_map)
  let mut output = ""

  for block in cfg.blocks {
    output = output +
      "// Block 0x" +
      uint_to_hex(block.start_addr) +
      " - 0x" +
      uint_to_hex(block.end_addr) +
      "\n"

    // Get instructions in this block
    let block_insts = get_block_instructions(
      instructions,
      block.start_addr,
      block.end_addr,
    )

    // Analyze each instruction with register tracking
    for inst_info in block_insts {
      let stmt = analyze_instruction(inst_info, ctx)
      output = output + format_statement(stmt) + "\n"
    }

    output = output + "\n"
  }

  output
}

///|
/// Get instructions within a block
fn get_block_instructions(
  instructions : FixedArray[DecodedInst],
  start : UInt,
  end : UInt,
) -> Array[DecodedInst] {
  let result : Array[DecodedInst] = []
  for inst in instructions {
    if inst.addr >= start && inst.addr <= end {
      result.push(inst)
    }
  }
  result
}

///|
/// Analyze single instruction with register tracking
fn analyze_instruction(
  inst_info : DecodedInst,
  ctx : DecompileContext,
) -> Statement {
  let inst = inst_info.inst

  match inst {
    // LUI - Load upper immediate (often used for address loading)
    @decode.LUI(rd, imm) => {
      let addr = imm.reinterpret_as_uint()

      // Check if this points to a string
      match ctx.string_map.get(addr) {
        Some(s) => {
          set_reg_value(ctx, rd, StringAddr(s))
          // Don't generate assignment for intermediate address calculation
          Comment("" + @decode.reg_name(rd) + " = &" + s)
        }
        None => {
          set_reg_value(ctx, rd, Address(addr))
          // Don't show intermediate calculation unless it's used meaningfully  
          Comment("" + @decode.reg_name(rd) + " = 0x" + uint_to_hex(addr))
        }
      }
    }
    // AUIPC
    @decode.AUIPC(rd, imm) => {
      let pc = inst_info.addr.reinterpret_as_int()
      let addr = (pc + imm).reinterpret_as_uint()

      match ctx.string_map.get(addr) {
        Some(s) => {
          set_reg_value(ctx, rd, StringAddr(s))
          Assign(@decode.reg_name(rd), "\"" + s + "\"")
        }
        None => {
          set_reg_value(ctx, rd, Address(addr))
          Assign(@decode.reg_name(rd), "PC + " + (imm >> 12).to_string())
        }
      }
    }

    // ADDI - Add immediate (often used with LUI for address calculation)
    @decode.ADDI(rd, rs1, imm) =>
      if rs1 == 2U { // Stack pointer
        if imm < 0 {
          StackOp(StackOpType::Adjust, None, imm)
        } else {
          Assign(
            @decode.reg_name(rd),
            @decode.reg_name(rs1) + " + " + imm.to_string(),
          )
        }
      } else {
        // Check if rs1 holds a string address
        match get_reg_value(ctx, rs1) {
          StringAddr(s) => {
            // This is unlikely, but handle it
            set_reg_value(ctx, rd, StringAddr(s))
            Assign(@decode.reg_name(rd), "\"" + s + "\"")
          }
          Address(addr) => {
            let final_addr = (addr.reinterpret_as_int() + imm).reinterpret_as_uint()
            match ctx.string_map.get(final_addr) {
              Some(s) => {
                set_reg_value(ctx, rd, StringAddr(s))
                // This is the meaningful assignment - show it!
                Assign(@decode.reg_name(rd), "\"" + s + "\"")
              }
              None => {
                set_reg_value(ctx, rd, Address(final_addr))
                // Only show if it's not an intermediate calculation
                // (i.e., if rd is a0-a7 which are argument registers)
                if rd >= 10U && rd <= 17U {
                  Assign(@decode.reg_name(rd), "0x" + uint_to_hex(final_addr))
                } else {
                  Comment(
                    "" +
                    @decode.reg_name(rd) +
                    " = 0x" +
                    uint_to_hex(final_addr),
                  )
                }
              }
            }
          }
          Constant(c) => {
            let result = c + imm
            set_reg_value(ctx, rd, Constant(result))
            // Only show if it's a meaningful constant (argument register)
            if rd >= 10U && rd <= 17U {
              Assign(@decode.reg_name(rd), result.to_string())
            } else {
              Comment("" + @decode.reg_name(rd) + " = " + result.to_string())
            }
          }
          _ => {
            set_reg_value(ctx, rd, Unknown)
            Assign(
              @decode.reg_name(rd),
              @decode.reg_name(rs1) + " + " + imm.to_string(),
            )
          }
        }
      }

    // Load instructions
    @decode.LW(rd, rs1, imm) | @decode.LD(rd, rs1, imm) => {
      set_reg_value(ctx, rd, Unknown)
      if rs1 == 2U {
        Load(@decode.reg_name(rd), "sp + " + imm.to_string(), None)
      } else {
        Load(
          @decode.reg_name(rd),
          @decode.reg_name(rs1) + " + " + imm.to_string(),
          None,
        )
      }
    }

    // Store instructions
    @decode.SW(rs1, rs2, imm) | @decode.SD(rs1, rs2, imm) =>
      if rs1 == 2U {
        StackOp(StackOpType::Push, Some(@decode.reg_name(rs2)), imm)
      } else {
        Store(
          @decode.reg_name(rs1) + " + " + imm.to_string(),
          @decode.reg_name(rs2),
          None,
        )
      }

    // JAL - Jump and link (function call)
    @decode.JAL(rd, imm) => {
      let target = (inst_info.addr.reinterpret_as_int() + imm).reinterpret_as_uint()
      let func_name = match ctx.symbol_map.get(target) {
        Some(name) => name
        None => "func_0x" + uint_to_hex(target)
      }

      // Try to get arguments from registers a0-a7
      let args = get_call_arguments(ctx)

      set_reg_value(ctx, rd, Unknown) // rd gets return value
      Call(func_name, args)
    }

    // Compressed JAL
    @decode.C_JAL(imm) => {
      let target = (inst_info.addr.reinterpret_as_int() + imm).reinterpret_as_uint()
      let func_name = match ctx.symbol_map.get(target) {
        Some(name) => name
        None => "func_0x" + uint_to_hex(target)
      }
      let args = get_call_arguments(ctx)
      Call(func_name, args)
    }

    // Branch instructions
    @decode.BEQ(rs1, rs2, imm) =>
      Comment(
        "if (" +
        @decode.reg_name(rs1) +
        " == " +
        @decode.reg_name(rs2) +
        ") goto " +
        imm.to_string(),
      )
    @decode.BNE(rs1, rs2, imm) =>
      Comment(
        "if (" +
        @decode.reg_name(rs1) +
        " != " +
        @decode.reg_name(rs2) +
        ") goto " +
        imm.to_string(),
      )
    @decode.BLT(rs1, rs2, imm) =>
      Comment(
        "if (" +
        @decode.reg_name(rs1) +
        " < " +
        @decode.reg_name(rs2) +
        ") goto " +
        imm.to_string(),
      )
    @decode.BGE(rs1, rs2, imm) =>
      Comment(
        "if (" +
        @decode.reg_name(rs1) +
        " >= " +
        @decode.reg_name(rs2) +
        ") goto " +
        imm.to_string(),
      )

    // Compressed branches
    @decode.C_BEQZ(rs1, imm) =>
      Comment("if (" + @decode.reg_name(rs1) + " == 0) goto " + imm.to_string())
    @decode.C_BNEZ(rs1, imm) =>
      Comment("if (" + @decode.reg_name(rs1) + " != 0) goto " + imm.to_string())

    // Return
    @decode.JALR(rd, rs1, imm) =>
      if rd == 0U && rs1 == 1U {
        // Check if a0 has a value
        let ret_val = match get_reg_value(ctx, 10U) { // a0 is x10
          StringAddr(s) => Some("\"" + s + "\"")
          Constant(c) => Some(c.to_string())
          Address(a) => Some("0x" + uint_to_hex(a))
          _ => None
        }
        Return(ret_val)
      } else if rd == 1U {
        // Tail call
        let target = (inst_info.addr.reinterpret_as_int() + imm).reinterpret_as_uint()
        let func_name = match ctx.symbol_map.get(target) {
          Some(name) => name
          None => "func_0x" + uint_to_hex(target)
        }
        let args = get_call_arguments(ctx)
        Call(func_name, args)
      } else {
        Comment("jalr " + @decode.reg_name(rd) + ", " + @decode.reg_name(rs1))
      }

    // Compressed return
    @decode.C_JR(rs1) =>
      if rs1 == 1U {
        let ret_val = match get_reg_value(ctx, 10U) {
          StringAddr(s) => Some("\"" + s + "\"")
          Constant(c) => Some(c.to_string())
          Address(a) => Some("0x" + uint_to_hex(a))
          _ => None
        }
        Return(ret_val)
      } else {
        Comment("jr " + @decode.reg_name(rs1))
      }

    // Compressed stores
    @decode.C_SWSP(rs2, imm) =>
      StackOp(
        StackOpType::Push,
        Some(@decode.reg_name(rs2)),
        imm.reinterpret_as_int(),
      )
    @decode.C_FSDSP(rs2, imm) =>
      StackOp(
        StackOpType::Push,
        Some(@decode.freg_name(rs2)),
        imm.reinterpret_as_int(),
      )

    // Compressed loads
    @decode.C_LWSP(rd, imm) => {
      set_reg_value(ctx, rd, Unknown)
      Load(@decode.reg_name(rd), "sp + " + imm.to_string(), None)
    }
    @decode.C_FLDSP(rd, imm) => {
      set_reg_value(ctx, rd, Unknown)
      Load(@decode.freg_name(rd), "sp + " + imm.to_string(), None)
    }

    // Compressed stack adjustment
    @decode.C_ADDI4SPN(rd, imm) => {
      set_reg_value(ctx, rd, Unknown)
      Assign(@decode.reg_name(rd), "sp + " + imm.to_string())
    }

    // Compressed LUI
    @decode.C_LUI(rd, imm) => {
      // C.LUI loads a 6-bit immediate, shifts it left by 12 bits
      let actual_value = imm << 12
      let addr = actual_value.reinterpret_as_uint()

      match ctx.string_map.get(addr) {
        Some(s) => {
          set_reg_value(ctx, rd, StringAddr(s))
          // Don't generate assignment for intermediate address calculation
          Comment("" + @decode.reg_name(rd) + " = &" + s)
        }
        None => {
          set_reg_value(ctx, rd, Address(addr))
          // Don't show intermediate calculation unless it's used meaningfully
          Comment("" + @decode.reg_name(rd) + " = 0x" + uint_to_hex(addr))
        }
      }
    }
    // Compressed LI
    @decode.C_LI(rd, imm) => {
      set_reg_value(ctx, rd, Constant(imm))
      // Only show assignment for argument registers (a0-a7)
      if rd >= 10U && rd <= 17U {
        Assign(@decode.reg_name(rd), imm.to_string())
      } else {
        Comment("" + @decode.reg_name(rd) + " = " + imm.to_string())
      }
    }

    // Compressed move
    @decode.C_MV(rd, rs2) => {
      let val = get_reg_value(ctx, rs2)
      set_reg_value(ctx, rd, val)
      // Show assignment if:
      // 1. Source has a string value (meaningful)
      // 2. Destination is an argument register (a0-a7)
      match val {
        StringAddr(s) => Assign(@decode.reg_name(rd), "\"" + s + "\"")
        _ =>
          if rd >= 10U && rd <= 17U {
            Assign(@decode.reg_name(rd), @decode.reg_name(rs2))
          } else {
            Comment("" + @decode.reg_name(rd) + " = " + @decode.reg_name(rs2))
          }
      }
    }

    // Compressed ADD
    @decode.C_ADD(rd, rs2) => {
      set_reg_value(ctx, rd, Unknown)
      Assign(
        @decode.reg_name(rd),
        @decode.reg_name(rd) + " + " + @decode.reg_name(rs2),
      )
    }

    // Register arithmetic
    @decode.ADD(rd, rs1, rs2) => {
      set_reg_value(ctx, rd, Unknown)
      // Only show arithmetic for argument registers or if operands are interesting
      if rd >= 10U && rd <= 17U {
        BinOp(
          @decode.reg_name(rd),
          @decode.reg_name(rs1),
          BinOp::Add,
          @decode.reg_name(rs2),
        )
      } else {
        Comment(
          "" +
          @decode.reg_name(rd) +
          " = " +
          @decode.reg_name(rs1) +
          " + " +
          @decode.reg_name(rs2),
        )
      }
    }
    @decode.SUB(rd, rs1, rs2) => {
      set_reg_value(ctx, rd, Unknown)
      BinOp(
        @decode.reg_name(rd),
        @decode.reg_name(rs1),
        BinOp::Sub,
        @decode.reg_name(rs2),
      )
    }

    // Default fallback
    _ => Raw(@disasm.disassemble(inst))
  }
}

///|
/// Get function call arguments from register values
fn get_call_arguments(ctx : DecompileContext) -> Array[String] {
  let args : Array[String] = []

  // Only check a0 (x10) for the first argument
  // In RISC-V calling convention, arguments are passed in a0-a7
  // But we only include registers that have known values
  let a0 = 10U
  match get_reg_value(ctx, a0) {
    StringAddr(s) => args.push("\"" + s + "\"")
    Constant(c) => args.push(c.to_string())
    Address(a) => args.push("0x" + uint_to_hex(a))
    _ => ()
  }

  args
}

///|
/// Format statement to string
fn format_statement(stmt : Statement) -> String {
  match stmt {
    Assign(dest, src) => "  " + dest + " = " + src + ";"
    BinOp(dest, left, op, right) => {
      let op_str = match op {
        BinOp::Add => "+"
        BinOp::Sub => "-"
        BinOp::And => "&"
        BinOp::Or => "|"
        BinOp::Xor => "^"
        BinOp::Shl => "<<"
        BinOp::Shr => ">>"
        BinOp::Mul => "*"
        BinOp::Div => "/"
        BinOp::Mod => "%"
      }
      "  " + dest + " = " + left + " " + op_str + " " + right + ";"
    }
    Load(dest, addr, _) => "  " + dest + " = *(" + addr + ");"
    Store(addr, value, _) => "  *(" + addr + ") = " + value + ";"
    Call(name, args) =>
      if args.length() > 0 {
        let mut arg_str = ""
        for i = 0; i < args.length(); i = i + 1 {
          if i > 0 {
            arg_str = arg_str + ", "
          }
          arg_str = arg_str + args[i]
        }
        "  " + name + "(" + arg_str + ");"
      } else {
        "  " + name + "();"
      }
    Return(None) => "  return;"
    Return(Some(val)) => "  return " + val + ";"
    StackOp(StackOpType::Push, Some(reg), off) =>
      "  // push " + reg + " [sp" + format_offset(off) + "]"
    StackOp(StackOpType::Pop, Some(reg), off) =>
      "  // pop " + reg + " [sp" + format_offset(off) + "]"
    StackOp(StackOpType::Adjust, _, off) =>
      if off < 0 {
        "  // sp = sp - " + (-off).to_string() + " (allocate)"
      } else {
        "  // sp = sp + " + off.to_string() + " (deallocate)"
      }
    StackOp(_, _, _) => "  // stack operation"
    Comment(text) => "  // " + text
    Raw(text) => "  // " + text
    VarDecl(name, ty, init) => "  " + ty + " " + name + " = " + init + ";"
    Break => "  break;"
    Continue => "  continue;"
    Label(name) => name + ":"
    Goto(target) => "  goto " + target + ";"
  }
}

///|
/// Format offset for display
fn format_offset(off : Int) -> String {
  if off > 0 {
    "+" + off.to_string()
  } else if off < 0 {
    off.to_string()
  } else {
    ""
  }
}

///|
/// Decompile function entry point
pub fn decompile_function(
  instructions : FixedArray[DecodedInst],
  cfg : CFG,
  symbol_map : Map[UInt, String],
  string_map : Map[UInt, String],
) -> String {
  decompile(cfg, instructions, symbol_map, string_map)
}

// ============================================================================
// Structured Control Flow Analysis
// ============================================================================

///|
/// Build dominator tree from CFG
/// Uses iterative algorithm for computing immediate dominators
pub fn build_dominator_tree(cfg : CFG) -> DominatorTree {
  if cfg.blocks.length() == 0 {
    return {
      idom: Map::new(),
      dom_children: Map::new(),
      dom_frontier: Map::new(),
      post_idom: Map::new(),
    }
  }

  let entry = cfg.entry_points[0]

  // Collect all block addresses
  let blocks : Array[UInt] = []
  for block in cfg.blocks {
    blocks.push(block.start_addr)
  }

  // Build predecessor map
  let preds : Map[UInt, Array[UInt]] = {}
  for block in cfg.blocks {
    preds[block.start_addr] = []
  }
  for edge in cfg.edges {
    match preds.get(edge.to_block) {
      Some(arr) => arr.push(edge.from_block)
      None => preds[edge.to_block] = [edge.from_block]
    }
  }

  // Build successor map
  let succs : Map[UInt, Array[UInt]] = {}
  for block in cfg.blocks {
    succs[block.start_addr] = []
  }
  for edge in cfg.edges {
    if edge.edge_type != EdgeType::Return {
      match succs.get(edge.from_block) {
        Some(arr) => arr.push(edge.to_block)
        None => succs[edge.from_block] = [edge.to_block]
      }
    }
  }

  // Initialize: entry dominates itself, others have all blocks as dominators
  let idom : Map[UInt, UInt] = {}
  idom[entry] = entry

  // Collect all block addresses into a set for intersection
  let all_blocks : Array[UInt] = []
  for block in cfg.blocks {
    all_blocks.push(block.start_addr)
  }

  // Iterative fixed-point computation
  let mut changed = true
  while changed {
    changed = false
    for block_addr in all_blocks {
      if block_addr == entry {
        continue
      }
      // Get predecessors
      let pred_list = preds.get(block_addr).or([])
      if pred_list.length() == 0 {
        continue
      }
      // Find first processed predecessor
      let mut new_idom : UInt? = None
      for p in pred_list {
        if idom.contains(p) {
          new_idom = Some(p)
          break
        }
      }
      match new_idom {
        Some(init_dom) => {
          // Intersect with other predecessors
          let mut dom = init_dom
          for p in pred_list {
            if idom.contains(p) && p != dom {
              dom = intersect(idom, dom, p)
            }
          }
          // Check if changed
          match idom.get(block_addr) {
            Some(old) =>
              if old != dom {
                idom[block_addr] = dom
                changed = true
              }
            None => {
              idom[block_addr] = dom
              changed = true
            }
          }
        }
        None => ()
      }
    }
  }

  // Build dominator children
  let dom_children : Map[UInt, Array[UInt]] = {}
  for block in cfg.blocks {
    dom_children[block.start_addr] = []
  }
  for block in cfg.blocks {
    let addr = block.start_addr
    if addr != entry {
      match idom.get(addr) {
        Some(parent) =>
          match dom_children.get(parent) {
            Some(children) => children.push(addr)
            None => dom_children[parent] = [addr]
          }
        None => ()
      }
    }
  }

  // Build dominance frontier
  let dom_frontier : Map[UInt, Array[UInt]] = {}
  for block in cfg.blocks {
    dom_frontier[block.start_addr] = []
  }
  for block in cfg.blocks {
    let addr = block.start_addr
    let pred_list = preds.get(addr).or([])
    if pred_list.length() >= 2 {
      for p in pred_list {
        let mut runner = p
        while true {
          match idom.get(runner) {
            Some(runner_idom) => {
              if runner_idom == addr {
                break
              }
              match dom_frontier.get(runner_idom) {
                Some(df) => {
                  // Add addr to frontier if not already present
                  let mut found = false
                  for x in df {
                    if x == addr {
                      found = true
                      break
                    }
                  }
                  if !found {
                    df.push(addr)
                  }
                }
                None => dom_frontier[runner_idom] = [addr]
              }
              runner = runner_idom
            }
            None => break
          }
        }
      }
    }
  }

  { idom, dom_children, dom_frontier, post_idom: Map::new() }
}

///|
/// Intersect helper for dominator computation
fn intersect(idom : Map[UInt, UInt], a : UInt, b : UInt) -> UInt {
  let mut finger1 = a
  let mut finger2 = b
  while finger1 != finger2 {
    // Move finger1 up if it's "after" finger2 (simple comparison)
    while finger1 > finger2 {
      match idom.get(finger1) {
        Some(d) => finger1 = d
        None => break
      }
    }
    while finger2 > finger1 {
      match idom.get(finger2) {
        Some(d) => finger2 = d
        None => break
      }
    }
  }
  finger1
}

///|
/// Detect natural loops in CFG using dominator tree
pub fn detect_loops(cfg : CFG, dom_tree : DominatorTree) -> LoopInfo {
  let loops : Array[NaturalLoop] = []
  let block_to_loops : Map[UInt, Array[Int]] = {}
  let mut max_depth = 0

  // Find back edges: edges where target dominates source
  for edge in cfg.edges {
    // Check if this is a back edge (target dominates source)
    let mut is_back_edge = false
    let mut check = edge.from_block
    while true {
      match dom_tree.idom.get(check) {
        Some(idom) => {
          if idom == edge.to_block {
            is_back_edge = true
            break
          }
          check = idom
        }
        None => break
      }
    }

    if is_back_edge {
      // Found a natural loop with header = edge.to_block
      let header = edge.to_block
      let body : Array[UInt] = [header]

      // Collect all blocks in the loop body
      // Using worklist algorithm
      let worklist : Array[UInt] = [edge.from_block]
      while worklist.length() > 0 {
        match worklist.pop() {
          Some(block) => {
            // Add to body if not already present
            let mut found = false
            for b in body {
              if b == block {
                found = true
                break
              }
            }
            if !found {
              body.push(block)
              // Add predecessors to worklist
              for e in cfg.edges {
                if e.to_block == block && e.edge_type != EdgeType::Return {
                  worklist.push(e.from_block)
                }
              }
            }
          }
          None => ()
        }
      }

      let loop_idx = loops.length()
      loops.push(NaturalLoop::{
        header,
        back_edges: [edge.from_block],
        body,
        depth: 1,
        parent: None,
        loop_type: LoopType::Unknown,
      })

      // Update block_to_loops mapping
      for b in body {
        match block_to_loops.get(b) {
          Some(arr) => arr.push(loop_idx)
          None => block_to_loops[b] = [loop_idx]
        }
      }
    }
  }

  // Calculate nesting depth and build final loops
  let final_loops : Array[NaturalLoop] = []
  for i = 0; i < loops.length(); i = i + 1 {
    let mut depth = 1
    let header = loops[i].header
    for j = 0; j < loops.length(); j = j + 1 {
      if i != j {
        // Check if loops[j] contains loops[i]
        let mut contains = false
        for b in loops[j].body {
          if b == header {
            contains = true
            break
          }
        }
        if contains {
          depth = depth + 1
        }
      }
    }
    final_loops.push(NaturalLoop::{
      header: loops[i].header,
      back_edges: loops[i].back_edges,
      body: loops[i].body,
      depth,
      parent: loops[i].parent,
      loop_type: loops[i].loop_type,
    })
    if depth > max_depth {
      max_depth = depth
    }
  }

  { loops: final_loops, block_to_loops, max_depth }
}

///|
/// Extract condition from a branch instruction
pub fn extract_condition(inst : @decode.Instruction) -> ConditionExpr {
  match inst {
    @decode.BEQ(rs1, rs2, _) =>
      ConditionExpr::Compare(
        CompareOp::Eq,
        @decode.reg_name(rs1),
        @decode.reg_name(rs2),
      )
    @decode.BNE(rs1, rs2, _) =>
      ConditionExpr::Compare(
        CompareOp::Ne,
        @decode.reg_name(rs1),
        @decode.reg_name(rs2),
      )
    @decode.BLT(rs1, rs2, _) =>
      ConditionExpr::Compare(
        CompareOp::Lt,
        @decode.reg_name(rs1),
        @decode.reg_name(rs2),
      )
    @decode.BGE(rs1, rs2, _) =>
      ConditionExpr::Compare(
        CompareOp::Ge,
        @decode.reg_name(rs1),
        @decode.reg_name(rs2),
      )
    @decode.BLTU(rs1, rs2, _) =>
      ConditionExpr::Compare(
        CompareOp::Ltu,
        @decode.reg_name(rs1),
        @decode.reg_name(rs2),
      )
    @decode.BGEU(rs1, rs2, _) =>
      ConditionExpr::Compare(
        CompareOp::Geu,
        @decode.reg_name(rs1),
        @decode.reg_name(rs2),
      )
    @decode.C_BEQZ(rs1, _) =>
      ConditionExpr::Compare(CompareOp::Eq, @decode.reg_name(rs1), "0")
    @decode.C_BNEZ(rs1, _) =>
      ConditionExpr::Compare(CompareOp::Ne, @decode.reg_name(rs1), "0")
    _ => ConditionExpr::True
  }
}

///|
/// Negate a condition
pub fn negate_condition(cond : ConditionExpr) -> ConditionExpr {
  match cond {
    ConditionExpr::Compare(op, left, right) => {
      let neg_op = match op {
        CompareOp::Eq => CompareOp::Ne
        CompareOp::Ne => CompareOp::Eq
        CompareOp::Lt => CompareOp::Ge
        CompareOp::Le => CompareOp::Gt
        CompareOp::Gt => CompareOp::Le
        CompareOp::Ge => CompareOp::Lt
        CompareOp::Ltu => CompareOp::Geu
        CompareOp::Geu => CompareOp::Ltu
      }
      ConditionExpr::Compare(neg_op, left, right)
    }
    ConditionExpr::True => ConditionExpr::False
    ConditionExpr::False => ConditionExpr::True
    ConditionExpr::Not(c) => c
    ConditionExpr::And(a, b) =>
      ConditionExpr::Or(negate_condition(a), negate_condition(b))
    ConditionExpr::Or(a, b) =>
      ConditionExpr::And(negate_condition(a), negate_condition(b))
    ConditionExpr::Single(s) => ConditionExpr::Compare(CompareOp::Eq, s, "0")
  }
}

///|
/// Structure a CFG into high-level control structures
pub fn structure_cfg(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
) -> StructuredCFG {
  let dom_tree = build_dominator_tree(cfg)
  let loop_info = detect_loops(cfg, dom_tree)

  // Build structure tree
  let structure = build_structure(
    cfg,
    instructions,
    dom_tree,
    loop_info,
    cfg.entry_points[0],
  )

  { cfg, dom_tree, loop_info, structure }
}

///|
/// Build control structure tree recursively
fn build_structure(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
  dom_tree : DominatorTree,
  loop_info : LoopInfo,
  current_block : UInt,
) -> ControlStructure {
  // Find the basic block
  let mut current : BasicBlock? = None
  for block in cfg.blocks {
    if block.start_addr == current_block {
      current = Some(block)
      break
    }
  }

  match current {
    Some(block) => {
      // Get statements for this block
      let stmts = get_block_statements(instructions, block)

      // Check if this is a loop header
      let loop_idx = find_loop_header(loop_info, current_block)
      match loop_idx {
        Some(idx) =>
          // Build loop structure
          build_loop_structure(
            cfg, instructions, dom_tree, loop_info, idx, stmts,
          )
        None =>
          // Check if this block ends with a conditional branch
          build_conditional_structure(
            cfg, instructions, dom_tree, loop_info, block, stmts,
          )
      }
    }
    None => ControlStructure::Empty
  }
}

///|
/// Find if a block is a loop header
fn find_loop_header(loop_info : LoopInfo, addr : UInt) -> Int? {
  for i = 0; i < loop_info.loops.length(); i = i + 1 {
    if loop_info.loops[i].header == addr {
      return Some(i)
    }
  }
  None
}

///|
/// Build loop structure
fn build_loop_structure(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
  dom_tree : DominatorTree,
  loop_info : LoopInfo,
  loop_idx : Int,
  header_stmts : Array[Statement],
) -> ControlStructure {
  let loop_ = loop_info.loops[loop_idx]
  let header = loop_.header

  // Find the back edge to get the loop condition
  let mut condition : ConditionExpr = ConditionExpr::True
  let body_blocks : Array[UInt] = []

  for b in loop_.body {
    if b != header {
      body_blocks.push(b)
    }
  }

  // Find the branch instruction at the back edge source
  for edge in cfg.edges {
    if edge.from_block != header && edge.to_block == header {
      // This might be a back edge, check for condition at the end of this block
      for block in cfg.blocks {
        if block.start_addr == edge.from_block {
          // Get the last instruction to find the condition
          let block_insts = get_block_instructions(
            instructions,
            block.start_addr,
            block.end_addr,
          )
          if block_insts.length() > 0 {
            let last_inst = block_insts[block_insts.length() - 1]
            if is_conditional_branch(last_inst.inst) {
              condition = extract_condition(last_inst.inst)
            }
          }
          break
        }
      }
    }
  }

  // Build body structure
  let body_structures : Array[ControlStructure] = []
  for b in body_blocks {
    let struct_ = build_structure(cfg, instructions, dom_tree, loop_info, b)
    body_structures.push(struct_)
  }

  // Determine loop type
  let loop_type = classify_loop_type(cfg, loop_, header_stmts)

  match loop_type {
    LoopType::While =>
      ControlStructure::WhileLoop(
        condition,
        ControlStructure::Sequence(body_structures),
      )
    LoopType::DoWhile =>
      ControlStructure::DoWhileLoop(
        condition,
        ControlStructure::Sequence(body_structures),
      )
    LoopType::For => {
      // Try to extract for loop components from header statements
      let (init, update) = extract_for_loop_parts(header_stmts)
      ControlStructure::ForLoop(
        init,
        condition,
        update,
        ControlStructure::Sequence(body_structures),
      )
    }
    LoopType::Infinite =>
      ControlStructure::WhileLoop(
        ConditionExpr::True,
        ControlStructure::Sequence(body_structures),
      )
    _ =>
      ControlStructure::WhileLoop(
        condition,
        ControlStructure::Sequence(body_structures),
      )
  }
}

///|
/// Build conditional (if-else) structure
fn build_conditional_structure(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
  dom_tree : DominatorTree,
  loop_info : LoopInfo,
  block : BasicBlock,
  stmts : Array[Statement],
) -> ControlStructure {
  // Get outgoing edges from this block
  let mut taken_edge : UInt? = None
  let mut not_taken_edge : UInt? = None
  let mut branch_cond : ConditionExpr = ConditionExpr::True

  for edge in cfg.edges {
    if edge.from_block == block.start_addr {
      match edge.edge_type {
        EdgeType::BranchTaken => {
          taken_edge = Some(edge.to_block)
          // Extract condition from the block's last instruction
          let block_insts = get_block_instructions(
            instructions,
            block.start_addr,
            block.end_addr,
          )
          if block_insts.length() > 0 {
            let last_inst = block_insts[block_insts.length() - 1]
            branch_cond = extract_condition(last_inst.inst)
          }
        }
        EdgeType::BranchNotTaken => not_taken_edge = Some(edge.to_block)
        EdgeType::Return => {
          // Handle return
          let mut ret_val : String? = None
          for stmt in stmts {
            match stmt {
              Return(v) => {
                ret_val = v
                break
              }
              _ => ()
            }
          }
          return ControlStructure::Return(ret_val)
        }
        EdgeType::Jump => {
          // Unconditional jump - could be goto or tail call
          taken_edge = Some(edge.to_block)
          branch_cond = ConditionExpr::True
        }
        EdgeType::Call =>
          // Function call
          // Continue to next block
          ()
      }
    }
  }

  // Check if this is a conditional branch
  match (taken_edge, not_taken_edge) {
    (Some(taken), Some(not_taken)) => {
      // Find common successor for if-else detection
      let then_struct = build_structure(
        cfg, instructions, dom_tree, loop_info, taken,
      )
      let else_struct = build_structure(
        cfg, instructions, dom_tree, loop_info, not_taken,
      )

      // Combine with the statements in this block
      if stmts.length() > 0 {
        ControlStructure::Sequence([
          ControlStructure::BasicBlock(block.start_addr, block.end_addr, stmts),
          ControlStructure::IfThenElse(
            branch_cond,
            then_struct,
            Some(else_struct),
          ),
        ])
      } else {
        ControlStructure::IfThenElse(
          branch_cond,
          then_struct,
          Some(else_struct),
        )
      }
    }
    (Some(taken), None) => {
      // Only taken edge - could be if without else or unconditional jump
      let then_struct = build_structure(
        cfg, instructions, dom_tree, loop_info, taken,
      )

      if stmts.length() > 0 {
        ControlStructure::Sequence([
          ControlStructure::BasicBlock(block.start_addr, block.end_addr, stmts),
          ControlStructure::IfThenElse(branch_cond, then_struct, None),
        ])
      } else {
        ControlStructure::IfThenElse(branch_cond, then_struct, None)
      }
    }
    (None, Some(not_taken)) => {
      // Only fall-through - continue to next block
      let next_struct = build_structure(
        cfg, instructions, dom_tree, loop_info, not_taken,
      )

      if stmts.length() > 0 {
        ControlStructure::Sequence([
          ControlStructure::BasicBlock(block.start_addr, block.end_addr, stmts),
          next_struct,
        ])
      } else {
        next_struct
      }
    }
    (None, None) =>
      // No outgoing edges - return or end of function
      if stmts.length() > 0 {
        ControlStructure::BasicBlock(block.start_addr, block.end_addr, stmts)
      } else {
        ControlStructure::Empty
      }
  }
}

///|
/// Classify loop type based on control flow pattern
fn classify_loop_type(
  cfg : CFG,
  loop_ : NaturalLoop,
  header_stmts : Array[Statement],
) -> LoopType {
  // Simple heuristic: if condition is checked at header, it's while
  // If condition is at the end of body, it's do-while

  let header = loop_.header
  let mut has_header_branch = false

  // Check if header ends with a conditional branch to outside
  for edge in cfg.edges {
    if edge.from_block == header && edge.edge_type == EdgeType::BranchNotTaken {
      // Check if the target is outside the loop
      let mut outside = true
      for b in loop_.body {
        if b == edge.to_block {
          outside = false
          break
        }
      }
      if outside {
        has_header_branch = true
      }
    }
  }

  if has_header_branch {
    // Check for for-loop pattern: header has assignment + condition check
    let mut has_init = false
    let mut has_compare = false
    for stmt in header_stmts {
      match stmt {
        Assign(_, _) => has_init = true
        Comment(s) =>
          if s.contains("==") ||
            s.contains("!=") ||
            s.contains("<") ||
            s.contains(">") {
            has_compare = true
          }
        _ => ()
      }
    }
    if has_init && has_compare {
      LoopType::For
    } else {
      LoopType::While
    }
  } else {
    // Condition at end of body
    LoopType::DoWhile
  }
}

///|
/// Extract for loop initialization and update parts
fn extract_for_loop_parts(stmts : Array[Statement]) -> (ForInit, ForUpdate) {
  let mut init : ForInit = ForInit::None
  let mut update : ForUpdate = ForUpdate::None

  for stmt in stmts {
    match stmt {
      Assign(dest, src) =>
        if init == ForInit::None {
          init = ForInit::Assign(dest, src)
        } else {
          update = ForUpdate::Expr(stmt)
        }
      BinOp(dest, left, _, right) => update = ForUpdate::Expr(stmt)
      _ => ()
    }
  }

  (init, update)
}

///|
/// Remove leading whitespace from string
fn ltrim_string(s : String) -> String {
  let mut start = 0
  let chars = s.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if c != ' ' && c != '\t' && c != '\n' && c != '\r' {
      start = i
      break
    }
  }
  // Build result string from start index
  let mut result = ""
  for i = start; i < chars.length(); i = i + 1 {
    result = result + chars[i].to_string()
  }
  result
}

///|
/// Get statements for a basic block
fn get_block_statements(
  instructions : FixedArray[DecodedInst],
  block : BasicBlock,
) -> Array[Statement] {
  let ctx = DecompileContext::new(Map::new(), Map::new())
  let stmts : Array[Statement] = []
  let block_insts = get_block_instructions(
    instructions,
    block.start_addr,
    block.end_addr,
  )

  for inst_info in block_insts {
    // Skip the last instruction if it's a terminator
    let is_last = inst_info.addr == block.end_addr
    let is_term = is_terminator(inst_info.inst)

    if !is_last || !is_term {
      let stmt = analyze_instruction(inst_info, ctx)
      stmts.push(stmt)
    }
  }

  stmts
}

///|
/// Format control structure to pseudo-code string
pub fn format_control_structure(cs : ControlStructure, indent : Int) -> String {
  let indent_str = make_indent(indent)

  match cs {
    ControlStructure::Sequence(items) => {
      let mut result = ""
      for item in items {
        result = result + format_control_structure(item, indent)
      }
      result
    }
    ControlStructure::IfThenElse(cond, then_body, else_body) => {
      let cond_str = format_condition(cond)
      let mut result = indent_str + "if (" + cond_str + ") {\n"
      result = result + format_control_structure(then_body, indent + 2)
      result = result + indent_str + "}"

      match else_body {
        Some(else_cs) =>
          match else_cs {
            ControlStructure::IfThenElse(_, _, _) => {
              // else-if chain
              result = result + " else "
              // Remove leading spaces from nested if
              let nested = format_control_structure(else_cs, 0)
              let trimmed = ltrim_string(nested)
              result = result + trimmed
            }
            _ => {
              result = result + " else {\n"
              result = result + format_control_structure(else_cs, indent + 2)
              result = result + indent_str + "}"
            }
          }
        None => ()
      }
      result + "\n"
    }
    ControlStructure::WhileLoop(cond, body) => {
      let cond_str = format_condition(cond)
      let mut result = indent_str + "while (" + cond_str + ") {\n"
      result = result + format_control_structure(body, indent + 2)
      result = result + indent_str + "}\n"
      result
    }
    ControlStructure::DoWhileLoop(cond, body) => {
      let cond_str = format_condition(cond)
      let mut result = indent_str + "do {\n"
      result = result + format_control_structure(body, indent + 2)
      result = result + indent_str + "} while (" + cond_str + ");\n"
      result
    }
    ControlStructure::ForLoop(init, cond, update, body) => {
      let init_str = format_for_init(init)
      let cond_str = format_condition(cond)
      let update_str = format_for_update(update)
      let mut result = indent_str +
        "for (" +
        init_str +
        "; " +
        cond_str +
        "; " +
        update_str +
        ") {\n"
      result = result + format_control_structure(body, indent + 2)
      result = result + indent_str + "}\n"
      result
    }
    ControlStructure::BasicBlock(start, end, stmts) => {
      let mut result = indent_str +
        "// Block 0x" +
        uint_to_hex(start) +
        " - 0x" +
        uint_to_hex(end) +
        "\n"
      for stmt in stmts {
        result = result + format_statement_at(stmt, indent) + "\n"
      }
      result
    }
    ControlStructure::Return(None) => indent_str + "return;\n"
    ControlStructure::Return(Some(val)) => indent_str + "return " + val + ";\n"
    ControlStructure::Break => indent_str + "break;\n"
    ControlStructure::Continue => indent_str + "continue;\n"
    ControlStructure::Call(name) => indent_str + name + "();\n"
    ControlStructure::Unknown(msg) => indent_str + "// UNKNOWN: " + msg + "\n"
    ControlStructure::Empty => ""
    ControlStructure::Switch(expr, cases, default) => {
      let mut result = indent_str + "switch (" + expr + ") {\n"
      for case in cases {
        for v in case.values {
          result = result + indent_str + "  case " + v.to_string() + ":\n"
        }
        result = result + format_control_structure(case.body, indent + 4)
        if !case.fallthrough {
          result = result + indent_str + "    break;\n"
        }
      }
      match default {
        Some(def) => {
          result = result + indent_str + "  default:\n"
          result = result + format_control_structure(def, indent + 4)
        }
        None => ()
      }
      result + indent_str + "}\n"
    }
  }
}

///|
/// Format condition expression
fn format_condition(cond : ConditionExpr) -> String {
  match cond {
    ConditionExpr::Compare(op, left, right) => {
      let op_str = match op {
        CompareOp::Eq => "=="
        CompareOp::Ne => "!="
        CompareOp::Lt => "<"
        CompareOp::Le => "<="
        CompareOp::Gt => ">"
        CompareOp::Ge => ">="
        CompareOp::Ltu => "<" // Display same as signed, type context determines unsigned
        CompareOp::Geu => ">="
      }
      left + " " + op_str + " " + right
    }
    ConditionExpr::Single(s) => s
    ConditionExpr::True => "true"
    ConditionExpr::False => "false"
    ConditionExpr::Not(c) => "!(" + format_condition(c) + ")"
    ConditionExpr::And(a, b) =>
      "(" + format_condition(a) + " && " + format_condition(b) + ")"
    ConditionExpr::Or(a, b) =>
      "(" + format_condition(a) + " || " + format_condition(b) + ")"
  }
}

///|
/// Format for loop initialization
fn format_for_init(init : ForInit) -> String {
  match init {
    ForInit::VarDecl(name, typ, val) => typ + " " + name + " = " + val
    ForInit::Assign(dest, src) => dest + " = " + src
    ForInit::None => ""
  }
}

///|
/// Format for loop update
fn format_for_update(update : ForUpdate) -> String {
  match update {
    ForUpdate::Expr(stmt) => format_statement_inline(stmt)
    ForUpdate::Multi(stmts) => {
      let mut result = ""
      for i = 0; i < stmts.length(); i = i + 1 {
        if i > 0 {
          result = result + ", "
        }
        result = result + format_statement_inline(stmts[i])
      }
      result
    }
    ForUpdate::None => ""
  }
}

///|
/// Format statement inline (without newline)
fn format_statement_inline(stmt : Statement) -> String {
  match stmt {
    Assign(dest, src) => dest + " = " + src
    BinOp(dest, left, op, right) => {
      let op_str = match op {
        BinOp::Add => "+"
        BinOp::Sub => "-"
        BinOp::And => "&"
        BinOp::Or => "|"
        BinOp::Xor => "^"
        BinOp::Shl => "<<"
        BinOp::Shr => ">>"
        BinOp::Mul => "*"
        BinOp::Div => "/"
        BinOp::Mod => "%"
      }
      dest + " = " + left + " " + op_str + " " + right
    }
    _ => ""
  }
}

///|
/// Format statement at given indentation
fn format_statement_at(stmt : Statement, indent : Int) -> String {
  let indent_str = make_indent(indent)
  match stmt {
    Assign(dest, src) => indent_str + dest + " = " + src + ";"
    BinOp(dest, left, op, right) => {
      let op_str = match op {
        BinOp::Add => "+"
        BinOp::Sub => "-"
        BinOp::And => "&"
        BinOp::Or => "|"
        BinOp::Xor => "^"
        BinOp::Shl => "<<"
        BinOp::Shr => ">>"
        BinOp::Mul => "*"
        BinOp::Div => "/"
        BinOp::Mod => "%"
      }
      indent_str + dest + " = " + left + " " + op_str + " " + right + ";"
    }
    Load(dest, addr, _) => indent_str + dest + " = *(" + addr + ");"
    Store(addr, value, _) => indent_str + "*(" + addr + ") = " + value + ";"
    Call(name, args) =>
      if args.length() > 0 {
        let mut arg_str = ""
        for i = 0; i < args.length(); i = i + 1 {
          if i > 0 {
            arg_str = arg_str + ", "
          }
          arg_str = arg_str + args[i]
        }
        indent_str + name + "(" + arg_str + ");"
      } else {
        indent_str + name + "();"
      }
    Return(None) => indent_str + "return;"
    Return(Some(val)) => indent_str + "return " + val + ";"
    Break => indent_str + "break;"
    Continue => indent_str + "continue;"
    Comment(text) => indent_str + "// " + text
    Raw(text) => indent_str + "// " + text
    VarDecl(name, typ, val) => indent_str + typ + " " + name + " = " + val + ";"
    Label(name) => name + ":"
    Goto(name) => indent_str + "goto " + name + ";"
    StackOp(StackOpType::Push, Some(reg), off) =>
      indent_str + "// push " + reg + " [sp" + format_offset(off) + "]"
    StackOp(StackOpType::Pop, Some(reg), off) =>
      indent_str + "// pop " + reg + " [sp" + format_offset(off) + "]"
    StackOp(StackOpType::Adjust, _, off) =>
      if off < 0 {
        indent_str + "// sp = sp - " + (-off).to_string() + " (allocate)"
      } else {
        indent_str + "// sp = sp + " + off.to_string() + " (deallocate)"
      }
    StackOp(_, _, _) => indent_str + "// stack operation"
  }
}

///|
/// Create indentation string
fn make_indent(n : Int) -> String {
  let mut result = ""
  for i = 0; i < n; i = i + 1 {
    result = result + " "
  }
  result
}

///|
/// Structured decompilation - main entry point
pub fn decompile_structured(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
  symbol_map : Map[UInt, String],
  string_map : Map[UInt, String],
) -> String {
  if cfg.blocks.length() == 0 {
    return "// No code blocks found\n"
  }

  let structured = structure_cfg(cfg, instructions)
  let mut output = ""

  // Try to find function name from entry point
  let entry = cfg.entry_points[0]
  let func_name = match symbol_map.get(entry) {
    Some(name) => name
    None => "func_" + uint_to_hex(entry)
  }

  output = output + "// Function: " + func_name + "\n"
  output = output + "// Entry: 0x" + uint_to_hex(entry) + "\n"
  output = output + "\n"

  // Output structured code
  output = output + format_control_structure(structured.structure, 0)

  output
}
