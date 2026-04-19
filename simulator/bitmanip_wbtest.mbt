///|
test "simulator executes zba shifts and zbb count or extend instructions" {
  let state = load_state_from_source_with_xlen(
    "zba_zbb_counts",
    "addi a0, zero, 15\n" +
    "clz a1, a0\n" +
    "ctz a2, a0\n" +
    "cpop a3, a0\n" +
    "addi a4, zero, -1\n" +
    "sext.b a5, a4\n" +
    "sext.h a6, a4\n" +
    "zext.h a7, a4\n" +
    "addi t0, zero, 2\n" +
    "sh1add t1, t0, a0\n" +
    "sh2add t2, t0, a0\n" +
    "sh3add s0, t0, a0\n" +
    "ebreak",
    32,
  )
  assert_eq(state.image.xlen, 32)
  let finished = run_with_limit(state, 24)
  assert_eq(finished.registers.get(11U), 28U)
  assert_eq(finished.registers.get(12U), 0U)
  assert_eq(finished.registers.get(13U), 4U)
  assert_eq(finished.registers.get(15U), normalize_xlen(0U - 1U, state.image.xlen))
  assert_eq(finished.registers.get(16U), normalize_xlen(0U - 1U, state.image.xlen))
  assert_eq(finished.registers.get(17U), 0xFFFFU)
  assert_eq(finished.registers.get(6U), 19U)
  assert_eq(finished.registers.get(7U), 23U)
  assert_eq(finished.registers.get(8U), 31U)
}

///|
test "simulator executes zbb logical max min family" {
  let state = load_state_from_source_with_xlen(
    "zbb_logical_ext",
    "addi a0, zero, -4\n" +
    "addi a1, zero, 3\n" +
    "andn a2, a0, a1\n" +
    "orn a3, a0, a1\n" +
    "xnor a4, a0, a1\n" +
    "max a5, a0, a1\n" +
    "min a6, a0, a1\n" +
    "maxu a7, a0, a1\n" +
    "minu s0, a0, a1\n" +
    "ebreak",
    32,
  )
  assert_eq(state.image.xlen, 32)
  let finished = run_with_limit(state, 16)
  assert_eq(finished.registers.get(12U), normalize_xlen(0U - 4U, state.image.xlen))
  assert_eq(finished.registers.get(13U), normalize_xlen(0U - 4U, state.image.xlen))
  assert_eq(finished.registers.get(14U), 0U)
  assert_eq(finished.registers.get(15U), 3U)
  assert_eq(finished.registers.get(16U), normalize_xlen(0U - 4U, state.image.xlen))
  assert_eq(finished.registers.get(17U), normalize_xlen(0U - 4U, state.image.xlen))
  assert_eq(finished.registers.get(8U), 3U)
}

///|
test "simulator executes zbs and rotate family" {
  let state = load_state_from_source_with_xlen(
    "zbs_rotate",
    "addi a0, zero, 10\n" +
    "addi a1, zero, 2\n" +
    "bset a2, a0, a1\n" +
    "bclr a3, a2, a1\n" +
    "bext a4, a2, a1\n" +
    "binv a5, a0, a1\n" +
    "bseti a6, a0, 0\n" +
    "bclri a7, a6, 1\n" +
    "bexti s0, a2, 1\n" +
    "binvi s1, a0, 3\n" +
    "addi t0, zero, 1\n" +
    "rol s2, t0, a1\n" +
    "ror s3, a0, a1\n" +
    "rori s4, a0, 1\n" +
    "addi t1, zero, 1\n" +
    "slli t1, t1, 8\n" +
    "addi t1, t1, 2\n" +
    "orc.b s5, t1\n" +
    "rev8 s6, t1\n" +
    "ebreak",
    32,
  )
  assert_eq(state.image.xlen, 32)
  let finished = run_with_limit(state, 32)
  assert_eq(finished.registers.get(12U), 14U)
  assert_eq(finished.registers.get(13U), 10U)
  assert_eq(finished.registers.get(14U), 1U)
  assert_eq(finished.registers.get(15U), 14U)
  assert_eq(finished.registers.get(16U), 11U)
  assert_eq(finished.registers.get(17U), 9U)
  assert_eq(finished.registers.get(8U), 1U)
  assert_eq(finished.registers.get(9U), 2U)
  assert_eq(finished.registers.get(18U), 4U)
  assert_eq(
    finished.registers.get(19U),
    rotate_right_of_xlen(10U, 2U, state.image.xlen),
  )
  assert_eq(
    finished.registers.get(20U),
    rotate_right_of_xlen(10U, 1U, state.image.xlen),
  )
  assert_eq(
    finished.registers.get(21U),
    or_combine_bytes_of_xlen(0x102U, state.image.xlen),
  )
  assert_eq(
    finished.registers.get(22U),
    reverse_bytes_of_xlen(0x102U, state.image.xlen),
  )
}
