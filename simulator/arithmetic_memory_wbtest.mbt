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
