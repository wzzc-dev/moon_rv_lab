///|
fn edge_type_to_string(edge_type : @analysis.EdgeType) -> String {
  match edge_type {
    @analysis.EdgeType::Jump => "jump"
    @analysis.EdgeType::BranchTaken => "branch_taken"
    @analysis.EdgeType::BranchNotTaken => "branch_not_taken"
    @analysis.EdgeType::Call => "call"
    @analysis.EdgeType::Return => "return"
  }
}

///|
fn to_json(data : WorkbenchData) -> String {
  let mut json = "{"
  json = json + "\"meta\":" + to_json_meta(data.meta)
  json = json + ",\"functions\":" + to_json_functions(data.functions)
  json = json + ",\"sections\":" + to_json_sections(data.sections)
  json = json + ",\"symbols\":" + to_json_symbols(data.symbols)
  json = json + ",\"callgraph\":" + to_json_callgraph(data.callgraph)
  json = json +
    ",\"analysis_summary\":" +
    to_json_analysis_summary(data.analysis_summary)
  json = json + ",\"instructions\":" + to_json_instructions(data.instructions)
  json = json + ",\"blocks\":" + to_json_blocks(data.blocks)
  json = json + ",\"edges\":" + to_json_edges(data.edges)
  json = json + ",\"runtime\":" + to_json_runtime(data.runtime)
  json = json + ",\"events\":" + to_json_runtime_events(data.events)
  json = json + "}"
  json
}

///|
fn to_json_overview(data : WorkbenchOverview) -> String {
  let mut json = "{"
  json = json + "\"meta\":" + to_json_meta(data.meta)
  json = json + ",\"functions\":" + to_json_functions(data.functions)
  json = json + ",\"sections\":" + to_json_sections(data.sections)
  json = json + ",\"symbols\":" + to_json_symbols(data.symbols)
  json = json + ",\"callgraph\":" + to_json_callgraph(data.callgraph)
  json = json +
    ",\"analysis_summary\":" +
    to_json_analysis_summary(data.analysis_summary)
  json = json + ",\"runtime\":" + to_json_runtime(data.runtime)
  json = json + ",\"events\":" + to_json_runtime_events(data.events)
  json = json + "}"
  json
}

///|
fn to_json_meta(meta : WorkbenchMeta) -> String {
  let mut json = "{"
  json = json + "\"title\":" + json_string(meta.title)
  json = json + ",\"source_file\":" + json_string(meta.source_file)
  json = json + ",\"input_format\":" + json_string(meta.input_format)
  json = json + ",\"entry_point\":" + json_string(meta.entry_point)
  json = json + ",\"file_class\":" + json_string(meta.file_class)
  json = json + ",\"xlen\":" + meta.xlen.to_string()
  json = json + ",\"architecture\":" + json_string(meta.architecture)
  json = json + ",\"section_count\":" + meta.section_count.to_string()
  json = json + ",\"program_count\":" + meta.program_count.to_string()
  json = json + ",\"function_count\":" + meta.function_count.to_string()
  json = json + ",\"instruction_count\":" + meta.instruction_count.to_string()
  json = json +
    ",\"total_instruction_count\":" +
    meta.total_instruction_count.to_string()
  json = json + ",\"basic_block_count\":" + meta.basic_block_count.to_string()
  json = json + ",\"cfg_edge_count\":" + meta.cfg_edge_count.to_string()
  json = json +
    ",\"runtime_event_count\":" +
    meta.runtime_event_count.to_string()
  json = json + ",\"truncated\":" + bool_to_json(meta.truncated)
  json = json + "}"
  json
}

///|
fn to_json_functions(functions : Array[WorkbenchFunction]) -> String {
  let mut json = "["
  for i = 0; i < functions.length(); i = i + 1 {
    let function = functions[i]
    if i > 0 {
      json = json + ","
    }
    json = json + to_json_function(function)
  }
  json = json + "]"
  json
}

///|
fn to_json_function(function : WorkbenchFunction) -> String {
  let mut json = "{"
  json = json + "\"name\":" + json_string(function.name)
  json = json + ",\"addr\":" + json_string(function.addr)
  json = json + ",\"size\":" + json_string(function.size)
  json = json +
    ",\"instruction_count\":" +
    function.instruction_count.to_string()
  json = json + ",\"block_count\":" + function.block_count.to_string()
  json = json +
    ",\"has_runtime_event\":" +
    bool_to_json(function.has_runtime_event)
  json = json + "}"
  json
}

///|
fn to_json_sections(sections : Array[WorkbenchSection]) -> String {
  let mut json = "["
  for i = 0; i < sections.length(); i = i + 1 {
    let section = sections[i]
    if i > 0 {
      json = json + ","
    }
    json = json + "{"
    json = json + "\"index\":" + section.index.to_string()
    json = json + ",\"name\":" + json_string(section.name)
    json = json + ",\"addr\":" + json_string(section.addr)
    json = json + ",\"size\":" + json_string(section.size)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_symbols(symbols : Array[WorkbenchSymbol]) -> String {
  let mut json = "["
  for i = 0; i < symbols.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let symbol = symbols[i]
    json = json + "{"
    json = json + "\"name\":" + json_string(symbol.name)
    json = json + ",\"addr\":" + json_string(symbol.addr)
    json = json + ",\"size\":" + json_string(symbol.size)
    json = json + ",\"type\":" + json_string(symbol.type_name)
    json = json + ",\"binding\":" + json_string(symbol.binding)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_callgraph(callgraph : WorkbenchCallGraph) -> String {
  let mut json = "{"
  json = json + "\"entry_point\":" + json_string(callgraph.entry_point)
  json = json + ",\"available\":" + bool_to_json(callgraph.available)
  json = json + ",\"reason\":" + json_string(callgraph.reason)
  json = json + ",\"nodes\":["
  for i = 0; i < callgraph.nodes.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let node = callgraph.nodes[i]
    json = json + "{"
    json = json + "\"addr\":" + json_string(node.addr)
    json = json + ",\"name\":" + json_string(node.name)
    json = json + ",\"calls\":" + json_array_strings(node.calls)
    json = json + "}"
  }
  json = json + "]"
  json = json + "}"
  json
}

///|
fn to_json_analysis_summary(summary : WorkbenchAnalysisSummary) -> String {
  let mut json = "{"
  json = json + "\"instruction_categories\":["
  for i = 0; i < summary.instruction_categories.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let item = summary.instruction_categories[i]
    json = json + "{"
    json = json + "\"name\":" + json_string(item.0)
    json = json + ",\"count\":" + item.1.to_string()
    json = json + "}"
  }
  json = json + "]"
  json = json +
    ",\"basic_block_count\":" +
    summary.basic_block_count.to_string()
  json = json + ",\"cfg_edge_count\":" + summary.cfg_edge_count.to_string()
  json = json +
    ",\"call_graph_node_count\":" +
    summary.call_graph_node_count.to_string()
  json = json +
    ",\"runtime_event_count\":" +
    summary.runtime_event_count.to_string()
  json = json + "}"
  json
}

///|
fn to_json_instructions(instructions : Array[WorkbenchInstruction]) -> String {
  let mut json = "["
  for i = 0; i < instructions.length(); i = i + 1 {
    let inst = instructions[i]
    if i > 0 {
      json = json + ","
    }
    json = json + "{"
    json = json + "\"index\":" + inst.index.to_string()
    json = json + ",\"addr\":" + json_string(inst.addr)
    json = json + ",\"asm\":" + json_string(inst.asm_text)
    json = json + ",\"category\":" + json_string(inst.category)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_blocks(blocks : Array[WorkbenchBlock]) -> String {
  let mut json = "["
  for i = 0; i < blocks.length(); i = i + 1 {
    let block = blocks[i]
    if i > 0 {
      json = json + ","
    }
    json = json + "{"
    json = json + "\"start_addr\":" + json_string(block.start_addr)
    json = json + ",\"end_addr\":" + json_string(block.end_addr)
    json = json +
      ",\"instruction_count\":" +
      block.instruction_count.to_string()
    json = json + ",\"is_terminated\":" + bool_to_json(block.is_terminated)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_edges(edges : Array[WorkbenchEdge]) -> String {
  let mut json = "["
  for i = 0; i < edges.length(); i = i + 1 {
    let edge = edges[i]
    if i > 0 {
      json = json + ","
    }
    json = json + "{"
    json = json + "\"from_block\":" + json_string(edge.from_block)
    json = json + ",\"to_block\":" + json_string(edge.to_block)
    json = json + ",\"edge_type\":" + json_string(edge.edge_type)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_runtime(runtime : WorkbenchRuntime) -> String {
  let mut json = "{"
  json = json + "\"initial_pc\":" + json_string(runtime.initial_pc)
  json = json + ",\"stop_reason\":" + json_string(runtime.stop_reason)
  json = json +
    ",\"initial_registers\":" +
    to_json_runtime_registers(runtime.initial_registers)
  json = json + "}"
  json
}

///|
fn to_json_runtime_registers(
  registers : Array[WorkbenchRegisterValue],
) -> String {
  let mut json = "["
  for i = 0; i < registers.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let reg = registers[i]
    json = json + "{"
    json = json + "\"name\":" + json_string(reg.name)
    json = json + ",\"value\":" + json_string(reg.value)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_runtime_register_writes(
  writes : Array[WorkbenchRegisterWrite],
) -> String {
  let mut json = "["
  for i = 0; i < writes.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let write = writes[i]
    json = json + "{"
    json = json + "\"name\":" + json_string(write.name)
    json = json + ",\"before\":" + json_string(write.before)
    json = json + ",\"after\":" + json_string(write.after)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_runtime_memory_writes(
  writes : Array[WorkbenchMemoryEvent],
) -> String {
  let mut json = "["
  for i = 0; i < writes.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let write = writes[i]
    json = json + "{"
    json = json + "\"addr\":" + json_string(write.addr)
    json = json + ",\"before\":" + json_string(write.before)
    json = json + ",\"after\":" + json_string(write.after)
    json = json + ",\"size\":" + write.size.to_string()
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_runtime_events(events : Array[WorkbenchTraceEvent]) -> String {
  let mut json = "["
  for i = 0; i < events.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let event = events[i]
    json = json + "{"
    json = json + "\"step\":" + event.step.to_string()
    json = json + ",\"addr\":" + json_string(event.addr)
    json = json + ",\"next_addr\":" + json_string(event.next_addr)
    json = json + ",\"asm\":" + json_string(event.asm_text)
    json = json + ",\"category\":" + json_string(event.category)
    json = json + ",\"block_start\":" + json_string(event.block_start)
    json = json +
      ",\"register_writes\":" +
      to_json_runtime_register_writes(event.register_writes)
    json = json +
      ",\"memory_writes\":" +
      to_json_runtime_memory_writes(event.memory_writes)
    json = json + ",\"stdout_append\":" + json_string(event.stdout_append)
    json = json + ",\"stderr_append\":" + json_string(event.stderr_append)
    json = json + ",\"syscall\":" + json_string(event.syscall)
    json = json + ",\"stop_reason\":" + json_string(event.stop_reason)
    json = json + "}"
  }
  json = json + "]"
  json
}

///|
fn to_json_function_slice(data : WorkbenchFunctionSlice) -> String {
  let mut json = "{"
  json = json + "\"function\":" + to_json_function(data.function)
  json = json + ",\"instructions\":" + to_json_instructions(data.instructions)
  json = json + ",\"blocks\":" + to_json_blocks(data.blocks)
  json = json + ",\"edges\":" + to_json_edges(data.edges)
  json = json + ",\"pseudo_code\":" + json_string(data.pseudo_code)
  json = json + ",\"dataflow\":" + to_json_dataflow(data.dataflow)
  json = json + ",\"available\":" + bool_to_json(data.available)
  json = json + ",\"reason\":" + json_string(data.reason)
  json = json + "}"
  json
}

///|
fn to_json_dataflow(dataflow : WorkbenchDataflow) -> String {
  let mut json = "{"
  json = json + "\"available\":" + bool_to_json(dataflow.available)
  json = json + ",\"reason\":" + json_string(dataflow.reason)
  json = json + ",\"entries\":["
  for i = 0; i < dataflow.entries.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let entry = dataflow.entries[i]
    json = json + "{"
    json = json + "\"addr\":" + json_string(entry.addr)
    json = json + ",\"def_use\":" + json_string(entry.def_use)
    json = json + ",\"liveness\":" + json_string(entry.liveness)
    json = json + ",\"constant_state\":" + json_string(entry.constant_state)
    json = json + "}"
  }
  json = json + "]"
  json = json + "}"
  json
}

///|
fn json_array_strings(values : Array[String]) -> String {
  let mut json = "["
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    json = json + json_string(values[i])
  }
  json = json + "]"
  json
}

///|
fn to_json_function_slices_map(
  slices : Array[WorkbenchFunctionSlice],
) -> String {
  let mut json = "{"
  for i = 0; i < slices.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    let slice = slices[i]
    json = json + json_string(slice.function.addr)
    json = json + ":"
    json = json + to_json_function_slice(slice)
  }
  json = json + "}"
  json
}

///|
fn api_error_json(err : WorkbenchError) -> String {
  "{\"ok\":false,\"error\":" + json_string(err.to_string()) + "}"
}

///|
fn normalize_max_events(value : Int) -> Int {
  if value <= 0 {
    200
  } else {
    value
  }
}

///|
fn build_stream_event_payloads(
  events : Array[WorkbenchTraceEvent],
  max_events : Int,
) -> Array[String] {
  let payloads : Array[String] = []
  let limit = if events.length() < max_events {
    events.length()
  } else {
    max_events
  }
  for i = 0; i < limit; i = i + 1 {
    let event = events[i]
    let mut json = "{"
    json = json + "\"step\":" + event.step.to_string()
    json = json + ",\"addr\":" + json_string(event.addr)
    json = json + ",\"next_addr\":" + json_string(event.next_addr)
    json = json + ",\"asm\":" + json_string(event.asm_text)
    json = json + ",\"category\":" + json_string(event.category)
    json = json + ",\"block_start\":" + json_string(event.block_start)
    json = json +
      ",\"register_writes\":" +
      to_json_runtime_register_writes(event.register_writes)
    json = json +
      ",\"memory_writes\":" +
      to_json_runtime_memory_writes(event.memory_writes)
    json = json + ",\"stdout_append\":" + json_string(event.stdout_append)
    json = json + ",\"stderr_append\":" + json_string(event.stderr_append)
    json = json + ",\"syscall\":" + json_string(event.syscall)
    json = json + ",\"stop_reason\":" + json_string(event.stop_reason)
    json = json +
      ",\"trace\":" +
      json_string(event.addr + ": " + event.asm_text)
    json = json + "}"
    payloads.push(json)
  }
  payloads
}

///|
fn join_json_values(values : Array[String]) -> String {
  let mut json = "["
  for i = 0; i < values.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    json = json + values[i]
  }
  json = json + "]"
  json
}

///|
fn bool_to_json(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn json_string(value : String) -> String {
  "\"" + escape_json(value) + "\""
}

///|
fn escape_json(value : String) -> String {
  let mut escaped = ""
  for c in value {
    match c {
      '"' => escaped = escaped + "\\\""
      '\\' => escaped = escaped + "\\\\"
      '\n' => escaped = escaped + "\\n"
      '\r' => escaped = escaped + "\\r"
      '\t' => escaped = escaped + "\\t"
      _ => escaped = escaped + c.to_string()
    }
  }
  escaped
}
