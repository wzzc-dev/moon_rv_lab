///|
test "simulator load_input respects shared input specs" {
  let path = write_test_raw_file("shared_input_spec", "addi a0, x0, 42\nebreak")
  match load_input(@program.raw_input_spec(path, 0x9000U, 32)) {
    Loaded(state) => {
      assert_eq(state.image.entry_point, 0x9000U)
      assert_eq(state.image.xlen, 32)
    }
    LoadFailed(err) => abort("load_input failed: \{err}")
  }
}

///|
test "simulator exposes execution support tiers and decode-only stops" {
  let @decode.DecodeResult(addi_inst) = @decode.decode(0x00100513U)
  assert_eq(
    @program.capability_tier_name(instruction_execution_tier(addi_inst, 64)),
    "fully_executable",
  )

  let @decode.DecodeResult(vector_inst) = @decode.decode(0x00028087U)
  assert_eq(
    @program.capability_tier_name(instruction_execution_tier(vector_inst, 64)),
    "decode_only",
  )

  let @decode.DecodeResult(invalid_inst) = @decode.decode(0xFFFFFFFFU)
  assert_eq(
    @program.capability_tier_name(instruction_execution_tier(invalid_inst, 64)),
    "unsupported",
  )

  let state = load_state_from_program_bytes(
    "decode_only_stop",
    program_bytes_from_parts([encode_u32(0x00028087U)]),
  )
  let stopped = step(state)
  match stopped.stop_reason {
    Some(StopReason::UnsupportedInstruction(msg)) =>
      assert_true(msg.contains("decode-only"))
    _ => abort("expected decode-only unsupported stop")
  }
}
