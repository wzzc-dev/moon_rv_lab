///|
fn load_state_from_compressed_parts(
  name : String,
  parts : Array[Array[Byte]],
) -> ExecState {
  load_state_from_program_bytes(name, program_bytes_from_parts(parts))
}

///|
test "simulator loads compressed instructions into the program image" {
  let state = load_state_from_compressed_parts("compressed_load", [
    encode_u16(0x4505U),
    encode_u16(0x9002U),
  ])
  assert_eq(state.pc, TEST_BASE)
  assert_eq(state.image.instructions.length(), 2)
  assert_eq(state.image.instructions[0].length, 2)
  assert_eq(state.image.instructions[1].length, 2)
  match state.image.instructions[0].inst {
    @decode.C_LI(rd, imm) => {
      assert_eq(rd, 10U)
      assert_eq(imm, 1)
    }
    _ => abort("expected first compressed instruction to decode as c.li")
  }
  match state.image.instructions[1].inst {
    @decode.C_EBREAK => ()
    _ => abort("expected second compressed instruction to decode as c.ebreak")
  }
}

///|
test "simulator executes compressed immediate instructions from raw bytes" {
  let state = load_state_from_compressed_parts("compressed_immediate", [
    encode_u16(0x4505U),
    encode_u16(0x0505U),
    encode_u16(0x9002U),
  ])
  let after_li = step(state)
  assert_eq(after_li.trace.length(), 1)
  assert_eq(after_li.registers.get(10U), 1U)
  match after_li.stop_reason {
    None => ()
    Some(_) => abort("expected compressed li to keep running")
  }

  let after_addi = step(after_li)
  assert_eq(after_addi.trace.length(), 2)
  assert_eq(after_addi.registers.get(10U), 2U)
  match after_addi.stop_reason {
    None => ()
    Some(_) => abort("expected compressed addi to keep running")
  }

  let finished = step(after_addi)
  assert_eq(finished.trace.length(), 3)
  match finished.stop_reason {
    Some(StopReason::Ebreak(addr)) => assert_eq(addr, TEST_BASE + 4U)
    _ => abort("expected compressed immediate ebreak stop")
  }
}

///|
test "simulator executes compressed register transfer instructions from raw bytes" {
  let state = load_state_from_compressed_parts("compressed_register", [
    encode_u32(0x00300613U),
    encode_u16(0x8532U),
    encode_u16(0x9532U),
    encode_u16(0x9002U),
  ])
  let after_setup = step(state)
  assert_eq(after_setup.registers.get(12U), 3U)
  match after_setup.stop_reason {
    None => ()
    Some(_) => abort("expected setup addi to keep running")
  }

  let after_mv = step(after_setup)
  assert_eq(after_mv.registers.get(10U), 3U)
  match after_mv.stop_reason {
    None => ()
    Some(_) => abort("expected compressed mv to keep running")
  }

  let after_add = step(after_mv)
  assert_eq(after_add.registers.get(10U), 6U)
  match after_add.stop_reason {
    None => ()
    Some(_) => abort("expected compressed add to keep running")
  }

  let finished = step(after_add)
  assert_eq(finished.trace.length(), 4)
  assert_eq(finished.registers.get(12U), 3U)
  match finished.stop_reason {
    Some(StopReason::Ebreak(addr)) => assert_eq(addr, TEST_BASE + 8U)
    _ => abort("expected compressed register ebreak stop")
  }
}

///|
test "simulator executes compressed nop before ebreak" {
  let state = load_state_from_compressed_parts("compressed_nop", [
    encode_u16(0x0001U),
    encode_u16(0x9002U),
  ])
  let finished = run_with_limit(state, 4)
  assert_eq(finished.trace.length(), 2)
  match finished.stop_reason {
    Some(StopReason::Ebreak(addr)) => assert_eq(addr, TEST_BASE + 2U)
    _ => abort("expected compressed nop ebreak stop")
  }
}

///|
test "compressed trace json preserves compressed asm text" {
  let state = load_state_from_compressed_parts("compressed_trace_json", [
    encode_u16(0x4505U),
    encode_u16(0x0505U),
    encode_u16(0x9002U),
  ])
  let finished = run_with_limit(state, 8)
  let json = trace_events_to_json(finished.trace)
  assert_true(json.contains("\"asm\":\"c.li a0, 1\""))
  assert_true(json.contains("\"asm\":\"c.addi a0, 1\""))
  assert_true(json.contains("\"asm\":\"c.ebreak\""))
}
