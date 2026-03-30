///|
test "simulator loads raw binaries with configured base metadata" {
  let path = write_test_raw_file("raw_load_base", "addi a0, x0, 42\nebreak")

  match load_raw(path, 0x8000U, 64) {
    Loaded(state) => {
      assert_eq(state.image.entry_point, 0x8000U)
      assert_eq(state.pc, 0x8000U)
      assert_eq(state.image.xlen, 64)
      assert_eq(state.image.symbols.length(), 0)
      assert_true(state.image.resolve_symbol("_start") is None)

      let finished = run_with_limit(state, 8)
      let snapshot = snapshot(finished)
      assert_eq(snapshot.pc, 0x8004U)
      assert_eq(snapshot.registers[10], 42U)
      match snapshot.stop_reason {
        Some(StopReason::Ebreak(addr)) => assert_eq(addr, 0x8004U)
        _ => abort("expected ebreak stop")
      }
    }
    LoadFailed(err) => abort("load raw failed: \{err}")
  }
}

///|
test "simulator preserves rv32 metadata for raw execution" {
  let finished = run_with_limit(
    load_state_from_raw_source(
      "raw_rv32",
      "addi a0, x0, 42\nebreak",
      TEST_BASE,
      32,
    ),
    8,
  )
  let snapshot = snapshot(finished)
  assert_eq(finished.image.xlen, 32)
  assert_eq(snapshot.registers[10], 42U)
  match snapshot.stop_reason {
    Some(StopReason::Ebreak(addr)) => assert_eq(addr, TEST_BASE + 4U)
    _ => abort("expected ebreak stop")
  }
}
