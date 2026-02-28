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

// ==================== Interval Analysis ====================

///|
/// Interval bound (can be finite or unbounded)
pub struct IntervalBound {
  /// The bound value (only meaningful if is_bounded is true)
  value : Int
  /// Whether this is a finite bound
  is_bounded : Bool
} derive(Show, Eq)

///|
/// Create a finite bound
pub fn IntervalBound::finite(value : Int) -> IntervalBound {
  { value, is_bounded: true }
}

///|
/// Create negative infinity
pub fn IntervalBound::neg_inf() -> IntervalBound {
  { value: 0, is_bounded: false }
}

///|
/// Create positive infinity
pub fn IntervalBound::pos_inf() -> IntervalBound {
  { value: 0, is_bounded: false }
}

///|
/// Check if this is negative infinity
pub fn IntervalBound::is_neg_inf(self : IntervalBound) -> Bool {
  !self.is_bounded && self.value == 0
}

///|
/// Check if this is positive infinity
pub fn IntervalBound::is_pos_inf(self : IntervalBound) -> Bool {
  !self.is_bounded && self.value != 0
}

///|
/// Compare two bounds (for signed comparison)
pub fn IntervalBound::compare(
  self : IntervalBound,
  other : IntervalBound,
) -> Int {
  // -∞ < any finite < +∞
  if self.is_neg_inf() {
    if other.is_neg_inf() {
      0
    } else {
      -1
    }
  } else if self.is_pos_inf() {
    if other.is_pos_inf() {
      0
    } else {
      1
    }
    // self is finite
  } else if other.is_neg_inf() {
    1
  } else if other.is_pos_inf() {
    -1
  } else if self.value < other.value {
    -1
  } else if self.value > other.value {
    1
  } else {
    0
  }
}

///|
/// Interval representing a range of integer values
pub struct Interval {
  /// Lower bound (inclusive)
  lower : IntervalBound
  /// Upper bound (inclusive)
  upper : IntervalBound
} derive(Show, Eq)

///|
/// Create an interval [lower, upper]
pub fn Interval::range(lower : Int, upper : Int) -> Interval {
  { lower: IntervalBound::finite(lower), upper: IntervalBound::finite(upper) }
}

///|
/// Create an interval for a single value
pub fn Interval::constant(value : Int) -> Interval {
  Interval::range(value, value)
}

///|
/// Create the full interval (-∞, +∞)
pub fn Interval::full() -> Interval {
  { lower: IntervalBound::neg_inf(), upper: IntervalBound::pos_inf() }
}

///|
/// Create an empty/bottom interval (represents no possible value)
pub fn Interval::empty() -> Interval {
  // Use a special representation: upper < lower (finite)
  { lower: IntervalBound::finite(1), upper: IntervalBound::finite(0) }
}

///|
/// Create interval [0, +∞) for unsigned values
pub fn Interval::non_negative() -> Interval {
  { lower: IntervalBound::finite(0), upper: IntervalBound::pos_inf() }
}

///|
/// Check if interval is empty (bottom)
pub fn Interval::is_empty(self : Interval) -> Bool {
  if self.lower.is_bounded && self.upper.is_bounded {
    self.lower.value > self.upper.value
  } else {
    false
  }
}

///|
/// Check if interval is full (top)
pub fn Interval::is_full(self : Interval) -> Bool {
  self.lower.is_neg_inf() && self.upper.is_pos_inf()
}

///|
/// Check if interval represents a single constant
pub fn Interval::is_constant(self : Interval) -> Bool {
  self.lower.is_bounded &&
  self.upper.is_bounded &&
  self.lower.value == self.upper.value
}

///|
/// Get the constant value if this is a constant interval
pub fn Interval::get_constant(self : Interval) -> Int? {
  if self.is_constant() {
    Some(self.lower.value)
  } else {
    None
  }
}

///|
/// Check if interval contains a specific value
pub fn Interval::contains(self : Interval, value : Int) -> Bool {
  if self.is_empty() {
    false
  } else {
    let lower_ok = self.lower.compare(IntervalBound::finite(value)) <= 0
    let upper_ok = IntervalBound::finite(value).compare(self.upper) <= 0
    lower_ok && upper_ok
  }
}

///|
/// Union of two intervals (widest range)
pub fn Interval::union(self : Interval, other : Interval) -> Interval {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }

  let new_lower = if self.lower.compare(other.lower) <= 0 {
    self.lower
  } else {
    other.lower
  }
  let new_upper = if self.upper.compare(other.upper) >= 0 {
    self.upper
  } else {
    other.upper
  }
  { lower: new_lower, upper: new_upper }
}

///|
/// Intersection of two intervals
pub fn Interval::intersect(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  let new_lower = if self.lower.compare(other.lower) >= 0 {
    self.lower
  } else {
    other.lower
  }
  let new_upper = if self.upper.compare(other.upper) <= 0 {
    self.upper
  } else {
    other.upper
  }

  if new_lower.compare(new_upper) > 0 {
    Interval::empty()
  } else {
    { lower: new_lower, upper: new_upper }
  }
}

///|
/// Widen this interval with another (for fixpoint computation)
pub fn Interval::widen(self : Interval, other : Interval) -> Interval {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }

  // Lower bound: if other lower < self lower, widen to -∞
  let new_lower = if other.lower.compare(self.lower) < 0 {
    IntervalBound::neg_inf()
  } else {
    self.lower
  }

  // Upper bound: if other upper > self upper, widen to +∞
  let new_upper = if other.upper.compare(self.upper) > 0 {
    IntervalBound::pos_inf()
  } else {
    self.upper
  }

  { lower: new_lower, upper: new_upper }
}

///|
/// Narrow this interval with another (for more precise fixpoint)
pub fn Interval::narrow(self : Interval, other : Interval) -> Interval {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }

  // Lower bound: if self lower is -∞, use other lower
  let new_lower = if self.lower.is_neg_inf() && other.lower.is_bounded {
    other.lower
  } else {
    self.lower
  }

  // Upper bound: if self upper is +∞, use other upper
  let new_upper = if self.upper.is_pos_inf() && other.upper.is_bounded {
    other.upper
  } else {
    self.upper
  }

  { lower: new_lower, upper: new_upper }
}

///|
/// Add two intervals
pub fn Interval::add(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // [-∞, a] + [-∞, b] = [-∞, +∞] (if any is unbounded)
  // [a, b] + [c, d] = [a+c, b+d]
  let new_lower = if self.lower.is_neg_inf() || other.lower.is_neg_inf() {
    IntervalBound::neg_inf()
  } else {
    IntervalBound::finite(self.lower.value + other.lower.value)
  }

  let new_upper = if self.upper.is_pos_inf() || other.upper.is_pos_inf() {
    IntervalBound::pos_inf()
  } else {
    IntervalBound::finite(self.upper.value + other.upper.value)
  }

  { lower: new_lower, upper: new_upper }
}

///|
/// Subtract two intervals
pub fn Interval::sub(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // [a, b] - [c, d] = [a-d, b-c]
  let new_lower = if self.lower.is_neg_inf() || other.upper.is_pos_inf() {
    IntervalBound::neg_inf()
  } else {
    IntervalBound::finite(self.lower.value - other.upper.value)
  }

  let new_upper = if self.upper.is_pos_inf() || other.lower.is_neg_inf() {
    IntervalBound::pos_inf()
  } else {
    IntervalBound::finite(self.upper.value - other.lower.value)
  }

  { lower: new_lower, upper: new_upper }
}

///|
/// Multiply two intervals
pub fn Interval::mul(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // Handle special cases with zero
  if (
      self.lower.is_bounded &&
      self.lower.value == 0 &&
      self.upper.is_bounded &&
      self.upper.value == 0
    ) ||
    (
      other.lower.is_bounded &&
      other.lower.value == 0 &&
      other.upper.is_bounded &&
      other.upper.value == 0
    ) {
    return Interval::constant(0)
  }

  // If either is unbounded in both directions, result is full
  if (self.lower.is_neg_inf() && self.upper.is_pos_inf()) ||
    (other.lower.is_neg_inf() && other.upper.is_pos_inf()) {
    return Interval::full()
  }

  // Compute all four corner products
  let products : Array[Int] = []

  // Helper to add product if both bounds are finite
  fn add_product(
    a : IntervalBound,
    b : IntervalBound,
    products : Array[Int],
  ) -> Unit {
    if a.is_bounded && b.is_bounded {
      products.push(a.value * b.value)
    }
  }

  add_product(self.lower, other.lower, products)
  add_product(self.lower, other.upper, products)
  add_product(self.upper, other.lower, products)
  add_product(self.upper, other.upper, products)

  if products.length() == 0 {
    return Interval::full()
  }

  // Find min and max
  let mut min_val = products[0]
  let mut max_val = products[0]
  for i = 1; i < products.length(); i = i + 1 {
    if products[i] < min_val {
      min_val = products[i]
    }
    if products[i] > max_val {
      max_val = products[i]
    }
  }

  // Check if unbounded directions should propagate
  let new_lower = if self.lower.is_neg_inf() ||
    other.lower.is_neg_inf() ||
    self.upper.is_pos_inf() ||
    other.upper.is_pos_inf() {
    // Check sign of bounds
    let has_neg = self.lower.is_neg_inf() ||
      other.lower.is_neg_inf() ||
      (self.lower.is_bounded && self.lower.value < 0) ||
      (other.lower.is_bounded && other.lower.value < 0)
    let has_pos = self.upper.is_pos_inf() ||
      other.upper.is_pos_inf() ||
      (self.upper.is_bounded && self.upper.value > 0) ||
      (other.upper.is_bounded && other.upper.value > 0)
    if has_neg && has_pos {
      IntervalBound::neg_inf()
    } else {
      IntervalBound::finite(min_val)
    }
  } else {
    IntervalBound::finite(min_val)
  }

  let new_upper = if self.upper.is_pos_inf() ||
    other.upper.is_pos_inf() ||
    self.lower.is_neg_inf() ||
    other.lower.is_neg_inf() {
    let has_neg = self.lower.is_neg_inf() ||
      other.lower.is_neg_inf() ||
      (self.lower.is_bounded && self.lower.value < 0) ||
      (other.lower.is_bounded && other.lower.value < 0)
    let has_pos = self.upper.is_pos_inf() ||
      other.upper.is_pos_inf() ||
      (self.upper.is_bounded && self.upper.value > 0) ||
      (other.upper.is_bounded && other.upper.value > 0)
    if has_neg && has_pos {
      IntervalBound::pos_inf()
    } else {
      IntervalBound::finite(max_val)
    }
  } else {
    IntervalBound::finite(max_val)
  }

  { lower: new_lower, upper: new_upper }
}

///|
/// Divide two intervals (conservative approximation)
pub fn Interval::div(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // If divisor might be zero, result is undefined
  if other.contains(0) {
    return Interval::full()
  }

  // If divisor is unbounded, result is full
  if other.lower.is_neg_inf() || other.upper.is_pos_inf() {
    return Interval::full()
  }

  // Compute all four corner quotients
  let quotients : Array[Int] = []

  fn safe_div(a : Int, b : Int, quotients : Array[Int]) -> Unit {
    if b != 0 {
      quotients.push(a / b)
    }
  }

  if self.lower.is_bounded && other.lower.is_bounded {
    safe_div(self.lower.value, other.lower.value, quotients)
    safe_div(self.lower.value, other.upper.value, quotients)
  }
  if self.upper.is_bounded && other.lower.is_bounded {
    safe_div(self.upper.value, other.lower.value, quotients)
    safe_div(self.upper.value, other.upper.value, quotients)
  }

  if quotients.length() == 0 {
    return Interval::full()
  }

  let mut min_val = quotients[0]
  let mut max_val = quotients[0]
  for i = 1; i < quotients.length(); i = i + 1 {
    if quotients[i] < min_val {
      min_val = quotients[i]
    }
    if quotients[i] > max_val {
      max_val = quotients[i]
    }
  }

  Interval::range(min_val, max_val)
}

///|
/// Bitwise AND of two intervals (conservative)
pub fn Interval::bitand(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // Conservative: result is in [0, min(upper1, upper2)] for non-negative
  // For general case, return full range
  if self.lower.is_bounded &&
    self.lower.value >= 0 &&
    other.lower.is_bounded &&
    other.lower.value >= 0 {
    let min_upper = if self.upper.is_bounded && other.upper.is_bounded {
      if self.upper.value < other.upper.value {
        self.upper.value
      } else {
        other.upper.value
      }
    } else if self.upper.is_bounded {
      self.upper.value
    } else if other.upper.is_bounded {
      other.upper.value
    } else {
      return Interval::non_negative()
    }
    Interval::range(0, min_upper)
  } else {
    Interval::full()
  }
}

///|
/// Bitwise OR of two intervals (conservative)
pub fn Interval::bitor(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // Conservative: result is in [min(lower1, lower2), max(upper1, upper2)]
  self.union(other)
}

///|
/// Bitwise XOR of two intervals (conservative)
pub fn Interval::bitxor(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // Conservative: return full range
  Interval::full()
}

///|
/// Shift left by an interval
pub fn Interval::shl(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  // If shift amount is a constant
  match other.get_constant() {
    Some(shift) =>
      if shift < 0 || shift > 63 {
        Interval::empty()
      } else if self.is_constant() {
        Interval::constant(self.lower.value << shift)
      } else if self.lower.is_bounded && self.upper.is_bounded {
        // Conservative: assume all bits are set
        Interval::full()
      } else {
        Interval::full()
      }
    None => Interval::full()
  }
}

///|
/// Shift right logical by an interval
pub fn Interval::shr(self : Interval, other : Interval) -> Interval {
  if self.is_empty() || other.is_empty() {
    return Interval::empty()
  }

  match other.get_constant() {
    Some(shift) =>
      if shift < 0 || shift > 63 {
        Interval::empty()
      } else if self.is_constant() {
        Interval::constant(self.lower.value >> shift)
      } else if self.lower.is_bounded && self.upper.is_bounded {
        // Result is smaller than original
        Interval::range(self.lower.value >> shift, self.upper.value >> shift)
      } else {
        Interval::full()
      }
    None => Interval::full()
  }
}

///|
/// Format interval to string
pub fn format_interval(interval : Interval) -> String {
  if interval.is_empty() {
    "⊥"
  } else if interval.is_full() {
    "[-∞, +∞]"
  } else if interval.is_constant() {
    "[" + interval.lower.value.to_string() + "]"
  } else {
    let lower_str = if interval.lower.is_neg_inf() {
      "-∞"
    } else {
      interval.lower.value.to_string()
    }
    let upper_str = if interval.upper.is_pos_inf() {
      "+∞"
    } else {
      interval.upper.value.to_string()
    }
    "[" + lower_str + ", " + upper_str + "]"
  }
}

///|
/// Interval state for all registers
pub struct IntervalState {
  /// Integer register intervals
  int_regs : FixedArray[Interval]
  /// Float register intervals (not typically used for interval analysis)
  float_regs : FixedArray[Interval]
} derive(Show)

///|
/// Create initial interval state (all full)
pub fn IntervalState::new() -> IntervalState {
  let int_vals : Array[Interval] = []
  let float_vals : Array[Interval] = []
  for i = 0; i < 32; i = i + 1 {
    int_vals.push(Interval::full())
    float_vals.push(Interval::full())
  }
  {
    int_regs: FixedArray::from_array(int_vals),
    float_regs: FixedArray::from_array(float_vals),
  }
}

///|
/// Get integer register interval
pub fn IntervalState::get_int(self : IntervalState, reg : UInt) -> Interval {
  if reg >= 32U {
    return Interval::full()
  }
  self.int_regs[reg.reinterpret_as_int()]
}

///|
/// Set integer register interval
pub fn IntervalState::set_int(
  self : IntervalState,
  reg : UInt,
  interval : Interval,
) -> IntervalState {
  if reg >= 32U {
    return self
  }
  let idx = reg.reinterpret_as_int()
  let new_vals : Array[Interval] = []
  for i = 0; i < 32; i = i + 1 {
    if i == idx {
      new_vals.push(interval)
    } else {
      new_vals.push(self.int_regs[i])
    }
  }
  { int_regs: FixedArray::from_array(new_vals), float_regs: self.float_regs }
}

///|
/// Merge two interval states (union)
pub fn IntervalState::merge(
  self : IntervalState,
  other : IntervalState,
) -> IntervalState {
  let int_vals : Array[Interval] = []
  for i = 0; i < 32; i = i + 1 {
    int_vals.push(self.int_regs[i].union(other.int_regs[i]))
  }
  { int_regs: FixedArray::from_array(int_vals), float_regs: self.float_regs }
}

///|
/// Widen two interval states
pub fn IntervalState::widen(
  self : IntervalState,
  other : IntervalState,
) -> IntervalState {
  let int_vals : Array[Interval] = []
  for i = 0; i < 32; i = i + 1 {
    int_vals.push(self.int_regs[i].widen(other.int_regs[i]))
  }
  { int_regs: FixedArray::from_array(int_vals), float_regs: self.float_regs }
}

///|
/// Check if two states are equal
pub fn IntervalState::equal(
  self : IntervalState,
  other : IntervalState,
) -> Bool {
  for i = 0; i < 32; i = i + 1 {
    if self.int_regs[i] != other.int_regs[i] {
      return false
    }
  }
  true
}

///|
/// Propagate interval through an instruction
pub fn propagate_interval(
  state : IntervalState,
  inst : @decode.Instruction,
  inst_addr : UInt,
) -> IntervalState {
  let mut new_state = state

  match inst {
    // LUI: Load upper immediate
    @decode.LUI(rd, imm) =>
      if rd != 0U {
        let value = (imm & 0xFFFFF) << 12
        new_state = new_state.set_int(rd, Interval::constant(value))
      }

    // AUIPC: Add upper immediate to PC
    @decode.AUIPC(rd, imm) =>
      if rd != 0U {
        // Result depends on PC, create a range around the PC
        let offset = (imm & 0xFFFFF) << 12
        new_state = new_state.set_int(
          rd,
          Interval::range(
            inst_addr.reinterpret_as_int() + offset,
            inst_addr.reinterpret_as_int() + offset,
          ),
        )
      }

    // ADDI: Add immediate
    @decode.ADDI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let imm_interval = Interval::constant(imm)
        new_state = new_state.set_int(rd, rs1_interval.add(imm_interval))
      }

    // ADDIW: Add immediate word (32-bit)
    @decode.ADDIW(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        // Sign-extend to 32 bits
        let imm_interval = Interval::constant(imm)
        new_state = new_state.set_int(rd, rs1_interval.add(imm_interval))
      }

    // ADD: Add registers
    @decode.ADD(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let rs2_interval = state.get_int(rs2)
        new_state = new_state.set_int(rd, rs1_interval.add(rs2_interval))
      }

    // SUB: Subtract registers
    @decode.SUB(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let rs2_interval = state.get_int(rs2)
        new_state = new_state.set_int(rd, rs1_interval.sub(rs2_interval))
      }

    // AND: Bitwise AND
    @decode.AND(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let rs2_interval = state.get_int(rs2)
        new_state = new_state.set_int(rd, rs1_interval.bitand(rs2_interval))
      }

    // OR: Bitwise OR
    @decode.OR(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let rs2_interval = state.get_int(rs2)
        new_state = new_state.set_int(rd, rs1_interval.bitor(rs2_interval))
      }

    // XOR: Bitwise XOR
    @decode.XOR(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let rs2_interval = state.get_int(rs2)
        new_state = new_state.set_int(rd, rs1_interval.bitxor(rs2_interval))
      }

    // SLLI: Shift left logical immediate
    @decode.SLLI(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let shamt_interval = Interval::constant(shamt.reinterpret_as_int())
        new_state = new_state.set_int(rd, rs1_interval.shl(shamt_interval))
      }

    // SRLI/SRAI: Shift right
    @decode.SRLI(rd, rs1, shamt) | @decode.SRAI(rd, rs1, shamt) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let shamt_interval = Interval::constant(shamt.reinterpret_as_int())
        new_state = new_state.set_int(rd, rs1_interval.shr(shamt_interval))
      }

    // MUL: Multiply
    @decode.MUL(rd, rs1, rs2) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let rs2_interval = state.get_int(rs2)
        new_state = new_state.set_int(rd, rs1_interval.mul(rs2_interval))
      }

    // LI/Loads: Memory loads -> unknown value
    @decode.LB(rd, _, _)
    | @decode.LH(rd, _, _)
    | @decode.LW(rd, _, _)
    | @decode.LD(rd, _, _)
    | @decode.LBU(rd, _, _)
    | @decode.LHU(rd, _, _)
    | @decode.LWU(rd, _, _) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, Interval::full())
      }

    // SLTI/SLTIU: Set less than immediate
    @decode.SLTI(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let result = if rs1_interval.is_constant() {
          if rs1_interval.lower.value < imm {
            Interval::constant(1)
          } else {
            Interval::constant(0)
          }
        } else {
          Interval::range(0, 1)
        }
        new_state = new_state.set_int(rd, result)
      }
    @decode.SLTIU(rd, rs1, imm) =>
      if rd != 0U {
        let rs1_interval = state.get_int(rs1)
        let result = if rs1_interval.is_constant() {
          let rs1_u = rs1_interval.lower.value.reinterpret_as_uint()
          let imm_u = imm.reinterpret_as_uint()
          if rs1_u < imm_u {
            Interval::constant(1)
          } else {
            Interval::constant(0)
          }
        } else {
          Interval::range(0, 1)
        }
        new_state = new_state.set_int(rd, result)
      }

    // SLT/SLTU: Set less than
    @decode.SLT(rd, rs1, rs2) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, Interval::range(0, 1))
      }
    @decode.SLTU(rd, rs1, rs2) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, Interval::range(0, 1))
      }

    // Compressed instructions
    @decode.C_LI(rd, imm) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, Interval::constant(imm))
      }
    @decode.C_ADDI(rd, imm) =>
      if rd != 0U {
        let rd_interval = state.get_int(rd)
        new_state = new_state.set_int(
          rd,
          rd_interval.add(Interval::constant(imm)),
        )
      }
    @decode.C_ADD(rd, rs) =>
      if rd != 0U {
        let rd_interval = state.get_int(rd)
        let rs_interval = state.get_int(rs)
        new_state = new_state.set_int(rd, rd_interval.add(rs_interval))
      }
    @decode.C_MV(rd, rs) =>
      if rd != 0U {
        new_state = new_state.set_int(rd, state.get_int(rs))
      }
    @decode.C_AND(rd, rs) =>
      if rd != 0U {
        let rd_interval = state.get_int(rd)
        let rs_interval = state.get_int(rs)
        new_state = new_state.set_int(rd, rd_interval.bitand(rs_interval))
      }
    @decode.C_OR(rd, rs) =>
      if rd != 0U {
        let rd_interval = state.get_int(rd)
        let rs_interval = state.get_int(rs)
        new_state = new_state.set_int(rd, rd_interval.bitor(rs_interval))
      }
    @decode.C_XOR(rd, rs) =>
      if rd != 0U {
        let rd_interval = state.get_int(rd)
        let rs_interval = state.get_int(rs)
        new_state = new_state.set_int(rd, rd_interval.bitxor(rs_interval))
      }

    // For other instructions, don't change state
    _ => ()
  }

  new_state
}

///|
/// Interval state for a basic block
pub struct BlockIntervalState {
  /// Block start address
  block_addr : UInt
  /// Interval state at entry
  state_in : IntervalState
  /// Interval state at exit
  state_out : IntervalState
} derive(Show)

///|
/// Compute interval analysis for all basic blocks
pub fn compute_interval_analysis(
  cfg : CFG,
  instructions : FixedArray[DecodedInst],
) -> FixedArray[BlockIntervalState] {
  let num_blocks = cfg.blocks.length()
  let block_states : Array[BlockIntervalState] = []

  // Build instruction index map
  let inst_by_addr : Map[UInt, DecodedInst] = {}
  for inst_info in instructions {
    inst_by_addr[inst_info.addr] = inst_info
  }

  // Build predecessor map
  let preds : Map[UInt, Array[UInt]] = {}
  for edge in cfg.edges {
    match preds.get(edge.to_block) {
      Some(arr) => arr.push(edge.from_block)
      None => preds[edge.to_block] = [edge.from_block]
    }
  }

  // Initialize block states
  for block in cfg.blocks {
    block_states.push(BlockIntervalState::{
      block_addr: block.start_addr,
      state_in: IntervalState::new(),
      state_out: IntervalState::new(),
    })
  }

  // Work list algorithm with widening
  let work_list : Array[UInt] = []
  if cfg.entry_points.length() > 0 {
    work_list.push(cfg.entry_points[0])
  } else if num_blocks > 0 {
    work_list.push(cfg.blocks[0].start_addr)
  }

  let mut iteration_count = 0
  let max_iterations = 100

  while work_list.length() > 0 && iteration_count < max_iterations {
    iteration_count = iteration_count + 1
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

    // Compute input state from predecessors
    let pred_addrs = preds.get(block_addr).unwrap_or([])
    let mut new_in = IntervalState::new()
    let mut first = true

    for pred_addr in pred_addrs {
      // Find predecessor block state
      for j = 0; j < num_blocks; j = j + 1 {
        if block_states[j].block_addr == pred_addr {
          if first {
            new_in = block_states[j].state_out
            first = false
          } else {
            new_in = new_in.widen(block_states[j].state_out)
          }
          break
        }
      }
    }

    // Propagate through instructions in this block
    let mut current_state = new_in
    let mut addr = block.start_addr
    while addr <= block.end_addr {
      match inst_by_addr.get(addr) {
        Some(inst) => {
          current_state = propagate_interval(current_state, inst.inst, addr)
          addr = addr + inst.length.reinterpret_as_uint()
        }
        None => addr = addr + 4U
      }
    }

    let new_out = current_state

    // Check for changes (use widening to ensure termination)
    if !old_state.state_in.equal(new_in) || !old_state.state_out.equal(new_out) {
      block_states[block_idx] = BlockIntervalState::{
        block_addr: block.start_addr,
        state_in: new_in,
        state_out: new_out,
      }

      // Add successors to work list
      for edge in cfg.edges {
        if edge.from_block == block.start_addr {
          let mut in_list = false
          for a in work_list {
            if a == edge.to_block {
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

  FixedArray::from_array(block_states)
}

///|
/// Check if array access is in bounds
pub fn check_array_bounds(index_interval : Interval, array_size : Int) -> Bool {
  // Check if index is always in bounds
  if index_interval.is_empty() {
    return true // Dead code
  }

  // If index is a constant, check directly
  match index_interval.get_constant() {
    Some(idx) => idx >= 0 && idx < array_size
    None =>
      // Check if interval is definitely in bounds
      if index_interval.lower.is_bounded &&
        index_interval.lower.value >= 0 &&
        index_interval.upper.is_bounded &&
        index_interval.upper.value < array_size {
        true
      } else {
        false
      }
  }
}

///|
/// Format interval state
pub fn format_interval_state(state : IntervalState) -> String {
  let mut result = "Intervals:\n"
  for i = 0; i < 32; i = i + 1 {
    let interval = state.int_regs[i]
    if !interval.is_full() {
      result = result +
        "  " +
        @decode.reg_name(i.reinterpret_as_uint()) +
        " = " +
        format_interval(interval) +
        "\n"
    }
  }
  result
}

// ============================================================================
// Interprocedural Analysis (过程间分析)
// ============================================================================

///|
/// Effect on a global variable
pub enum GlobalEffect {
  /// Read from global
  Read(UInt) // address
  /// Write to global
  Write(UInt) // address
  /// Read and write
  ReadWrite(UInt) // address
  /// Address taken (may be accessed indirectly)
  AddressTaken(UInt)
} derive(Show, Eq)

///|
/// Function summary for interprocedural analysis
pub struct FunctionSummary {
  /// Function start address
  addr : UInt
  /// Function name (if known)
  name : String
  /// Parameter registers used (a0-a7, fa0-fa7)
  params : FixedArray[ParamInfo]
  /// Return value info
  return_info : ReturnInfo
  /// Global variable effects
  global_effects : FixedArray[GlobalEffect]
  /// Functions called by this function
  calls : FixedArray[UInt]
  /// Whether this function has indirect calls
  has_indirect_call : Bool
  /// Whether this function is a leaf (no calls)
  is_leaf : Bool
  /// Stack frame size (if determinable)
  stack_size : Int?
  /// Saved registers
  saved_regs : FixedArray[UInt]
  /// Modified registers (excluding saved regs)
  modified_regs : FixedArray[UInt]
  /// Summary confidence (0-100)
  confidence : Int
} derive(Show)

///|
/// Parameter information
pub struct ParamInfo {
  /// Register number (10-17 for a0-a7, 32-39 for fa0-fa7)
  reg : UInt
  /// Parameter index
  index : Int
  /// Inferred type
  typ : VarType
  /// Whether this parameter is used
  is_used : Bool
  /// Interval constraints on this parameter
  interval : Interval
} derive(Show)

///|
/// Return value information
pub struct ReturnInfo {
  /// Return register (a0 for int, fa0 for float)
  reg : UInt?
  /// Return type
  typ : VarType
  /// Return interval (for integer returns)
  interval : Interval
  /// Whether function returns a value
  has_return : Bool
  /// Whether function returns through memory
  memory_return : Bool
} derive(Show)

///|
/// Call site information for interprocedural analysis
pub struct CallSite {
  /// Address of call instruction
  addr : UInt
  /// Target function address (None for indirect calls)
  target : UInt?
  /// Argument values at call site
  args : FixedArray[ArgValue]
  /// Return address (address after call)
  return_addr : UInt
  /// Caller's state before call
  caller_state : IntervalState
} derive(Show)

///|
/// Argument value at call site
pub struct ArgValue {
  /// Argument register
  reg : UInt
  /// Argument value (interval)
  value : Interval
  /// Argument index
  index : Int
} derive(Show)

///|
/// Interprocedural analysis context
pub struct InterproceduralContext {
  /// Function summaries indexed by function address
  summaries : FixedArray[(UInt, FunctionSummary)]
  /// Call graph edges (caller -> callees)
  call_graph : FixedArray[(UInt, FixedArray[UInt])]
  /// Global variable assignments
  globals : FixedArray[GlobalVarInfo]
  /// Analysis iteration count
  iteration : Int
} derive(Show)

///|
/// Global variable information
pub struct GlobalVarInfo {
  /// Address of global variable
  addr : UInt
  /// Size in bytes
  size : Int
  /// Name (if available from symbol table)
  name : String
  /// Initial value interval
  initial_value : Interval
  /// Functions that read this global
  readers : FixedArray[UInt]
  /// Functions that write this global
  writers : FixedArray[UInt]
} derive(Show)

///|
/// Create empty function summary
pub fn FunctionSummary::empty(addr : UInt) -> FunctionSummary {
  FunctionSummary::{
    addr,
    name: "sub_" + format_hex_uint(addr),
    params: FixedArray::from_array([]),
    return_info: ReturnInfo::{
      reg: None,
      typ: VarType::Unknown,
      interval: Interval::full(),
      has_return: false,
      memory_return: false,
    },
    global_effects: FixedArray::from_array([]),
    calls: FixedArray::from_array([]),
    has_indirect_call: false,
    is_leaf: true,
    stack_size: None,
    saved_regs: FixedArray::from_array([]),
    modified_regs: FixedArray::from_array([]),
    confidence: 0,
  }
}

///|
/// Analyze a function to build its summary
pub fn analyze_function_summary(
  instructions : FixedArray[DecodedInst],
  cfg : CFG,
  func_addr : UInt,
  func_name : String?,
) -> FunctionSummary {
  let params : Array[ParamInfo] = []
  let mut return_reg : UInt? = None
  let return_interval = Interval::full()
  let mut has_return = false
  let global_effects : Array[GlobalEffect] = []
  let calls : Array[UInt] = []
  let mut has_indirect_call = false
  let mut is_leaf = true
  let mut stack_size : Int? = None
  let saved_regs : Array[UInt] = []
  let modified_regs : Array[UInt] = []
  let mut ra_saved = false
  ignore(ra_saved) // Will be used in future enhancements
  let frame_setup_detected = false
  ignore(frame_setup_detected) // Will be used in future enhancements

  // Track which argument registers are used
  let arg_regs_used : Array[Bool] = []
  // Note: We'll track arg usage through operand analysis below

  // Analyze each instruction
  for inst_info in instructions {
    ignore(inst_info.addr)

    match inst_info.inst {
      // Stack frame setup
      @decode.ADDI(2U, 2U, imm) =>
        if imm < 0 {
          // addi sp, sp, -imm (allocating stack)
          stack_size = Some(-imm)
        }
      @decode.ADDI(8U, 2U, 0) =>
        // addi fp, sp, 0 (setting frame pointer)
        ()

      // Save return address
      @decode.SD(1U, 2U, _off) | @decode.SW(1U, 2U, _off) => ra_saved = true

      // Function calls
      @decode.JAL(1U, _target) =>
        // target is Int (signed offset), would need conversion for address
        is_leaf = false
      @decode.JALR(1U, _rs1, _off) => {
        // Indirect call (via function pointer)
        has_indirect_call = true
        is_leaf = false
      }
      @decode.C_JAL(_target) => is_leaf = false

      // Return handling - check what's in a0
      @decode.JALR(0U, 1U, 0) | @decode.C_JR(1U) => {
        // Return instruction - a0 contains return value
        has_return = true
        return_reg = Some(10U) // a0
      }

      // Memory operations - potential global access
      @decode.LB(_, _, _)
      | @decode.LH(_, _, _)
      | @decode.LW(_, _, _)
      | @decode.LD(_, _, _)
      | @decode.LBU(_, _, _)
      | @decode.LHU(_, _, _)
      | @decode.LWU(_, _, _) =>
        // Check if loading from global (rs1 could be address from LUI/AUIPC)
        ()
      @decode.SB(_, _, _)
      | @decode.SH(_, _, _)
      | @decode.SW(_, _, _)
      | @decode.SD(_, _, _) =>
        // Store to potential global
        ()
      _ => ()
    }
  }

  let name = match func_name {
    Some(n) => n
    None => "sub_" + format_hex_uint(func_addr)
  }

  FunctionSummary::{
    addr: func_addr,
    name,
    params: FixedArray::from_array(params),
    return_info: ReturnInfo::{
      reg: return_reg,
      typ: VarType::Unknown,
      interval: return_interval,
      has_return,
      memory_return: false,
    },
    global_effects: FixedArray::from_array(global_effects),
    calls: FixedArray::from_array(calls),
    has_indirect_call,
    is_leaf,
    stack_size,
    saved_regs: FixedArray::from_array(saved_regs),
    modified_regs: FixedArray::from_array(modified_regs),
    confidence: 80, // Base confidence
  }
}

///|
/// Propagate argument values to callee
pub fn propagate_args_to_callee(
  caller_state : IntervalState,
  summary : FunctionSummary,
) -> IntervalState {
  let mut callee_state = IntervalState::new()

  // Copy argument values to callee's parameter positions
  for param in summary.params {
    let arg_value = caller_state.get_int(param.reg)
    callee_state = callee_state.set_int(param.reg, arg_value)
  }

  callee_state
}

///|
/// Propagate return value from callee to caller
pub fn propagate_return_to_caller(
  caller_state : IntervalState,
  callee_summary : FunctionSummary,
) -> IntervalState {
  let mut new_state = caller_state

  // If callee returns a value, update caller's a0
  if callee_summary.return_info.has_return {
    match callee_summary.return_info.reg {
      Some(reg) =>
        new_state = new_state.set_int(reg, callee_summary.return_info.interval)
      None => ()
    }
  }

  // Mark modified registers as potentially changed
  for reg in callee_summary.modified_regs {
    // Check if it's a caller-saved register that wasn't saved
    let is_caller_saved = (reg >= 10U && reg <= 17U) || // a0-a7
      (reg >= 5U && reg <= 7U) // t0-t2

    if is_caller_saved {
      // Clear the value since it might be clobbered
      new_state = new_state.set_int(reg, Interval::full())
    }
  }

  new_state
}

///|
/// Build interprocedural context from call graph
pub fn build_interprocedural_context(
  functions : FixedArray[(UInt, FixedArray[DecodedInst], CFG, String?)],
) -> InterproceduralContext {
  let summaries : Array[(UInt, FunctionSummary)] = []
  let call_edges : Array[(UInt, FixedArray[UInt])] = []
  let globals : Array[GlobalVarInfo] = []

  // First pass: build summaries for each function
  for i = 0; i < functions.length(); i = i + 1 {
    let tuple = functions[i]
    let addr = tuple.0
    let instructions = tuple.1
    let cfg = tuple.2
    let name = tuple.3
    let summary = analyze_function_summary(instructions, cfg, addr, name)
    ignore(summary)
    // Record call edges - simplified for now
    ()
  }

  // Second pass: resolve indirect calls and propagate information
  // (This would require more complex analysis)

  InterproceduralContext::{
    summaries: FixedArray::from_array(summaries),
    call_graph: FixedArray::from_array(call_edges),
    globals: FixedArray::from_array(globals),
    iteration: 0,
  }
}

///|
/// Get function summary by address
pub fn get_function_summary(
  ctx : InterproceduralContext,
  addr : UInt,
) -> FunctionSummary? {
  for i = 0; i < ctx.summaries.length(); i = i + 1 {
    let tuple = ctx.summaries[i]
    if tuple.0 == addr {
      return Some(tuple.1)
    }
  }
  None
}

///|
/// Analyze call graph for topological order
pub fn compute_call_graph_order(
  ctx : InterproceduralContext,
) -> FixedArray[UInt] {
  let order : Array[UInt] = []
  let visited : Array[UInt] = []

  // Simple reverse topological order using DFS
  fn visit(
    addr : UInt,
    ctx : InterproceduralContext,
    visited : Array[UInt],
    order : Array[UInt],
  ) -> Unit {
    // Check if already visited
    for v in visited {
      if v == addr {
        return
      }
    }
    visited.push(addr)

    // Visit callees first
    match get_function_summary(ctx, addr) {
      Some(summary) =>
        for target in summary.calls {
          visit(target, ctx, visited, order)
        }
      None => ()
    }

    order.push(addr)
  }

  // Visit all functions
  for i = 0; i < ctx.summaries.length(); i = i + 1 {
    let tuple = ctx.summaries[i]
    visit(tuple.0, ctx, visited, order)
  }

  FixedArray::from_array(order)
}

///|
/// Perform interprocedural interval analysis
pub fn compute_interprocedural_intervals(
  functions : FixedArray[(UInt, FixedArray[DecodedInst], CFG, String?)],
  max_iterations : Int,
) -> InterproceduralContext {
  let ctx = build_interprocedural_context(functions)

  // Iterate until fixpoint
  for iter = 0; iter < max_iterations; iter = iter + 1 {
    let changed = false

    // Process functions in reverse topological order
    let order = compute_call_graph_order(ctx)

    for addr in order {
      // Find function in input
      for i = 0; i < functions.length(); i = i + 1 {
        let tuple = functions[i]
        if tuple.0 == addr {
          // Get current summary
          match get_function_summary(ctx, addr) {
            Some(_summary) => {
              // Compute intraprocedural analysis with current context
              let _block_states = compute_interval_analysis(tuple.2, tuple.1)
              // Update summary based on analysis results
              // (simplified - would need more complex merging)
              ()
            }
            None => ()
          }
        }
      }
    }

    if !changed {
      break
    }
  }

  ctx
}

///|
/// Format function summary
pub fn format_function_summary(summary : FunctionSummary) -> String {
  let mut result = "Function: " +
    summary.name +
    " @ " +
    format_hex_uint(summary.addr) +
    "\n"

  result = result +
    "  Parameters: " +
    summary.params.length().to_string() +
    "\n"
  for param in summary.params {
    result = result +
      "    a" +
      param.index.to_string() +
      ": " +
      format_interval(param.interval) +
      "\n"
  }

  result = result + "  Returns: "
  if summary.return_info.has_return {
    result = result +
      "a0 = " +
      format_interval(summary.return_info.interval) +
      "\n"
  } else {
    result = result + "void\n"
  }

  result = result + "  Stack size: "
  match summary.stack_size {
    Some(size) => result = result + size.to_string() + " bytes\n"
    None => result = result + "unknown\n"
  }

  result = result + "  Is leaf: " + summary.is_leaf.to_string() + "\n"
  result = result +
    "  Has indirect call: " +
    summary.has_indirect_call.to_string() +
    "\n"

  if summary.calls.length() > 0 {
    result = result + "  Calls:\n"
    for target in summary.calls {
      result = result + "    " + format_hex_uint(target) + "\n"
    }
  }

  result = result + "  Saved regs: "
  for reg in summary.saved_regs {
    result = result + @decode.reg_name(reg) + " "
  }
  result = result + "\n"

  result = result + "  Modified regs: "
  for reg in summary.modified_regs {
    result = result + @decode.reg_name(reg) + " "
  }
  result = result + "\n"

  result = result + "  Confidence: " + summary.confidence.to_string() + "%\n"

  result
}

///|
/// Format interprocedural context
pub fn format_interprocedural_context(ctx : InterproceduralContext) -> String {
  let mut result = "=== Interprocedural Analysis Results ===\n\n"

  result = result +
    "Functions analyzed: " +
    ctx.summaries.length().to_string() +
    "\n"
  result = result +
    "Call graph edges: " +
    ctx.call_graph.length().to_string() +
    "\n"
  result = result +
    "Globals tracked: " +
    ctx.globals.length().to_string() +
    "\n"
  result = result + "Iterations: " + ctx.iteration.to_string() + "\n\n"

  for i = 0; i < ctx.summaries.length(); i = i + 1 {
    let tuple = ctx.summaries[i]
    result = result + format_function_summary(tuple.1) + "\n"
  }

  result
}

///|
/// Placeholder functions to suppress unused constructor warnings
fn _global_effect_placeholder() -> GlobalEffect {
  let _ = GlobalEffect::Read(0U)
  let _ = GlobalEffect::Write(0U)
  let _ = GlobalEffect::ReadWrite(0U)
  let _ = GlobalEffect::AddressTaken(0U)
  GlobalEffect::Read(0U)
}
