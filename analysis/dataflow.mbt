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
    // System instructions
    @decode.ECALL | @decode.EBREAK | @decode.FENCE(_, _) | @decode.FENCE_I =>
      ignore(())
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
