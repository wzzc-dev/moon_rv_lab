///|
const TEST_BASE : UInt = 0x10000U

///|
const TEST_DIR : String = "tmp_simulator_tests"

///|
fn ensure_test_dir() -> Unit {
  if !@fs.path_exists(TEST_DIR) {
    @fs.create_dir(TEST_DIR) catch {
      _ => abort("failed to create simulator test dir")
    }
  }
}

///|
fn assemble_test_elf(source : String) -> FixedArray[Byte] {
  assemble_test_elf_with_xlen(source, 64)
}

///|
fn assemble_test_elf_with_xlen(source : String, xlen : Int) -> FixedArray[Byte] {
  let assembled = @asm.assemble_with_symbols(source, TEST_BASE)
  if assembled.errors.length() != 0 {
    abort("assembly failed")
  }
  let bytes = @asm.encode_to_bytes(assembled)
  if xlen <= 32 {
    @format.assemble_to_elf32(bytes, TEST_BASE)
  } else {
    @format.assemble_to_elf64(bytes, TEST_BASE)
  }
}

///|
fn load_state_from_elf_bytes(
  name : String,
  elf_bytes : FixedArray[Byte],
) -> ExecState {
  match @format.parse_elf(elf_bytes) {
    Some(elf) => {
      if !elf.is_riscv() {
        abort("not a riscv elf")
      }
      let segments = load_segments_from_elf(elf)
      if segments.length() == 0 {
        abort("no loadable segments")
      }
      let entry = elf.entry_point()
      let xlen = if elf.is_64bit { 64 } else { 32 }
      let image = build_program_image(name + ".elf", elf, segments, entry, xlen)
      match image.instruction_by_addr.get(entry) {
        Some(_) => make_initial_state(image)
        None => abort("entry not decoded")
      }
    }
    None => abort("parse elf failed")
  }
}

///|
fn load_state_from_program_bytes(
  name : String,
  program_bytes : FixedArray[Byte],
) -> ExecState {
  load_state_from_elf_bytes(
    name,
    @format.assemble_to_elf(program_bytes, TEST_BASE),
  )
}

///|
fn load_state_from_source(name : String, source : String) -> ExecState {
  load_state_from_elf_bytes(name, assemble_test_elf(source))
}

///|
fn load_state_from_source_with_xlen(
  name : String,
  source : String,
  xlen : Int,
) -> ExecState {
  load_state_from_elf_bytes(name, assemble_test_elf_with_xlen(source, xlen))
}

///|
fn encode_u16(code : UInt) -> Array[Byte] {
  let bytes : Array[Byte] = []
  bytes.push((code & 0xFFU).to_byte())
  bytes.push(((code >> 8) & 0xFFU).to_byte())
  bytes
}

///|
fn encode_u32(code : UInt) -> Array[Byte] {
  let bytes : Array[Byte] = []
  bytes.push((code & 0xFFU).to_byte())
  bytes.push(((code >> 8) & 0xFFU).to_byte())
  bytes.push(((code >> 16) & 0xFFU).to_byte())
  bytes.push(((code >> 24) & 0xFFU).to_byte())
  bytes
}

///|
fn program_bytes_from_parts(parts : Array[Array[Byte]]) -> FixedArray[Byte] {
  let bytes : Array[Byte] = []
  for part in parts {
    for byte in part {
      bytes.push(byte)
    }
  }
  FixedArray::from_array(bytes)
}

///|
fn string_to_c_bytes(value : String) -> Array[Byte] {
  let bytes : Array[Byte] = []
  for ch in value.to_array() {
    bytes.push(ch.to_int().to_byte())
  }
  bytes.push(b'\x00')
  bytes
}

///|
fn write_memory_bytes(
  state : ExecState,
  addr : UInt,
  bytes : Array[Byte],
) -> ExecState {
  let memory = state.memory
  for i = 0; i < bytes.length(); i = i + 1 {
    memory.writes[addr + i.reinterpret_as_uint()] = bytes[i]
  }
  { ..state, memory, }
}

///|
fn configure_syscall(
  state : ExecState,
  arg0 : UInt,
  arg1 : UInt,
  arg2 : UInt,
  arg3 : UInt,
  arg4 : UInt,
  arg5 : UInt,
  syscall_no : UInt,
) -> ExecState {
  let xlen = state.image.xlen
  let regs = state.registers
  let regs = regs.set(10U, arg0, xlen)
  let regs = regs.set(11U, arg1, xlen)
  let regs = regs.set(12U, arg2, xlen)
  let regs = regs.set(13U, arg3, xlen)
  let regs = regs.set(14U, arg4, xlen)
  let regs = regs.set(15U, arg5, xlen)
  let regs = regs.set(17U, syscall_no, xlen)
  { ..state, registers: regs, stop_reason: None }
}

///|
fn expect_syscall_name(event : TraceEvent, name : String) -> SyscallRecord {
  match event.syscall {
    Some(record) => {
      if record.name != name {
        abort("unexpected syscall")
      }
      record
    }
    None => abort("missing syscall record")
  }
}

///|
fn expect_written_byte(state : ExecState, addr : UInt, value : Byte) -> Unit {
  match state.memory.writes.get(addr) {
    Some(byte) => if byte != value { abort("unexpected memory byte") }
    None => abort("missing memory write")
  }
}
