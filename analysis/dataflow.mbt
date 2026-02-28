///| Data flow analysis module for RISC-V

///| Provides def-use chains and live variable analysis

///|
/// Register operand role
pub enum OperandRole {
  /// Register is read (source operand)
  Use
  /// Register is written (destination operand)
  Def
  /// Register is both read and written
  UseDef
} derive(Show, Eq)

///|
/// Register operand info
pub struct RegOperand {
  /// Register number (0-31 for x regs, 32-63 for f regs)
  reg : UInt
  /// Is this a floating-point register?
  is_float : Bool
  /// Role of this operand
  role : OperandRole
} derive(Show)

///|
/// Instruction register operands
pub struct InstOperands {
  /// All register operands in this instruction
  operands : FixedArray[RegOperand]
} derive(Show)

///|
/// Get register operands for an instruction
pub fn get_operands(inst : @decode.Instruction) -> InstOperands {
  let ops : Array[RegOperand] = []

  match inst {
    // U-type instructions
    @decode.LUI(rd, _) | @decode.AUIPC(rd, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    // J-type instructions
    @decode.JAL(rd, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    // JALR: rd (def), rs1 (use)
    @decode.JALR(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Branch instructions (use rs1, rs2)
    @decode.BEQ(rs1, rs2, _)
    | @decode.BNE(rs1, rs2, _)
    | @decode.BLT(rs1, rs2, _)
    | @decode.BGE(rs1, rs2, _)
    | @decode.BLTU(rs1, rs2, _)
    | @decode.BGEU(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Load instructions (def rd, use rs1)
    @decode.LB(rd, rs1, _)
    | @decode.LH(rd, rs1, _)
    | @decode.LW(rd, rs1, _)
    | @decode.LBU(rd, rs1, _)
    | @decode.LHU(rd, rs1, _)
    | @decode.LD(rd, rs1, _)
    | @decode.LWU(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Store instructions (use rs1, rs2)
    @decode.SB(rs1, rs2, _)
    | @decode.SH(rs1, rs2, _)
    | @decode.SW(rs1, rs2, _)
    | @decode.SD(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Immediate arithmetic (def rd, use rs1)
    @decode.ADDI(rd, rs1, _)
    | @decode.SLTI(rd, rs1, _)
    | @decode.SLTIU(rd, rs1, _)
    | @decode.XORI(rd, rs1, _)
    | @decode.ORI(rd, rs1, _)
    | @decode.ANDI(rd, rs1, _)
    | @decode.SLLI(rd, rs1, _)
    | @decode.SRLI(rd, rs1, _)
    | @decode.SRAI(rd, rs1, _)
    | @decode.ADDIW(rd, rs1, _)
    | @decode.SLLIW(rd, rs1, _)
    | @decode.SRLIW(rd, rs1, _)
    | @decode.SRAIW(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Register arithmetic (def rd, use rs1, rs2)
    @decode.ADD(rd, rs1, rs2)
    | @decode.SUB(rd, rs1, rs2)
    | @decode.SLL(rd, rs1, rs2)
    | @decode.SLT(rd, rs1, rs2)
    | @decode.SLTU(rd, rs1, rs2)
    | @decode.XOR(rd, rs1, rs2)
    | @decode.SRL(rd, rs1, rs2)
    | @decode.SRA(rd, rs1, rs2)
    | @decode.OR(rd, rs1, rs2)
    | @decode.AND(rd, rs1, rs2)
    | @decode.ADDW(rd, rs1, rs2)
    | @decode.SUBW(rd, rs1, rs2)
    | @decode.SLLW(rd, rs1, rs2)
    | @decode.SRLW(rd, rs1, rs2)
    | @decode.SRAW(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // RV32M extension
    @decode.MUL(rd, rs1, rs2)
    | @decode.MULH(rd, rs1, rs2)
    | @decode.MULHSU(rd, rs1, rs2)
    | @decode.MULHU(rd, rs1, rs2)
    | @decode.DIV(rd, rs1, rs2)
    | @decode.DIVU(rd, rs1, rs2)
    | @decode.REM(rd, rs1, rs2)
    | @decode.REMU(rd, rs1, rs2)
    | @decode.MULW(rd, rs1, rs2)
    | @decode.DIVW(rd, rs1, rs2)
    | @decode.DIVUW(rd, rs1, rs2)
    | @decode.REMW(rd, rs1, rs2)
    | @decode.REMUW(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // RV32A extension
    @decode.LR_W(rd, rs1, _, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.SC_W(rd, rs1, rs2, _, _)
    | @decode.AMOSWAP_W(rd, rs1, rs2, _, _)
    | @decode.AMOADD_W(rd, rs1, rs2, _, _)
    | @decode.AMOXOR_W(rd, rs1, rs2, _, _)
    | @decode.AMOAND_W(rd, rs1, rs2, _, _)
    | @decode.AMOOR_W(rd, rs1, rs2, _, _)
    | @decode.AMOMIN_W(rd, rs1, rs2, _, _)
    | @decode.AMOMAX_W(rd, rs1, rs2, _, _)
    | @decode.AMOMINU_W(rd, rs1, rs2, _, _)
    | @decode.AMOMAXU_W(rd, rs1, rs2, _, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // RV64A extension
    @decode.LR_D(rd, rs1, _, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.SC_D(rd, rs1, rs2, _, _)
    | @decode.AMOSWAP_D(rd, rs1, rs2, _, _)
    | @decode.AMOADD_D(rd, rs1, rs2, _, _)
    | @decode.AMOXOR_D(rd, rs1, rs2, _, _)
    | @decode.AMOAND_D(rd, rs1, rs2, _, _)
    | @decode.AMOOR_D(rd, rs1, rs2, _, _)
    | @decode.AMOMIN_D(rd, rs1, rs2, _, _)
    | @decode.AMOMAX_D(rd, rs1, rs2, _, _)
    | @decode.AMOMINU_D(rd, rs1, rs2, _, _)
    | @decode.AMOMAXU_D(rd, rs1, rs2, _, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zicsr instructions
    @decode.CSRRW(rd, _, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.CSRRS(rd, _, rs1) | @decode.CSRRC(rd, _, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.CSRRWI(rd, _, _)
    | @decode.CSRRSI(rd, _, _)
    | @decode.CSRRCI(rd, _, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    // Zba extension
    @decode.SH1ADD(rd, rs1, rs2)
    | @decode.SH2ADD(rd, rs1, rs2)
    | @decode.SH3ADD(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zba RV64 extension
    @decode.SH1ADD_UW(rd, rs1, rs2)
    | @decode.SH2ADD_UW(rd, rs1, rs2)
    | @decode.SH3ADD_UW(rd, rs1, rs2)
    | @decode.ADD_UW(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.SLLI_UW(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zbb extension
    @decode.CLZ(rd, rs1)
    | @decode.CTZ(rd, rs1)
    | @decode.CPOP(rd, rs1)
    | @decode.SEXT_B(rd, rs1)
    | @decode.SEXT_H(rd, rs1)
    | @decode.ZEXT_H(rd, rs1)
    | @decode.ORC_B(rd, rs1)
    | @decode.REV8(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.ANDN(rd, rs1, rs2)
    | @decode.ORN(rd, rs1, rs2)
    | @decode.XNOR(rd, rs1, rs2)
    | @decode.MAX(rd, rs1, rs2)
    | @decode.MAXU(rd, rs1, rs2)
    | @decode.MIN(rd, rs1, rs2)
    | @decode.MINU(rd, rs1, rs2)
    | @decode.ROL(rd, rs1, rs2)
    | @decode.ROR(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.RORI(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zbb RV64 extension
    @decode.CLZW(rd, rs1) | @decode.CTZW(rd, rs1) | @decode.CPOPW(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.ROLW(rd, rs1, rs2) | @decode.RORW(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.RORIW(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zbc extension
    @decode.CLMUL(rd, rs1, rs2)
    | @decode.CLMULH(rd, rs1, rs2)
    | @decode.CLMULR(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zbs extension
    @decode.BCLR(rd, rs1, rs2)
    | @decode.BEXT(rd, rs1, rs2)
    | @decode.BINV(rd, rs1, rs2)
    | @decode.BSET(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.BCLRI(rd, rs1, _)
    | @decode.BEXTI(rd, rs1, _)
    | @decode.BINVI(rd, rs1, _)
    | @decode.BSETI(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // RV32C compressed instructions
    @decode.C_NOP => ignore(())
    @decode.C_ADDI4SPN(rd, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      // sp is implicitly used
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
    }
    @decode.C_LW(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_SW(rs2, rs1, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_ADDI(rd, _) | @decode.C_LI(rd, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    @decode.C_JAL(_) => ignore(())
    @decode.C_ADDI16SP(_) =>
      ops.push(RegOperand::{
        reg: 2U,
        is_float: false,
        role: OperandRole::UseDef,
      })
    @decode.C_LUI(rd, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    @decode.C_SRLI(rd, _) | @decode.C_SRAI(rd, _) | @decode.C_ANDI(rd, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::UseDef,
        })
      }
    @decode.C_SUB(rd, rs2)
    | @decode.C_XOR(rd, rs2)
    | @decode.C_OR(rd, rs2)
    | @decode.C_AND(rd, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::UseDef,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_J(_) => ignore(())
    @decode.C_BEQZ(rs1, _) | @decode.C_BNEZ(rs1, _) =>
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    @decode.C_SLLI(rd, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::UseDef,
        })
      }
    @decode.C_LWSP(rd, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
    }
    @decode.C_JR(rs1) =>
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    @decode.C_MV(rd, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_EBREAK => ignore(())
    @decode.C_JALR(rs1) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      // ra is implicitly defined
      ops.push(RegOperand::{ reg: 1U, is_float: false, role: OperandRole::Def })
    }
    @decode.C_ADD(rd, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::UseDef,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_SWSP(rs2, _) => {
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
    }
    // RV32F extension
    @decode.FLW(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.FSW(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FADD_S(rd, rs1, rs2)
    | @decode.FSUB_S(rd, rs1, rs2)
    | @decode.FMUL_S(rd, rs1, rs2)
    | @decode.FDIV_S(rd, rs1, rs2)
    | @decode.FMIN_S(rd, rs1, rs2)
    | @decode.FMAX_S(rd, rs1, rs2)
    | @decode.FSGNJ_S(rd, rs1, rs2)
    | @decode.FSGNJN_S(rd, rs1, rs2)
    | @decode.FSGNJX_S(rd, rs1, rs2) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FSQRT_S(rd, rs1) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_W_S(rd, rs1, _)
    | @decode.FCVT_WU_S(rd, rs1, _)
    | @decode.FCVT_L_S(rd, rs1, _)
    | @decode.FCVT_LU_S(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FMV_X_W(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FEQ_S(rd, rs1, rs2)
    | @decode.FLT_S(rd, rs1, rs2)
    | @decode.FLE_S(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FCLASS_S(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_S_W(rd, rs1, _)
    | @decode.FCVT_S_WU(rd, rs1, _)
    | @decode.FCVT_S_L(rd, rs1, _)
    | @decode.FCVT_S_LU(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.FMV_W_X(rd, rs1) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // RV32D extension
    @decode.FLD(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.FSD(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FADD_D(rd, rs1, rs2)
    | @decode.FSUB_D(rd, rs1, rs2)
    | @decode.FMUL_D(rd, rs1, rs2)
    | @decode.FDIV_D(rd, rs1, rs2)
    | @decode.FMIN_D(rd, rs1, rs2)
    | @decode.FMAX_D(rd, rs1, rs2)
    | @decode.FSGNJ_D(rd, rs1, rs2)
    | @decode.FSGNJN_D(rd, rs1, rs2)
    | @decode.FSGNJX_D(rd, rs1, rs2) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FSQRT_D(rd, rs1) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_S_D(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_D_S(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FEQ_D(rd, rs1, rs2)
    | @decode.FLT_D(rd, rs1, rs2)
    | @decode.FLE_D(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FCLASS_D(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_W_D(rd, rs1, _)
    | @decode.FCVT_WU_D(rd, rs1, _)
    | @decode.FCVT_L_D(rd, rs1, _)
    | @decode.FCVT_LU_D(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_D_W(rd, rs1, _)
    | @decode.FCVT_D_WU(rd, rs1, _)
    | @decode.FCVT_D_L(rd, rs1, _)
    | @decode.FCVT_D_LU(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.FMV_X_D(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FMV_D_X(rd, rs1) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // RV32Q extension (quad-precision floating-point)
    @decode.FLQ(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.FSQ(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FADD_Q(rd, rs1, rs2)
    | @decode.FSUB_Q(rd, rs1, rs2)
    | @decode.FMUL_Q(rd, rs1, rs2)
    | @decode.FDIV_Q(rd, rs1, rs2)
    | @decode.FMIN_Q(rd, rs1, rs2)
    | @decode.FMAX_Q(rd, rs1, rs2)
    | @decode.FSGNJ_Q(rd, rs1, rs2)
    | @decode.FSGNJN_Q(rd, rs1, rs2)
    | @decode.FSGNJX_Q(rd, rs1, rs2) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FSQRT_Q(rd, rs1) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_Q_S(rd, rs1, _)
    | @decode.FCVT_Q_D(rd, rs1, _)
    | @decode.FCVT_S_Q(rd, rs1, _)
    | @decode.FCVT_D_Q(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FEQ_Q(rd, rs1, rs2)
    | @decode.FLT_Q(rd, rs1, rs2)
    | @decode.FLE_Q(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.FCLASS_Q(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_W_Q(rd, rs1, _)
    | @decode.FCVT_WU_Q(rd, rs1, _)
    | @decode.FCVT_L_Q(rd, rs1, _)
    | @decode.FCVT_LU_Q(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FCVT_Q_W(rd, rs1, _)
    | @decode.FCVT_Q_WU(rd, rs1, _)
    | @decode.FCVT_Q_L(rd, rs1, _)
    | @decode.FCVT_Q_LU(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.FMV_X_Q(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ops.push(RegOperand::{ reg: rs1, is_float: true, role: OperandRole::Use })
    }
    @decode.FMV_Q_X(rd, rs1) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Zcf/Zcd compressed floating point
    @decode.C_FLD(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_FLDSP(rd, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      // sp is always used
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
    }
    @decode.C_FLW(rd, rs1, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.C_FLWSP(rd, _) => {
      ops.push(RegOperand::{ reg: rd, is_float: true, role: OperandRole::Def })
      // sp is always used
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
    }
    @decode.C_FSD(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.C_FSDSP(rs2, _) => {
      // sp is always used
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.C_FSW(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    @decode.C_FSWSP(rs2, _) => {
      // sp is always used
      ops.push(RegOperand::{ reg: 2U, is_float: false, role: OperandRole::Use })
      ops.push(RegOperand::{ reg: rs2, is_float: true, role: OperandRole::Use })
    }
    // System instructions
    @decode.ECALL | @decode.EBREAK | @decode.FENCE(_, _) | @decode.FENCE_I =>
      ignore(())
    // Vector instructions - handle v0-v31 as vector registers
    // VSETVLI
    @decode.VSETVLI(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector loads: def vd, use rs1 (base address)
    @decode.VLE8_V(rd, rs1, _)
    | @decode.VLE16_V(rd, rs1, _)
    | @decode.VLE32_V(rd, rs1, _)
    | @decode.VLE64_V(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector stores: use rs1 (base), use vs2 (data)
    @decode.VSE8_V(rs1, rs2, _)
    | @decode.VSE16_V(rs1, rs2, _)
    | @decode.VSE32_V(rs1, rs2, _)
    | @decode.VSE64_V(rs1, rs2, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector arithmetic: def vd, use vs1, use vs2
    // Most vector-vector and vector-scalar instructions follow this pattern
    @decode.VADD_VV(rd, rs1, rs2, _)
    | @decode.VSUB_VV(rd, rs1, rs2, _)
    | @decode.VAND_VV(rd, rs1, rs2, _)
    | @decode.VOR_VV(rd, rs1, rs2, _)
    | @decode.VXOR_VV(rd, rs1, rs2, _)
    | @decode.VMUL_VV(rd, rs1, rs2, _)
    | @decode.VMUL_VX(rd, rs1, rs2, _)
    | @decode.VDIV_VV(rd, rs1, rs2, _)
    | @decode.VDIVU_VV(rd, rs1, rs2, _)
    | @decode.VREM_VV(rd, rs1, rs2, _)
    | @decode.VREMU_VV(rd, rs1, rs2, _)
    | @decode.VMULH_VV(rd, rs1, rs2, _)
    | @decode.VMULHU_VV(rd, rs1, rs2, _)
    | @decode.VMULHSU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector shift instructions
    @decode.VSLL_VV(rd, rs1, rs2, _)
    | @decode.VSRL_VV(rd, rs1, rs2, _)
    | @decode.VSRA_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector mask compare
    @decode.VMSEQ_VV(rd, rs1, rs2, _)
    | @decode.VMSNE_VV(rd, rs1, rs2, _)
    | @decode.VMSLT_VV(rd, rs1, rs2, _)
    | @decode.VMSLTU_VV(rd, rs1, rs2, _)
    | @decode.VMSLE_VV(rd, rs1, rs2, _)
    | @decode.VMSLEU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening multiply
    @decode.VWMUL_VV(rd, rs1, rs2, _) | @decode.VWMULSU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening add/sub
    @decode.VWADD_VV(rd, rs1, rs2, _)
    | @decode.VWADDU_VV(rd, rs1, rs2, _)
    | @decode.VWSUB_VV(rd, rs1, rs2, _)
    | @decode.VWSUBU_VV(rd, rs1, rs2, _)
    | @decode.VWADD_WV(rd, rs1, rs2, _)
    | @decode.VWADDU_WV(rd, rs1, rs2, _)
    | @decode.VWSUB_WV(rd, rs1, rs2, _)
    | @decode.VWSUBU_WV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector FP instructions - simplified handling
    @decode.VFADD_VV(rd, rs1, rs2, _)
    | @decode.VFSUB_VV(rd, rs1, rs2, _)
    | @decode.VFMUL_VV(rd, rs1, rs2, _)
    | @decode.VFDIV_VV(rd, rs1, rs2, _)
    | @decode.VFMIN_VV(rd, rs1, rs2, _)
    | @decode.VFMAX_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector reduction instructions
    @decode.VREDSUM_VS(rd, rs1, rs2, _)
    | @decode.VREDMAX_VS(rd, rs1, rs2, _)
    | @decode.VREDMIN_VS(rd, rs1, rs2, _)
    | @decode.VREDAND_VS(rd, rs1, rs2, _)
    | @decode.VREDOR_VS(rd, rs1, rs2, _)
    | @decode.VREDXOR_VS(rd, rs1, rs2, _)
    | @decode.VWREDSUM_VS(rd, rs1, rs2, _)
    | @decode.VWREDSUMU_VS(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector narrowing clip (separate immediate variants)
    @decode.VNCLIP_WV(rd, rs1, rs2, _) | @decode.VNCLIP_WX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VNCLIP_WI(rd, uimm, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(uimm)
    }
    @decode.VNCLIPU_WV(rd, rs1, rs2, _) | @decode.VNCLIPU_WX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VNCLIPU_WI(rd, uimm, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(uimm)
    }
    // Vector scalar shift (separate immediate variants)
    @decode.VSSRA_VV(rd, rs1, rs2, _)
    | @decode.VSSRA_VX(rd, rs1, rs2, _)
    | @decode.VSSRL_VV(rd, rs1, rs2, _)
    | @decode.VSSRL_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VSSRA_VI(rd, uimm, rs2, _) | @decode.VSSRL_VI(rd, uimm, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(uimm)
    }
    // Vector saturating add/sub
    @decode.VAADD_VV(rd, rs1, rs2, _)
    | @decode.VAADD_VX(rd, rs1, rs2, _)
    | @decode.VASUB_VV(rd, rs1, rs2, _)
    | @decode.VASUB_VX(rd, rs1, rs2, _)
    | @decode.VSSUB_VV(rd, rs1, rs2, _)
    | @decode.VSSUB_VX(rd, rs1, rs2, _)
    | @decode.VSSUBU_VV(rd, rs1, rs2, _)
    | @decode.VSSUBU_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector signed/unsigned add (separate immediate variants)
    @decode.VSADD_VV(rd, rs1, rs2, _)
    | @decode.VSADD_VX(rd, rs1, rs2, _)
    | @decode.VSADDU_VV(rd, rs1, rs2, _)
    | @decode.VSADDU_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VSADD_VI(rd, uimm, rs2, _) | @decode.VSADDU_VI(rd, uimm, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(uimm)
    }
    // Vector strided store (2 args)
    @decode.VS1R_V(rs1, rs2)
    | @decode.VS2R_V(rs1, rs2)
    | @decode.VS4R_V(rs1, rs2)
    | @decode.VS8R_V(rs1, rs2) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector unit-stride fault-only-first load (2 args)
    @decode.VL1RE8_V(rd, rs1)
    | @decode.VL1RE16_V(rd, rs1)
    | @decode.VL1RE32_V(rd, rs1)
    | @decode.VL1RE64_V(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector compress and gather
    @decode.VCOMPRESS_VM(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector gather (separate immediate variants)
    @decode.VRGATHER_VV(rd, rs1, rs2, _)
    | @decode.VRGATHER_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VRGATHER_VI(rd, uimm, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(uimm)
    }
    // Vector slide (separate immediate variants)
    @decode.VSLIDEUP_VX(rd, rs1, rs2, _)
    | @decode.VSLIDEDOWN_VX(rd, rs1, rs2, _)
    | @decode.VSLIDE1UP_VX(rd, rs1, rs2, _)
    | @decode.VSLIDE1DOWN_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VSLIDEUP_VI(rd, uimm, rs2, _)
    | @decode.VSLIDEDOWN_VI(rd, uimm, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(uimm)
    }
    // Vector mask instructions
    @decode.VID_V(rd, _, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    @decode.VIOTA_M(rd, rs2, _, _)
    | @decode.VPOPC_M(rd, rs2, _, _)
    | @decode.VFIRST_M(rd, rs2, _, _)
    | @decode.VMSBF_M(rd, rs2, _, _)
    | @decode.VMSIF_M(rd, rs2, _, _)
    | @decode.VMSOF_M(rd, rs2, _, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector setvl/setivli
    @decode.VSETVLI(rd, rs1, avl) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      ignore(avl)
    }
    @decode.VSETIVLI(rd, uimm, avl) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      ignore(uimm)
      ignore(avl)
    }
    @decode.VSETVL(rd, rs1, rs2) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector mask logical
    @decode.VMAND_MM(rd, rs1, rs2, _)
    | @decode.VMNAND_MM(rd, rs1, rs2, _)
    | @decode.VMANDN_MM(rd, rs1, rs2, _)
    | @decode.VMXOR_MM(rd, rs1, rs2, _)
    | @decode.VMOR_MM(rd, rs1, rs2, _)
    | @decode.VMNOR_MM(rd, rs1, rs2, _)
    | @decode.VMORN_MM(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float reduction
    @decode.VFREDSUM_VS(rd, rs1, rs2, _)
    | @decode.VFREDOSUM_VS(rd, rs1, rs2, _)
    | @decode.VFREDMAX_VS(rd, rs1, rs2, _)
    | @decode.VFREDMIN_VS(rd, rs1, rs2, _)
    | @decode.VFWREDSUM_VS(rd, rs1, rs2, _)
    | @decode.VFWREDOSUM_VS(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float reduction (unsigned)
    @decode.VREDMAXU_VS(rd, rs1, rs2, _)
    | @decode.VREDMINU_VS(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening float multiply
    @decode.VFWMUL_VF(rd, rs1, rs2, _) | @decode.VFWMUL_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening float add/sub
    @decode.VFWADD_VV(rd, rs1, rs2, _)
    | @decode.VFWADD_VF(rd, rs1, rs2, _)
    | @decode.VFWADD_WV(rd, rs1, rs2, _)
    | @decode.VFWADD_WF(rd, rs1, rs2, _)
    | @decode.VFWSUB_VV(rd, rs1, rs2, _)
    | @decode.VFWSUB_VF(rd, rs1, rs2, _)
    | @decode.VFWSUB_WV(rd, rs1, rs2, _)
    | @decode.VFWSUB_WF(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float move
    @decode.VFMV_S_F(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VFMV_F_S(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VFMV_V_F(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VFMERGE_VFM(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float classify
    @decode.VFCLASS_V(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float compare
    @decode.VMFEQ_VV(rd, rs1, rs2, _)
    | @decode.VMFNE_VV(rd, rs1, rs2, _)
    | @decode.VMFLT_VV(rd, rs1, rs2, _)
    | @decode.VMFLE_VV(rd, rs1, rs2, _)
    | @decode.VMFEQ_VF(rd, rs1, rs2, _)
    | @decode.VMFNE_VF(rd, rs1, rs2, _)
    | @decode.VMFLT_VF(rd, rs1, rs2, _)
    | @decode.VMFLE_VF(rd, rs1, rs2, _)
    | @decode.VMFGT_VF(rd, rs1, rs2, _)
    | @decode.VMFGE_VF(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float sign injection
    @decode.VFSGNJ_VV(rd, rs1, rs2, _)
    | @decode.VFSGNJN_VV(rd, rs1, rs2, _)
    | @decode.VFSGNJX_VV(rd, rs1, rs2, _)
    | @decode.VFSGNJ_VF(rd, rs1, rs2, _)
    | @decode.VFSGNJN_VF(rd, rs1, rs2, _)
    | @decode.VFSGNJX_VF(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float sqrt
    @decode.VFSQRT_V(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float arithmetic
    @decode.VFADD_VV(rd, rs1, rs2, _)
    | @decode.VFSUB_VV(rd, rs1, rs2, _)
    | @decode.VFMUL_VV(rd, rs1, rs2, _)
    | @decode.VFDIV_VV(rd, rs1, rs2, _)
    | @decode.VFADD_VF(rd, rs1, rs2, _)
    | @decode.VFSUB_VF(rd, rs1, rs2, _)
    | @decode.VFMUL_VF(rd, rs1, rs2, _)
    | @decode.VFRSUB_VF(rd, rs1, rs2, _)
    | @decode.VFMIN_VF(rd, rs1, rs2, _)
    | @decode.VFMAX_VF(rd, rs1, rs2, _)
    | @decode.VFRDIV_VF(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float min/max vv
    @decode.VFMIN_VV(rd, rs1, rs2, _) | @decode.VFMAX_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector indexed load/store
    @decode.VLOXEI64_V(rd, rs1, rs2, _)
    | @decode.VLOXEI32_V(rd, rs1, rs2, _)
    | @decode.VLOXEI16_V(rd, rs1, rs2, _)
    | @decode.VLOXEI8_V(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VSOXEI64_V(rs1, rs2, rs3, _)
    | @decode.VSOXEI32_V(rs1, rs2, rs3, _)
    | @decode.VSOXEI16_V(rs1, rs2, rs3, _)
    | @decode.VSOXEI8_V(rs1, rs2, rs3, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs3 != 0U {
        ops.push(RegOperand::{
          reg: rs3 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // More vector loads (indexed)
    @decode.VLSE64_V(rd, rs1, rs2, _)
    | @decode.VLSE32_V(rd, rs1, rs2, _)
    | @decode.VLSE16_V(rd, rs1, rs2, _)
    | @decode.VLSE8_V(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VSSE64_V(rs1, rs2, rs3, _)
    | @decode.VSSE32_V(rs1, rs2, rs3, _)
    | @decode.VSSE16_V(rs1, rs2, rs3, _)
    | @decode.VSSE8_V(rs1, rs2, rs3, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs3 != 0U {
        ops.push(RegOperand::{
          reg: rs3 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // More vector stores
    @decode.VS4R_V(rs1, rs2) | @decode.VS8R_V(rs1, rs2) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector indexed unordered load
    @decode.VLUXEI64_V(rd, rs1, rs2, _)
    | @decode.VLUXEI32_V(rd, rs1, rs2, _)
    | @decode.VLUXEI16_V(rd, rs1, rs2, _)
    | @decode.VLUXEI8_V(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector indexed unordered store
    @decode.VSUXEI64_V(rs1, rs2, rs3, _)
    | @decode.VSUXEI32_V(rs1, rs2, rs3, _)
    | @decode.VSUXEI16_V(rs1, rs2, rs3, _)
    | @decode.VSUXEI8_V(rs1, rs2, rs3, _) => {
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs3 != 0U {
        ops.push(RegOperand::{
          reg: rs3 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector sign/zero extend
    @decode.VSEXT_VF2(rd, rs1, _)
    | @decode.VZEXT_VF2(rd, rs1, _)
    | @decode.VSEXT_VF4(rd, rs1, _)
    | @decode.VZEXT_VF4(rd, rs1, _)
    | @decode.VSEXT_VF8(rd, rs1, _)
    | @decode.VZEXT_VF8(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector scalar move
    @decode.VMV_S_X(rd, rs1) | @decode.VMV_X_S(rd, rs1) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector integer move
    @decode.VMV_V_I(rd, _, _) =>
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
    @decode.VMV_V_X(rd, rs1, _) | @decode.VMV_V_V(rd, rs1, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector merge
    @decode.VMERGE_VIM(rd, _, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    @decode.VMERGE_VXM(rd, rs1, rs2, _) | @decode.VMERGE_VVM(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening multiply (signed-unsigned)
    @decode.VWMULSU_VX(rd, rs1, rs2, _) | @decode.VWMULSU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening multiply
    @decode.VWMUL_VX(rd, rs1, rs2, _)
    | @decode.VWMUL_VV(rd, rs1, rs2, _)
    | @decode.VWMULU_VX(rd, rs1, rs2, _)
    | @decode.VWMULU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening sub (wide)
    @decode.VWSUB_WX(rd, rs1, rs2, _)
    | @decode.VWSUB_WV(rd, rs1, rs2, _)
    | @decode.VWSUBU_WX(rd, rs1, rs2, _)
    | @decode.VWSUBU_WV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector widening add
    @decode.VWADD_WX(rd, rs1, rs2, _)
    | @decode.VWADD_WV(rd, rs1, rs2, _)
    | @decode.VWADDU_WX(rd, rs1, rs2, _)
    | @decode.VWADDU_WV(rd, rs1, rs2, _)
    | @decode.VWSUB_VX(rd, rs1, rs2, _)
    | @decode.VWSUB_VV(rd, rs1, rs2, _)
    | @decode.VWSUBU_VX(rd, rs1, rs2, _)
    | @decode.VWSUBU_VV(rd, rs1, rs2, _)
    | @decode.VWADD_VX(rd, rs1, rs2, _)
    | @decode.VWADD_VV(rd, rs1, rs2, _)
    | @decode.VWADDU_VX(rd, rs1, rs2, _)
    | @decode.VWADDU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector division/remainder
    @decode.VREM_VX(rd, rs1, rs2, _)
    | @decode.VREMU_VX(rd, rs1, rs2, _)
    | @decode.VDIV_VX(rd, rs1, rs2, _)
    | @decode.VDIVU_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector multiply high
    @decode.VMULHSU_VX(rd, rs1, rs2, _)
    | @decode.VMULHU_VX(rd, rs1, rs2, _)
    | @decode.VMULH_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector max/min
    @decode.VMAX_VX(rd, rs1, rs2, _)
    | @decode.VMAX_VV(rd, rs1, rs2, _)
    | @decode.VMAXU_VX(rd, rs1, rs2, _)
    | @decode.VMAXU_VV(rd, rs1, rs2, _)
    | @decode.VMIN_VX(rd, rs1, rs2, _)
    | @decode.VMIN_VV(rd, rs1, rs2, _)
    | @decode.VMINU_VX(rd, rs1, rs2, _)
    | @decode.VMINU_VV(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector float division
    @decode.VFDIV_VF(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector mask compare (immediate)
    @decode.VMSGT_VI(rd, _, vs2, _)
    | @decode.VMSGTU_VI(rd, _, vs2, _)
    | @decode.VMSLE_VI(rd, _, vs2, _)
    | @decode.VMSLEU_VI(rd, _, vs2, _)
    | @decode.VMSNE_VI(rd, _, vs2, _)
    | @decode.VMSEQ_VI(rd, _, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector mask compare (register)
    @decode.VMSGT_VX(rd, rs1, rs2, _)
    | @decode.VMSGTU_VX(rd, rs1, rs2, _)
    | @decode.VMSLE_VX(rd, rs1, rs2, _)
    | @decode.VMSLEU_VX(rd, rs1, rs2, _)
    | @decode.VMSLT_VX(rd, rs1, rs2, _)
    | @decode.VMSLTU_VX(rd, rs1, rs2, _)
    | @decode.VMSNE_VX(rd, rs1, rs2, _)
    | @decode.VMSEQ_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector narrowing shift right (immediate)
    @decode.VNSRA_VI(rd, _, vs2, _) | @decode.VNSRL_VI(rd, _, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector narrowing shift right (register)
    @decode.VNSRA_VX(rd, rs1, vs2, _)
    | @decode.VNSRA_VV(rd, rs1, vs2, _)
    | @decode.VNSRL_VX(rd, rs1, vs2, _)
    | @decode.VNSRL_VV(rd, rs1, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector shift (immediate)
    @decode.VSRA_VI(rd, _, vs2, _)
    | @decode.VSRL_VI(rd, _, vs2, _)
    | @decode.VSLL_VI(rd, _, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector shift (register)
    @decode.VSRA_VX(rd, rs1, vs2, _)
    | @decode.VSRL_VX(rd, rs1, vs2, _)
    | @decode.VSLL_VX(rd, rs1, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector logical (immediate)
    @decode.VXOR_VI(rd, _, vs2, _)
    | @decode.VOR_VI(rd, _, vs2, _)
    | @decode.VAND_VI(rd, _, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector logical (register)
    @decode.VXOR_VX(rd, rs1, vs2, _)
    | @decode.VOR_VX(rd, rs1, vs2, _)
    | @decode.VAND_VX(rd, rs1, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector rsub (immediate)
    @decode.VRSUB_VI(rd, _, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector rsub (register)
    @decode.VRSUB_VX(rd, rs1, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector sub
    @decode.VSUB_VX(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector add (immediate)
    @decode.VADD_VI(rd, _, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector add (register)
    @decode.VADD_VX(rd, rs1, vs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if vs2 != 0U {
        ops.push(RegOperand::{
          reg: vs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Vector mask logical
    @decode.VMXNOR_MM(rd, rs1, rs2, _) => {
      if rd != 0U {
        ops.push(RegOperand::{
          reg: rd + 32U,
          is_float: false,
          role: OperandRole::Def,
        })
      }
      if rs1 != 0U {
        ops.push(RegOperand::{
          reg: rs1 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
      if rs2 != 0U {
        ops.push(RegOperand::{
          reg: rs2 + 32U,
          is_float: false,
          role: OperandRole::Use,
        })
      }
    }
    // Invalid
    @decode.Invalid(_) => ignore(())
  }

  InstOperands::{ operands: FixedArray::from_array(ops) }
}

///|
/// Def-Use chain entry
pub struct DefUseEntry {
  /// Instruction address where the definition/use occurs
  addr : UInt
  /// Instruction index in the instruction array
  index : Int
  /// Register being defined/used
  reg : UInt
  /// Is this a floating-point register?
  is_float : Bool
  /// Is this a definition?
  is_def : Bool
} derive(Show)

///|
/// Def-Use chain for a register
pub struct DefUseChain {
  /// Register number
  reg : UInt
  /// Is this a floating-point register?
  is_float : Bool
  /// All definitions of this register
  defs : FixedArray[DefUseEntry]
  /// All uses of this register
  uses : FixedArray[DefUseEntry]
} derive(Show)

///|
/// Compute def-use chains for a sequence of instructions
pub fn compute_def_use_chains(
  instructions : FixedArray[DecodedInst],
) -> FixedArray[DefUseChain] {
  // Collect all registers used
  let reg_uses : Array[(UInt, Bool)] = [] // (reg, is_float)
  for inst_info in instructions {
    let ops = get_operands(inst_info.inst)
    for op in ops.operands {
      let key = (op.reg, op.is_float)
      let mut found = false
      for existing in reg_uses {
        if existing.0 == key.0 && existing.1 == key.1 {
          found = true
        }
      }
      if !found {
        reg_uses.push(key)
      }
    }
  }

  // Build chains for each register
  let chains : Array[DefUseChain] = []
  for reg_key in reg_uses {
    let (reg, is_float) = reg_key
    let defs : Array[DefUseEntry] = []
    let uses : Array[DefUseEntry] = []

    for i = 0; i < instructions.length(); i = i + 1 {
      let inst_info = instructions[i]
      let ops = get_operands(inst_info.inst)
      for op in ops.operands {
        if op.reg == reg && op.is_float == is_float {
          match op.role {
            OperandRole::Def =>
              defs.push(DefUseEntry::{
                addr: inst_info.addr,
                index: i,
                reg,
                is_float,
                is_def: true,
              })
            OperandRole::Use =>
              uses.push(DefUseEntry::{
                addr: inst_info.addr,
                index: i,
                reg,
                is_float,
                is_def: false,
              })
            OperandRole::UseDef => {
              defs.push(DefUseEntry::{
                addr: inst_info.addr,
                index: i,
                reg,
                is_float,
                is_def: true,
              })
              uses.push(DefUseEntry::{
                addr: inst_info.addr,
                index: i,
                reg,
                is_float,
                is_def: false,
              })
            }
          }
        }
      }
    }

    if defs.length() > 0 || uses.length() > 0 {
      chains.push(DefUseChain::{
        reg,
        is_float,
        defs: FixedArray::from_array(defs),
        uses: FixedArray::from_array(uses),
      })
    }
  }

  FixedArray::from_array(chains)
}

///|
/// Live set representation (bitmask for 32 integer + 32 float registers)
pub struct LiveSet {
  /// Integer registers (bit i = 1 means xi is live)
  int_regs : UInt
  /// Floating-point registers (bit i = 1 means fi is live)
  float_regs : UInt
} derive(Show, Eq)

///|
/// Create empty live set
pub fn LiveSet::empty() -> LiveSet {
  { int_regs: 0U, float_regs: 0U }
}

///|
/// Create bit mask for register
fn reg_bit(reg : UInt) -> UInt {
  1U << reg.reinterpret_as_int()
}

///|
/// Add integer register to live set
pub fn LiveSet::add_int(self : LiveSet, reg : UInt) -> LiveSet {
  { int_regs: self.int_regs | reg_bit(reg), float_regs: self.float_regs }
}

///|
/// Add float register to live set
pub fn LiveSet::add_float(self : LiveSet, reg : UInt) -> LiveSet {
  { int_regs: self.int_regs, float_regs: self.float_regs | reg_bit(reg) }
}

///|
/// Remove integer register from live set
pub fn LiveSet::remove_int(self : LiveSet, reg : UInt) -> LiveSet {
  {
    int_regs: self.int_regs & (0xFFFFFFFFU ^ reg_bit(reg)),
    float_regs: self.float_regs,
  }
}

///|
/// Remove float register from live set
pub fn LiveSet::remove_float(self : LiveSet, reg : UInt) -> LiveSet {
  {
    int_regs: self.int_regs,
    float_regs: self.float_regs & (0xFFFFFFFFU ^ reg_bit(reg)),
  }
}

///|
/// Check if integer register is in live set
pub fn LiveSet::contains_int(self : LiveSet, reg : UInt) -> Bool {
  (self.int_regs & reg_bit(reg)) != 0U
}

///|
/// Check if float register is in live set
pub fn LiveSet::contains_float(self : LiveSet, reg : UInt) -> Bool {
  (self.float_regs & reg_bit(reg)) != 0U
}

///|
/// Union of two live sets
pub fn LiveSet::union(self : LiveSet, other : LiveSet) -> LiveSet {
  {
    int_regs: self.int_regs | other.int_regs,
    float_regs: self.float_regs | other.float_regs,
  }
}

///|
/// Check if two live sets are equal
pub fn LiveSet::equal(self : LiveSet, other : LiveSet) -> Bool {
  self.int_regs == other.int_regs && self.float_regs == other.float_regs
}

///|
/// Live variable info for a basic block
pub struct BlockLiveness {
  /// Block start address
  block_addr : UInt
  /// Registers live at entry
  live_in : LiveSet
  /// Registers live at exit
  live_out : LiveSet
  /// Registers defined in block (before any use)
  def : LiveSet
  /// Registers used in block (before any def)
  uses : LiveSet
} derive(Show)

///|
/// Compute liveness for each basic block
pub fn compute_liveness(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
) -> FixedArray[BlockLiveness] {
  // Build instruction index map
  let num_blocks = cfg.blocks.length()
  let block_liveness : Array[BlockLiveness] = []

  // Initialize liveness info for each block
  for block in cfg.blocks {
    let mut def_set = LiveSet::empty()
    let mut uses_set = LiveSet::empty()

    // Compute def and use sets for this block
    for inst_info in instructions {
      if inst_info.addr >= block.start_addr && inst_info.addr <= block.end_addr {
        let ops = get_operands(inst_info.inst)
        for op in ops.operands {
          match op.role {
            OperandRole::Use =>
              // If not already defined in this block, add to use set
              if op.is_float {
                if !def_set.contains_float(op.reg) {
                  uses_set = uses_set.add_float(op.reg)
                }
              } else if !def_set.contains_int(op.reg) {
                uses_set = uses_set.add_int(op.reg)
              }
            OperandRole::Def =>
              // Add to def set
              if op.is_float {
                def_set = def_set.add_float(op.reg)
              } else {
                def_set = def_set.add_int(op.reg)
              }
            OperandRole::UseDef =>
              // First use, then def
              if op.is_float {
                if !def_set.contains_float(op.reg) {
                  uses_set = uses_set.add_float(op.reg)
                }
                def_set = def_set.add_float(op.reg)
              } else {
                if !def_set.contains_int(op.reg) {
                  uses_set = uses_set.add_int(op.reg)
                }
                def_set = def_set.add_int(op.reg)
              }
          }
        }
      }
    }

    block_liveness.push(BlockLiveness::{
      block_addr: block.start_addr,
      live_in: LiveSet::empty(),
      live_out: LiveSet::empty(),
      def: def_set,
      uses: uses_set,
    })
  }

  // Fixed-point iteration
  let mut changed = true
  while changed {
    changed = false
    for i = 0; i < num_blocks; i = i + 1 {
      let block = cfg.blocks[i]
      let info = block_liveness[i]

      // Compute live_out = union of live_in of all successors
      let mut new_out = LiveSet::empty()
      for edge in cfg.edges {
        if edge.from_block == block.start_addr {
          // Find successor block's live_in
          for j = 0; j < num_blocks; j = j + 1 {
            if cfg.blocks[j].start_addr == edge.to_block {
              new_out = new_out.union(block_liveness[j].live_in)
            }
          }
        }
      }

      // Compute live_in = use ∪ (live_out - def)
      // Use XOR with all 1s to implement bitwise NOT
      let new_in = info.uses.union(LiveSet::{
        int_regs: new_out.int_regs & (0xFFFFFFFFU ^ info.def.int_regs),
        float_regs: new_out.float_regs & (0xFFFFFFFFU ^ info.def.float_regs),
      })

      // Check for changes
      if !info.live_in.equal(new_in) || !info.live_out.equal(new_out) {
        changed = true
        block_liveness[i] = BlockLiveness::{
          block_addr: info.block_addr,
          live_in: new_in,
          live_out: new_out,
          def: info.def,
          uses: info.uses,
        }
      }
    }
  }

  FixedArray::from_array(block_liveness)
}

///|
/// Print live set
pub fn print_live_set(set : LiveSet) -> String {
  let mut result = "int:["
  let mut first = true
  for i = 0; i < 32; i = i + 1 {
    if set.contains_int(i.reinterpret_as_uint()) {
      if !first {
        result = result + ", "
      }
      result = result + @decode.reg_name(i.reinterpret_as_uint())
      first = false
    }
  }
  result = result + "] float:["
  first = true
  for i = 0; i < 32; i = i + 1 {
    if set.contains_float(i.reinterpret_as_uint()) {
      if !first {
        result = result + ", "
      }
      result = result + @decode.freg_name(i.reinterpret_as_uint())
      first = false
    }
  }
  result = result + "]"
  result
}

///|
/// Print def-use chains
pub fn print_def_use_chains(chains : FixedArray[DefUseChain]) -> Unit {
  println("=== Def-Use Chains ===")
  for chain in chains {
    let reg_name = if chain.is_float {
      @decode.freg_name(chain.reg)
    } else {
      @decode.reg_name(chain.reg)
    }
    println("\{reg_name}:")
    if chain.defs.length() > 0 {
      let mut def_str = "  defs: "
      for i = 0; i < chain.defs.length(); i = i + 1 {
        if i > 0 {
          def_str = def_str + ", "
        }
        def_str = def_str + "0x" + uint_to_hex(chain.defs[i].addr)
      }
      println(def_str)
    }
    if chain.uses.length() > 0 {
      let mut use_str = "  uses: "
      for i = 0; i < chain.uses.length(); i = i + 1 {
        if i > 0 {
          use_str = use_str + ", "
        }
        use_str = use_str + "0x" + _uint_to_hex(chain.uses[i].addr)
      }
      println(use_str)
    }
  }
}

///|
/// Convert UInt to hex string (local helper)
fn _uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut v = value
    while v > 0U {
      let digit = (v % 16U).reinterpret_as_int()
      let c = if digit < 10 {
        (digit + 48).unsafe_to_char()
      } else {
        (digit + 87).unsafe_to_char()
      }
      result = c.to_string() + result
      v = v / 16U
    }
    result
  }
}

// ============================================================================
// Phase 4: Constant Propagation Analysis
// ============================================================================

///|
/// Constant value representation for constant propagation
pub enum ConstValue {
  /// Value is a known constant
  Constant(Int)
  /// Value is not a constant (could be any value)
  NotConstant
  /// Value is unknown (uninitialized or from unknown source)
  Unknown
  /// Value is an address (from LUI/AUIPC)
  Address(UInt)
} derive(Show, Eq)

///|
/// Constant propagation state for all registers
pub struct ConstState {
  /// Integer register values
  int_regs : FixedArray[ConstValue]
  /// Floating-point register values
  float_regs : FixedArray[ConstValue]
} derive(Show)

///|
/// Create initial constant state (all unknown)
pub fn ConstState::new() -> ConstState {
  let int_vals : Array[ConstValue] = []
  let float_vals : Array[ConstValue] = []
  for i = 0; i < 32; i = i + 1 {
    int_vals.push(ConstValue::Unknown)
    float_vals.push(ConstValue::Unknown)
  }
  {
    int_regs: FixedArray::from_array(int_vals),
    float_regs: FixedArray::from_array(float_vals),
  }
}

///|
/// Get integer register value
pub fn ConstState::get_int(self : ConstState, reg : UInt) -> ConstValue {
  if reg >= 32U {
    return ConstValue::Unknown
  }
  self.int_regs[reg.reinterpret_as_int()]
}

///|
/// Set integer register value
pub fn ConstState::set_int(
  self : ConstState,
  reg : UInt,
  value : ConstValue,
) -> ConstState {
  if reg >= 32U {
    return self
  }
  let idx = reg.reinterpret_as_int()
  let new_vals : Array[ConstValue] = []
  for i = 0; i < 32; i = i + 1 {
    if i == idx {
      new_vals.push(value)
    } else {
      new_vals.push(self.int_regs[i])
    }
  }
  { int_regs: FixedArray::from_array(new_vals), float_regs: self.float_regs }
}

///|
/// Get float register value
pub fn ConstState::get_float(self : ConstState, reg : UInt) -> ConstValue {
  if reg >= 32U {
    return ConstValue::Unknown
  }
  self.float_regs[reg.reinterpret_as_int()]
}

///|
/// Set float register value
pub fn ConstState::set_float(
  self : ConstState,
  reg : UInt,
  value : ConstValue,
) -> ConstState {
  if reg >= 32U {
    return self
  }
  let idx = reg.reinterpret_as_int()
  let new_vals : Array[ConstValue] = []
  for i = 0; i < 32; i = i + 1 {
    if i == idx {
      new_vals.push(value)
    } else {
      new_vals.push(self.float_regs[i])
    }
  }
  { int_regs: self.int_regs, float_regs: FixedArray::from_array(new_vals) }
}

///|
/// Merge two constant states (meet operation)
pub fn ConstState::merge(self : ConstState, other : ConstState) -> ConstState {
  let int_vals : Array[ConstValue] = []
  let float_vals : Array[ConstValue] = []

  for i = 0; i < 32; i = i + 1 {
    int_vals.push(merge_const_values(self.int_regs[i], other.int_regs[i]))
    float_vals.push(merge_const_values(self.float_regs[i], other.float_regs[i]))
  }

  {
    int_regs: FixedArray::from_array(int_vals),
    float_regs: FixedArray::from_array(float_vals),
  }
}

///|
/// Merge two constant values
fn merge_const_values(a : ConstValue, b : ConstValue) -> ConstValue {
  match (a, b) {
    (ConstValue::Constant(va), ConstValue::Constant(vb)) =>
      if va == vb {
        ConstValue::Constant(va)
      } else {
        ConstValue::NotConstant
      }
    (ConstValue::Address(va), ConstValue::Address(vb)) =>
      if va == vb {
        ConstValue::Address(va)
      } else {
        ConstValue::NotConstant
      }
    (ConstValue::Unknown, other) => other
    (other, ConstValue::Unknown) => other
    _ => ConstValue::NotConstant
  }
}

///|
/// Check if two states are equal
pub fn ConstState::equal(self : ConstState, other : ConstState) -> Bool {
  let mut equal = true
  for i = 0; i < 32; i = i + 1 {
    if self.int_regs[i] != other.int_regs[i] {
      equal = false
      break
    }
    if self.float_regs[i] != other.float_regs[i] {
      equal = false
      break
    }
  }
  equal
}

///|
/// Constant propagation result for a basic block
pub struct BlockConstState {
  /// Block start address
  block_addr : UInt
  /// State at entry
  state_in : ConstState
  /// State at exit
  state_out : ConstState
} derive(Show)

///|
/// Propagate constant through an instruction
pub fn propagate_instruction(
  state : ConstState,
  inst : @decode.Instruction,
  inst_addr : UInt,
) -> ConstState {
  let mut new_state = state

  match inst {
    // LUI: Load upper immediate
    @decode.LUI(rd, imm) =>
      if rd != 0U {
        // LUI loads the immediate into the upper 12 bits
        let value = (imm & 0xFFFFF) << 12
        new_state = new_state.set_int(rd, ConstValue::Constant(value))
      }

    // AUIPC: Add upper immediate to PC
    @decode.AUIPC(rd, imm) =>
      if rd != 0U {
        // AUIPC result depends on PC, which may not be constant
        // But for position-independent code analysis, we can track the address
        let offset = (imm & 0xFFFFF) << 12
        new_state = new_state.set_int(
          rd,
          ConstValue::Address(
            (inst_addr.reinterpret_as_int() + offset).reinterpret_as_uint(),
          ),
        )
      }

    // ADDI: Add immediate
    @decode.ADDI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v + imm))
          ConstValue::Address(addr) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Address(
                (addr.reinterpret_as_int() + imm).reinterpret_as_uint(),
              ),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // ADDIW: Add immediate (32-bit, sign-extend)
    @decode.ADDIW(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) => {
            // Sign-extend to 32 bits, then add, then sign-extend result
            let v32 = sign_extend_32(v)
            let result = sign_extend_64_32(v32 + imm)
            new_state = new_state.set_int(rd, ConstValue::Constant(result))
          }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // ADD: Add registers
    @decode.ADD(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(rd, add_const_values(rs1_val, rs2_val))
      }

    // ADDW: Add registers (32-bit)
    @decode.ADDW(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(rd, add_const_values_32(rs1_val, rs2_val))
      }

    // SUB: Subtract registers
    @decode.SUB(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(rd, sub_const_values(rs1_val, rs2_val))
      }

    // SUBW: Subtract registers (32-bit)
    @decode.SUBW(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(rd, sub_const_values_32(rs1_val, rs2_val))
      }

    // ANDI: AND immediate
    @decode.ANDI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v & imm))
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // ORI: OR immediate
    @decode.ORI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v | imm))
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // XORI: XOR immediate
    @decode.XORI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v ^ imm))
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // SLLI: Shift left logical immediate
    @decode.SLLI(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let shift_amount = shamt.reinterpret_as_int() & 63
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v << shift_amount),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // SRLI: Shift right logical immediate
    @decode.SRLI(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let shift_amount = shamt.reinterpret_as_int() & 63
        match rs1_val {
          ConstValue::Constant(v) =>
            // Logical right shift (treat as unsigned)
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(lshr(v, shift_amount)),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // SRAI: Shift right arithmetic immediate
    @decode.SRAI(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let shift_amount = shamt.reinterpret_as_int() & 63
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v >> shift_amount),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // SLLIW/SRLIW/SRAIW: 32-bit shift operations
    @decode.SLLIW(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let shift_amount = shamt.reinterpret_as_int() & 31
        match rs1_val {
          ConstValue::Constant(v) => {
            let v32 = sign_extend_32(v)
            let result = sign_extend_64_32(v32 << shift_amount)
            new_state = new_state.set_int(rd, ConstValue::Constant(result))
          }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.SRLIW(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let shift_amount = shamt.reinterpret_as_int() & 31
        match rs1_val {
          ConstValue::Constant(v) => {
            let v32 = sign_extend_32(v)
            let result = sign_extend_64_32(lshr(v32, shift_amount))
            new_state = new_state.set_int(rd, ConstValue::Constant(result))
          }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.SRAIW(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let shift_amount = shamt.reinterpret_as_int() & 31
        match rs1_val {
          ConstValue::Constant(v) => {
            let v32 = sign_extend_32(v)
            let result = sign_extend_64_32(v32 >> shift_amount)
            new_state = new_state.set_int(rd, ConstValue::Constant(result))
          }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // AND/OR/XOR: Bitwise operations
    @decode.AND(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(
          rd,
          binop_const_values(rs1_val, rs2_val, BinOp::And),
        )
      }
    @decode.OR(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(
          rd,
          binop_const_values(rs1_val, rs2_val, BinOp::Or),
        )
      }
    @decode.XOR(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        new_state = new_state.set_int(
          rd,
          binop_const_values(rs1_val, rs2_val, BinOp::Xor),
        )
      }

    // SLL/SRL/SRA: Shift by register
    @decode.SLL(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v1 << (v2 & 63)),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.SRL(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(lshr(v1, v2 & 63)),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.SRA(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v1 >> (v2 & 63)),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // MUL/DIV/REM: Multiply/divide/remainder
    @decode.MUL(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v1 * v2))
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.MULH(rd, rs1, rs2)
    | @decode.MULHSU(rd, rs1, rs2)
    | @decode.MULHU(rd, rs1, rs2) =>
      if rd != 0U {
        // High multiply results are complex, mark as not constant
        new_state = new_state.set_int(rd, ConstValue::NotConstant)
      }
    @decode.DIV(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            if v2 != 0 {
              new_state = new_state.set_int(rd, ConstValue::Constant(v1 / v2))
            } else {
              // Division by zero - undefined
              new_state = new_state.set_int(rd, ConstValue::NotConstant)
            }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.DIVU(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            if v2 != 0 {
              // Unsigned division
              let u1 = v1.reinterpret_as_uint()
              let u2 = v2.reinterpret_as_uint()
              new_state = new_state.set_int(
                rd,
                ConstValue::Constant((u1 / u2).reinterpret_as_int()),
              )
            } else {
              new_state = new_state.set_int(rd, ConstValue::NotConstant)
            }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.REM(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            if v2 != 0 {
              new_state = new_state.set_int(rd, ConstValue::Constant(v1 % v2))
            } else {
              new_state = new_state.set_int(rd, ConstValue::NotConstant)
            }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.REMU(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            if v2 != 0 {
              // Unsigned remainder
              let u1 = v1.reinterpret_as_uint()
              let u2 = v2.reinterpret_as_uint()
              new_state = new_state.set_int(
                rd,
                ConstValue::Constant((u1 % u2).reinterpret_as_int()),
              )
            } else {
              new_state = new_state.set_int(rd, ConstValue::NotConstant)
            }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // MULW/DIVW/REMW: 32-bit multiply/divide
    @decode.MULW(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) => {
            let result = sign_extend_64_32(
              sign_extend_32(v1) * sign_extend_32(v2),
            )
            new_state = new_state.set_int(rd, ConstValue::Constant(result))
          }
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.DIVW(rd, rs1, rs2)
    | @decode.DIVUW(rd, rs1, rs2)
    | @decode.REMW(rd, rs1, rs2)
    | @decode.REMUW(rd, rs1, rs2) =>
      if rd != 0U {
        // 32-bit division is complex, mark as not constant for now
        new_state = new_state.set_int(rd, ConstValue::NotConstant)
      }

    // SLTI/SLTIU: Set less than immediate
    @decode.SLTI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(if v < imm { 1 } else { 0 }),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.SLTIU(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        match rs1_val {
          ConstValue::Constant(v) =>
            // Compare as unsigned
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(if ult(v, imm) { 1 } else { 0 }),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // SLT/SLTU: Set less than
    @decode.SLT(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(if v1 < v2 { 1 } else { 0 }),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.SLTU(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_val = state.get_int(rs1)
        let rs2_val = state.get_int(rs2)
        match (rs1_val, rs2_val) {
          (ConstValue::Constant(v1), ConstValue::Constant(v2)) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(if ult(v1, v2) { 1 } else { 0 }),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // Loads: Values from memory are unknown
    @decode.LB(rd, _, _)
    | @decode.LH(rd, _, _)
    | @decode.LW(rd, _, _)
    | @decode.LD(rd, _, _)
    | @decode.LBU(rd, _, _)
    | @decode.LHU(rd, _, _)
    | @decode.LWU(rd, _, _) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, ConstValue::Unknown)
      }

    // Float loads
    @decode.FLW(rd, _, _) | @decode.FLD(rd, _, _) =>
      new_state = new_state.set_float(rd, ConstValue::Unknown)

    // Float operations - mark result as not constant for now
    @decode.FADD_S(rd, _, _)
    | @decode.FSUB_S(rd, _, _)
    | @decode.FMUL_S(rd, _, _)
    | @decode.FDIV_S(rd, _, _)
    | @decode.FADD_D(rd, _, _)
    | @decode.FSUB_D(rd, _, _)
    | @decode.FMUL_D(rd, _, _)
    | @decode.FDIV_D(rd, _, _) =>
      new_state = new_state.set_float(rd, ConstValue::NotConstant)

    // JAL: Write return address
    @decode.JAL(rd, _) =>
      if rd != 0U {
        // Return address is the address after this instruction
        new_state = new_state.set_int(rd, ConstValue::Address(inst_addr + 4U))
      }

    // JALR: Write return address
    @decode.JALR(rd, _, _) =>
      if rd != 0U {
        // Return address, but target depends on register
        new_state = new_state.set_int(rd, ConstValue::Address(inst_addr + 4U))
      }

    // Compressed instructions
    @decode.C_LI(rd, imm) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, ConstValue::Constant(imm))
      }
    @decode.C_LUI(rd, imm) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, ConstValue::Constant(imm << 12))
      }
    @decode.C_ADDI(rd, imm) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        match rd_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v + imm))
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.C_ADDI16SP(imm) => {
      let sp_val = state.get_int(2U)
      match sp_val {
        ConstValue::Constant(v) =>
          new_state = new_state.set_int(2U, ConstValue::Constant(v + imm))
        _ => new_state = new_state.set_int(2U, ConstValue::NotConstant)
      }
    }
    @decode.C_ADDI4SPN(rd, imm) =>
      if rd != 0U {
        let sp_val = state.get_int(2U)
        match sp_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v + imm.reinterpret_as_int()),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.C_MV(rd, rs) =>
      if rd != 0U {
        let rs_val = state.get_int(rs)
        new_state = new_state.set_int(rd, rs_val)
      }
    @decode.C_ADD(rd, rs) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        let rs_val = state.get_int(rs)
        new_state = new_state.set_int(rd, add_const_values(rd_val, rs_val))
      }
    @decode.C_AND(rd, rs) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        let rs_val = state.get_int(rs)
        new_state = new_state.set_int(
          rd,
          binop_const_values(rd_val, rs_val, BinOp::And),
        )
      }
    @decode.C_OR(rd, rs) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        let rs_val = state.get_int(rs)
        new_state = new_state.set_int(
          rd,
          binop_const_values(rd_val, rs_val, BinOp::Or),
        )
      }
    @decode.C_XOR(rd, rs) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        let rs_val = state.get_int(rs)
        new_state = new_state.set_int(
          rd,
          binop_const_values(rd_val, rs_val, BinOp::Xor),
        )
      }
    @decode.C_SUB(rd, rs) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        let rs_val = state.get_int(rs)
        new_state = new_state.set_int(rd, sub_const_values(rd_val, rs_val))
      }
    @decode.C_SLLI(rd, shamt) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        match rd_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v << shamt.reinterpret_as_int()),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.C_SRLI(rd, shamt) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        match rd_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(lshr(v, shamt.reinterpret_as_int())),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.C_SRAI(rd, shamt) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        match rd_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(
              rd,
              ConstValue::Constant(v >> shamt.reinterpret_as_int()),
            )
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }
    @decode.C_ANDI(rd, imm) =>
      if rd != 0U {
        let rd_val = state.get_int(rd)
        match rd_val {
          ConstValue::Constant(v) =>
            new_state = new_state.set_int(rd, ConstValue::Constant(v & imm))
          _ => new_state = new_state.set_int(rd, ConstValue::NotConstant)
        }
      }

    // Loads from memory
    @decode.C_LW(rd, _, _) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, ConstValue::Unknown)
      }
    @decode.C_LWSP(rd, _) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, ConstValue::Unknown)
      }

    // For other instructions, don't change state (already handled or no register write)
    _ => ()
  }

  new_state
}

///|
/// Add two constant values
fn add_const_values(a : ConstValue, b : ConstValue) -> ConstValue {
  match (a, b) {
    (ConstValue::Constant(va), ConstValue::Constant(vb)) =>
      ConstValue::Constant(va + vb)
    (ConstValue::Address(addr), ConstValue::Constant(v)) =>
      ConstValue::Address((addr.reinterpret_as_int() + v).reinterpret_as_uint())
    (ConstValue::Constant(v), ConstValue::Address(addr)) =>
      ConstValue::Address((addr.reinterpret_as_int() + v).reinterpret_as_uint())
    (ConstValue::Unknown, _) => ConstValue::Unknown
    (_, ConstValue::Unknown) => ConstValue::Unknown
    _ => ConstValue::NotConstant
  }
}

///|
/// Add two constant values (32-bit)
fn add_const_values_32(a : ConstValue, b : ConstValue) -> ConstValue {
  match (a, b) {
    (ConstValue::Constant(va), ConstValue::Constant(vb)) => {
      let result = sign_extend_64_32(sign_extend_32(va) + sign_extend_32(vb))
      ConstValue::Constant(result)
    }
    _ => ConstValue::NotConstant
  }
}

///|
/// Subtract two constant values
fn sub_const_values(a : ConstValue, b : ConstValue) -> ConstValue {
  match (a, b) {
    (ConstValue::Constant(va), ConstValue::Constant(vb)) =>
      ConstValue::Constant(va - vb)
    (ConstValue::Address(addr), ConstValue::Constant(v)) =>
      ConstValue::Address((addr.reinterpret_as_int() - v).reinterpret_as_uint())
    (ConstValue::Unknown, _) => ConstValue::Unknown
    (_, ConstValue::Unknown) => ConstValue::Unknown
    _ => ConstValue::NotConstant
  }
}

///|
/// Subtract two constant values (32-bit)
fn sub_const_values_32(a : ConstValue, b : ConstValue) -> ConstValue {
  match (a, b) {
    (ConstValue::Constant(va), ConstValue::Constant(vb)) => {
      let result = sign_extend_64_32(sign_extend_32(va) - sign_extend_32(vb))
      ConstValue::Constant(result)
    }
    _ => ConstValue::NotConstant
  }
}

///|
/// Binary operation on constant values
fn binop_const_values(a : ConstValue, b : ConstValue, op : BinOp) -> ConstValue {
  match (a, b) {
    (ConstValue::Constant(va), ConstValue::Constant(vb)) =>
      match op {
        BinOp::Add => ConstValue::Constant(va + vb)
        BinOp::Sub => ConstValue::Constant(va - vb)
        BinOp::And => ConstValue::Constant(va & vb)
        BinOp::Or => ConstValue::Constant(va | vb)
        BinOp::Xor => ConstValue::Constant(va ^ vb)
        BinOp::Shl => ConstValue::Constant(va << vb)
        BinOp::Shr => ConstValue::Constant(va >> vb)
        BinOp::Mul => ConstValue::Constant(va * vb)
        BinOp::Div =>
          if vb != 0 {
            ConstValue::Constant(va / vb)
          } else {
            ConstValue::NotConstant
          }
        BinOp::Mod =>
          if vb != 0 {
            ConstValue::Constant(va % vb)
          } else {
            ConstValue::NotConstant
          }
      }
    (ConstValue::Unknown, _) => ConstValue::Unknown
    (_, ConstValue::Unknown) => ConstValue::Unknown
    _ => ConstValue::NotConstant
  }
}

///|
/// Sign-extend 32-bit value
fn sign_extend_32(v : Int) -> Int {
  // Sign-extend from 32 bits to 64 bits
  v << 32 >> 32
}

///|
/// Sign-extend 32-bit result to 64-bit
fn sign_extend_64_32(v : Int) -> Int {
  v << 32 >> 32
}

///|
/// Logical right shift (unsigned)
fn lshr(v : Int, amount : Int) -> Int {
  // Convert to UInt, shift, convert back
  let vu = v.reinterpret_as_uint()
  let shift_amount = if amount < 0 { 0 } else { amount }
  (vu >> shift_amount).reinterpret_as_int()
}

///|
/// Compare as unsigned
fn ult(a : Int, b : Int) -> Bool {
  a.reinterpret_as_uint() < b.reinterpret_as_uint()
}

///|
/// Compare as unsigned (greater or equal)
fn uge(a : Int, b : Int) -> Bool {
  a.reinterpret_as_uint() >= b.reinterpret_as_uint()
}

///|
/// Compute constant propagation for all basic blocks
pub fn compute_constant_propagation(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
) -> FixedArray[BlockConstState] {
  let num_blocks = cfg.blocks.length()
  let block_states : Array[BlockConstState] = []

  // Initialize block states
  for block in cfg.blocks {
    block_states.push(BlockConstState::{
      block_addr: block.start_addr,
      state_in: ConstState::new(),
      state_out: ConstState::new(),
    })
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

  // Build instruction index by address
  let inst_by_addr : Map[UInt, DecodedInst] = {}
  for inst in instructions {
    inst_by_addr[inst.addr] = inst
  }

  // Build successor map for CFG
  let succs : Map[UInt, Array[UInt]] = {}
  for block in cfg.blocks {
    succs[block.start_addr] = []
  }
  for edge in cfg.edges {
    match succs.get(edge.from_block) {
      Some(arr) => arr.push(edge.to_block)
      None => succs[edge.from_block] = [edge.to_block]
    }
  }

  // Fixed-point iteration
  let mut changed = true
  let max_iterations = 100
  let mut iteration = 0

  while changed && iteration < max_iterations {
    changed = false
    iteration = iteration + 1

    // Process blocks in order
    for i = 0; i < num_blocks; i = i + 1 {
      let block = cfg.blocks[i]
      let old_state = block_states[i]

      // Compute input state: merge of all predecessors' output states
      let pred_addrs = preds.get(block.start_addr).unwrap_or([])
      let mut new_in = ConstState::new()

      if pred_addrs.length() > 0 {
        // Find first predecessor
        let mut first = true
        for pred_addr in pred_addrs {
          // Find predecessor block index
          for j = 0; j < num_blocks; j = j + 1 {
            if block_states[j].block_addr == pred_addr {
              if first {
                new_in = block_states[j].state_out
                first = false
              } else {
                new_in = new_in.merge(block_states[j].state_out)
              }
              break
            }
          }
        }
      }
      // Entry block: use initial state (all unknown)

      // Propagate through instructions in this block
      let mut current_state = new_in
      let mut addr = block.start_addr
      while addr <= block.end_addr {
        match inst_by_addr.get(addr) {
          Some(inst) => {
            current_state = propagate_instruction(
              current_state,
              inst.inst,
              addr,
            )
            addr = addr + inst.length.reinterpret_as_uint()
          }
          None =>
            // No instruction at this address, skip 4 bytes (or 2 for compressed)
            addr = addr + 4U
        }
      }

      let new_out = current_state

      // Check for changes
      if !old_state.state_in.equal(new_in) ||
        !old_state.state_out.equal(new_out) {
        changed = true
        block_states[i] = BlockConstState::{
          block_addr: block.start_addr,
          state_in: new_in,
          state_out: new_out,
        }
      }
    }
  }

  FixedArray::from_array(block_states)
}

///|
/// Get constant value at a specific instruction address
pub fn get_const_at_point(
  block_states : FixedArray[BlockConstState],
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
  addr : UInt,
  reg : UInt,
) -> ConstValue {
  // Find the block containing this address
  let mut target_block_idx = -1
  for i = 0; i < cfg.blocks.length(); i = i + 1 {
    let block = cfg.blocks[i]
    if addr >= block.start_addr && addr <= block.end_addr {
      target_block_idx = i
      break
    }
  }

  if target_block_idx < 0 {
    return ConstValue::Unknown
  }

  let block = cfg.blocks[target_block_idx]
  let block_state = block_states[target_block_idx]

  // Propagate from block entry to this instruction
  let mut current_state = block_state.state_in
  for inst in instructions {
    if inst.addr >= block.start_addr && inst.addr < addr {
      current_state = propagate_instruction(current_state, inst.inst, inst.addr)
    }
  }

  current_state.get_int(reg)
}

///|
/// Format constant value
pub fn format_const_value(value : ConstValue) -> String {
  match value {
    ConstValue::Constant(v) => "Const(\{v})"
    ConstValue::NotConstant => "NotConst"
    ConstValue::Unknown => "Unknown"
    ConstValue::Address(addr) => "Addr(0x\{_uint_to_hex(addr)})"
  }
}

///|
/// Format constant state
pub fn format_const_state(state : ConstState) -> String {
  let mut result = "Int:["
  let mut first = true
  for i = 0; i < 32; i = i + 1 {
    let val = state.int_regs[i]
    match val {
      ConstValue::Constant(v) => {
        if !first {
          result = result + ", "
        }
        result = result + @decode.reg_name(i.reinterpret_as_uint()) + "=\{v}"
        first = false
      }
      ConstValue::Address(addr) => {
        if !first {
          result = result + ", "
        }
        result = result +
          @decode.reg_name(i.reinterpret_as_uint()) +
          "=0x\{_uint_to_hex(addr)}"
        first = false
      }
      _ => ()
    }
  }
  result = result + "]"
  result
}

///|
/// Conditional constant propagation result
pub struct ConditionalConstInfo {
  /// Block is reachable
  reachable : Map[UInt, Bool]
  /// Constant values at block entry
  block_consts : FixedArray[BlockConstState]
} derive(Show)

///|
/// Evaluate branch condition
fn evaluate_branch_condition(
  state : ConstState,
  inst : @decode.Instruction,
) -> BranchResult {
  match inst {
    @decode.BEQ(rs1, rs2, _) => {
      let v1 = state.get_int(rs1)
      let v2 = state.get_int(rs2)
      match (v1, v2) {
        (ConstValue::Constant(c1), ConstValue::Constant(c2)) =>
          if c1 == c2 {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    @decode.BNE(rs1, rs2, _) => {
      let v1 = state.get_int(rs1)
      let v2 = state.get_int(rs2)
      match (v1, v2) {
        (ConstValue::Constant(c1), ConstValue::Constant(c2)) =>
          if c1 != c2 {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    @decode.BLT(rs1, rs2, _) => {
      let v1 = state.get_int(rs1)
      let v2 = state.get_int(rs2)
      match (v1, v2) {
        (ConstValue::Constant(c1), ConstValue::Constant(c2)) =>
          if c1 < c2 {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    @decode.BGE(rs1, rs2, _) => {
      let v1 = state.get_int(rs1)
      let v2 = state.get_int(rs2)
      match (v1, v2) {
        (ConstValue::Constant(c1), ConstValue::Constant(c2)) =>
          if c1 >= c2 {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    @decode.BLTU(rs1, rs2, _) => {
      let v1 = state.get_int(rs1)
      let v2 = state.get_int(rs2)
      match (v1, v2) {
        (ConstValue::Constant(c1), ConstValue::Constant(c2)) =>
          if ult(c1, c2) {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    @decode.BGEU(rs1, rs2, _) => {
      let v1 = state.get_int(rs1)
      let v2 = state.get_int(rs2)
      match (v1, v2) {
        (ConstValue::Constant(c1), ConstValue::Constant(c2)) =>
          if uge(c1, c2) {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    // Compressed branches
    @decode.C_BEQZ(rs, _) => {
      let v = state.get_int(rs)
      match v {
        ConstValue::Constant(c) =>
          if c == 0 {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    @decode.C_BNEZ(rs, _) => {
      let v = state.get_int(rs)
      match v {
        ConstValue::Constant(c) =>
          if c != 0 {
            BranchResult::Taken
          } else {
            BranchResult::NotTaken
          }
        _ => BranchResult::Unknown
      }
    }
    _ => BranchResult::Unknown
  }
}

///|
/// Branch evaluation result
enum BranchResult {
  Taken
  NotTaken
  Unknown
} derive(Eq)

///|
/// Compute conditional constant propagation (more precise)
pub fn compute_conditional_constant_propagation(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
) -> ConditionalConstInfo {
  let num_blocks = cfg.blocks.length()
  let block_states : Array[BlockConstState] = []
  let reachable : Map[UInt, Bool] = {}

  // Initialize block states
  for block in cfg.blocks {
    block_states.push(BlockConstState::{
      block_addr: block.start_addr,
      state_in: ConstState::new(),
      state_out: ConstState::new(),
    })
    reachable[block.start_addr] = false
  }

  // Mark entry point as reachable
  if cfg.entry_points.length() > 0 {
    reachable[cfg.entry_points[0]] = true
  } else if num_blocks > 0 {
    reachable[cfg.blocks[0].start_addr] = true
  }

  // Build predecessor/successor maps
  let preds : Map[UInt, Array[UInt]] = {}
  let succs : Map[UInt, Array[Edge]] = {}
  for block in cfg.blocks {
    preds[block.start_addr] = []
    succs[block.start_addr] = []
  }
  for edge in cfg.edges {
    match preds.get(edge.to_block) {
      Some(arr) => arr.push(edge.from_block)
      None => preds[edge.to_block] = [edge.from_block]
    }
    match succs.get(edge.from_block) {
      Some(arr) => arr.push(edge)
      None => succs[edge.from_block] = [edge]
    }
  }

  // Build instruction index by address
  let inst_by_addr : Map[UInt, DecodedInst] = {}
  for inst in instructions {
    inst_by_addr[inst.addr] = inst
  }

  // Work list algorithm
  let work_list : Array[UInt] = []
  if cfg.entry_points.length() > 0 {
    work_list.push(cfg.entry_points[0])
  } else if num_blocks > 0 {
    work_list.push(cfg.blocks[0].start_addr)
  }

  let mut max_iterations = 100
  while work_list.length() > 0 && max_iterations > 0 {
    max_iterations = max_iterations - 1
    let block_addr_opt = work_list.pop()

    let block_addr = match block_addr_opt {
      Some(addr) => addr
      None => continue
    }

    // Find block index
    let mut block_idx = -1
    for i = 0; i < num_blocks; i = i + 1 {
      if block_states[i].block_addr == block_addr {
        block_idx = i
        break
      }
    }

    if block_idx < 0 {
      continue
    }

    let block = cfg.blocks[block_idx]
    let old_state = block_states[block_idx]

    // Compute input state from reachable predecessors
    let pred_addrs = preds.get(block_addr).unwrap_or([])
    let mut new_in = ConstState::new()
    let mut has_reachable_pred = false

    for pred_addr in pred_addrs {
      if reachable.get(pred_addr).unwrap_or(false) {
        for j = 0; j < num_blocks; j = j + 1 {
          if block_states[j].block_addr == pred_addr {
            if !has_reachable_pred {
              new_in = block_states[j].state_out
              has_reachable_pred = true
            } else {
              new_in = new_in.merge(block_states[j].state_out)
            }
            break
          }
        }
      }
    }

    // Propagate through block
    let mut current_state = new_in
    let mut last_branch_inst : @decode.Instruction? = None
    let mut last_branch_addr : UInt = 0U

    let mut addr = block.start_addr
    while addr <= block.end_addr {
      match inst_by_addr.get(addr) {
        Some(inst) => {
          // Check if this is a branch instruction
          match inst.inst {
            @decode.BEQ(_, _, _)
            | @decode.BNE(_, _, _)
            | @decode.BLT(_, _, _)
            | @decode.BGE(_, _, _)
            | @decode.BLTU(_, _, _)
            | @decode.BGEU(_, _, _)
            | @decode.C_BEQZ(_, _)
            | @decode.C_BNEZ(_, _) => {
              last_branch_inst = Some(inst.inst)
              last_branch_addr = addr
            }
            _ => ()
          }
          current_state = propagate_instruction(current_state, inst.inst, addr)
          addr = addr + inst.length.reinterpret_as_uint()
        }
        None => addr = addr + 4U
      }
    }

    let new_out = current_state

    // Update state if changed
    let state_changed = !old_state.state_in.equal(new_in) ||
      !old_state.state_out.equal(new_out)
    if state_changed {
      block_states[block_idx] = BlockConstState::{
        block_addr: block.start_addr,
        state_in: new_in,
        state_out: new_out,
      }
    }

    // Process successors
    let block_succs = succs.get(block_addr).unwrap_or([])
    for edge in block_succs {
      let should_add = match edge.edge_type {
        EdgeType::BranchTaken =>
          // Check if we can determine branch outcome
          match last_branch_inst {
            Some(inst) => {
              let result = evaluate_branch_condition(new_out, inst)
              result == BranchResult::Taken || result == BranchResult::Unknown
            }
            None => true
          }
        EdgeType::BranchNotTaken =>
          match last_branch_inst {
            Some(inst) => {
              let result = evaluate_branch_condition(new_out, inst)
              result == BranchResult::NotTaken ||
              result == BranchResult::Unknown
            }
            None => true
          }
        _ => true
      }

      if should_add {
        let was_reachable = reachable.get(edge.to_block).unwrap_or(false)
        if !was_reachable {
          reachable[edge.to_block] = true
        }
        if state_changed || !was_reachable {
          // Check if already in work list
          let mut in_list = false
          for addr in work_list {
            if addr == edge.to_block {
              in_list = true
              break
            }
          }
          if !in_list {
            work_list.push(edge.to_block)
          }
        }
      }
    }
  }

  ConditionalConstInfo::{
    reachable,
    block_consts: FixedArray::from_array(block_states),
  }
}
