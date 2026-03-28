///|
const REGRESSION_BASE : UInt = 0x1000U

///|
fn make_inst(
  addr : UInt,
  inst : @decode.Instruction,
  length : Int,
) -> DecodedInst {
  { addr, inst, code: 0U, length }
}

///|
fn make_symbol_map(entries : Array[(UInt, String)]) -> Map[UInt, String] {
  let symbols : Map[UInt, String] = {}
  for entry in entries {
    symbols[entry.0] = entry.1
  }
  symbols
}

///|
fn straight_line_fixture() -> FixedArray[DecodedInst] {
  FixedArray::from_array([
    make_inst(REGRESSION_BASE, @decode.C_LI(10U, 5), 2),
    make_inst(REGRESSION_BASE + 2U, @decode.ADDI(11U, 10U, 3), 4),
    make_inst(REGRESSION_BASE + 6U, @decode.ADDI(12U, 11U, 5), 4),
    make_inst(REGRESSION_BASE + 10U, @decode.JALR(0U, 1U, 0), 4),
  ])
}

///|
fn branch_fixture() -> FixedArray[DecodedInst] {
  FixedArray::from_array([
    make_inst(REGRESSION_BASE, @decode.C_LI(5U, 1), 2),
    make_inst(REGRESSION_BASE + 2U, @decode.BEQ(5U, 5U, 10), 4),
    make_inst(REGRESSION_BASE + 6U, @decode.C_LI(10U, 99), 2),
    make_inst(REGRESSION_BASE + 8U, @decode.JALR(0U, 1U, 0), 4),
    make_inst(REGRESSION_BASE + 12U, @decode.C_LI(10U, 7), 2),
    make_inst(REGRESSION_BASE + 14U, @decode.JALR(0U, 1U, 0), 4),
  ])
}

///|
fn loop_fixture() -> FixedArray[DecodedInst] {
  FixedArray::from_array([
    make_inst(REGRESSION_BASE, @decode.C_LI(10U, 0), 2),
    make_inst(REGRESSION_BASE + 2U, @decode.C_LI(11U, 3), 2),
    make_inst(REGRESSION_BASE + 4U, @decode.BGE(10U, 11U, 16), 4),
    make_inst(REGRESSION_BASE + 8U, @decode.ADDI(10U, 10U, 1), 4),
    make_inst(REGRESSION_BASE + 12U, @decode.JAL(0U, -8), 4),
    make_inst(REGRESSION_BASE + 20U, @decode.JALR(0U, 1U, 0), 4),
  ])
}

///|
fn call_chain_fixture() -> FixedArray[DecodedInst] {
  FixedArray::from_array([
    make_inst(REGRESSION_BASE, @decode.C_LI(10U, 1), 2),
    make_inst(REGRESSION_BASE + 2U, @decode.JAL(1U, 8), 4),
    make_inst(REGRESSION_BASE + 6U, @decode.JALR(0U, 1U, 0), 4),
    make_inst(REGRESSION_BASE + 10U, @decode.C_LI(10U, 7), 2),
    make_inst(REGRESSION_BASE + 12U, @decode.JALR(0U, 1U, 0), 4),
  ])
}

///|
fn find_block_const_state(
  states : FixedArray[BlockConstState],
  addr : UInt,
) -> BlockConstState {
  for state in states {
    if state.block_addr == addr {
      return state
    }
  }
  abort("block const state not found")
}

///|
fn has_cfg_edge(
  cfg : CFG,
  from_block : UInt,
  to_block : UInt,
  expected_type : EdgeType,
) -> Bool {
  for edge in cfg.edges {
    if edge.from_block == from_block && edge.to_block == to_block {
      match (edge.edge_type, expected_type) {
        (Jump, Jump)
        | (BranchTaken, BranchTaken)
        | (BranchNotTaken, BranchNotTaken)
        | (Call, Call)
        | (Return, Return) => return true
        _ => ()
      }
    }
  }
  false
}

///|
test "dataflow constant propagation tracks straight-line arithmetic fixture" {
  let instructions = straight_line_fixture()
  let cfg = build_cfg(instructions, REGRESSION_BASE)
  let states = compute_constant_propagation(cfg, instructions)

  assert_eq(
    get_const_at_point(states, cfg, instructions, REGRESSION_BASE + 2U, 10U),
    ConstValue::Constant(5),
  )
  assert_eq(
    get_const_at_point(states, cfg, instructions, REGRESSION_BASE + 6U, 11U),
    ConstValue::Constant(8),
  )
}

///|
test "dataflow conditional constant propagation prunes dead branch fixture" {
  let instructions = branch_fixture()
  let cfg = build_cfg(instructions, REGRESSION_BASE)
  let info = compute_conditional_constant_propagation(cfg, instructions)
  let live_state = find_block_const_state(
    info.block_consts,
    REGRESSION_BASE + 12U,
  )

  assert_eq(info.reachable.get(REGRESSION_BASE), Some(true))
  assert_eq(info.reachable.get(REGRESSION_BASE + 6U), Some(false))
  assert_eq(info.reachable.get(REGRESSION_BASE + 12U), Some(true))
  assert_eq(live_state.state_in.get_int(5U), ConstValue::Constant(1))
}

///|
test "loop fixture keeps cfg back edge and exit edge stable" {
  let instructions = loop_fixture()
  let cfg = build_cfg(instructions, REGRESSION_BASE)

  assert_eq(cfg.blocks.length(), 4)
  assert_true(
    has_cfg_edge(
      cfg,
      REGRESSION_BASE + 4U,
      REGRESSION_BASE + 8U,
      BranchNotTaken,
    ),
  )
  assert_true(
    has_cfg_edge(cfg, REGRESSION_BASE + 4U, REGRESSION_BASE + 20U, BranchTaken),
  )
  assert_true(
    has_cfg_edge(cfg, REGRESSION_BASE + 8U, REGRESSION_BASE + 4U, Jump),
  )
}

///|
test "decompile call chain fixture keeps helper call and returns" {
  let instructions = call_chain_fixture()
  let cfg = build_cfg(instructions, REGRESSION_BASE)
  let pseudo = decompile(
    cfg,
    instructions,
    make_symbol_map([
      (REGRESSION_BASE, "entry"),
      (REGRESSION_BASE + 10U, "helper"),
    ]),
    {},
  )

  inspect(
    pseudo,
    content=(
      #|// Block 0x1000 - 0x1002
      #|  a0 = 1;
      #|  helper(1);
      #|
      #|// Block 0x1006 - 0x1006
      #|  return 1;
      #|
      #|// Block 0x100a - 0x100a
      #|  a0 = 7;
      #|
      #|// Block 0x100c - 0x100c
      #|  return 7;
      #|
      #|
    ),
  )
}
