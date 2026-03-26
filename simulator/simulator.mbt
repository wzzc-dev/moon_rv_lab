///|
/// Minimal typed execution backend for RISC-V ELF programs.

///|
const SHF_WRITE : UInt = 0x1U

///|
const SHF_ALLOC : UInt = 0x2U

///|
const DEFAULT_STACK_TOP : UInt = 0x7fff0000U

///|
const DEFAULT_HEAP_GAP : UInt = 0x1000U

///|
const FSTAT_ZERO_FILL : Int = 128

///|
pub enum LoadError {
  FileNotFound(String)
  InvalidElf(String)
  ParseElfFailed(String)
  NotRiscV(String)
  NoLoadableSegments(String)
  InvalidEntry(UInt)
} derive(Show)

///|
pub enum LoadResult {
  Loaded(ExecState)
  LoadFailed(LoadError)
} derive(Show)

///|
pub struct Breakpoint {
  addr : UInt
} derive(Show)

///|
pub fn breakpoint(addr : UInt) -> Breakpoint {
  { addr, }
}

///|
pub struct RegisterFile {
  regs : FixedArray[UInt]
} derive(Show)

///|
pub struct MemorySegment {
  start_addr : UInt
  data : FixedArray[Byte]
  writable : Bool
  executable : Bool
} derive(Show)

///|
pub struct Memory {
  segments : Array[MemorySegment]
  writes : Map[UInt, Byte]
  heap_base : UInt
  heap_end : UInt
  stack_top : UInt
} derive(Show)

///|
pub struct ProgramImage {
  file_path : String
  entry_point : UInt
  xlen : Int
  symbols : Array[@format.Symbol]
  instructions : FixedArray[@analysis.DecodedInst]
  instruction_by_addr : Map[UInt, @analysis.DecodedInst]
  segments : Array[MemorySegment]
} derive(Show)

///|
pub struct OpenFile {
  fd : Int
  path : String
  data : Array[Byte]
  cursor : Int
  readable : Bool
  writable : Bool
  closed : Bool
} derive(Show)

///|
pub struct RegisterDelta {
  reg : UInt
  name : String
  before : UInt
  after : UInt
} derive(Show)

///|
pub struct MemoryWrite {
  addr : UInt
  before : Byte
  after : Byte
  size : Int
} derive(Show)

///|
pub struct SyscallRecord {
  number : UInt
  name : String
  args : FixedArray[UInt]
  result : UInt
  result_signed : Int
} derive(Show)

///|
pub enum StopReason {
  Breakpoint(UInt)
  Exit(Int)
  ExitGroup(Int)
  Ebreak(UInt)
  MaxSteps(Int)
  Fault(String)
  UnsupportedInstruction(String)
} derive(Show)

///|
pub struct TraceEvent {
  step : Int
  pc_before : UInt
  pc_after : UInt
  inst : @analysis.DecodedInst
  register_writes : FixedArray[RegisterDelta]
  memory_writes : FixedArray[MemoryWrite]
  syscall : SyscallRecord?
  stdout_append : String
  stderr_append : String
  stop_reason : StopReason?
} derive(Show)

///|
pub struct ExecSnapshot {
  pc : UInt
  steps : Int
  registers : FixedArray[UInt]
  stop_reason : StopReason?
  stdout : String
  stderr : String
} derive(Show)

///|
pub struct ExecDiff {
  pc_before : UInt
  pc_after : UInt
  register_writes : FixedArray[RegisterDelta]
} derive(Show)

///|
pub struct ExecState {
  image : ProgramImage
  registers : RegisterFile
  memory : Memory
  pc : UInt
  steps : Int
  breakpoints : Array[Breakpoint]
  open_files : Map[Int, OpenFile]
  next_fd : Int
  stdin_buffer : Array[Byte]
  stdin_cursor : Int
  stdout : String
  stderr : String
  trace : Array[TraceEvent]
  stop_reason : StopReason?
} derive(Show)

///|
pub fn RegisterFile::new() -> RegisterFile {
  { regs: FixedArray::make(32, 0U) }
}

///|
pub fn RegisterFile::get(self : RegisterFile, reg : UInt) -> UInt {
  let idx = reg.reinterpret_as_int()
  if idx < 0 || idx >= self.regs.length() {
    0U
  } else {
    self.regs[idx]
  }
}

///|
pub fn RegisterFile::set(
  self : RegisterFile,
  reg : UInt,
  value : UInt,
  xlen : Int,
) -> RegisterFile {
  if reg == 0U {
    return self
  }
  let idx = reg.reinterpret_as_int()
  if idx < 0 || idx >= self.regs.length() {
    return self
  }
  let regs = copy_uint_fixed_array(self.regs)
  regs[idx] = normalize_xlen(value, xlen)
  { regs, }
}

///|
pub fn load(input_file : String, entry_override? : UInt = 0U) -> LoadResult {
  if !@fs.path_exists(input_file) {
    return LoadFailed(LoadError::FileNotFound(input_file))
  }
  let bytes = @fs.read_file_to_bytes(input_file).to_fixedarray() catch {
    _ => return LoadFailed(LoadError::FileNotFound(input_file))
  }
  if !@format.is_elf(bytes) {
    return LoadFailed(LoadError::InvalidElf(input_file))
  }
  match @format.parse_elf(bytes) {
    None => LoadFailed(LoadError::ParseElfFailed(input_file))
    Some(elf) => {
      if !elf.is_riscv() {
        return LoadFailed(LoadError::NotRiscV(input_file))
      }
      let segments = load_segments_from_elf(elf)
      if segments.length() == 0 {
        return LoadFailed(LoadError::NoLoadableSegments(input_file))
      }
      let xlen = if elf.is_64bit { 64 } else { 32 }
      let entry_point = if entry_override != 0U {
        entry_override
      } else {
        elf.entry_point()
      }
      let image = build_program_image(
        input_file, elf, segments, entry_point, xlen,
      )
      match image.instruction_by_addr.get(entry_point) {
        Some(_) => Loaded(make_initial_state(image))
        None => LoadFailed(LoadError::InvalidEntry(entry_point))
      }
    }
  }
}

///|
pub fn with_breakpoints(
  state : ExecState,
  breakpoints : Array[Breakpoint],
) -> ExecState {
  { ..state, breakpoints, }
}

///|
pub fn with_entry(state : ExecState, entry_addr : UInt) -> ExecState {
  {
    ..state,
    pc: entry_addr,
    image: { ..state.image, entry_point: entry_addr },
    stop_reason: None,
  }
}

///|
pub fn snapshot(state : ExecState) -> ExecSnapshot {
  {
    pc: state.pc,
    steps: state.steps,
    registers: copy_uint_fixed_array(state.registers.regs),
    stop_reason: state.stop_reason,
    stdout: state.stdout,
    stderr: state.stderr,
  }
}

///|
pub fn diff(before : ExecSnapshot, after : ExecSnapshot) -> ExecDiff {
  let deltas : Array[RegisterDelta] = []
  for i = 0; i < before.registers.length(); i = i + 1 {
    if before.registers[i] != after.registers[i] {
      let reg = i.reinterpret_as_uint()
      deltas.push({
        reg,
        name: @decode.reg_name(reg),
        before: before.registers[i],
        after: after.registers[i],
      })
    }
  }
  {
    pc_before: before.pc,
    pc_after: after.pc,
    register_writes: FixedArray::from_array(deltas),
  }
}

///|
pub fn step(state : ExecState) -> ExecState {
  match state.stop_reason {
    Some(_) => state
    None =>
      match state.image.instruction_by_addr.get(state.pc) {
        None =>
          {
            ..state,
            stop_reason: Some(
              StopReason::Fault("no instruction at " + format_hex(state.pc)),
            ),
          }
        Some(decoded) => execute_single_step(state, decoded)
      }
  }
}

///|
pub fn run_until_break(state : ExecState, max_steps : Int) -> ExecState {
  run_internal(state, max_steps)
}

///|
pub fn run_with_limit(state : ExecState, max_steps : Int) -> ExecState {
  run_internal(state, max_steps)
}

///|
pub fn ProgramImage::resolve_symbol(
  self : ProgramImage,
  name : String,
) -> UInt? {
  for sym in self.symbols {
    if sym.name == name {
      return Some(sym.value)
    }
  }
  None
}

///|
pub fn stop_reason_to_string(reason : StopReason?) -> String {
  match reason {
    Some(StopReason::Breakpoint(addr)) => "breakpoint @" + format_hex(addr)
    Some(StopReason::Exit(code)) => "exit(" + code.to_string() + ")"
    Some(StopReason::ExitGroup(code)) => "exit_group(" + code.to_string() + ")"
    Some(StopReason::Ebreak(addr)) => "ebreak @" + format_hex(addr)
    Some(StopReason::MaxSteps(limit)) =>
      "max steps reached (" + limit.to_string() + ")"
    Some(StopReason::Fault(msg)) => "fault: " + msg
    Some(StopReason::UnsupportedInstruction(msg)) => "unsupported: " + msg
    None => "running"
  }
}

///|
pub fn exec_snapshot_to_json(snapshot : ExecSnapshot) -> String {
  let mut json = "{"
  json = json + "\"pc\":" + json_string(format_hex(snapshot.pc))
  json = json + ",\"steps\":" + snapshot.steps.to_string()
  json = json +
    ",\"stop_reason\":" +
    json_string(stop_reason_to_string(snapshot.stop_reason))
  json = json + ",\"stdout\":" + json_string(snapshot.stdout)
  json = json + ",\"stderr\":" + json_string(snapshot.stderr)
  json = json + ",\"registers\":" + registers_to_json(snapshot.registers)
  json = json + "}"
  json
}

///|
pub fn exec_diff_to_json(diff : ExecDiff) -> String {
  let mut json = "{"
  json = json + "\"pc_before\":" + json_string(format_hex(diff.pc_before))
  json = json + ",\"pc_after\":" + json_string(format_hex(diff.pc_after))
  json = json +
    ",\"register_writes\":" +
    register_deltas_to_json(diff.register_writes)
  json = json + "}"
  json
}

///|
pub fn trace_event_to_json(event : TraceEvent) -> String {
  let mut json = "{"
  json = json + "\"step\":" + event.step.to_string()
  json = json + ",\"pc_before\":" + json_string(format_hex(event.pc_before))
  json = json + ",\"pc_after\":" + json_string(format_hex(event.pc_after))
  json = json + ",\"addr\":" + json_string(format_hex(event.inst.addr))
  json = json + ",\"asm\":" + json_string(@disasm.disassemble(event.inst.inst))
  json = json +
    ",\"category\":" +
    json_string(event.inst.inst.category().to_string())
  json = json +
    ",\"register_writes\":" +
    register_deltas_to_json(event.register_writes)
  json = json +
    ",\"memory_writes\":" +
    memory_writes_to_json(event.memory_writes)
  json = json + ",\"stdout_append\":" + json_string(event.stdout_append)
  json = json + ",\"stderr_append\":" + json_string(event.stderr_append)
  json = json +
    ",\"stop_reason\":" +
    json_string(stop_reason_to_string(event.stop_reason))
  match event.syscall {
    Some(record) => json = json + ",\"syscall\":" + syscall_to_json(record)
    None => json = json + ",\"syscall\":null"
  }
  json = json + "}"
  json
}

///|
pub fn trace_events_to_json(events : Array[TraceEvent]) -> String {
  let mut json = "["
  for i = 0; i < events.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    json = json + trace_event_to_json(events[i])
  }
  json = json + "]"
  json
}

///|
fn execute_single_step(
  state : ExecState,
  decoded : @analysis.DecodedInst,
) -> ExecState {
  let before = snapshot(state)
  let next_pc = state.pc + decoded.length.reinterpret_as_uint()
  let mut registers = state.registers
  let mut memory = state.memory
  let mut open_files = state.open_files
  let mut stdout = state.stdout
  let mut stderr = state.stderr
  let mut stdin_cursor = state.stdin_cursor
  let mut pc_after = next_pc
  let mut memory_writes : Array[MemoryWrite] = []
  let mut syscall : SyscallRecord? = None
  let mut stdout_append = ""
  let mut stderr_append = ""
  let mut stop_reason : StopReason? = None

  let read_reg = fn(reg : UInt) -> UInt { registers.get(reg) }
  let write_reg = fn(reg : UInt, value : UInt) -> Unit {
    registers = registers.set(reg, value, state.image.xlen)
  }
  let write_byte = fn(addr : UInt, value : Byte) -> Unit {
    let before_byte = read_byte(memory, addr)
    memory.writes[addr] = value
    memory_writes.push({ addr, before: before_byte, after: value, size: 1 })
  }

  match decoded.inst {
    @decode.LUI(rd, imm) =>
      write_reg(rd, normalize_xlen(imm.reinterpret_as_uint(), state.image.xlen))
    @decode.AUIPC(rd, imm) =>
      write_reg(rd, normalize_xlen(add_signed(state.pc, imm), state.image.xlen))
    @decode.JAL(rd, imm) => {
      write_reg(rd, next_pc)
      pc_after = add_signed(state.pc, imm)
    }
    @decode.JALR(rd, rs1, imm) => {
      write_reg(rd, next_pc)
      let target = add_signed(read_reg(rs1), imm)
      pc_after = if (target & 1U) != 0U { target - 1U } else { target }
    }
    @decode.BEQ(rs1, rs2, imm) =>
      if read_reg(rs1) == read_reg(rs2) {
        pc_after = add_signed(state.pc, imm)
      }
    @decode.BNE(rs1, rs2, imm) =>
      if read_reg(rs1) != read_reg(rs2) {
        pc_after = add_signed(state.pc, imm)
      }
    @decode.BLT(rs1, rs2, imm) =>
      if signed_of_xlen(read_reg(rs1), state.image.xlen) <
        signed_of_xlen(read_reg(rs2), state.image.xlen) {
        pc_after = add_signed(state.pc, imm)
      }
    @decode.BGE(rs1, rs2, imm) =>
      if signed_of_xlen(read_reg(rs1), state.image.xlen) >=
        signed_of_xlen(read_reg(rs2), state.image.xlen) {
        pc_after = add_signed(state.pc, imm)
      }
    @decode.BLTU(rs1, rs2, imm) =>
      if normalize_xlen(read_reg(rs1), state.image.xlen) <
        normalize_xlen(read_reg(rs2), state.image.xlen) {
        pc_after = add_signed(state.pc, imm)
      }
    @decode.BGEU(rs1, rs2, imm) =>
      if normalize_xlen(read_reg(rs1), state.image.xlen) >=
        normalize_xlen(read_reg(rs2), state.image.xlen) {
        pc_after = add_signed(state.pc, imm)
      }
    @decode.LB(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      let value = read_byte(memory, addr).to_uint()
      write_reg(rd, sign_extend_to_uint(value, 8))
    }
    @decode.LH(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_reg(rd, sign_extend_to_uint(read_u16(memory, addr), 16))
    }
    @decode.LW(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_reg(rd, sign_extend_to_uint(read_u32(memory, addr), 32))
    }
    @decode.LBU(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_reg(rd, read_byte(memory, addr).to_uint())
    }
    @decode.LHU(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_reg(rd, read_u16(memory, addr))
    }
    @decode.LD(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_reg(rd, read_u64(memory, addr))
    }
    @decode.LWU(rd, rs1, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_reg(rd, read_u32(memory, addr))
    }
    @decode.SB(rs1, rs2, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_byte(addr, (read_reg(rs2) & 0xFFU).to_byte())
    }
    @decode.SH(rs1, rs2, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_u16(write_byte, addr, read_reg(rs2))
    }
    @decode.SW(rs1, rs2, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_u32(write_byte, addr, read_reg(rs2))
    }
    @decode.SD(rs1, rs2, imm) => {
      let addr = add_signed(read_reg(rs1), imm)
      write_u64(write_byte, addr, read_reg(rs2))
    }
    @decode.ADDI(rd, rs1, imm) =>
      write_reg(
        rd,
        normalize_xlen(add_signed(read_reg(rs1), imm), state.image.xlen),
      )
    @decode.SLTI(rd, rs1, imm) =>
      write_reg(
        rd,
        if signed_of_xlen(read_reg(rs1), state.image.xlen) < imm {
          1U
        } else {
          0U
        },
      )
    @decode.SLTIU(rd, rs1, imm) =>
      write_reg(
        rd,
        if normalize_xlen(read_reg(rs1), state.image.xlen) <
          normalize_xlen(imm.reinterpret_as_uint(), state.image.xlen) {
          1U
        } else {
          0U
        },
      )
    @decode.XORI(rd, rs1, imm) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) ^ imm.reinterpret_as_uint(),
          state.image.xlen,
        ),
      )
    @decode.ORI(rd, rs1, imm) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) | imm.reinterpret_as_uint(),
          state.image.xlen,
        ),
      )
    @decode.ANDI(rd, rs1, imm) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) & imm.reinterpret_as_uint(),
          state.image.xlen,
        ),
      )
    @decode.SLLI(rd, rs1, shamt) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) <<
          (shamt & shift_mask_for_xlen(state.image.xlen)).reinterpret_as_int(),
          state.image.xlen,
        ),
      )
    @decode.SRLI(rd, rs1, shamt) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) >>
          (shamt & shift_mask_for_xlen(state.image.xlen)).reinterpret_as_int(),
          state.image.xlen,
        ),
      )
    @decode.SRAI(rd, rs1, shamt) =>
      write_reg(
        rd,
        arithmetic_shift_right(
          read_reg(rs1),
          shamt & shift_mask_for_xlen(state.image.xlen),
          state.image.xlen,
        ),
      )
    @decode.ADD(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(read_reg(rs1) + read_reg(rs2), state.image.xlen),
      )
    @decode.SUB(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(read_reg(rs1) - read_reg(rs2), state.image.xlen),
      )
    @decode.SLL(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) <<
          (read_reg(rs2) & shift_mask_for_xlen(state.image.xlen)).reinterpret_as_int(),
          state.image.xlen,
        ),
      )
    @decode.SLT(rd, rs1, rs2) =>
      write_reg(
        rd,
        if signed_of_xlen(read_reg(rs1), state.image.xlen) <
          signed_of_xlen(read_reg(rs2), state.image.xlen) {
          1U
        } else {
          0U
        },
      )
    @decode.SLTU(rd, rs1, rs2) =>
      write_reg(
        rd,
        if normalize_xlen(read_reg(rs1), state.image.xlen) <
          normalize_xlen(read_reg(rs2), state.image.xlen) {
          1U
        } else {
          0U
        },
      )
    @decode.XOR(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(read_reg(rs1) ^ read_reg(rs2), state.image.xlen),
      )
    @decode.SRL(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(
          read_reg(rs1) >>
          (read_reg(rs2) & shift_mask_for_xlen(state.image.xlen)).reinterpret_as_int(),
          state.image.xlen,
        ),
      )
    @decode.SRA(rd, rs1, rs2) =>
      write_reg(
        rd,
        arithmetic_shift_right(
          read_reg(rs1),
          read_reg(rs2) & shift_mask_for_xlen(state.image.xlen),
          state.image.xlen,
        ),
      )
    @decode.OR(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(read_reg(rs1) | read_reg(rs2), state.image.xlen),
      )
    @decode.AND(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(read_reg(rs1) & read_reg(rs2), state.image.xlen),
      )
    @decode.MUL(rd, rs1, rs2) =>
      write_reg(
        rd,
        normalize_xlen(read_reg(rs1) * read_reg(rs2), state.image.xlen),
      )
    @decode.DIV(rd, rs1, rs2) =>
      write_reg(
        rd,
        signed_division_result(read_reg(rs1), read_reg(rs2), state.image.xlen),
      )
    @decode.DIVU(rd, rs1, rs2) =>
      write_reg(
        rd,
        unsigned_division_result(read_reg(rs1), read_reg(rs2), state.image.xlen),
      )
    @decode.REM(rd, rs1, rs2) =>
      write_reg(
        rd,
        signed_remainder_result(read_reg(rs1), read_reg(rs2), state.image.xlen),
      )
    @decode.REMU(rd, rs1, rs2) =>
      write_reg(
        rd,
        unsigned_remainder_result(
          read_reg(rs1),
          read_reg(rs2),
          state.image.xlen,
        ),
      )
    @decode.ADDIW(rd, rs1, imm) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          normalize_xlen(add_signed(read_reg(rs1), imm), 32),
          32,
        ),
      )
    @decode.SLLIW(rd, rs1, shamt) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          (read_reg(rs1) & 0xFFFFFFFFU) << (shamt & 0x1FU).reinterpret_as_int(),
          32,
        ),
      )
    @decode.SRLIW(rd, rs1, shamt) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          (read_reg(rs1) & 0xFFFFFFFFU) >> (shamt & 0x1FU).reinterpret_as_int(),
          32,
        ),
      )
    @decode.SRAIW(rd, rs1, shamt) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          arithmetic_shift_right(read_reg(rs1) & 0xFFFFFFFFU, shamt & 0x1FU, 32),
          32,
        ),
      )
    @decode.ADDW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint((read_reg(rs1) + read_reg(rs2)) & 0xFFFFFFFFU, 32),
      )
    @decode.SUBW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint((read_reg(rs1) - read_reg(rs2)) & 0xFFFFFFFFU, 32),
      )
    @decode.SLLW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          (read_reg(rs1) & 0xFFFFFFFFU) <<
          (read_reg(rs2) & 0x1FU).reinterpret_as_int(),
          32,
        ),
      )
    @decode.SRLW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          (read_reg(rs1) & 0xFFFFFFFFU) >>
          (read_reg(rs2) & 0x1FU).reinterpret_as_int(),
          32,
        ),
      )
    @decode.SRAW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          arithmetic_shift_right(
            read_reg(rs1) & 0xFFFFFFFFU,
            read_reg(rs2) & 0x1FU,
            32,
          ),
          32,
        ),
      )
    @decode.DIVW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          signed_division_result(read_reg(rs1), read_reg(rs2), 32),
          32,
        ),
      )
    @decode.DIVUW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          unsigned_division_result(read_reg(rs1), read_reg(rs2), 32),
          32,
        ),
      )
    @decode.REMW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          signed_remainder_result(read_reg(rs1), read_reg(rs2), 32),
          32,
        ),
      )
    @decode.REMUW(rd, rs1, rs2) =>
      write_reg(
        rd,
        sign_extend_to_uint(
          unsigned_remainder_result(read_reg(rs1), read_reg(rs2), 32),
          32,
        ),
      )
    @decode.FENCE(_, _) => ()
    @decode.FENCE_I => ()
    @decode.EBREAK => {
      stop_reason = Some(StopReason::Ebreak(state.pc))
      pc_after = state.pc
    }
    @decode.ECALL => {
      let result = handle_syscall(
        state, memory, open_files, stdout, stderr, stdin_cursor, memory_writes,
      )
      memory = result.memory
      open_files = result.open_files
      stdout = result.stdout
      stderr = result.stderr
      stdin_cursor = result.stdin_cursor
      memory_writes = result.memory_writes
      syscall = result.syscall
      stdout_append = result.stdout_append
      stderr_append = result.stderr_append
      stop_reason = result.stop_reason
      registers = result.registers
    }
    _ =>
      stop_reason = Some(
        StopReason::UnsupportedInstruction(@disasm.disassemble(decoded.inst)),
      )
  }

  let mut next = {
    ..state,
    registers,
    memory,
    pc: pc_after,
    steps: state.steps + 1,
    open_files,
    stdin_cursor,
    stdout,
    stderr,
    stop_reason,
  }
  let after = snapshot(next)
  let delta = diff(before, after)
  let trace = state.trace.copy()
  trace.push({
    step: next.steps,
    pc_before: state.pc,
    pc_after,
    inst: decoded,
    register_writes: delta.register_writes,
    memory_writes: FixedArray::from_array(memory_writes),
    syscall,
    stdout_append,
    stderr_append,
    stop_reason,
  })
  next = { ..next, trace, }
  next
}

///|
priv struct SyscallStepResult {
  memory : Memory
  open_files : Map[Int, OpenFile]
  registers : RegisterFile
  stdin_cursor : Int
  stdout : String
  stderr : String
  memory_writes : Array[MemoryWrite]
  stdout_append : String
  stderr_append : String
  syscall : SyscallRecord?
  stop_reason : StopReason?
}

///|
fn handle_syscall(
  state : ExecState,
  memory : Memory,
  open_files : Map[Int, OpenFile],
  stdout : String,
  stderr : String,
  stdin_cursor : Int,
  memory_writes : Array[MemoryWrite],
) -> SyscallStepResult {
  let mut next_memory = memory
  let next_open_files = open_files
  let mut next_registers = state.registers
  let mut next_stdout = stdout
  let mut next_stderr = stderr
  let mut next_stdin_cursor = stdin_cursor
  let next_memory_writes = memory_writes
  let mut stdout_append = ""
  let mut stderr_append = ""
  let mut stop_reason : StopReason? = None
  let args : Array[UInt] = []
  for i = 0; i < 6; i = i + 1 {
    args.push(state.registers.get((10 + i).reinterpret_as_uint()))
  }
  let syscall_no = state.registers.get(17U)
  let mut result_signed = -1
  let mut syscall_name = "unknown"

  let write_reg = fn(value : Int) -> Unit {
    result_signed = value
    next_registers = next_registers.set(
      10U,
      value.reinterpret_as_uint(),
      state.image.xlen,
    )
  }

  match syscall_no {
    63U => {
      syscall_name = "read"
      let fd = args[0].reinterpret_as_int()
      let buf = args[1]
      let count = args[2].reinterpret_as_int()
      if fd == 0 {
        let remaining = next_stdin_length(state, next_stdin_cursor)
        let readable = min_int(count, remaining)
        for i = 0; i < readable; i = i + 1 {
          let b = state.stdin_buffer[next_stdin_cursor + i]
          let before_byte = read_byte(
            next_memory,
            buf + i.reinterpret_as_uint(),
          )
          next_memory.writes[buf + i.reinterpret_as_uint()] = b
          next_memory_writes.push({
            addr: buf + i.reinterpret_as_uint(),
            before: before_byte,
            after: b,
            size: 1,
          })
        }
        next_stdin_cursor = next_stdin_cursor + readable
        write_reg(readable)
      } else {
        match next_open_files.get(fd) {
          Some(file) =>
            if file.closed || !file.readable {
              write_reg(-1)
            } else {
              let remaining = if file.cursor >= file.data.length() {
                0
              } else {
                file.data.length() - file.cursor
              }
              let readable = min_int(count, remaining)
              let updated = { ..file, cursor: file.cursor + readable }
              for i = 0; i < readable; i = i + 1 {
                let b = file.data[file.cursor + i]
                let before_byte = read_byte(
                  next_memory,
                  buf + i.reinterpret_as_uint(),
                )
                next_memory.writes[buf + i.reinterpret_as_uint()] = b
                next_memory_writes.push({
                  addr: buf + i.reinterpret_as_uint(),
                  before: before_byte,
                  after: b,
                  size: 1,
                })
              }
              next_open_files.set(fd, updated)
              write_reg(readable)
            }
          None => write_reg(-1)
        }
      }
    }
    64U => {
      syscall_name = "write"
      let fd = args[0].reinterpret_as_int()
      let buf = args[1]
      let count = args[2].reinterpret_as_int()
      let text = read_string_range(next_memory, buf, count)
      if fd == 1 {
        next_stdout = next_stdout + text
        stdout_append = text
        write_reg(count)
      } else if fd == 2 {
        next_stderr = next_stderr + text
        stderr_append = text
        write_reg(count)
      } else {
        match next_open_files.get(fd) {
          Some(file) =>
            if file.closed || !file.writable {
              write_reg(-1)
            } else {
              let updated = write_to_open_file(file, next_memory, buf, count)
              next_open_files.set(fd, updated)
              write_reg(count)
            }
          None => write_reg(-1)
        }
      }
    }
    56U => {
      syscall_name = "openat"
      let path_addr = args[1]
      let path = read_c_string(next_memory, path_addr, 4096)
      if path == "" || !@fs.path_exists(path) {
        write_reg(-1)
      } else {
        let bytes = @fs.read_file_to_bytes(path).to_fixedarray() catch {
          _ => []
        }
        let data = Array::from_fixed_array(bytes)
        let mut fd = state.next_fd
        while next_open_files.contains(fd) {
          fd = fd + 1
        }
        next_open_files.set(fd, {
          fd,
          path,
          data,
          cursor: 0,
          readable: true,
          writable: false,
          closed: false,
        })
        write_reg(fd)
      }
    }
    57U => {
      syscall_name = "close"
      let fd = args[0].reinterpret_as_int()
      match next_open_files.get(fd) {
        Some(file) => {
          next_open_files.set(fd, { ..file, closed: true })
          write_reg(0)
        }
        None => write_reg(-1)
      }
    }
    62U => {
      syscall_name = "lseek"
      let fd = args[0].reinterpret_as_int()
      let offset = signed_of_xlen(args[1], state.image.xlen)
      let whence = args[2].reinterpret_as_int()
      match next_open_files.get(fd) {
        Some(file) =>
          if file.closed {
            write_reg(-1)
          } else {
            let base = match whence {
              0 => 0
              1 => file.cursor
              2 => file.data.length()
              _ => -1
            }
            if base < 0 {
              write_reg(-1)
            } else {
              let cursor = base + offset
              if cursor < 0 {
                write_reg(-1)
              } else {
                next_open_files.set(fd, { ..file, cursor, })
                write_reg(cursor)
              }
            }
          }
        None => write_reg(-1)
      }
    }
    80U => {
      syscall_name = "fstat"
      let buf = args[1]
      for i = 0; i < FSTAT_ZERO_FILL; i = i + 1 {
        let addr = buf + i.reinterpret_as_uint()
        let before_byte = read_byte(next_memory, addr)
        next_memory.writes[addr] = b'\x00'
        next_memory_writes.push({
          addr,
          before: before_byte,
          after: b'\x00',
          size: 1,
        })
      }
      write_reg(0)
    }
    29U => {
      syscall_name = "ioctl"
      write_reg(-25)
    }
    93U => {
      syscall_name = "exit"
      let code = args[0].reinterpret_as_int()
      write_reg(code)
      stop_reason = Some(StopReason::Exit(code))
    }
    94U => {
      syscall_name = "exit_group"
      let code = args[0].reinterpret_as_int()
      write_reg(code)
      stop_reason = Some(StopReason::ExitGroup(code))
    }
    214U => {
      syscall_name = "brk"
      let requested = args[0]
      if requested == 0U {
        write_reg(next_memory.heap_end.reinterpret_as_int())
      } else if requested >= next_memory.heap_base {
        next_memory = { ..next_memory, heap_end: requested }
        write_reg(requested.reinterpret_as_int())
      } else {
        write_reg(next_memory.heap_end.reinterpret_as_int())
      }
    }
    _ => {
      syscall_name = "unknown"
      write_reg(-1)
    }
  }

  {
    memory: next_memory,
    open_files: next_open_files,
    registers: next_registers,
    stdin_cursor: next_stdin_cursor,
    stdout: next_stdout,
    stderr: next_stderr,
    memory_writes: next_memory_writes,
    stdout_append,
    stderr_append,
    syscall: Some({
      number: syscall_no,
      name: syscall_name,
      args: FixedArray::from_array(args),
      result: normalize_xlen(
        result_signed.reinterpret_as_uint(),
        state.image.xlen,
      ),
      result_signed,
    }),
    stop_reason,
  }
}

///|
fn run_internal(state : ExecState, max_steps : Int) -> ExecState {
  let limit = if max_steps <= 0 { 1 } else { max_steps }
  let start_steps = state.steps
  let mut current = state
  while true {
    match current.stop_reason {
      Some(_) => return current
      None => ()
    }
    if has_breakpoint(current.breakpoints, current.pc) {
      return {
        ..current,
        stop_reason: Some(StopReason::Breakpoint(current.pc)),
      }
    }
    if current.steps - start_steps >= limit {
      return { ..current, stop_reason: Some(StopReason::MaxSteps(limit)) }
    }
    current = step(current)
  }
  current
}

///|
fn has_breakpoint(breakpoints : Array[Breakpoint], addr : UInt) -> Bool {
  for bp in breakpoints {
    if bp.addr == addr {
      return true
    }
  }
  false
}

///|
fn build_program_image(
  input_file : String,
  elf : @format.ElfFile,
  segments : Array[MemorySegment],
  entry_point : UInt,
  xlen : Int,
) -> ProgramImage {
  let instructions : Array[@analysis.DecodedInst] = []
  let inst_map : Map[UInt, @analysis.DecodedInst] = Map::new()
  for segment in segments {
    if segment.executable {
      let decoded = @analysis.decode_instructions(
        segment.data,
        segment.start_addr,
      )
      for inst in decoded {
        instructions.push(inst)
        inst_map[inst.addr] = inst
      }
    }
  }
  {
    file_path: input_file,
    entry_point,
    xlen,
    symbols: elf.get_symbols(),
    instructions: FixedArray::from_array(instructions),
    instruction_by_addr: inst_map,
    segments,
  }
}

///|
fn make_initial_state(image : ProgramImage) -> ExecState {
  let regs = RegisterFile::new().set(
    2U,
    stack_top_for_segments(image.segments),
    image.xlen,
  )
  {
    image,
    registers: regs,
    memory: {
      segments: image.segments,
      writes: Map::new(),
      heap_base: heap_base_for_segments(image.segments),
      heap_end: heap_base_for_segments(image.segments),
      stack_top: stack_top_for_segments(image.segments),
    },
    pc: image.entry_point,
    steps: 0,
    breakpoints: [],
    open_files: Map::new(),
    next_fd: 3,
    stdin_buffer: [],
    stdin_cursor: 0,
    stdout: "",
    stderr: "",
    trace: [],
    stop_reason: None,
  }
}

///|
fn load_segments_from_elf(elf : @format.ElfFile) -> Array[MemorySegment] {
  let segments : Array[MemorySegment] = []
  if elf.is_64bit {
    for sh in elf.sections64 {
      if (sh.sh_flags & SHF_ALLOC) != 0U && sh.sh_size > 0U {
        segments.push(section_to_segment_64(elf.raw_data, sh))
      }
    }
  } else {
    for sh in elf.sections32 {
      if (sh.sh_flags & SHF_ALLOC) != 0U && sh.sh_size > 0U {
        segments.push(section_to_segment_32(elf.raw_data, sh))
      }
    }
  }
  segments
}

///|
fn section_to_segment_64(
  raw : FixedArray[Byte],
  sh : @format.Elf64SectionHeader,
) -> MemorySegment {
  let size = sh.sh_size.reinterpret_as_int()
  let data : FixedArray[Byte] = FixedArray::make(size, b'\x00')
  if sh.sh_type != @format.SHT_NOBITS {
    let start = sh.sh_offset.reinterpret_as_int()
    let available = min_int(size, raw.length() - start)
    for i = 0; i < available; i = i + 1 {
      data[i] = raw[start + i]
    }
  }
  {
    start_addr: sh.sh_addr,
    data,
    writable: (sh.sh_flags & SHF_WRITE) != 0U,
    executable: (sh.sh_flags & @format.SHF_EXECINSTR) != 0U,
  }
}

///|
fn section_to_segment_32(
  raw : FixedArray[Byte],
  sh : @format.Elf32SectionHeader,
) -> MemorySegment {
  let size = sh.sh_size.reinterpret_as_int()
  let data : FixedArray[Byte] = FixedArray::make(size, b'\x00')
  if sh.sh_type != @format.SHT_NOBITS {
    let start = sh.sh_offset.reinterpret_as_int()
    let available = min_int(size, raw.length() - start)
    for i = 0; i < available; i = i + 1 {
      data[i] = raw[start + i]
    }
  }
  {
    start_addr: sh.sh_addr,
    data,
    writable: (sh.sh_flags & SHF_WRITE) != 0U,
    executable: (sh.sh_flags & @format.SHF_EXECINSTR) != 0U,
  }
}

///|
fn heap_base_for_segments(segments : Array[MemorySegment]) -> UInt {
  let mut max_end = 0U
  for segment in segments {
    let end_addr = segment.start_addr +
      segment.data.length().reinterpret_as_uint()
    if end_addr > max_end {
      max_end = end_addr
    }
  }
  align_up(max_end + DEFAULT_HEAP_GAP, 0x1000U)
}

///|
fn stack_top_for_segments(segments : Array[MemorySegment]) -> UInt {
  let heap_base = heap_base_for_segments(segments)
  if heap_base < DEFAULT_STACK_TOP {
    DEFAULT_STACK_TOP
  } else {
    align_up(heap_base + 0x100000U, 0x1000U)
  }
}

///|
fn copy_uint_fixed_array(values : FixedArray[UInt]) -> FixedArray[UInt] {
  let copied : FixedArray[UInt] = FixedArray::make(values.length(), 0U)
  for i = 0; i < values.length(); i = i + 1 {
    copied[i] = values[i]
  }
  copied
}

///|
fn normalize_xlen(value : UInt, xlen : Int) -> UInt {
  if xlen <= 32 {
    value & 0xFFFFFFFFU
  } else {
    value
  }
}

///|
fn sign_extend_to_uint(value : UInt, bits : Int) -> UInt {
  sign_extend_bits(value, bits).reinterpret_as_uint()
}

///|
fn sign_extend_bits(value : UInt, bits : Int) -> Int {
  if bits >= 64 {
    value.reinterpret_as_int()
  } else if bits == 32 {
    (value & 0xFFFFFFFFU).reinterpret_as_int()
  } else {
    let mask = (1U << bits) - 1U
    let truncated = value & mask
    let sign_bit = 1U << (bits - 1)
    if (truncated & sign_bit) != 0U {
      truncated.reinterpret_as_int() - (1 << bits)
    } else {
      truncated.reinterpret_as_int()
    }
  }
}

///|
fn signed_of_xlen(value : UInt, xlen : Int) -> Int {
  sign_extend_bits(normalize_xlen(value, xlen), xlen)
}

///|
fn shift_mask_for_xlen(xlen : Int) -> UInt {
  if xlen <= 32 {
    0x1FU
  } else {
    0x3FU
  }
}

///|
fn arithmetic_shift_right(value : UInt, shamt : UInt, xlen : Int) -> UInt {
  let shifted = signed_of_xlen(value, xlen) >> shamt.reinterpret_as_int()
  normalize_xlen(shifted.reinterpret_as_uint(), xlen)
}

///|
fn signed_division_result(lhs : UInt, rhs : UInt, xlen : Int) -> UInt {
  let divisor = signed_of_xlen(rhs, xlen)
  if divisor == 0 {
    return normalize_xlen(0U - 1U, xlen)
  }
  let dividend = signed_of_xlen(lhs, xlen)
  if xlen == 32 && dividend == -2147483647 - 1 && divisor == -1 {
    return normalize_xlen(dividend.reinterpret_as_uint(), 32)
  }
  normalize_xlen((dividend / divisor).reinterpret_as_uint(), xlen)
}

///|
fn unsigned_division_result(lhs : UInt, rhs : UInt, xlen : Int) -> UInt {
  let divisor = normalize_xlen(rhs, xlen)
  if divisor == 0U {
    return normalize_xlen(0U - 1U, xlen)
  }
  normalize_xlen(normalize_xlen(lhs, xlen) / divisor, xlen)
}

///|
fn signed_remainder_result(lhs : UInt, rhs : UInt, xlen : Int) -> UInt {
  let divisor = signed_of_xlen(rhs, xlen)
  let dividend = signed_of_xlen(lhs, xlen)
  if divisor == 0 {
    return normalize_xlen(lhs, xlen)
  }
  if xlen == 32 && dividend == -2147483647 - 1 && divisor == -1 {
    return 0U
  }
  normalize_xlen((dividend % divisor).reinterpret_as_uint(), xlen)
}

///|
fn unsigned_remainder_result(lhs : UInt, rhs : UInt, xlen : Int) -> UInt {
  let divisor = normalize_xlen(rhs, xlen)
  if divisor == 0U {
    return normalize_xlen(lhs, xlen)
  }
  normalize_xlen(normalize_xlen(lhs, xlen) % divisor, xlen)
}

///|
fn add_signed(base : UInt, offset : Int) -> UInt {
  if offset >= 0 {
    base + offset.reinterpret_as_uint()
  } else {
    base - (-offset).reinterpret_as_uint()
  }
}

///|
fn read_byte(memory : Memory, addr : UInt) -> Byte {
  match memory.writes.get(addr) {
    Some(value) => value
    None => {
      for segment in memory.segments {
        let start = segment.start_addr
        let end_ = segment.start_addr +
          segment.data.length().reinterpret_as_uint()
        if addr >= start && addr < end_ {
          return segment.data[(addr - start).reinterpret_as_int()]
        }
      }
      b'\x00'
    }
  }
}

///|
fn read_u16(memory : Memory, addr : UInt) -> UInt {
  read_byte(memory, addr).to_uint() |
  (read_byte(memory, addr + 1U).to_uint() << 8)
}

///|
fn read_u32(memory : Memory, addr : UInt) -> UInt {
  read_byte(memory, addr).to_uint() |
  (read_byte(memory, addr + 1U).to_uint() << 8) |
  (read_byte(memory, addr + 2U).to_uint() << 16) |
  (read_byte(memory, addr + 3U).to_uint() << 24)
}

///|
fn read_u64(memory : Memory, addr : UInt) -> UInt {
  read_byte(memory, addr).to_uint() |
  (read_byte(memory, addr + 1U).to_uint() << 8) |
  (read_byte(memory, addr + 2U).to_uint() << 16) |
  (read_byte(memory, addr + 3U).to_uint() << 24) |
  (read_byte(memory, addr + 4U).to_uint() << 32) |
  (read_byte(memory, addr + 5U).to_uint() << 40) |
  (read_byte(memory, addr + 6U).to_uint() << 48) |
  (read_byte(memory, addr + 7U).to_uint() << 56)
}

///|
fn write_u16(
  write_byte : (UInt, Byte) -> Unit,
  addr : UInt,
  value : UInt,
) -> Unit {
  write_byte(addr, (value & 0xFFU).to_byte())
  write_byte(addr + 1U, ((value >> 8) & 0xFFU).to_byte())
}

///|
fn write_u32(
  write_byte : (UInt, Byte) -> Unit,
  addr : UInt,
  value : UInt,
) -> Unit {
  write_byte(addr, (value & 0xFFU).to_byte())
  write_byte(addr + 1U, ((value >> 8) & 0xFFU).to_byte())
  write_byte(addr + 2U, ((value >> 16) & 0xFFU).to_byte())
  write_byte(addr + 3U, ((value >> 24) & 0xFFU).to_byte())
}

///|
fn write_u64(
  write_byte : (UInt, Byte) -> Unit,
  addr : UInt,
  value : UInt,
) -> Unit {
  write_byte(addr, (value & 0xFFU).to_byte())
  write_byte(addr + 1U, ((value >> 8) & 0xFFU).to_byte())
  write_byte(addr + 2U, ((value >> 16) & 0xFFU).to_byte())
  write_byte(addr + 3U, ((value >> 24) & 0xFFU).to_byte())
  write_byte(addr + 4U, ((value >> 32) & 0xFFU).to_byte())
  write_byte(addr + 5U, ((value >> 40) & 0xFFU).to_byte())
  write_byte(addr + 6U, ((value >> 48) & 0xFFU).to_byte())
  write_byte(addr + 7U, ((value >> 56) & 0xFFU).to_byte())
}

///|
fn read_c_string(memory : Memory, addr : UInt, max_len : Int) -> String {
  let mut result = ""
  for i = 0; i < max_len; i = i + 1 {
    let ch = read_byte(memory, addr + i.reinterpret_as_uint())
    if ch == b'\x00' {
      break
    }
    result = result + ch.to_int().unsafe_to_char().to_string()
  }
  result
}

///|
fn read_string_range(memory : Memory, addr : UInt, count : Int) -> String {
  let mut result = ""
  for i = 0; i < count; i = i + 1 {
    let ch = read_byte(memory, addr + i.reinterpret_as_uint())
    result = result + ch.to_int().unsafe_to_char().to_string()
  }
  result
}

///|
fn write_to_open_file(
  file : OpenFile,
  memory : Memory,
  buf : UInt,
  count : Int,
) -> OpenFile {
  let data = file.data.copy()
  let mut cursor = file.cursor
  for i = 0; i < count; i = i + 1 {
    let b = read_byte(memory, buf + i.reinterpret_as_uint())
    if cursor < data.length() {
      data[cursor] = b
    } else {
      data.push(b)
    }
    cursor = cursor + 1
  }
  { ..file, data, cursor }
}

///|
fn next_stdin_length(state : ExecState, cursor : Int) -> Int {
  if cursor >= state.stdin_buffer.length() {
    0
  } else {
    state.stdin_buffer.length() - cursor
  }
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn align_up(value : UInt, align : UInt) -> UInt {
  if align == 0U {
    value
  } else {
    let rem = value % align
    if rem == 0U {
      value
    } else {
      value + align - rem
    }
  }
}

///|
fn registers_to_json(registers : FixedArray[UInt]) -> String {
  let mut json = "{"
  for i = 0; i < registers.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    json = json + json_string(@decode.reg_name(i.reinterpret_as_uint()))
    json = json + ":"
    json = json + json_string(format_hex(registers[i]))
  }
  json = json + "}"
  json
}

///|
fn register_deltas_to_json(deltas : FixedArray[RegisterDelta]) -> String {
  let mut json = "["
  for i = 0; i < deltas.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let delta = deltas[i]
    json = json + "{"
    json = json + "\"reg\":" + delta.reg.to_string()
    json = json + ",\"name\":" + json_string(delta.name)
    json = json + ",\"before\":" + json_string(format_hex(delta.before))
    json = json + ",\"after\":" + json_string(format_hex(delta.after))
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn memory_writes_to_json(writes : FixedArray[MemoryWrite]) -> String {
  let mut json = "["
  for i = 0; i < writes.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let write = writes[i]
    json = json + "{"
    json = json + "\"addr\":" + json_string(format_hex(write.addr))
    json = json +
      ",\"before\":" +
      json_string(format_hex(write.before.to_uint()))
    json = json + ",\"after\":" + json_string(format_hex(write.after.to_uint()))
    json = json + ",\"size\":" + write.size.to_string()
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn syscall_to_json(record : SyscallRecord) -> String {
  let mut json = "{"
  json = json + "\"number\":" + record.number.to_string()
  json = json + ",\"name\":" + json_string(record.name)
  json = json + ",\"args\":["
  for i = 0; i < record.args.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    json = json + json_string(format_hex(record.args[i]))
  }
  json = json + "]"
  json = json + ",\"result\":" + json_string(format_hex(record.result))
  json = json + ",\"result_signed\":" + record.result_signed.to_string()
  json = json + "}"
  json
}

///|
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut v = value
    while v > 0U {
      let digit = (v % 16U).reinterpret_as_int()
      let ch = if digit < 10 {
        (digit + 48).unsafe_to_char()
      } else {
        (digit + 87).unsafe_to_char()
      }
      result = ch.to_string() + result
      v = v / 16U
    }
    result
  }
}

///|
fn format_hex(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
fn json_string(value : String) -> String {
  "\"" + escape_json(value) + "\""
}

///|
fn escape_json(value : String) -> String {
  let mut escaped = ""
  for c in value {
    match c {
      '"' => escaped = escaped + "\\\""
      '\\' => escaped = escaped + "\\\\"
      '\n' => escaped = escaped + "\\n"
      '\r' => escaped = escaped + "\\r"
      '\t' => escaped = escaped + "\\t"
      _ => escaped = escaped + c.to_string()
    }
  }
  escaped
}
