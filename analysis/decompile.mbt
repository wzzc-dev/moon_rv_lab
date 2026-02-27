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
  Sequence(Array[ControlStructure])
  IfThenElse(ConditionExpr, ControlStructure, ControlStructure?)
  WhileLoop(ConditionExpr, ControlStructure)
  BasicBlock(UInt, UInt, Array[Statement])
  Call(String)
  Return
  Unknown(String)
} derive(Show)

///|
/// Condition expression
pub enum ConditionExpr {
  Compare(CompareOp, String, String)
  Single(String)
  True
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
