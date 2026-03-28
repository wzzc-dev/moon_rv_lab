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
