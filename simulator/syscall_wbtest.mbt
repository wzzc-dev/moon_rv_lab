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
