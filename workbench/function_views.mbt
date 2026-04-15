///|
/// Workbench overview and function-slice builders.

///|
fn build_slice_data(
  index : StaticProgramIndex,
  function_range : FunctionRange,
) -> BuiltSliceData {
  let instructions = collect_instructions_in_range(
    index.all_instructions,
    function_range.addr,
    function_range.end_addr,
  )
  let blocks = collect_blocks_in_range(
    index.blocks,
    function_range.addr,
    function_range.end_addr,
  )
  let edges = collect_edges_for_blocks(index.edges, blocks)
  if instructions.length() == 0 {
    {
      instructions: [],
      blocks: [],
      edges: [],
      available: false,
      reason: "no instructions indexed for this function",
      instruction_count: 0,
      block_count: 0,
    }
  } else {
    {
      instructions,
      blocks,
      edges,
      available: true,
      reason: "",
      instruction_count: instructions.length(),
      block_count: blocks.length(),
    }
  }
}

///|
fn has_runtime_event_for_range(
  function_range : FunctionRange,
  events : Array[WorkbenchTraceEvent],
) -> Bool {
  for event in events {
    match parse_hex_uint(event.addr) {
      Some(addr) =>
        if addr >= function_range.addr && addr < function_range.end_addr {
          return true
        }
      None => ()
    }
  }
  false
}

///|
fn make_workbench_function(
  function_range : FunctionRange,
  slice : BuiltSliceData,
  has_runtime_event : Bool,
) -> WorkbenchFunction {
  {
    name: function_range.name,
    addr: format_hex(function_range.addr),
    size: format_hex(function_range.size),
    instruction_count: slice.instruction_count,
    block_count: slice.block_count,
    has_runtime_event,
  }
}

///|
fn build_symbol_map_for_index(index : StaticProgramIndex) -> Map[UInt, String] {
  let result : Map[UInt, String] = {}
  for function_range in index.function_ranges {
    result[function_range.addr] = function_range.name
  }
  result
}

///|
fn build_workbench_symbols(
  index : StaticProgramIndex,
) -> Array[WorkbenchSymbol] {
  if index.input_format == "raw" {
    return []
  }
  let result : Array[WorkbenchSymbol] = []
  for function_range in index.function_ranges {
    result.push({
      name: function_range.name,
      addr: format_hex(function_range.addr),
      size: format_hex(function_range.size),
      type_name: "func",
      binding: "derived",
    })
  }
  result
}

///|
fn build_workbench_callgraph(index : StaticProgramIndex) -> WorkbenchCallGraph {
  if index.input_format == "raw" {
    return {
      entry_point: format_hex(index.entry_point),
      nodes: [],
      available: false,
      reason: "RAW input lacks reliable function boundaries, so call graph generation is unavailable.",
    }
  }
  if index.all_instructions.length() == 0 {
    return {
      entry_point: format_hex(index.entry_point),
      nodes: [],
      available: false,
      reason: "no instructions available",
    }
  }
  let cfg = @analysis.build_cfg(index.all_instructions, index.entry_point)
  let callgraph = @analysis.build_call_graph(index.all_instructions, cfg)
  let nodes : Array[WorkbenchCallGraphNode] = []
  for node in callgraph.nodes {
    let calls : Array[String] = []
    for call in node.calls {
      calls.push(format_hex(call))
    }
    nodes.push({ addr: format_hex(node.address), name: node.name, calls })
  }
  {
    entry_point: format_hex(callgraph.entry_point),
    nodes,
    available: true,
    reason: "",
  }
}

///|
fn count_instruction_categories_for_summary(
  instructions : FixedArray[@analysis.DecodedInst],
) -> Array[(String, Int)] {
  let counts : Map[String, Int] = {}
  for inst in instructions {
    let key = category_to_string(inst.inst.category())
    counts[key] = counts.get_or_default(key, 0) + 1
  }
  counts.to_array()
}

///|
fn build_workbench_analysis_summary(
  index : StaticProgramIndex,
  events : Array[WorkbenchTraceEvent],
  callgraph : WorkbenchCallGraph,
) -> WorkbenchAnalysisSummary {
  {
    instruction_categories: count_instruction_categories_for_summary(
      index.all_instructions,
    ),
    basic_block_count: index.blocks.length(),
    cfg_edge_count: index.edges.length(),
    call_graph_node_count: callgraph.nodes.length(),
    runtime_event_count: events.length(),
  }
}

///|
fn build_function_pseudo_code(
  index : StaticProgramIndex,
  function_range : FunctionRange,
  instructions : FixedArray[@analysis.DecodedInst],
  available : Bool,
) -> String {
  if !available || instructions.length() == 0 {
    return ""
  }
  let cfg = @analysis.build_cfg(instructions, function_range.addr)
  let symbol_map = build_symbol_map_for_index(index)
  @analysis.decompile(cfg, instructions, symbol_map, {})
}

///|
fn find_liveness_for_block(
  states : FixedArray[@analysis.BlockLiveness],
  block_addr : UInt,
) -> @analysis.BlockLiveness? {
  for state in states {
    if state.block_addr == block_addr {
      return Some(state)
    }
  }
  None
}

///|
fn build_workbench_dataflow(
  index : StaticProgramIndex,
  function_range : FunctionRange,
  instructions : FixedArray[@analysis.DecodedInst],
  available : Bool,
) -> WorkbenchDataflow {
  if index.input_format == "raw" {
    return {
      available: false,
      reason: "RAW input lacks reliable function boundaries, so function-level dataflow is unavailable.",
      entries: [],
    }
  }
  if !available || instructions.length() == 0 {
    return {
      available: false,
      reason: "function slice unavailable",
      entries: [],
    }
  }
  let cfg = @analysis.build_cfg(instructions, function_range.addr)
  let def_use = @analysis.compute_def_use_chains(instructions)
  let liveness = @analysis.compute_liveness(cfg, instructions)
  let const_states = @analysis.compute_constant_propagation(cfg, instructions)

  let mut def_use_text = ""
  for chain in def_use {
    if chain.defs.length() > 0 || chain.uses.length() > 0 {
      def_use_text = def_use_text +
        @decode.reg_name(chain.reg) +
        " defs=" +
        chain.defs.length().to_string() +
        " uses=" +
        chain.uses.length().to_string() +
        "; "
    }
  }

  let entries : Array[WorkbenchDataflowEntry] = []
  for block in cfg.blocks {
    let live = match find_liveness_for_block(liveness, block.start_addr) {
      Some(state) => @analysis.print_live_set(state.live_in)
      None => ""
    }
    let mut const_text = ""
    for state in const_states {
      if state.block_addr == block.start_addr {
        const_text = @analysis.format_const_state(state.state_in)
      }
    }
    entries.push({
      addr: format_hex(block.start_addr),
      def_use: def_use_text,
      liveness: live,
      constant_state: const_text,
    })
  }
  { available: true, reason: "", entries }
}

///|
fn build_workbench_functions(
  index : StaticProgramIndex,
  events : Array[WorkbenchTraceEvent],
) -> Array[WorkbenchFunction] {
  let result : Array[WorkbenchFunction] = []
  for function_range in index.function_ranges {
    let slice = build_slice_data(index, function_range)
    result.push(
      make_workbench_function(
        function_range,
        slice,
        has_runtime_event_for_range(function_range, events),
      ),
    )
  }
  result
}

///|
fn build_workbench_meta(
  index : StaticProgramIndex,
  functions : Array[WorkbenchFunction],
  runtime_event_count : Int,
  max_instructions : Int,
) -> WorkbenchMeta {
  let limit = normalize_max_instructions(max_instructions)
  let total_instruction_count = index.all_instructions.length()
  let shown_instruction_count = if total_instruction_count < limit {
    total_instruction_count
  } else {
    limit
  }
  {
    title: index.title,
    source_file: index.source_file,
    input_format: index.input_format,
    entry_point: format_hex(index.entry_point),
    file_class: index.file_class,
    xlen: index.xlen,
    architecture: index.architecture,
    section_count: index.section_count,
    program_count: index.program_count,
    function_count: functions.length(),
    instruction_count: shown_instruction_count,
    total_instruction_count,
    basic_block_count: index.blocks.length(),
    cfg_edge_count: index.edges.length(),
    runtime_event_count,
    truncated: total_instruction_count > limit,
  }
}

///|
fn build_workbench_overview(
  index : StaticProgramIndex,
  functions : Array[WorkbenchFunction],
  runtime : WorkbenchRuntime,
  events : Array[WorkbenchTraceEvent],
  max_instructions : Int,
) -> WorkbenchOverview {
  let callgraph = build_workbench_callgraph(index)
  let analysis_summary = build_workbench_analysis_summary(
    index, events, callgraph,
  )
  {
    meta: build_workbench_meta(
      index,
      functions,
      events.length(),
      max_instructions,
    ),
    functions,
    sections: index.sections,
    symbols: build_workbench_symbols(index),
    callgraph,
    analysis_summary,
    runtime,
    events,
  }
}

///|
fn find_function_range_by_exact_addr(
  index : StaticProgramIndex,
  addr : UInt,
) -> FunctionRange? {
  for function_range in index.function_ranges {
    if function_range.addr == addr {
      return Some(function_range)
    }
  }
  None
}

///|
fn find_function_range_by_addr(
  index : StaticProgramIndex,
  addr : UInt,
) -> FunctionRange? {
  for function_range in index.function_ranges {
    if addr >= function_range.addr && addr < function_range.end_addr {
      return Some(function_range)
    }
  }
  None
}

///|
fn find_function_range_by_name(
  index : StaticProgramIndex,
  name : String,
) -> FunctionRange? {
  for function_range in index.function_ranges {
    if function_range.name == name {
      return Some(function_range)
    }
  }
  None
}

///|
fn build_function_slice_from_range(
  index : StaticProgramIndex,
  function_range : FunctionRange,
) -> WorkbenchFunctionSlice {
  let slice = build_slice_data(index, function_range)
  let function = make_workbench_function(function_range, slice, false)
  let instructions = collect_instruction_range_fixed_array(
    index.all_instructions,
    function_range.addr,
    function_range.end_addr,
  )
  {
    function,
    instructions: slice.instructions,
    blocks: slice.blocks,
    edges: slice.edges,
    pseudo_code: build_function_pseudo_code(
      index,
      function_range,
      instructions,
      slice.available,
    ),
    dataflow: build_workbench_dataflow(
      index,
      function_range,
      instructions,
      slice.available,
    ),
    available: slice.available,
    reason: slice.reason,
  }
}

///|
fn build_all_instructions_slice(
  index : StaticProgramIndex,
) -> WorkbenchFunctionSlice {
  {
    function: {
      name: "All instructions",
      addr: "__all__",
      size: format_hex(0U),
      instruction_count: index.all_instructions.length(),
      block_count: index.blocks.length(),
      has_runtime_event: false,
    },
    instructions: collect_instructions(
      index.all_instructions,
      index.all_instructions.length(),
    ),
    blocks: index.blocks,
    edges: index.edges,
    pseudo_code: "",
    dataflow: {
      available: false,
      reason: "dataflow view is available for a single function only",
      entries: [],
    },
    available: true,
    reason: "",
  }
}

///|
fn build_function_slice_response(
  index : StaticProgramIndex,
  function : String,
  allow_all : Bool,
) -> WorkbenchFunctionSlice? {
  if allow_all &&
    function == "__all__" &&
    index.all_instructions.length() <= DEFAULT_MAX_INSTRUCTIONS {
    return Some(build_all_instructions_slice(index))
  }

  match parse_hex_uint(function) {
    Some(addr) =>
      match find_function_range_by_exact_addr(index, addr) {
        Some(range) => Some(build_function_slice_from_range(index, range))
        None =>
          match find_function_range_by_addr(index, addr) {
            Some(range) => Some(build_function_slice_from_range(index, range))
            None => None
          }
      }
    None =>
      match find_function_range_by_name(index, function) {
        Some(range) => Some(build_function_slice_from_range(index, range))
        None => None
      }
  }
}

///|
fn build_embedded_function_slices(
  index : StaticProgramIndex,
  functions : Array[WorkbenchFunction],
  _max_instructions : Int,
) -> Array[WorkbenchFunctionSlice] {
  let result : Array[WorkbenchFunctionSlice] = []
  if index.all_instructions.length() <= DEFAULT_MAX_INSTRUCTIONS {
    result.push(build_all_instructions_slice(index))
  }
  for function in functions {
    match build_function_slice_response(index, function.addr, false) {
      Some(slice) => result.push(slice)
      None => ()
    }
  }
  result
}
