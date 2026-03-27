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
  let assembled = @asm.assemble_with_symbols(source, TEST_BASE)
  if assembled.errors.length() != 0 {
    abort("assembly failed")
  }
  @format.assemble_to_elf(@asm.encode_to_bytes(assembled), TEST_BASE)
}

///|
fn load_state_from_source(name : String, source : String) -> ExecState {
  let elf_bytes = assemble_test_elf(source)
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

///|
test "simulator executes arithmetic and records trace" {
  let state = load_state_from_source(
    "arithmetic_trace", "addi a0, x0, 5\naddi a1, x0, 7\nadd a2, a0, a1\nebreak",
  )
  let finished = run_with_limit(state, 10)
  assert_eq(finished.registers.get(10U), 5U)
  assert_eq(finished.registers.get(11U), 7U)
  assert_eq(finished.registers.get(12U), 12U)
  assert_eq(finished.trace.length(), 4)
  assert_eq(finished.trace[2].pc_after, TEST_BASE + 12U)
  assert_eq(finished.trace[2].register_writes.length(), 1)
  assert_eq(finished.trace[2].register_writes[0].name, "a2")
  assert_eq(finished.trace[2].register_writes[0].after, 12U)
  match finished.stop_reason {
    Some(StopReason::Ebreak(addr)) => assert_eq(addr, TEST_BASE + 12U)
    _ => abort("expected ebreak stop")
  }
}

///|
test "simulator handles branch and memory operations in execution order" {
  let state = load_state_from_source(
    "branch_memory", "addi sp, sp, -16\naddi t0, x0, 7\nsw t0, 0(sp)\nlw a2, 0(sp)\nbeq t0, t0, 8\naddi a0, x0, 1\naddi a1, x0, 9\nebreak",
  )
  let finished = run_with_limit(state, 20)
  assert_eq(finished.registers.get(10U), 0U)
  assert_eq(finished.registers.get(11U), 9U)
  assert_eq(finished.trace.length(), 7)
  assert_eq(finished.trace[2].memory_writes.length(), 4)
  assert_eq(finished.trace[4].pc_after, TEST_BASE + 24U)
  assert_eq(finished.trace[5].pc_before, TEST_BASE + 24U)
}

///|
test "simulator sparse memory reads back stored words" {
  let writes : Map[UInt, Byte] = Map::new()
  writes[0x2000U] = b'\x07'
  writes[0x2001U] = b'\x00'
  writes[0x2002U] = b'\x00'
  writes[0x2003U] = b'\x00'
  let memory = {
    segments: [],
    writes,
    heap_base: 0U,
    heap_end: 0U,
    stack_top: 0U,
  }
  assert_eq(read_u32(memory, 0x2000U), 7U)
  assert_eq(sign_extend_to_uint(read_u32(memory, 0x2000U), 32), 7U)
}

///|
test "simulator stops before executing a configured breakpoint" {
  let state = load_state_from_source(
    "breakpoint", "addi a0, x0, 1\naddi a1, x0, 2\nebreak",
  )
  let stopped = run_until_break(
    with_breakpoints(state, [breakpoint(TEST_BASE + 4U)]),
    10,
  )
  assert_eq(stopped.steps, 1)
  assert_eq(stopped.trace.length(), 1)
  assert_eq(stopped.registers.get(10U), 1U)
  assert_eq(stopped.registers.get(11U), 0U)
  match stopped.stop_reason {
    Some(StopReason::Breakpoint(addr)) => assert_eq(addr, TEST_BASE + 4U)
    _ => abort("expected breakpoint stop")
  }
}

///|
test "simulator routes write and exit syscalls through runtime state" {
  let state = load_state_from_source("write_exit", "ecall\necall\nebreak")
  let stack = state.registers.get(2U)
  let buffer = stack - 32U
  let state = write_memory_bytes(state, buffer, [b'H', b'i', b'\n'])
  let state = configure_syscall(state, 1U, buffer, 3U, 0U, 0U, 0U, 64U)
  let state = step(state)
  assert_eq(state.stdout, "Hi\n")
  assert_eq(state.trace.length(), 1)
  ignore(expect_syscall_name(state.trace[0], "write"))
  let state = configure_syscall(state, 7U, 0U, 0U, 0U, 0U, 0U, 93U)
  let state = step(state)
  assert_eq(state.trace.length(), 2)
  assert_eq(state.stdout, "Hi\n")
  let exit_record = expect_syscall_name(state.trace[1], "exit")
  assert_eq(exit_record.result_signed, 7)
  match state.stop_reason {
    Some(StopReason::Exit(code)) => assert_eq(code, 7)
    _ => abort("expected exit stop")
  }
}

///|
test "simulator supports file-oriented syscalls and brk updates" {
  ensure_test_dir()
  let host_path = TEST_DIR + "/io.txt"
  @fs.write_string_to_file(host_path, "ABCDE") catch {
    _ => abort("failed to write host input")
  }

  let state = load_state_from_source(
    "file_syscalls", "ecall\necall\necall\necall\necall\necall\necall\necall\nebreak",
  )
  let stack = state.registers.get(2U)
  let path_addr = stack - 512U
  let read_buf = stack - 256U
  let stat_buf = stack - 128U
  let state = write_memory_bytes(state, path_addr, string_to_c_bytes(host_path))

  let state = configure_syscall(state, 0U, path_addr, 0U, 0U, 0U, 0U, 56U)
  let state = step(state)
  let fd = state.registers.get(10U)
  assert_true(fd >= 3U)
  ignore(expect_syscall_name(state.trace[0], "openat"))

  let state = configure_syscall(state, fd, read_buf, 4U, 0U, 0U, 0U, 63U)
  let state = step(state)
  let read_record = expect_syscall_name(state.trace[1], "read")
  assert_eq(read_record.result_signed, 4)
  expect_written_byte(state, read_buf, b'A')
  expect_written_byte(state, read_buf + 1U, b'B')
  expect_written_byte(state, read_buf + 2U, b'C')
  expect_written_byte(state, read_buf + 3U, b'D')

  let state = configure_syscall(state, fd, 0U, 0U, 0U, 0U, 0U, 62U)
  let state = step(state)
  let lseek_record = expect_syscall_name(state.trace[2], "lseek")
  assert_eq(lseek_record.result_signed, 0)

  let state = configure_syscall(state, fd, stat_buf, 0U, 0U, 0U, 0U, 80U)
  let state = step(state)
  let fstat_record = expect_syscall_name(state.trace[3], "fstat")
  assert_eq(fstat_record.result_signed, 0)
  assert_eq(state.trace[3].memory_writes.length(), 128)

  let state = configure_syscall(state, fd, 0U, 0U, 0U, 0U, 0U, 57U)
  let state = step(state)
  let close_record = expect_syscall_name(state.trace[4], "close")
  assert_eq(close_record.result_signed, 0)

  let state = configure_syscall(state, fd, 0U, 0U, 0U, 0U, 0U, 29U)
  let state = step(state)
  let ioctl_record = expect_syscall_name(state.trace[5], "ioctl")
  assert_eq(ioctl_record.result_signed, -25)

  let current_brk = state.memory.heap_end
  let state = configure_syscall(state, 0U, 0U, 0U, 0U, 0U, 0U, 214U)
  let state = step(state)
  let brk_query = expect_syscall_name(state.trace[6], "brk")
  assert_eq(brk_query.result_signed, current_brk.reinterpret_as_int())

  let requested_brk = current_brk + 0x1000U
  let state = configure_syscall(state, requested_brk, 0U, 0U, 0U, 0U, 0U, 214U)
  let state = step(state)
  let brk_set = expect_syscall_name(state.trace[7], "brk")
  assert_eq(brk_set.result_signed, requested_brk.reinterpret_as_int())
  assert_eq(state.memory.heap_end, requested_brk)
}

///|
test "simulator executes compressed integer arithmetic branch and stack ops" {
  let source =
    #|c.li a0, 2
    #|c.addi a0, 1
    #|c.mv a1, a0
    #|c.add a1, a0
    #|c.sub a1, a0
    #|c.xor a1, a0
    #|c.or a1, a0
    #|c.and a1, a0
    #|c.andi a1, 1
    #|c.slli a1, 2
    #|c.srli a1, 1
    #|c.addi16sp -16
    #|c.beqz a1, 4
    #|c.bnez a1, 4
    #|c.li a2, 9
    #|c.j 4
    #|c.li a3, 7
    #|c.nop
    #|c.ebreak
  let state = load_state_from_source(
    "compressed_integer",
    source,
  )
  let initial_sp = state.registers.get(2U)
  let finished = run_with_limit(state, 40)
  assert_eq(finished.registers.get(10U), 3U)
  assert_eq(finished.registers.get(11U), 2U)
  assert_eq(finished.registers.get(12U), 0U)
  assert_eq(finished.registers.get(13U), 0U)
  assert_eq(finished.registers.get(2U), initial_sp - 16U)
  assert_true(finished.trace.length() >= 16)
  assert_eq(finished.trace[13].pc_after, TEST_BASE + 32U)
  match finished.stop_reason {
    Some(StopReason::Ebreak(addr)) => assert_eq(addr, TEST_BASE + 36U)
    _ => abort("expected compressed ebreak stop")
  }
}
