///| RISC-V instruction types and definitions

///| Based on RISC-V Specification Volume I: User-Level ISA

///|
/// RISC-V instruction enumeration
pub(all) enum Instruction {
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
  // RV32M extension (multiply/divide)
  MUL(UInt, UInt, UInt) // rd, rs1, rs2 - multiply lower
  MULH(UInt, UInt, UInt) // rd, rs1, rs2 - multiply upper (signed * signed)
  MULHSU(UInt, UInt, UInt) // rd, rs1, rs2 - multiply upper (signed * unsigned)
  MULHU(UInt, UInt, UInt) // rd, rs1, rs2 - multiply upper (unsigned * unsigned)
  DIV(UInt, UInt, UInt) // rd, rs1, rs2 - divide signed
  DIVU(UInt, UInt, UInt) // rd, rs1, rs2 - divide unsigned
  REM(UInt, UInt, UInt) // rd, rs1, rs2 - remainder signed
  REMU(UInt, UInt, UInt) // rd, rs1, rs2 - remainder unsigned
  // RV64I base instruction set (64-bit specific)
  // Load/Store 64-bit
  LD(UInt, UInt, Int) // rd, rs1, imm - load doubleword
  SD(UInt, UInt, Int) // rs1, rs2, imm - store doubleword
  LWU(UInt, UInt, Int) // rd, rs1, imm - load word unsigned
  // Immediate arithmetic 64-bit (W = word, 32-bit operations)
  ADDIW(UInt, UInt, Int) // rd, rs1, imm - add immediate word
  SLLIW(UInt, UInt, UInt) // rd, rs1, shamt - shift left logical immediate word
  SRLIW(UInt, UInt, UInt) // rd, rs1, shamt - shift right logical immediate word
  SRAIW(UInt, UInt, UInt) // rd, rs1, shamt - shift right arithmetic immediate word
  // Register arithmetic 64-bit (W = word, 32-bit operations)
  ADDW(UInt, UInt, UInt) // rd, rs1, rs2 - add word
  SUBW(UInt, UInt, UInt) // rd, rs1, rs2 - subtract word
  SLLW(UInt, UInt, UInt) // rd, rs1, rs2 - shift left logical word
  SRLW(UInt, UInt, UInt) // rd, rs1, rs2 - shift right logical word
  SRAW(UInt, UInt, UInt) // rd, rs1, rs2 - shift right arithmetic word
  // RV64M extension (multiply/divide word)
  MULW(UInt, UInt, UInt) // rd, rs1, rs2 - multiply word
  DIVW(UInt, UInt, UInt) // rd, rs1, rs2 - divide word signed
  DIVUW(UInt, UInt, UInt) // rd, rs1, rs2 - divide word unsigned
  REMW(UInt, UInt, UInt) // rd, rs1, rs2 - remainder word signed
  REMUW(UInt, UInt, UInt) // rd, rs1, rs2 - remainder word unsigned
  // RV32A extension (atomic operations)
  // Load-Reserved/Store-Conditional
  LR_W(UInt, UInt, UInt, UInt) // rd, rs1, aq, rl - load-reserved word
  SC_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl - store-conditional word
  // Atomic Memory Operations (AMO)
  AMOSWAP_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOADD_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOXOR_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOAND_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOOR_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMIN_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAX_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMINU_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAXU_W(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  // RV64A extension (64-bit atomic operations)
  LR_D(UInt, UInt, UInt, UInt) // rd, rs1, aq, rl - load-reserved doubleword
  SC_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl - store-conditional doubleword
  AMOSWAP_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOADD_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOXOR_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOAND_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOOR_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMIN_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAX_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMINU_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  AMOMAXU_D(UInt, UInt, UInt, UInt, UInt) // rd, rs1, rs2, aq, rl
  // Fence instructions
  FENCE(UInt, UInt) // pred, succ
  FENCE_I
  // System instructions
  ECALL
  EBREAK
  // RV32C compressed instructions (16-bit)
  C_ADDI4SPN(UInt, UInt) // rd', imm
  C_LW(UInt, UInt, UInt) // rd', rs1', imm
  C_SW(UInt, UInt, UInt) // rs2', rs1', imm
  C_NOP
  C_ADDI(UInt, Int) // rd, imm
  C_JAL(Int) // imm
  C_LI(UInt, Int) // rd, imm
  C_ADDI16SP(Int) // imm
  C_LUI(UInt, Int) // rd, imm
  C_SRLI(UInt, UInt) // rd', shamt
  C_SRAI(UInt, UInt) // rd', shamt
  C_ANDI(UInt, Int) // rd', imm
  C_SUB(UInt, UInt) // rd', rs2'
  C_XOR(UInt, UInt) // rd', rs2'
  C_OR(UInt, UInt) // rd', rs2'
  C_AND(UInt, UInt) // rd', rs2'
  C_J(Int) // imm
  C_BEQZ(UInt, Int) // rs1', imm
  C_BNEZ(UInt, Int) // rs1', imm
  C_SLLI(UInt, UInt) // rd, shamt
  C_LWSP(UInt, UInt) // rd, imm
  C_JR(UInt) // rs1
  C_MV(UInt, UInt) // rd, rs2
  C_EBREAK
  C_JALR(UInt) // rs1
  C_ADD(UInt, UInt) // rd, rs2
  C_SWSP(UInt, UInt) // rs2, imm
  // Zicsr extension (CSR instructions)
  CSRRW(UInt, UInt, UInt) // rd, csr, rs1 - CSR read/write
  CSRRS(UInt, UInt, UInt) // rd, csr, rs1 - CSR read/set
  CSRRC(UInt, UInt, UInt) // rd, csr, rs1 - CSR read/clear
  CSRRWI(UInt, UInt, UInt) // rd, csr, uimm - CSR read/write immediate
  CSRRSI(UInt, UInt, UInt) // rd, csr, uimm - CSR read/set immediate
  CSRRCI(UInt, UInt, UInt) // rd, csr, uimm - CSR read/clear immediate
  // Zba extension (address generation)
  SH1ADD(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 1 and add
  SH2ADD(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 2 and add
  SH3ADD(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 3 and add
  // Zba RV64 extension (address generation 64-bit)
  SH1ADD_UW(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 1 and add (unsigned word)
  SH2ADD_UW(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 2 and add (unsigned word)
  SH3ADD_UW(UInt, UInt, UInt) // rd, rs1, rs2 - shift left by 3 and add (unsigned word)
  ADD_UW(UInt, UInt, UInt) // rd, rs1, rs2 - add unsigned word
  SLLI_UW(UInt, UInt, UInt) // rd, rs1, shamt - shift left logical immediate unsigned word
  // Zbb extension (basic bit manipulation)
  ANDN(UInt, UInt, UInt) // rd, rs1, rs2 - AND with inverted rs2
  ORN(UInt, UInt, UInt) // rd, rs1, rs2 - OR with inverted rs2
  XNOR(UInt, UInt, UInt) // rd, rs1, rs2 - XNOR
  CLZ(UInt, UInt) // rd, rs1 - count leading zeros
  CTZ(UInt, UInt) // rd, rs1 - count trailing zeros
  CPOP(UInt, UInt) // rd, rs1 - count population (set bits)
  SEXT_B(UInt, UInt) // rd, rs1 - sign extend byte
  SEXT_H(UInt, UInt) // rd, rs1 - sign extend halfword
  ZEXT_H(UInt, UInt) // rd, rs1 - zero extend halfword (also in Zbb)
  MAX(UInt, UInt, UInt) // rd, rs1, rs2 - maximum (signed)
  MAXU(UInt, UInt, UInt) // rd, rs1, rs2 - maximum (unsigned)
  MIN(UInt, UInt, UInt) // rd, rs1, rs2 - minimum (signed)
  MINU(UInt, UInt, UInt) // rd, rs1, rs2 - minimum (unsigned)
  ROL(UInt, UInt, UInt) // rd, rs1, rs2 - rotate left
  ROR(UInt, UInt, UInt) // rd, rs1, rs2 - rotate right
  RORI(UInt, UInt, UInt) // rd, rs1, shamt - rotate right immediate
  ORC_B(UInt, UInt) // rd, rs1 - OR combine bytes
  REV8(UInt, UInt) // rd, rs1 - byte reverse
  // Zbb RV64 extension (basic bit manipulation 64-bit)
  CLZW(UInt, UInt) // rd, rs1 - count leading zeros word
  CTZW(UInt, UInt) // rd, rs1 - count trailing zeros word
  CPOPW(UInt, UInt) // rd, rs1 - count population word
  ROLW(UInt, UInt, UInt) // rd, rs1, rs2 - rotate left word
  RORW(UInt, UInt, UInt) // rd, rs1, rs2 - rotate right word
  RORIW(UInt, UInt, UInt) // rd, rs1, shamt - rotate right immediate word
  // Zbc extension (carry-less multiplication)
  CLMUL(UInt, UInt, UInt) // rd, rs1, rs2 - carry-less multiply low
  CLMULH(UInt, UInt, UInt) // rd, rs1, rs2 - carry-less multiply high
  CLMULR(UInt, UInt, UInt) // rd, rs1, rs2 - carry-less multiply reversed
  // Zbs extension (single bit instructions)
  BCLR(UInt, UInt, UInt) // rd, rs1, rs2 - bit clear
  BCLRI(UInt, UInt, UInt) // rd, rs1, shamt - bit clear immediate
  BEXT(UInt, UInt, UInt) // rd, rs1, rs2 - bit extract
  BEXTI(UInt, UInt, UInt) // rd, rs1, shamt - bit extract immediate
  BINV(UInt, UInt, UInt) // rd, rs1, rs2 - bit invert
  BINVI(UInt, UInt, UInt) // rd, rs1, shamt - bit invert immediate
  BSET(UInt, UInt, UInt) // rd, rs1, rs2 - bit set
  BSETI(UInt, UInt, UInt) // rd, rs1, shamt - bit set immediate
  // RV32F extension (single-precision floating-point)
  // Load/Store
  FLW(UInt, UInt, Int) // rd, rs1, imm - load single-precision
  FSW(UInt, UInt, Int) // rs1, rs2, imm - store single-precision
  // Computational
  FADD_S(UInt, UInt, UInt) // rd, rs1, rs2 - add single
  FSUB_S(UInt, UInt, UInt) // rd, rs1, rs2 - subtract single
  FMUL_S(UInt, UInt, UInt) // rd, rs1, rs2 - multiply single
  FDIV_S(UInt, UInt, UInt) // rd, rs1, rs2 - divide single
  FSQRT_S(UInt, UInt) // rd, rs1 - square root single
  FMIN_S(UInt, UInt, UInt) // rd, rs1, rs2 - minimum single
  FMAX_S(UInt, UInt, UInt) // rd, rs1, rs2 - maximum single
  // Sign injection
  FSGNJ_S(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject single
  FSGNJN_S(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject neg single
  FSGNJX_S(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject xor single
  FSGNJ_D(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject double
  FSGNJN_D(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject neg double
  FSGNJX_D(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject xor double
  // Conversion/Move
  FCVT_W_S(UInt, UInt, UInt) // rd, rs1, rm - convert single to int (signed)
  FCVT_WU_S(UInt, UInt, UInt) // rd, rs1, rm - convert single to int (unsigned)
  FMV_X_W(UInt, UInt) // rd, rs1 - move bits from float to int
  FEQ_S(UInt, UInt, UInt) // rd, rs1, rs2 - equal
  FLT_S(UInt, UInt, UInt) // rd, rs1, rs2 - less than
  FLE_S(UInt, UInt, UInt) // rd, rs1, rs2 - less than or equal
  FCLASS_S(UInt, UInt) // rd, rs1 - classify single
  FCVT_S_W(UInt, UInt, UInt) // rd, rs1, rm - convert int to single (signed)
  FCVT_S_WU(UInt, UInt, UInt) // rd, rs1, rm - convert int to single (unsigned)
  FMV_W_X(UInt, UInt) // rd, rs1 - move bits from int to float
  // RV64F extension (64-bit specific conversions)
  FCVT_L_S(UInt, UInt, UInt) // rd, rs1, rm - convert single to long (signed)
  FCVT_LU_S(UInt, UInt, UInt) // rd, rs1, rm - convert single to long (unsigned)
  FCVT_S_L(UInt, UInt, UInt) // rd, rs1, rm - convert long to single (signed)
  FCVT_S_LU(UInt, UInt, UInt) // rd, rs1, rm - convert long to single (unsigned)
  // RV32D extension (double-precision floating-point)
  // Load/Store
  FLD(UInt, UInt, Int) // rd, rs1, imm - load double-precision
  FSD(UInt, UInt, Int) // rs1, rs2, imm - store double-precision
  // Computational
  FADD_D(UInt, UInt, UInt) // rd, rs1, rs2 - add double
  FSUB_D(UInt, UInt, UInt) // rd, rs1, rs2 - subtract double
  FMUL_D(UInt, UInt, UInt) // rd, rs1, rs2 - multiply double
  FDIV_D(UInt, UInt, UInt) // rd, rs1, rs2 - divide double
  FSQRT_D(UInt, UInt) // rd, rs1 - square root double
  FMIN_D(UInt, UInt, UInt) // rd, rs1, rs2 - minimum double
  FMAX_D(UInt, UInt, UInt) // rd, rs1, rs2 - maximum double
  // Conversion/Move
  FCVT_S_D(UInt, UInt, UInt) // rd, rs1, rm - convert double to single
  FCVT_D_S(UInt, UInt, UInt) // rd, rs1, rm - convert single to double
  FEQ_D(UInt, UInt, UInt) // rd, rs1, rs2 - equal
  FLT_D(UInt, UInt, UInt) // rd, rs1, rs2 - less than
  FLE_D(UInt, UInt, UInt) // rd, rs1, rs2 - less than or equal
  FCLASS_D(UInt, UInt) // rd, rs1 - classify double
  FCVT_W_D(UInt, UInt, UInt) // rd, rs1, rm - convert double to int (signed)
  FCVT_WU_D(UInt, UInt, UInt) // rd, rs1, rm - convert double to int (unsigned)
  FCVT_D_W(UInt, UInt, UInt) // rd, rs1, rm - convert int to double (signed)
  FCVT_D_WU(UInt, UInt, UInt) // rd, rs1, rm - convert int to double (unsigned)
  // RV64D extension (64-bit specific conversions)
  FCVT_L_D(UInt, UInt, UInt) // rd, rs1, rm - convert double to long (signed)
  FCVT_LU_D(UInt, UInt, UInt) // rd, rs1, rm - convert double to long (unsigned)
  FMV_X_D(UInt, UInt) // rd, rs1 - move bits from double to int
  FCVT_D_L(UInt, UInt, UInt) // rd, rs1, rm - convert long to double (signed)
  FCVT_D_LU(UInt, UInt, UInt) // rd, rs1, rm - convert long to double (unsigned)
  FMV_D_X(UInt, UInt) // rd, rs1 - move bits from int to double
  // RV32Q extension (quad-precision floating-point, 128-bit)
  // Load/Store
  FLQ(UInt, UInt, Int) // rd, rs1, imm - load quad-precision
  FSQ(UInt, UInt, Int) // rs1, rs2, imm - store quad-precision
  // Computational
  FADD_Q(UInt, UInt, UInt) // rd, rs1, rs2 - add quad
  FSUB_Q(UInt, UInt, UInt) // rd, rs1, rs2 - subtract quad
  FMUL_Q(UInt, UInt, UInt) // rd, rs1, rs2 - multiply quad
  FDIV_Q(UInt, UInt, UInt) // rd, rs1, rs2 - divide quad
  FSQRT_Q(UInt, UInt) // rd, rs1 - square root quad
  FMIN_Q(UInt, UInt, UInt) // rd, rs1, rs2 - minimum quad
  FMAX_Q(UInt, UInt, UInt) // rd, rs1, rs2 - maximum quad
  // Sign injection
  FSGNJ_Q(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject quad
  FSGNJN_Q(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject neg quad
  FSGNJX_Q(UInt, UInt, UInt) // rd, rs1, rs2 - sign inject xor quad
  // Conversion
  FCVT_S_Q(UInt, UInt, UInt) // rd, rs1, rm - convert quad to single
  FCVT_Q_S(UInt, UInt, UInt) // rd, rs1, rm - convert single to quad
  FCVT_D_Q(UInt, UInt, UInt) // rd, rs1, rm - convert quad to double
  FCVT_Q_D(UInt, UInt, UInt) // rd, rs1, rm - convert double to quad
  // Compare
  FEQ_Q(UInt, UInt, UInt) // rd, rs1, rs2 - equal
  FLT_Q(UInt, UInt, UInt) // rd, rs1, rs2 - less than
  FLE_Q(UInt, UInt, UInt) // rd, rs1, rs2 - less than or equal
  FCLASS_Q(UInt, UInt) // rd, rs1 - classify quad
  // Integer conversion
  FCVT_W_Q(UInt, UInt, UInt) // rd, rs1, rm - convert quad to int (signed)
  FCVT_WU_Q(UInt, UInt, UInt) // rd, rs1, rm - convert quad to int (unsigned)
  FCVT_Q_W(UInt, UInt, UInt) // rd, rs1, rm - convert int to quad (signed)
  FCVT_Q_WU(UInt, UInt, UInt) // rd, rs1, rm - convert int to quad (unsigned)
  // RV64Q extension (64-bit specific conversions)
  FCVT_L_Q(UInt, UInt, UInt) // rd, rs1, rm - convert quad to long (signed)
  FCVT_LU_Q(UInt, UInt, UInt) // rd, rs1, rm - convert quad to long (unsigned)
  FCVT_Q_L(UInt, UInt, UInt) // rd, rs1, rm - convert long to quad (signed)
  FCVT_Q_LU(UInt, UInt, UInt) // rd, rs1, rm - convert long to quad (unsigned)
  // Move between GPR and FPR
  FMV_X_Q(UInt, UInt) // rd, rs1 - move bits from quad to int
  FMV_Q_X(UInt, UInt) // rd, rs1 - move bits from int to quad
  // Zcf extension (single-precision floating-point compressed instructions)
  C_FLW(UInt, UInt, UInt) // rd', rs1', imm - load single (compressed)
  C_FSW(UInt, UInt, UInt) // rs2', rs1', imm - store single (compressed)
  C_FLWSP(UInt, UInt) // rd, imm - load single from SP (compressed)
  C_FSWSP(UInt, UInt) // rs2, imm - store single to SP (compressed)
  // Zcd extension (double-precision floating-point compressed instructions)
  C_FLD(UInt, UInt, UInt) // rd', rs1', imm - load double (compressed)
  C_FSD(UInt, UInt, UInt) // rs2', rs1', imm - store double (compressed)
  C_FLDSP(UInt, UInt) // rd, imm - load double from SP (compressed)
  C_FSDSP(UInt, UInt) // rs2, imm - store double to SP (compressed)
  // RVV Vector Extension (V extension)
  // Configuration instructions
  VSETVLI(UInt, UInt, UInt) // rd, rs1, vtypei - set vector length immediate
  VSETIVLI(UInt, UInt, UInt) // rd, uimm, vtypei - set vector length immediate (immediate AVL)
  VSETVL(UInt, UInt, UInt) // rd, rs1, rs2 - set vector length (register vtype)
  // Vector integer arithmetic instructions - OPIVV/OPIVX/OPIVI
  VADD_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector add
  VADD_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar add
  VADD_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - vector-immediate add
  VSUB_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector sub
  VSUB_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar sub
  VRSUB_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - scalar-vector rsub
  VRSUB_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - immediate-vector rsub
  VAND_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector and
  VAND_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar and
  VAND_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - vector-immediate and
  VOR_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector or
  VOR_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar or
  VOR_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - vector-immediate or
  VXOR_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector xor
  VXOR_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar xor
  VXOR_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - vector-immediate xor
  VSLL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector shift left logical
  VSLL_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar shift left logical
  VSLL_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - vector-immediate shift left logical
  VSRL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector shift right logical
  VSRL_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar shift right logical
  VSRL_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - vector-immediate shift right logical
  VSRA_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector shift right arithmetic
  VSRA_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar shift right arithmetic
  VSRA_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - vector-immediate shift right arithmetic
  VNSRL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - narrowing shift right logical
  VNSRL_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - narrowing shift right logical
  VNSRL_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - narrowing shift right logical
  VNSRA_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - narrowing shift right arithmetic
  VNSRA_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - narrowing shift right arithmetic
  VNSRA_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - narrowing shift right arithmetic
  VMSEQ_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set equal
  VMSEQ_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set equal
  VMSEQ_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - mask set equal
  VMSNE_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set not equal
  VMSNE_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set not equal
  VMSNE_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - mask set not equal
  VMSLTU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set less than unsigned
  VMSLTU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set less than unsigned
  VMSLT_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set less than signed
  VMSLT_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set less than signed
  VMSLEU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set less than or equal unsigned
  VMSLEU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set less than or equal unsigned
  VMSLEU_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - mask set less than or equal unsigned
  VMSLE_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set less than or equal signed
  VMSLE_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set less than or equal signed
  VMSLE_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - mask set less than or equal signed
  VMSGTU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set greater than unsigned
  VMSGTU_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - mask set greater than unsigned
  VMSGT_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set greater than signed
  VMSGT_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - mask set greater than signed
  VMINU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - minimum unsigned
  VMINU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - minimum unsigned
  VMIN_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - minimum signed
  VMIN_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - minimum signed
  VMAXU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - maximum unsigned
  VMAXU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - maximum unsigned
  VMAX_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - maximum signed
  VMAX_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - maximum signed
  VMUL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - multiply
  VMUL_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - multiply
  VMULH_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - multiply high signed
  VMULH_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - multiply high signed
  VMULHU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - multiply high unsigned
  VMULHU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - multiply high unsigned
  VMULHSU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - multiply high signed-unsigned
  VMULHSU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - multiply high signed-unsigned
  VDIVU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - divide unsigned
  VDIVU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - divide unsigned
  VDIV_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - divide signed
  VDIV_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - divide signed
  VREMU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - remainder unsigned
  VREMU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - remainder unsigned
  VREM_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - remainder signed
  VREM_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - remainder signed
  // Vector widening integer arithmetic - OPWVV/OPWVX
  VWADDU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening add unsigned
  VWADDU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening add unsigned
  VWADD_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening add signed
  VWADD_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening add signed
  VWSUBU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening sub unsigned
  VWSUBU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening sub unsigned
  VWSUB_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening sub signed
  VWSUB_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening sub signed
  VWADDU_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening add unsigned (wide)
  VWADDU_WX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening add unsigned (wide)
  VWADD_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening add signed (wide)
  VWADD_WX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening add signed (wide)
  VWSUBU_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening sub unsigned (wide)
  VWSUBU_WX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening sub unsigned (wide)
  VWSUB_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening sub signed (wide)
  VWSUB_WX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening sub signed (wide)
  VWMUL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening multiply signed
  VWMUL_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening multiply signed
  VWMULU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening multiply unsigned
  VWMULU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening multiply unsigned
  VWMULSU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening multiply signed-unsigned
  VWMULSU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening multiply signed-unsigned
  // Vector integer merge/move
  VMERGE_VVM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - merge
  VMERGE_VXM(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - merge (scalar)
  VMERGE_VIM(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - merge (immediate)
  VMV_V_V(UInt, UInt, Bool) // vd, vs1, vm - move vector
  VMV_V_X(UInt, UInt, Bool) // vd, rs1, vm - move from scalar
  VMV_V_I(UInt, Int, Bool) // vd, simm, vm - move immediate
  VMV_X_S(UInt, UInt) // rd, vs2 - move to scalar
  VMV_S_X(UInt, UInt) // vd, rs1 - move to vector element 0
  // Vector integer extension
  VZEXT_VF2(UInt, UInt, Bool) // vd, vs2, vm - zero extend 2x
  VSEXT_VF2(UInt, UInt, Bool) // vd, vs2, vm - sign extend 2x
  VZEXT_VF4(UInt, UInt, Bool) // vd, vs2, vm - zero extend 4x
  VSEXT_VF4(UInt, UInt, Bool) // vd, vs2, vm - sign extend 4x
  VZEXT_VF8(UInt, UInt, Bool) // vd, vs2, vm - zero extend 8x
  VSEXT_VF8(UInt, UInt, Bool) // vd, vs2, vm - sign extend 8x
  // Vector load/store instructions
  VLE8_V(UInt, UInt, Bool) // vd, rs1, vm - load vector 8-bit
  VLE16_V(UInt, UInt, Bool) // vd, rs1, vm - load vector 16-bit
  VLE32_V(UInt, UInt, Bool) // vd, rs1, vm - load vector 32-bit
  VLE64_V(UInt, UInt, Bool) // vd, rs1, vm - load vector 64-bit
  VSE8_V(UInt, UInt, Bool) // vs3, rs1, vm - store vector 8-bit
  VSE16_V(UInt, UInt, Bool) // vs3, rs1, vm - store vector 16-bit
  VSE32_V(UInt, UInt, Bool) // vs3, rs1, vm - store vector 32-bit
  VSE64_V(UInt, UInt, Bool) // vs3, rs1, vm - store vector 64-bit
  // Vector strided load/store
  VLSE8_V(UInt, UInt, UInt, Bool) // vd, rs1, rs2, vm - load strided 8-bit
  VLSE16_V(UInt, UInt, UInt, Bool) // vd, rs1, rs2, vm - load strided 16-bit
  VLSE32_V(UInt, UInt, UInt, Bool) // vd, rs1, rs2, vm - load strided 32-bit
  VLSE64_V(UInt, UInt, UInt, Bool) // vd, rs1, rs2, vm - load strided 64-bit
  VSSE8_V(UInt, UInt, UInt, Bool) // vs3, rs1, rs2, vm - store strided 8-bit
  VSSE16_V(UInt, UInt, UInt, Bool) // vs3, rs1, rs2, vm - store strided 16-bit
  VSSE32_V(UInt, UInt, UInt, Bool) // vs3, rs1, rs2, vm - store strided 32-bit
  VSSE64_V(UInt, UInt, UInt, Bool) // vs3, rs1, rs2, vm - store strided 64-bit
  // Vector indexed load/store
  VLUXEI8_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed 8-bit
  VLUXEI16_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed 16-bit
  VLUXEI32_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed 32-bit
  VLUXEI64_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed 64-bit
  VSUXEI8_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed 8-bit
  VSUXEI16_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed 16-bit
  VSUXEI32_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed 32-bit
  VSUXEI64_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed 64-bit
  VLOXEI8_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed ordered 8-bit
  VLOXEI16_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed ordered 16-bit
  VLOXEI32_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed ordered 32-bit
  VLOXEI64_V(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - load indexed ordered 64-bit
  VSOXEI8_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed ordered 8-bit
  VSOXEI16_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed ordered 16-bit
  VSOXEI32_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed ordered 32-bit
  VSOXEI64_V(UInt, UInt, UInt, Bool) // vs3, rs1, vs2, vm - store indexed ordered 64-bit
  // Vector floating-point instructions - OPFVV/OPFVF
  VFADD_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float add
  VFADD_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float add
  VFSUB_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float sub
  VFSUB_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float sub
  VFRSUB_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - scalar-vector float rsub
  VFMUL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float mul
  VFMUL_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float mul
  VFDIV_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float div
  VFDIV_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float div
  VFRDIV_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - scalar-vector float rdiv
  VFMIN_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float min
  VFMIN_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float min
  VFMAX_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float max
  VFMAX_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float max
  VFSQRT_V(UInt, UInt, Bool) // vd, vs2, vm - vector float sqrt
  VFSGNJ_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float sign inject
  VFSGNJ_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float sign inject
  VFSGNJN_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float sign inject neg
  VFSGNJN_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float sign inject neg
  VFSGNJX_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - vector float sign inject xor
  VFSGNJX_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - vector-scalar float sign inject xor
  VMFEQ_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set float equal
  VMFEQ_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set float equal
  VMFNE_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set float not equal
  VMFNE_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set float not equal
  VMFLT_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set float less than
  VMFLT_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set float less than
  VMFLE_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask set float less than or equal
  VMFLE_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set float less than or equal
  VMFGT_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set float greater than
  VMFGE_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - mask set float greater than or equal
  VFCLASS_V(UInt, UInt, Bool) // vd, vs2, vm - vector float classify
  VFMERGE_VFM(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - float merge
  VFMV_V_F(UInt, UInt, Bool) // vd, rs1, vm - float move from scalar
  VFMV_F_S(UInt, UInt) // rd, vs2 - float move to scalar
  VFMV_S_F(UInt, UInt) // vd, rs1 - float move to vector element 0
  // Vector widening floating-point
  VFWADD_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float add
  VFWADD_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening float add
  VFWSUB_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float sub
  VFWSUB_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening float sub
  VFWADD_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float add (wide)
  VFWADD_WF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening float add (wide)
  VFWSUB_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float sub (wide)
  VFWSUB_WF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening float sub (wide)
  VFWMUL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float mul
  VFWMUL_VF(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - widening float mul
  // Vector reduction instructions
  VREDSUM_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction sum
  VREDMAXU_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction max unsigned
  VREDMAX_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction max signed
  VREDMINU_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction min unsigned
  VREDMIN_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction min signed
  VREDAND_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction and
  VREDOR_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction or
  VREDXOR_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - reduction xor
  VWREDSUMU_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening reduction sum unsigned
  VWREDSUM_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening reduction sum signed
  VFREDOSUM_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - float reduction ordered sum
  VFREDSUM_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - float reduction sum
  VFREDMAX_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - float reduction max
  VFREDMIN_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - float reduction min
  VFWREDOSUM_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float reduction ordered sum
  VFWREDSUM_VS(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - widening float reduction sum
  // Vector mask instructions
  VMAND_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask and
  VMNAND_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask nand
  VMANDN_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask and not
  VMXOR_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask xor
  VMOR_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask or
  VMNOR_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask nor
  VMORN_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask or not
  VMXNOR_MM(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - mask xnor
  VPOPC_M(UInt, UInt, UInt, Bool) // rd, vs2, vm - count population in mask
  VFIRST_M(UInt, UInt, UInt, Bool) // rd, vs2, vm - find first set in mask
  VMSBF_M(UInt, UInt, UInt, Bool) // vd, vs2, vm - mask set before first
  VMSIF_M(UInt, UInt, UInt, Bool) // vd, vs2, vm - mask set including first
  VMSOF_M(UInt, UInt, UInt, Bool) // vd, vs2, vm - mask set only first
  VIOTA_M(UInt, UInt, UInt, Bool) // vd, vs2, vm - iota from mask
  VID_V(UInt, UInt, Bool) // vd, vm - vector index
  // Vector permutation instructions
  VSLIDEUP_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - slide up
  VSLIDEUP_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - slide up immediate
  VSLIDEDOWN_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - slide down
  VSLIDEDOWN_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - slide down immediate
  VSLIDE1UP_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - slide 1 up
  VSLIDE1DOWN_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - slide 1 down
  VRGATHER_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - gather from vector
  VRGATHER_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - gather from scalar
  VRGATHER_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - gather from immediate
  VCOMPRESS_VM(UInt, UInt, UInt, Bool) // vd, vs2, vm - compress
  // Vector whole register load/store
  VL1RE8_V(UInt, UInt) // vd, rs1 - load whole register 8-bit
  VL1RE16_V(UInt, UInt) // vd, rs1 - load whole register 16-bit
  VL1RE32_V(UInt, UInt) // vd, rs1 - load whole register 32-bit
  VL1RE64_V(UInt, UInt) // vd, rs1 - load whole register 64-bit
  VS1R_V(UInt, UInt) // vs3, rs1 - store whole register 8-bit
  VS2R_V(UInt, UInt) // vs3, rs1 - store whole register 8-bit (2 regs)
  VS4R_V(UInt, UInt) // vs3, rs1 - store whole register 8-bit (4 regs)
  VS8R_V(UInt, UInt) // vs3, rs1 - store whole register 8-bit (8 regs)
  // Vector fixed-point arithmetic
  VSADDU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - saturating add unsigned
  VSADDU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - saturating add unsigned
  VSADDU_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - saturating add unsigned
  VSADD_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - saturating add signed
  VSADD_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - saturating add signed
  VSADD_VI(UInt, Int, UInt, Bool) // vd, simm, vs2, vm - saturating add signed
  VSSUBU_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - saturating sub unsigned
  VSSUBU_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - saturating sub unsigned
  VSSUB_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - saturating sub signed
  VSSUB_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - saturating sub signed
  VAADD_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - averaging add
  VAADD_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - averaging add
  VASUB_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - averaging sub
  VASUB_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - averaging sub
  VSSRL_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - scaling shift right logical
  VSSRL_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - scaling shift right logical
  VSSRL_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - scaling shift right logical
  VSSRA_VV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - scaling shift right arithmetic
  VSSRA_VX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - scaling shift right arithmetic
  VSSRA_VI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - scaling shift right arithmetic
  VNCLIPU_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - narrowing clip unsigned
  VNCLIPU_WX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - narrowing clip unsigned
  VNCLIPU_WI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - narrowing clip unsigned
  VNCLIP_WV(UInt, UInt, UInt, Bool) // vd, vs1, vs2, vm - narrowing clip signed
  VNCLIP_WX(UInt, UInt, UInt, Bool) // vd, rs1, vs2, vm - narrowing clip signed
  VNCLIP_WI(UInt, UInt, UInt, Bool) // vd, uimm, vs2, vm - narrowing clip signed
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
  Float
  Vector
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
    ADDI(_, _, _) | SLLI(_, _, _) | SRLI(_, _, _) | SRAI(_, _, _) =>
      InstructionCategory::Arithmetic
    SLTI(_, _, _) | SLTIU(_, _, _) => InstructionCategory::Compare
    XORI(_, _, _) | ORI(_, _, _) | ANDI(_, _, _) => InstructionCategory::Logical
    ADD(_, _, _)
    | SUB(_, _, _)
    | SLL(_, _, _)
    | MUL(_, _, _)
    | MULH(_, _, _)
    | MULHSU(_, _, _)
    | MULHU(_, _, _)
    | DIV(_, _, _)
    | DIVU(_, _, _)
    | REM(_, _, _)
    | REMU(_, _, _) => InstructionCategory::Arithmetic
    SLT(_, _, _) | SLTU(_, _, _) => InstructionCategory::Compare
    XOR(_, _, _) | SRL(_, _, _) | SRA(_, _, _) | OR(_, _, _) | AND(_, _, _) =>
      InstructionCategory::Logical
    // RV64I instructions
    LD(_, _, _) | LWU(_, _, _) => InstructionCategory::Load
    SD(_, _, _) => InstructionCategory::Store
    ADDIW(_, _, _)
    | SLLIW(_, _, _)
    | SRLIW(_, _, _)
    | SRAIW(_, _, _)
    | ADDW(_, _, _)
    | SUBW(_, _, _)
    | SLLW(_, _, _)
    | SRLW(_, _, _)
    | SRAW(_, _, _) => InstructionCategory::Arithmetic
    // RV64M instructions
    MULW(_, _, _)
    | DIVW(_, _, _)
    | DIVUW(_, _, _)
    | REMW(_, _, _)
    | REMUW(_, _, _) => InstructionCategory::Arithmetic
    // RV32A/RV64A atomic instructions
    LR_W(_, _, _, _) | LR_D(_, _, _, _) => InstructionCategory::Load
    SC_W(_, _, _, _, _) | SC_D(_, _, _, _, _) => InstructionCategory::Store
    AMOSWAP_W(_, _, _, _, _)
    | AMOADD_W(_, _, _, _, _)
    | AMOXOR_W(_, _, _, _, _)
    | AMOAND_W(_, _, _, _, _)
    | AMOOR_W(_, _, _, _, _)
    | AMOMIN_W(_, _, _, _, _)
    | AMOMAX_W(_, _, _, _, _)
    | AMOMINU_W(_, _, _, _, _)
    | AMOMAXU_W(_, _, _, _, _)
    | AMOSWAP_D(_, _, _, _, _)
    | AMOADD_D(_, _, _, _, _)
    | AMOXOR_D(_, _, _, _, _)
    | AMOAND_D(_, _, _, _, _)
    | AMOOR_D(_, _, _, _, _)
    | AMOMIN_D(_, _, _, _, _)
    | AMOMAX_D(_, _, _, _, _)
    | AMOMINU_D(_, _, _, _, _)
    | AMOMAXU_D(_, _, _, _, _) => InstructionCategory::Arithmetic
    FENCE(_, _) | FENCE_I => InstructionCategory::System
    ECALL | EBREAK => InstructionCategory::System
    // RV32C compressed instructions
    C_NOP
    | C_ADDI(_, _)
    | C_LI(_, _)
    | C_ADDI16SP(_)
    | C_LUI(_, _)
    | C_SRLI(_, _)
    | C_SRAI(_, _)
    | C_ADDI4SPN(_, _)
    | C_SLLI(_, _) => InstructionCategory::Arithmetic
    C_ANDI(_, _) | C_AND(_, _) | C_OR(_, _) | C_XOR(_, _) =>
      InstructionCategory::Logical
    C_J(_) | C_JAL(_) | C_JR(_) | C_JALR(_) => InstructionCategory::Jump
    C_BEQZ(_, _) | C_BNEZ(_, _) => InstructionCategory::Branch
    C_LW(_, _, _) | C_LWSP(_, _) => InstructionCategory::Load
    C_SW(_, _, _) | C_SWSP(_, _) => InstructionCategory::Store
    C_MV(_, _) => InstructionCategory::Arithmetic
    C_ADD(_, _) => InstructionCategory::Arithmetic
    C_SUB(_, _) => InstructionCategory::Arithmetic
    C_EBREAK => InstructionCategory::System
    // Zicsr instructions
    CSRRW(_, _, _)
    | CSRRS(_, _, _)
    | CSRRC(_, _, _)
    | CSRRWI(_, _, _)
    | CSRRSI(_, _, _)
    | CSRRCI(_, _, _) => InstructionCategory::System
    // Zba extension (address generation)
    SH1ADD(_, _, _) | SH2ADD(_, _, _) | SH3ADD(_, _, _) =>
      InstructionCategory::Arithmetic
    // Zba RV64 extension
    SH1ADD_UW(_, _, _)
    | SH2ADD_UW(_, _, _)
    | SH3ADD_UW(_, _, _)
    | ADD_UW(_, _, _)
    | SLLI_UW(_, _, _) => InstructionCategory::Arithmetic
    // Zbb extension (basic bit manipulation)
    ANDN(_, _, _)
    | ORN(_, _, _)
    | XNOR(_, _, _)
    | CLZ(_, _)
    | CTZ(_, _)
    | CPOP(_, _)
    | SEXT_B(_, _)
    | SEXT_H(_, _)
    | ZEXT_H(_, _)
    | MAX(_, _, _)
    | MAXU(_, _, _)
    | MIN(_, _, _)
    | MINU(_, _, _)
    | ROL(_, _, _)
    | ROR(_, _, _)
    | RORI(_, _, _)
    | ORC_B(_, _)
    | REV8(_, _) => InstructionCategory::Logical
    // Zbb RV64 extension
    CLZW(_, _)
    | CTZW(_, _)
    | CPOPW(_, _)
    | ROLW(_, _, _)
    | RORW(_, _, _)
    | RORIW(_, _, _) => InstructionCategory::Logical
    // Zbc extension (carry-less multiplication)
    CLMUL(_, _, _) | CLMULH(_, _, _) | CLMULR(_, _, _) =>
      InstructionCategory::Arithmetic
    // Zbs extension (single bit instructions)
    BCLR(_, _, _)
    | BCLRI(_, _, _)
    | BEXT(_, _, _)
    | BEXTI(_, _, _)
    | BINV(_, _, _)
    | BINVI(_, _, _)
    | BSET(_, _, _)
    | BSETI(_, _, _) => InstructionCategory::Logical
    // RV32F extension (single-precision floating-point)
    FLW(_, _, _) => InstructionCategory::Load
    FSW(_, _, _) => InstructionCategory::Store
    FADD_S(_, _, _)
    | FSUB_S(_, _, _)
    | FMUL_S(_, _, _)
    | FDIV_S(_, _, _)
    | FSQRT_S(_, _)
    | FMIN_S(_, _, _)
    | FMAX_S(_, _, _)
    | FSGNJ_S(_, _, _)
    | FSGNJN_S(_, _, _)
    | FSGNJX_S(_, _, _)
    | FSGNJ_D(_, _, _)
    | FSGNJN_D(_, _, _)
    | FSGNJX_D(_, _, _) => InstructionCategory::Float
    FCVT_W_S(_, _, _)
    | FCVT_WU_S(_, _, _)
    | FMV_X_W(_, _)
    | FCVT_S_W(_, _, _)
    | FCVT_S_WU(_, _, _)
    | FMV_W_X(_, _)
    | FCVT_L_S(_, _, _)
    | FCVT_LU_S(_, _, _)
    | FCVT_S_L(_, _, _)
    | FCVT_S_LU(_, _, _) => InstructionCategory::Float
    FEQ_S(_, _, _) | FLT_S(_, _, _) | FLE_S(_, _, _) =>
      InstructionCategory::Compare
    FCLASS_S(_, _) => InstructionCategory::Float
    // RV32D extension (double-precision floating-point)
    FLD(_, _, _) => InstructionCategory::Load
    FSD(_, _, _) => InstructionCategory::Store
    FADD_D(_, _, _)
    | FSUB_D(_, _, _)
    | FMUL_D(_, _, _)
    | FDIV_D(_, _, _)
    | FSQRT_D(_, _)
    | FMIN_D(_, _, _)
    | FMAX_D(_, _, _) => InstructionCategory::Float
    FCVT_S_D(_, _, _)
    | FCVT_D_S(_, _, _)
    | FCVT_W_D(_, _, _)
    | FCVT_WU_D(_, _, _)
    | FCVT_D_W(_, _, _)
    | FCVT_D_WU(_, _, _)
    | FCVT_L_D(_, _, _)
    | FCVT_LU_D(_, _, _)
    | FMV_X_D(_, _)
    | FCVT_D_L(_, _, _)
    | FCVT_D_LU(_, _, _)
    | FMV_D_X(_, _)
    | FMV_X_Q(_, _)
    | FMV_Q_X(_, _) => InstructionCategory::Float
    FEQ_D(_, _, _) | FLT_D(_, _, _) | FLE_D(_, _, _) =>
      InstructionCategory::Compare
    FCLASS_D(_, _) => InstructionCategory::Float
    // RV32Q extension (quad-precision floating-point)
    FLQ(_, _, _) => InstructionCategory::Load
    FSQ(_, _, _) => InstructionCategory::Store
    FADD_Q(_, _, _)
    | FSUB_Q(_, _, _)
    | FMUL_Q(_, _, _)
    | FDIV_Q(_, _, _)
    | FSQRT_Q(_, _)
    | FMIN_Q(_, _, _)
    | FMAX_Q(_, _, _)
    | FSGNJ_Q(_, _, _)
    | FSGNJN_Q(_, _, _)
    | FSGNJX_Q(_, _, _)
    | FCVT_S_Q(_, _, _)
    | FCVT_Q_S(_, _, _)
    | FCVT_D_Q(_, _, _)
    | FCVT_Q_D(_, _, _)
    | FCVT_W_Q(_, _, _)
    | FCVT_WU_Q(_, _, _)
    | FCVT_Q_W(_, _, _)
    | FCVT_Q_WU(_, _, _)
    | FCVT_L_Q(_, _, _)
    | FCVT_LU_Q(_, _, _)
    | FCVT_Q_L(_, _, _)
    | FCVT_Q_LU(_, _, _) => InstructionCategory::Float
    FEQ_Q(_, _, _) | FLT_Q(_, _, _) | FLE_Q(_, _, _) =>
      InstructionCategory::Compare
    FCLASS_Q(_, _) => InstructionCategory::Float
    // Zcf extension (single-precision compressed)
    C_FLW(_, _, _) | C_FLWSP(_, _) => InstructionCategory::Load
    C_FSW(_, _, _) | C_FSWSP(_, _) => InstructionCategory::Store
    // Zcd extension (double-precision compressed)
    C_FLD(_, _, _) | C_FLDSP(_, _) => InstructionCategory::Load
    C_FSD(_, _, _) | C_FSDSP(_, _) => InstructionCategory::Store
    // RVV Vector Extension
    // Configuration
    VSETVLI(_, _, _) | VSETIVLI(_, _, _) | VSETVL(_, _, _) =>
      InstructionCategory::System
    // Vector integer arithmetic
    VADD_VV(_, _, _, _)
    | VADD_VX(_, _, _, _)
    | VADD_VI(_, _, _, _)
    | VSUB_VV(_, _, _, _)
    | VSUB_VX(_, _, _, _)
    | VRSUB_VX(_, _, _, _)
    | VRSUB_VI(_, _, _, _)
    | VAND_VV(_, _, _, _)
    | VAND_VX(_, _, _, _)
    | VAND_VI(_, _, _, _)
    | VOR_VV(_, _, _, _)
    | VOR_VX(_, _, _, _)
    | VOR_VI(_, _, _, _)
    | VXOR_VV(_, _, _, _)
    | VXOR_VX(_, _, _, _)
    | VXOR_VI(_, _, _, _)
    | VSLL_VV(_, _, _, _)
    | VSLL_VX(_, _, _, _)
    | VSLL_VI(_, _, _, _)
    | VSRL_VV(_, _, _, _)
    | VSRL_VX(_, _, _, _)
    | VSRL_VI(_, _, _, _)
    | VSRA_VV(_, _, _, _)
    | VSRA_VX(_, _, _, _)
    | VSRA_VI(_, _, _, _)
    | VMINU_VV(_, _, _, _)
    | VMINU_VX(_, _, _, _)
    | VMIN_VV(_, _, _, _)
    | VMIN_VX(_, _, _, _)
    | VMAXU_VV(_, _, _, _)
    | VMAXU_VX(_, _, _, _)
    | VMAX_VV(_, _, _, _)
    | VMAX_VX(_, _, _, _)
    | VMUL_VV(_, _, _, _)
    | VMUL_VX(_, _, _, _)
    | VMULH_VV(_, _, _, _)
    | VMULH_VX(_, _, _, _)
    | VMULHU_VV(_, _, _, _)
    | VMULHU_VX(_, _, _, _)
    | VMULHSU_VV(_, _, _, _)
    | VMULHSU_VX(_, _, _, _)
    | VDIVU_VV(_, _, _, _)
    | VDIVU_VX(_, _, _, _)
    | VDIV_VV(_, _, _, _)
    | VDIV_VX(_, _, _, _)
    | VREMU_VV(_, _, _, _)
    | VREMU_VX(_, _, _, _)
    | VREM_VV(_, _, _, _)
    | VREM_VX(_, _, _, _)
    | VNSRL_VV(_, _, _, _)
    | VNSRL_VX(_, _, _, _)
    | VNSRL_VI(_, _, _, _)
    | VNSRA_VV(_, _, _, _)
    | VNSRA_VX(_, _, _, _)
    | VNSRA_VI(_, _, _, _)
    | VWADDU_VV(_, _, _, _)
    | VWADDU_VX(_, _, _, _)
    | VWADD_VV(_, _, _, _)
    | VWADD_VX(_, _, _, _)
    | VWSUBU_VV(_, _, _, _)
    | VWSUBU_VX(_, _, _, _)
    | VWSUB_VV(_, _, _, _)
    | VWSUB_VX(_, _, _, _)
    | VWADDU_WV(_, _, _, _)
    | VWADDU_WX(_, _, _, _)
    | VWADD_WV(_, _, _, _)
    | VWADD_WX(_, _, _, _)
    | VWSUBU_WV(_, _, _, _)
    | VWSUBU_WX(_, _, _, _)
    | VWSUB_WV(_, _, _, _)
    | VWSUB_WX(_, _, _, _)
    | VWMUL_VV(_, _, _, _)
    | VWMUL_VX(_, _, _, _)
    | VWMULU_VV(_, _, _, _)
    | VWMULU_VX(_, _, _, _)
    | VWMULSU_VV(_, _, _, _)
    | VWMULSU_VX(_, _, _, _)
    | VMERGE_VVM(_, _, _, _)
    | VMERGE_VXM(_, _, _, _)
    | VMERGE_VIM(_, _, _, _)
    | VMV_V_V(_, _, _)
    | VMV_V_X(_, _, _)
    | VMV_V_I(_, _, _)
    | VMV_X_S(_, _)
    | VMV_S_X(_, _)
    | VZEXT_VF2(_, _, _)
    | VSEXT_VF2(_, _, _)
    | VZEXT_VF4(_, _, _)
    | VSEXT_VF4(_, _, _)
    | VZEXT_VF8(_, _, _)
    | VSEXT_VF8(_, _, _) => InstructionCategory::Vector
    // Vector compare
    VMSEQ_VV(_, _, _, _)
    | VMSEQ_VX(_, _, _, _)
    | VMSEQ_VI(_, _, _, _)
    | VMSNE_VV(_, _, _, _)
    | VMSNE_VX(_, _, _, _)
    | VMSNE_VI(_, _, _, _)
    | VMSLTU_VV(_, _, _, _)
    | VMSLTU_VX(_, _, _, _)
    | VMSLT_VV(_, _, _, _)
    | VMSLT_VX(_, _, _, _)
    | VMSLEU_VV(_, _, _, _)
    | VMSLEU_VX(_, _, _, _)
    | VMSLEU_VI(_, _, _, _)
    | VMSLE_VV(_, _, _, _)
    | VMSLE_VX(_, _, _, _)
    | VMSLE_VI(_, _, _, _)
    | VMSGTU_VX(_, _, _, _)
    | VMSGTU_VI(_, _, _, _)
    | VMSGT_VX(_, _, _, _)
    | VMSGT_VI(_, _, _, _) => InstructionCategory::Compare
    // Vector load/store
    VLE8_V(_, _, _)
    | VLE16_V(_, _, _)
    | VLE32_V(_, _, _)
    | VLE64_V(_, _, _)
    | VLSE8_V(_, _, _, _)
    | VLSE16_V(_, _, _, _)
    | VLSE32_V(_, _, _, _)
    | VLSE64_V(_, _, _, _)
    | VLUXEI8_V(_, _, _, _)
    | VLUXEI16_V(_, _, _, _)
    | VLUXEI32_V(_, _, _, _)
    | VLUXEI64_V(_, _, _, _)
    | VLOXEI8_V(_, _, _, _)
    | VLOXEI16_V(_, _, _, _)
    | VLOXEI32_V(_, _, _, _)
    | VLOXEI64_V(_, _, _, _)
    | VL1RE8_V(_, _)
    | VL1RE16_V(_, _)
    | VL1RE32_V(_, _)
    | VL1RE64_V(_, _) => InstructionCategory::Load
    VSE8_V(_, _, _)
    | VSE16_V(_, _, _)
    | VSE32_V(_, _, _)
    | VSE64_V(_, _, _)
    | VSSE8_V(_, _, _, _)
    | VSSE16_V(_, _, _, _)
    | VSSE32_V(_, _, _, _)
    | VSSE64_V(_, _, _, _)
    | VSUXEI8_V(_, _, _, _)
    | VSUXEI16_V(_, _, _, _)
    | VSUXEI32_V(_, _, _, _)
    | VSUXEI64_V(_, _, _, _)
    | VSOXEI8_V(_, _, _, _)
    | VSOXEI16_V(_, _, _, _)
    | VSOXEI32_V(_, _, _, _)
    | VSOXEI64_V(_, _, _, _)
    | VS1R_V(_, _)
    | VS2R_V(_, _)
    | VS4R_V(_, _)
    | VS8R_V(_, _) => InstructionCategory::Store
    // Vector floating-point
    VFADD_VV(_, _, _, _)
    | VFADD_VF(_, _, _, _)
    | VFSUB_VV(_, _, _, _)
    | VFSUB_VF(_, _, _, _)
    | VFRSUB_VF(_, _, _, _)
    | VFMUL_VV(_, _, _, _)
    | VFMUL_VF(_, _, _, _)
    | VFDIV_VV(_, _, _, _)
    | VFDIV_VF(_, _, _, _)
    | VFRDIV_VF(_, _, _, _)
    | VFMIN_VV(_, _, _, _)
    | VFMIN_VF(_, _, _, _)
    | VFMAX_VV(_, _, _, _)
    | VFMAX_VF(_, _, _, _)
    | VFSQRT_V(_, _, _)
    | VFSGNJ_VV(_, _, _, _)
    | VFSGNJ_VF(_, _, _, _)
    | VFSGNJN_VV(_, _, _, _)
    | VFSGNJN_VF(_, _, _, _)
    | VFSGNJX_VV(_, _, _, _)
    | VFSGNJX_VF(_, _, _, _)
    | VFCLASS_V(_, _, _)
    | VFMERGE_VFM(_, _, _, _)
    | VFMV_V_F(_, _, _)
    | VFMV_F_S(_, _)
    | VFMV_S_F(_, _)
    | VFWADD_VV(_, _, _, _)
    | VFWADD_VF(_, _, _, _)
    | VFWSUB_VV(_, _, _, _)
    | VFWSUB_VF(_, _, _, _)
    | VFWADD_WV(_, _, _, _)
    | VFWADD_WF(_, _, _, _)
    | VFWSUB_WV(_, _, _, _)
    | VFWSUB_WF(_, _, _, _)
    | VFWMUL_VV(_, _, _, _)
    | VFWMUL_VF(_, _, _, _) => InstructionCategory::Float
    // Vector float compare
    VMFEQ_VV(_, _, _, _)
    | VMFEQ_VF(_, _, _, _)
    | VMFNE_VV(_, _, _, _)
    | VMFNE_VF(_, _, _, _)
    | VMFLT_VV(_, _, _, _)
    | VMFLT_VF(_, _, _, _)
    | VMFLE_VV(_, _, _, _)
    | VMFLE_VF(_, _, _, _)
    | VMFGT_VF(_, _, _, _)
    | VMFGE_VF(_, _, _, _) => InstructionCategory::Compare
    // Vector reduction
    VREDSUM_VS(_, _, _, _)
    | VREDMAXU_VS(_, _, _, _)
    | VREDMAX_VS(_, _, _, _)
    | VREDMINU_VS(_, _, _, _)
    | VREDMIN_VS(_, _, _, _)
    | VREDAND_VS(_, _, _, _)
    | VREDOR_VS(_, _, _, _)
    | VREDXOR_VS(_, _, _, _)
    | VWREDSUMU_VS(_, _, _, _)
    | VWREDSUM_VS(_, _, _, _)
    | VFREDOSUM_VS(_, _, _, _)
    | VFREDSUM_VS(_, _, _, _)
    | VFREDMAX_VS(_, _, _, _)
    | VFREDMIN_VS(_, _, _, _)
    | VFWREDOSUM_VS(_, _, _, _)
    | VFWREDSUM_VS(_, _, _, _) => InstructionCategory::Vector
    // Vector mask
    VMAND_MM(_, _, _, _)
    | VMNAND_MM(_, _, _, _)
    | VMANDN_MM(_, _, _, _)
    | VMXOR_MM(_, _, _, _)
    | VMOR_MM(_, _, _, _)
    | VMNOR_MM(_, _, _, _)
    | VMORN_MM(_, _, _, _)
    | VMXNOR_MM(_, _, _, _)
    | VPOPC_M(_, _, _, _)
    | VFIRST_M(_, _, _, _)
    | VMSBF_M(_, _, _, _)
    | VMSIF_M(_, _, _, _)
    | VMSOF_M(_, _, _, _)
    | VIOTA_M(_, _, _, _)
    | VID_V(_, _, _) => InstructionCategory::Logical
    // Vector permutation
    VSLIDEUP_VX(_, _, _, _)
    | VSLIDEUP_VI(_, _, _, _)
    | VSLIDEDOWN_VX(_, _, _, _)
    | VSLIDEDOWN_VI(_, _, _, _)
    | VSLIDE1UP_VX(_, _, _, _)
    | VSLIDE1DOWN_VX(_, _, _, _)
    | VRGATHER_VV(_, _, _, _)
    | VRGATHER_VX(_, _, _, _)
    | VRGATHER_VI(_, _, _, _)
    | VCOMPRESS_VM(_, _, _, _) => InstructionCategory::Vector
    // Vector fixed-point
    VSADDU_VV(_, _, _, _)
    | VSADDU_VX(_, _, _, _)
    | VSADDU_VI(_, _, _, _)
    | VSADD_VV(_, _, _, _)
    | VSADD_VX(_, _, _, _)
    | VSADD_VI(_, _, _, _)
    | VSSUBU_VV(_, _, _, _)
    | VSSUBU_VX(_, _, _, _)
    | VSSUB_VV(_, _, _, _)
    | VSSUB_VX(_, _, _, _)
    | VAADD_VV(_, _, _, _)
    | VAADD_VX(_, _, _, _)
    | VASUB_VV(_, _, _, _)
    | VASUB_VX(_, _, _, _)
    | VSSRL_VV(_, _, _, _)
    | VSSRL_VX(_, _, _, _)
    | VSSRL_VI(_, _, _, _)
    | VSSRA_VV(_, _, _, _)
    | VSSRA_VX(_, _, _, _)
    | VSSRA_VI(_, _, _, _)
    | VNCLIPU_WV(_, _, _, _)
    | VNCLIPU_WX(_, _, _, _)
    | VNCLIPU_WI(_, _, _, _)
    | VNCLIP_WV(_, _, _, _)
    | VNCLIP_WX(_, _, _, _)
    | VNCLIP_WI(_, _, _, _) => InstructionCategory::Vector
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
    | BGEU(_, _, _)
    | C_BEQZ(_, _)
    | C_BNEZ(_, _) => true
    _ => false
  }
}

///|
/// Check if instruction is a jump
pub fn Instruction::is_jump(self : Instruction) -> Bool {
  match self {
    JAL(_, _) | JALR(_, _, _) | C_J(_) | C_JAL(_) | C_JR(_) | C_JALR(_) => true
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
    // Standard branch instructions
    BEQ(_, _, imm) => imm
    BNE(_, _, imm) => imm
    BLT(_, _, imm) => imm
    BGE(_, _, imm) => imm
    BLTU(_, _, imm) => imm
    BGEU(_, _, imm) => imm
    // Standard jump instructions
    JAL(_, imm) => imm
    JALR(_, _, imm) => imm
    // Compressed jump instructions
    C_J(imm) => imm
    C_JAL(imm) => imm
    // Compressed branch instructions
    C_BEQZ(_, imm) => imm
    C_BNEZ(_, imm) => imm
    // Others
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

///|
/// Floating-point register name lookup (f0-f31)
pub fn freg_name(reg : UInt) -> String {
  match reg {
    0U => "ft0"
    1U => "ft1"
    2U => "ft2"
    3U => "ft3"
    4U => "ft4"
    5U => "ft5"
    6U => "ft6"
    7U => "ft7"
    8U => "fs0"
    9U => "fs1"
    10U => "fa0"
    11U => "fa1"
    12U => "fa2"
    13U => "fa3"
    14U => "fa4"
    15U => "fa5"
    16U => "fa6"
    17U => "fa7"
    18U => "fs2"
    19U => "fs3"
    20U => "fs4"
    21U => "fs5"
    22U => "fs6"
    23U => "fs7"
    24U => "fs8"
    25U => "fs9"
    26U => "fs10"
    27U => "fs11"
    28U => "ft8"
    29U => "ft9"
    30U => "ft10"
    31U => "ft11"
    _ => "funknown"
  }
}

///|
/// Compressed floating-point register name lookup (fd', fs', ft' for f8-f15)
pub fn creg_name(reg : UInt) -> String {
  match reg {
    8U => "ft0'"
    9U => "ft1'"
    10U => "fa0'"
    11U => "fa1'"
    12U => "fa2'"
    13U => "fa3'"
    14U => "fa4'"
    15U => "fa5'"
    16U => "fa6'"
    17U => "fa7'"
    18U => "fs2'"
    19U => "fs3'"
    20U => "fs4'"
    21U => "fs5'"
    22U => "fs6'"
    23U => "fs7'"
    24U => "fs8'"
    25U => "fs9'"
    26U => "fs10'"
    27U => "fs11'"
    28U => "ft8'"
    29U => "ft9'"
    30U => "ft10'"
    31U => "ft11'"
    _ => "fc\{reg}" // For f0-f7, show as fc0, fc1, etc.
  }
}

///|
/// Vector register name lookup (v0-v31)
pub fn vreg_name(reg : UInt) -> String {
  match reg {
    0U => "v0"
    1U => "v1"
    2U => "v2"
    3U => "v3"
    4U => "v4"
    5U => "v5"
    6U => "v6"
    7U => "v7"
    8U => "v8"
    9U => "v9"
    10U => "v10"
    11U => "v11"
    12U => "v12"
    13U => "v13"
    14U => "v14"
    15U => "v15"
    16U => "v16"
    17U => "v17"
    18U => "v18"
    19U => "v19"
    20U => "v20"
    21U => "v21"
    22U => "v22"
    23U => "v23"
    24U => "v24"
    25U => "v25"
    26U => "v26"
    27U => "v27"
    28U => "v28"
    29U => "v29"
    30U => "v30"
    31U => "v31"
    _ => "v?"
  }
}
