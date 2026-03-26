///|
/// Web workbench HTML generator for rvkit

///|
const DEFAULT_MAX_INSTRUCTIONS : Int = 1200

///|
pub struct WorkbenchOptions {
  title : String
  max_instructions : Int
} derive(Show)

///|
pub fn default_options() -> WorkbenchOptions {
  { title: "", max_instructions: DEFAULT_MAX_INSTRUCTIONS }
}

///|
/// Create options for workbench generation.
pub fn create_options(
  title : String,
  max_instructions : Int,
) -> WorkbenchOptions {
  { title, max_instructions }
}

///|
pub enum WorkbenchError {
  FileNotFound(String)
  InvalidElf(String)
  ParseElfFailed(String)
  NotRiscV(String)
  NoCodeSection(String)
  WriteFailed(String)
} derive(Show)

///|
struct WorkbenchMeta {
  title : String
  source_file : String
  entry_point : String
  file_class : String
  architecture : String
  section_count : Int
  program_count : Int
  function_count : Int
  instruction_count : Int
  total_instruction_count : Int
  basic_block_count : Int
  cfg_edge_count : Int
  runtime_event_count : Int
  truncated : Bool
} derive(Show)

///|
struct WorkbenchFunction {
  name : String
  addr : String
  size : String
} derive(Show)

///|
struct WorkbenchSection {
  index : Int
  name : String
  addr : String
  size : String
} derive(Show)

///|
struct WorkbenchInstruction {
  index : Int
  addr : String
  asm_text : String
  category : String
} derive(Show)

///|
struct WorkbenchBlock {
  start_addr : String
  end_addr : String
  instruction_count : Int
  is_terminated : Bool
} derive(Show)

///|
struct WorkbenchEdge {
  from_block : String
  to_block : String
  edge_type : String
} derive(Show)

///|
struct WorkbenchRegisterValue {
  name : String
  value : String
} derive(Show)

///|
struct WorkbenchRegisterWrite {
  name : String
  before : String
  after : String
} derive(Show)

///|
struct WorkbenchMemoryEvent {
  addr : String
  before : String
  after : String
  size : Int
} derive(Show)

///|
struct WorkbenchTraceEvent {
  step : Int
  addr : String
  next_addr : String
  asm_text : String
  category : String
  block_start : String
  register_writes : Array[WorkbenchRegisterWrite]
  memory_writes : Array[WorkbenchMemoryEvent]
  stdout_append : String
  stderr_append : String
  syscall : String
  stop_reason : String
} derive(Show)

///|
struct WorkbenchRuntime {
  initial_pc : String
  stop_reason : String
  initial_registers : Array[WorkbenchRegisterValue]
} derive(Show)

///|
struct WorkbenchData {
  meta : WorkbenchMeta
  functions : Array[WorkbenchFunction]
  sections : Array[WorkbenchSection]
  instructions : Array[WorkbenchInstruction]
  blocks : Array[WorkbenchBlock]
  edges : Array[WorkbenchEdge]
  runtime : WorkbenchRuntime
  events : Array[WorkbenchTraceEvent]
} derive(Show)

///|
priv enum LoadWorkbenchResult {
  Ok(WorkbenchData)
  Err(WorkbenchError)
}

///|
/// Generate a standalone Web workbench page from an ELF input.
/// Returns `Some(error)` on failure; `None` means success.
pub fn generate_from_file(
  input_file : String,
  output_file : String,
  options : WorkbenchOptions,
) -> WorkbenchError? {
  match load_workbench_data(input_file, options) {
    Ok(data) => {
      let json = to_json(data)
      let html = build_html_page(data.meta.title, json)
      if write_output_file(output_file, html) {
        None
      } else {
        Some(WorkbenchError::WriteFailed(output_file))
      }
    }
    Err(err) => Some(err)
  }
}

///|
/// Build a JSON payload for `/api/snapshot`.
pub fn snapshot_api_json_from_file(
  input_file : String,
  max_instructions : Int,
) -> String {
  let options = create_options("", max_instructions)
  match load_workbench_data(input_file, options) {
    Ok(data) => "{\"ok\":true,\"data\":" + to_json(data) + "}"
    Err(err) => api_error_json(err)
  }
}

///|
/// Build a JSON payload for `/api/stream`.
pub fn stream_api_json_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int,
) -> String {
  match
    stream_event_payloads_from_file(input_file, max_instructions, max_events) {
    StreamEventsOk(events) =>
      "{\"ok\":true,\"events\":" +
      join_json_values(events) +
      ",\"total_events\":" +
      events.length().to_string() +
      "}"
    StreamEventsErr(err) => "{\"ok\":false,\"error\":" + json_string(err) + "}"
  }
}

///|
pub enum StreamEventsLoadResult {
  StreamEventsOk(Array[String])
  StreamEventsErr(String)
} derive(Show)

///|
/// Build stream event payloads for SSE APIs.
pub fn stream_event_payloads_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int,
) -> StreamEventsLoadResult {
  let options = create_options("", max_instructions)
  let event_limit = normalize_max_events(max_events)
  match load_workbench_data(input_file, options) {
    Ok(data) =>
      StreamEventsOk(build_stream_event_payloads(data.events, event_limit))
    Err(err) => StreamEventsErr(err.to_string())
  }
}

///|
fn load_workbench_data(
  input_file : String,
  options : WorkbenchOptions,
) -> LoadWorkbenchResult {
  match read_file_bytes(input_file) {
    None => Err(WorkbenchError::FileNotFound(input_file))
    Some(bytes) => {
      if !@format.is_elf(bytes) {
        return Err(WorkbenchError::InvalidElf(input_file))
      }
      match @format.parse_elf(bytes) {
        None => Err(WorkbenchError::ParseElfFailed(input_file))
        Some(elf) => {
          if !elf.is_riscv() {
            return Err(WorkbenchError::NotRiscV(input_file))
          }
          let code_sections = elf.get_code_sections()
          if code_sections.length() == 0 {
            return Err(WorkbenchError::NoCodeSection(input_file))
          }

          let (code_addr, code_bytes) = code_sections[0]
          let all_instructions = @analysis.decode_instructions(
            code_bytes, code_addr,
          )
          let cfg = @analysis.build_cfg(all_instructions, code_addr)
          let max_instructions = normalize_max_instructions(
            options.max_instructions,
          )
          let shown_count = if all_instructions.length() < max_instructions {
            all_instructions.length()
          } else {
            max_instructions
          }

          let page_title = if options.title == "" {
            "MoonRV Lab Workbench"
          } else {
            options.title
          }
          let functions = collect_functions(elf)
          let sections = collect_sections(elf)
          let instructions = collect_instructions(all_instructions, shown_count)
          let blocks = collect_blocks(cfg)
          let edges = collect_edges(cfg)
          let (runtime, events) = load_runtime_trace(
            input_file, shown_count, blocks,
          )

          let meta = {
            title: page_title,
            source_file: input_file,
            entry_point: format_hex(elf.entry_point()),
            file_class: if elf.is_64bit {
              "ELF64"
            } else {
              "ELF32"
            },
            architecture: if elf.is_riscv() {
              "RISC-V"
            } else {
              "Unknown"
            },
            section_count: elf.section_count(),
            program_count: elf.program_count(),
            function_count: functions.length(),
            instruction_count: shown_count,
            total_instruction_count: all_instructions.length(),
            basic_block_count: blocks.length(),
            cfg_edge_count: edges.length(),
            runtime_event_count: events.length(),
            truncated: shown_count < all_instructions.length(),
          }

          Ok({
            meta,
            functions,
            sections,
            instructions,
            blocks,
            edges,
            runtime,
            events,
          })
        }
      }
    }
  }
}

///|
fn collect_functions(elf : @format.ElfFile) -> Array[WorkbenchFunction] {
  let result : Array[WorkbenchFunction] = []
  let symbols = elf.get_function_symbols()
  for sym in symbols {
    if sym.name != "" {
      result.push({
        name: sym.name,
        addr: format_hex(sym.value),
        size: format_hex(sym.size),
      })
    }
  }
  result
}

///|
fn collect_sections(elf : @format.ElfFile) -> Array[WorkbenchSection] {
  let result : Array[WorkbenchSection] = []
  for i = 0; i < elf.section_count(); i = i + 1 {
    let section_name = elf.get_section_name(i)
    match elf.get_section(i) {
      Some((addr, _offset, size)) =>
        result.push({
          index: i,
          name: section_name,
          addr: format_hex(addr),
          size: format_hex(size),
        })
      None => ()
    }
  }
  result
}

///|
fn collect_instructions(
  all_instructions : FixedArray[@analysis.DecodedInst],
  count : Int,
) -> Array[WorkbenchInstruction] {
  let result : Array[WorkbenchInstruction] = []
  for i = 0; i < count; i = i + 1 {
    let inst_info = all_instructions[i]
    result.push({
      index: i,
      addr: format_hex(inst_info.addr),
      asm_text: @disasm.disassemble(inst_info.inst),
      category: category_to_string(inst_info.inst.category()),
    })
  }
  result
}

///|
fn collect_blocks(cfg : @analysis.CFG) -> Array[WorkbenchBlock] {
  let result : Array[WorkbenchBlock] = []
  for block in cfg.blocks {
    result.push({
      start_addr: format_hex(block.start_addr),
      end_addr: format_hex(block.end_addr),
      instruction_count: block.instruction_count,
      is_terminated: block.is_terminated,
    })
  }
  result
}

///|
fn collect_edges(cfg : @analysis.CFG) -> Array[WorkbenchEdge] {
  let result : Array[WorkbenchEdge] = []
  for edge in cfg.edges {
    result.push({
      from_block: format_hex(edge.from_block),
      to_block: format_hex(edge.to_block),
      edge_type: edge_type_to_string(edge.edge_type),
    })
  }
  result
}

///|
fn load_runtime_trace(
  input_file : String,
  step_limit : Int,
  blocks : Array[WorkbenchBlock],
) -> (WorkbenchRuntime, Array[WorkbenchTraceEvent]) {
  match @simulator.load(input_file) {
    @simulator.Loaded(initial_state) => {
      let initial_snapshot = @simulator.snapshot(initial_state)
      let finished = @simulator.run_with_limit(initial_state, step_limit)
      (
        {
          initial_pc: format_hex(initial_snapshot.pc),
          stop_reason: @simulator.stop_reason_to_string(finished.stop_reason),
          initial_registers: collect_initial_registers(initial_snapshot),
        },
        collect_runtime_events(finished.trace, blocks),
      )
    }
    @simulator.LoadFailed(_) =>
      (
        { initial_pc: "0x0", stop_reason: "load failed", initial_registers: [] },
        [],
      )
  }
}

///|
fn collect_initial_registers(
  snapshot : @simulator.ExecSnapshot,
) -> Array[WorkbenchRegisterValue] {
  let result : Array[WorkbenchRegisterValue] = []
  for i = 0; i < snapshot.registers.length(); i = i + 1 {
    result.push({
      name: @decode.reg_name(i.reinterpret_as_uint()),
      value: format_hex(snapshot.registers[i]),
    })
  }
  result
}

///|
fn collect_runtime_events(
  trace : Array[@simulator.TraceEvent],
  blocks : Array[WorkbenchBlock],
) -> Array[WorkbenchTraceEvent] {
  let result : Array[WorkbenchTraceEvent] = []
  for event in trace {
    let register_writes : Array[WorkbenchRegisterWrite] = []
    for delta in event.register_writes {
      register_writes.push({
        name: delta.name,
        before: format_hex(delta.before),
        after: format_hex(delta.after),
      })
    }

    let memory_writes : Array[WorkbenchMemoryEvent] = []
    for write in event.memory_writes {
      memory_writes.push({
        addr: format_hex(write.addr),
        before: format_hex(write.before.to_uint()),
        after: format_hex(write.after.to_uint()),
        size: write.size,
      })
    }

    let syscall = match event.syscall {
      Some(record) => format_syscall(record)
      None => ""
    }
    let stop_reason = @simulator.stop_reason_to_string(event.stop_reason)
    result.push({
      step: event.step,
      addr: format_hex(event.inst.addr),
      next_addr: format_hex(event.pc_after),
      asm_text: @disasm.disassemble(event.inst.inst),
      category: category_to_string(event.inst.inst.category()),
      block_start: find_block_start_for_addr(
        blocks,
        format_hex(event.inst.addr),
      ),
      register_writes,
      memory_writes,
      stdout_append: event.stdout_append,
      stderr_append: event.stderr_append,
      syscall,
      stop_reason,
    })
  }
  result
}

///|
fn format_syscall(record : @simulator.SyscallRecord) -> String {
  let mut args = ""
  for i = 0; i < record.args.length(); i = i + 1 {
    if i > 0 {
      args = args + ", "
    }
    args = args + format_hex(record.args[i])
  }
  record.name + "(" + args + ") -> " + record.result_signed.to_string()
}

///|
fn normalize_max_instructions(value : Int) -> Int {
  if value <= 0 {
    DEFAULT_MAX_INSTRUCTIONS
  } else {
    value
  }
}

///|
fn category_to_string(cat : @decode.InstructionCategory) -> String {
  match cat {
    @decode.InstructionCategory::Arithmetic => "Arithmetic"
    @decode.InstructionCategory::Logical => "Logical"
    @decode.InstructionCategory::Compare => "Compare"
    @decode.InstructionCategory::Branch => "Branch"
    @decode.InstructionCategory::Jump => "Jump"
    @decode.InstructionCategory::Load => "Load"
    @decode.InstructionCategory::Store => "Store"
    @decode.InstructionCategory::System => "System"
    @decode.InstructionCategory::Float => "Float"
    @decode.InstructionCategory::Vector => "Vector"
    @decode.InstructionCategory::Unknown => "Unknown"
  }
}

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
  json = json + ",\"instructions\":" + to_json_instructions(data.instructions)
  json = json + ",\"blocks\":" + to_json_blocks(data.blocks)
  json = json + ",\"edges\":" + to_json_edges(data.edges)
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
  json = json + ",\"entry_point\":" + json_string(meta.entry_point)
  json = json + ",\"file_class\":" + json_string(meta.file_class)
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
    json = json + "{"
    json = json + "\"name\":" + json_string(function.name)
    json = json + ",\"addr\":" + json_string(function.addr)
    json = json + ",\"size\":" + json_string(function.size)
    json = json + "}"
  }
  json = json + "]"
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
fn find_block_start_for_addr(
  blocks : Array[WorkbenchBlock],
  addr : String,
) -> String {
  match parse_hex_uint(addr) {
    Some(addr_value) => {
      let mut matched = ""
      for block in blocks {
        match parse_hex_uint(block.start_addr) {
          Some(start) =>
            match parse_hex_uint(block.end_addr) {
              Some(end) =>
                if matched == "" && addr_value >= start && addr_value <= end {
                  matched = block.start_addr
                }
              None => ()
            }
          None => ()
        }
      }
      matched
    }
    None => ""
  }
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

///|
fn escape_html(value : String) -> String {
  let mut escaped = ""
  for c in value {
    match c {
      '&' => escaped = escaped + "&amp;"
      '<' => escaped = escaped + "&lt;"
      '>' => escaped = escaped + "&gt;"
      '"' => escaped = escaped + "&quot;"
      '\'' => escaped = escaped + "&#39;"
      _ => escaped = escaped + c.to_string()
    }
  }
  escaped
}

///|
fn build_html_page(title : String, data_json : String) -> String {
  let safe_title = escape_html(title)
  let mut html = ""
  html = html + "<!doctype html>\n"
  html = html + "<html lang=\"zh-CN\">\n"
  html = html + "<head>\n"
  html = html + "  <meta charset=\"utf-8\" />\n"
  html = html +
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n"
  html = html + "  <title>\{safe_title}</title>\n"
  html = html + "  <style>\n"
  html = html + "    :root {\n"
  html = html + "      --bg: #eef1f5;\n"
  html = html + "      --panel: #ffffff;\n"
  html = html + "      --panel-muted: #f7f8fa;\n"
  html = html + "      --toolbar: #f4f6f8;\n"
  html = html + "      --ink: #1c1f24;\n"
  html = html + "      --muted: #677184;\n"
  html = html + "      --line: #d7dbe2;\n"
  html = html + "      --line-strong: #c4cad4;\n"
  html = html + "      --accent: #1e6bb8;\n"
  html = html + "      --accent-soft: #e8f1fb;\n"
  html = html + "      --pc: #fff8cc;\n"
  html = html + "      --selected: #eef4ff;\n"
  html = html + "      --success-soft: #edf7ef;\n"
  html = html + "      --warning-bg: #fff3df;\n"
  html = html + "      --warning-ink: #8a4f00;\n"
  html = html + "      --splitter-size: 6px;\n"
  html = html + "      --nav-width: 240px;\n"
  html = html + "      --inspector-width: 320px;\n"
  html = html + "      --bottom-height: 260px;\n"
  html = html + "      --nav-split-size: var(--splitter-size);\n"
  html = html + "      --inspector-split-size: var(--splitter-size);\n"
  html = html + "      --bottom-split-size: var(--splitter-size);\n"
  html = html + "    }\n"
  html = html + "    * { box-sizing: border-box; }\n"
  html = html + "    html, body { height: 100%; }\n"
  html = html + "    body {\n"
  html = html + "      margin: 0;\n"
  html = html +
    "      font-family: \"SFMono-Regular\", \"Cascadia Mono\", \"JetBrains Mono\", \"Iosevka\", monospace;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "      line-height: 1.45;\n"
  html = html + "      background: var(--bg);\n"
  html = html + "      color: var(--ink);\n"
  html = html + "    }\n"
  html = html + "    button,\n"
  html = html + "    select,\n"
  html = html + "    input {\n"
  html = html + "      font: inherit;\n"
  html = html + "      color: inherit;\n"
  html = html + "    }\n"
  html = html + "    button {\n"
  html = html + "      cursor: pointer;\n"
  html = html + "      border: 1px solid var(--line-strong);\n"
  html = html + "      background: #fff;\n"
  html = html + "      border-radius: 2px;\n"
  html = html + "      padding: 4px 8px;\n"
  html = html + "      min-height: 26px;\n"
  html = html + "    }\n"
  html = html + "    button:hover { background: #f9fafb; }\n"
  html = html + "    button:disabled {\n"
  html = html + "      cursor: default;\n"
  html = html + "      opacity: 0.55;\n"
  html = html + "      background: #fbfbfc;\n"
  html = html + "    }\n"
  html = html + "    button.primary {\n"
  html = html + "      background: var(--accent);\n"
  html = html + "      border-color: var(--accent);\n"
  html = html + "      color: #fff;\n"
  html = html + "    }\n"
  html = html + "    button.toggle-btn.active {\n"
  html = html + "      background: var(--accent-soft);\n"
  html = html + "      border-color: #9fc1e5;\n"
  html = html + "      color: #154e87;\n"
  html = html + "    }\n"
  html = html + "    select,\n"
  html = html + "    input {\n"
  html = html + "      width: 100%;\n"
  html = html + "      min-height: 26px;\n"
  html = html + "      border: 1px solid var(--line-strong);\n"
  html = html + "      border-radius: 2px;\n"
  html = html + "      background: #fff;\n"
  html = html + "      padding: 4px 8px;\n"
  html = html + "    }\n"
  html = html + "    .workbench-app {\n"
  html = html + "      display: grid;\n"
  html = html + "      grid-template-rows: auto auto 1fr;\n"
  html = html + "      min-height: 100vh;\n"
  html = html + "      gap: 0;\n"
  html = html + "    }\n"
  html = html + "    .toolbar {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-columns: minmax(240px, 1fr) minmax(520px, 2fr);\n"
  html = html + "      gap: 12px;\n"
  html = html + "      align-items: center;\n"
  html = html + "      padding: 8px 10px;\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      background: var(--toolbar);\n"
  html = html + "    }\n"
  html = html + "    .toolbar-title {\n"
  html = html + "      min-width: 0;\n"
  html = html + "    }\n"
  html = html + "    .title-row {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      gap: 8px;\n"
  html = html + "      min-width: 0;\n"
  html = html + "    }\n"
  html = html + "    .title-row h1 {\n"
  html = html + "      margin: 0;\n"
  html = html + "      font-size: 13px;\n"
  html = html + "      font-weight: 700;\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "      overflow: hidden;\n"
  html = html + "      text-overflow: ellipsis;\n"
  html = html + "    }\n"
  html = html + "    .path-row {\n"
  html = html + "      margin-top: 2px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "      overflow: hidden;\n"
  html = html + "      text-overflow: ellipsis;\n"
  html = html + "    }\n"
  html = html + "    .pill {\n"
  html = html + "      display: inline-flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      min-height: 20px;\n"
  html = html + "      padding: 0 6px;\n"
  html = html + "      border: 1px solid var(--line-strong);\n"
  html = html + "      background: #fff;\n"
  html = html + "      border-radius: 999px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "    }\n"
  html = html + "    .toolbar-controls {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-columns: minmax(180px, 240px) minmax(180px, 1fr) auto auto;\n"
  html = html + "      gap: 8px;\n"
  html = html + "      align-items: end;\n"
  html = html + "    }\n"
  html = html + "    .toolbar-field {\n"
  html = html + "      display: flex;\n"
  html = html + "      flex-direction: column;\n"
  html = html + "      gap: 3px;\n"
  html = html + "      min-width: 0;\n"
  html = html + "    }\n"
  html = html + "    .toolbar-field label,\n"
  html = html + "    .toolbar-field span {\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-size: 11px;\n"
  html = html + "    }\n"
  html = html + "    .toolbar-buttons,\n"
  html = html + "    .toolbar-toggles {\n"
  html = html + "      display: flex;\n"
  html = html + "      gap: 6px;\n"
  html = html + "      align-items: center;\n"
  html = html + "      flex-wrap: wrap;\n"
  html = html + "    }\n"
  html = html + "    .status-strip {\n"
  html = html + "      display: none;\n"
  html = html + "      padding: 6px 10px;\n"
  html = html + "      border-bottom: 1px solid #f0cf99;\n"
  html = html + "      background: var(--warning-bg);\n"
  html = html + "      color: var(--warning-ink);\n"
  html = html + "    }\n"
  html = html + "    .workbench-shell {\n"
  html = html + "      display: grid;\n"
  html = html + "      min-height: 0;\n"
  html = html +
    "      grid-template-columns: var(--nav-width) var(--nav-split-size) minmax(0, 1fr) var(--inspector-split-size) var(--inspector-width);\n"
  html = html + "    }\n"
  html = html + "    .pane {\n"
  html = html + "      min-width: 0;\n"
  html = html + "      min-height: 0;\n"
  html = html + "      display: flex;\n"
  html = html + "      flex-direction: column;\n"
  html = html + "      background: var(--panel);\n"
  html = html + "    }\n"
  html = html + "    .pane-head {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      justify-content: space-between;\n"
  html = html + "      gap: 8px;\n"
  html = html + "      min-height: 32px;\n"
  html = html + "      padding: 0 8px;\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      background: #fbfbfc;\n"
  html = html + "    }\n"
  html = html + "    .pane-title {\n"
  html = html + "      font-size: 12px;\n"
  html = html + "      font-weight: 700;\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "    }\n"
  html = html + "    .pane-subtitle {\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-size: 11px;\n"
  html = html + "    }\n"
  html = html + "    .pane-actions {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      gap: 6px;\n"
  html = html + "      flex-wrap: wrap;\n"
  html = html + "    }\n"
  html = html + "    .pane-scroll {\n"
  html = html + "      min-height: 0;\n"
  html = html + "      overflow: auto;\n"
  html = html + "    }\n"
  html = html + "    .pane-body {\n"
  html = html + "      padding: 8px;\n"
  html = html + "    }\n"
  html = html + "    .splitter {\n"
  html = html + "      position: relative;\n"
  html = html + "      background: var(--bg);\n"
  html = html + "      user-select: none;\n"
  html = html + "    }\n"
  html = html + "    .splitter::after {\n"
  html = html + "      content: \"\";\n"
  html = html + "      position: absolute;\n"
  html = html + "      inset: 0;\n"
  html = html + "      background: transparent;\n"
  html = html + "    }\n"
  html = html + "    .splitter-x {\n"
  html = html + "      width: var(--splitter-size);\n"
  html = html + "      cursor: col-resize;\n"
  html = html + "      border-left: 1px solid var(--line);\n"
  html = html + "      border-right: 1px solid var(--line);\n"
  html = html + "    }\n"
  html = html + "    .splitter-y {\n"
  html = html + "      height: var(--splitter-size);\n"
  html = html + "      cursor: row-resize;\n"
  html = html + "      border-top: 1px solid var(--line);\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "    }\n"
  html = html + "    .center-shell {\n"
  html = html + "      display: grid;\n"
  html = html + "      min-height: 0;\n"
  html = html +
    "      grid-template-rows: minmax(260px, 1fr) var(--bottom-split-size) var(--bottom-height);\n"
  html = html + "      border-left: 1px solid var(--line);\n"
  html = html + "      border-right: 1px solid var(--line);\n"
  html = html + "    }\n"
  html = html + "    .nav-pane,\n"
  html = html + "    .inspector-pane {\n"
  html = html + "      background: var(--panel-muted);\n"
  html = html + "    }\n"
  html = html + "    .main-pane,\n"
  html = html + "    .result-pane {\n"
  html = html + "      background: var(--panel);\n"
  html = html + "    }\n"
  html = html + "    .summary-grid {\n"
  html = html + "      display: grid;\n"
  html = html + "      grid-template-columns: repeat(2, minmax(0, 1fr));\n"
  html = html + "      gap: 6px;\n"
  html = html + "      margin-bottom: 8px;\n"
  html = html + "    }\n"
  html = html + "    .stat {\n"
  html = html + "      padding: 6px;\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      background: #fff;\n"
  html = html + "    }\n"
  html = html + "    .stat .k {\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-size: 11px;\n"
  html = html + "    }\n"
  html = html + "    .stat .v {\n"
  html = html + "      margin-top: 3px;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "      overflow: hidden;\n"
  html = html + "      text-overflow: ellipsis;\n"
  html = html + "    }\n"
  html = html + "    .compact-list {\n"
  html = html + "      display: flex;\n"
  html = html + "      flex-direction: column;\n"
  html = html + "      gap: 2px;\n"
  html = html + "    }\n"
  html = html + "    .list-header {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      justify-content: space-between;\n"
  html = html + "      gap: 8px;\n"
  html = html + "      margin: 10px 0 4px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "    }\n"
  html = html + "    .nav-row {\n"
  html = html + "      width: 100%;\n"
  html = html + "      text-align: left;\n"
  html = html + "      padding: 6px 8px;\n"
  html = html + "      border: 1px solid transparent;\n"
  html = html + "      background: transparent;\n"
  html = html + "      display: grid;\n"
  html = html + "      gap: 2px;\n"
  html = html + "    }\n"
  html = html + "    .nav-row:hover { background: #fff; }\n"
  html = html + "    .nav-row.active {\n"
  html = html + "      background: var(--accent-soft);\n"
  html = html + "      border-color: #b9d2ec;\n"
  html = html + "    }\n"
  html = html + "    .nav-row.current {\n"
  html = html + "      border-color: #d0b04b;\n"
  html = html + "    }\n"
  html = html + "    .nav-row-title {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      gap: 6px;\n"
  html = html + "      min-width: 0;\n"
  html = html + "    }\n"
  html = html + "    .nav-row-title span:first-child {\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "      overflow: hidden;\n"
  html = html + "      text-overflow: ellipsis;\n"
  html = html + "    }\n"
  html = html + "    .nav-row-meta {\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-size: 11px;\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "      overflow: hidden;\n"
  html = html + "      text-overflow: ellipsis;\n"
  html = html + "    }\n"
  html = html + "    .pane-tabs {\n"
  html = html + "      display: flex;\n"
  html = html + "      gap: 1px;\n"
  html = html + "      padding: 0 8px;\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      background: #f8f9fb;\n"
  html = html + "    }\n"
  html = html + "    .pane-tab {\n"
  html = html + "      border: 0;\n"
  html = html + "      border-bottom: 2px solid transparent;\n"
  html = html + "      background: transparent;\n"
  html = html + "      border-radius: 0;\n"
  html = html + "      min-height: 29px;\n"
  html = html + "      padding: 0 10px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "    }\n"
  html = html + "    .pane-tab.active {\n"
  html = html + "      color: var(--ink);\n"
  html = html + "      border-bottom-color: var(--accent);\n"
  html = html + "      background: #fff;\n"
  html = html + "    }\n"
  html = html + "    .tab-panel {\n"
  html = html + "      display: none;\n"
  html = html + "      min-height: 0;\n"
  html = html + "      flex: 1 1 auto;\n"
  html = html + "    }\n"
  html = html + "    .tab-panel.active {\n"
  html = html + "      display: flex;\n"
  html = html + "      min-height: 0;\n"
  html = html + "      flex-direction: column;\n"
  html = html + "    }\n"
  html = html + "    .tab-scroll {\n"
  html = html + "      min-height: 0;\n"
  html = html + "      overflow: auto;\n"
  html = html + "      padding: 8px;\n"
  html = html + "    }\n"
  html = html + "    table {\n"
  html = html + "      width: 100%;\n"
  html = html + "      border-collapse: collapse;\n"
  html = html + "      table-layout: fixed;\n"
  html = html + "    }\n"
  html = html + "    th,\n"
  html = html + "    td {\n"
  html = html + "      padding: 4px 6px;\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      text-align: left;\n"
  html = html + "      vertical-align: top;\n"
  html = html + "      word-break: break-word;\n"
  html = html + "    }\n"
  html = html + "    thead th {\n"
  html = html + "      position: sticky;\n"
  html = html + "      top: 0;\n"
  html = html + "      z-index: 1;\n"
  html = html + "      background: #fbfbfc;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-weight: 600;\n"
  html = html + "    }\n"
  html = html + "    tbody tr:hover td { background: #f7faff; }\n"
  html = html + "    tbody tr.active td { background: var(--pc); }\n"
  html = html + "    tbody tr.focus td { background: var(--selected); }\n"
  html = html + "    .interactive tbody tr { cursor: pointer; }\n"
  html = html + "    .mono { font-variant-ligatures: none; }\n"
  html = html + "    .column-index { width: 50px; }\n"
  html = html + "    .column-addr { width: 112px; }\n"
  html = html + "    .column-category { width: 96px; }\n"
  html = html + "    .column-next { width: 112px; }\n"
  html = html + "    .code-cell { white-space: pre-wrap; }\n"
  html = html + "    .muted { color: var(--muted); }\n"
  html = html + "    .badge {\n"
  html = html + "      display: inline-flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      gap: 4px;\n"
  html = html + "      min-height: 18px;\n"
  html = html + "      padding: 0 5px;\n"
  html = html + "      border: 1px solid var(--line-strong);\n"
  html = html + "      border-radius: 999px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      background: #fff;\n"
  html = html + "      font-size: 11px;\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "    }\n"
  html = html + "    .badge.changed {\n"
  html = html + "      background: var(--success-soft);\n"
  html = html + "      border-color: #bdd9c4;\n"
  html = html + "      color: #296238;\n"
  html = html + "    }\n"
  html = html + "    .badge.current {\n"
  html = html + "      background: #fff6d7;\n"
  html = html + "      border-color: #dbc166;\n"
  html = html + "      color: #6f5602;\n"
  html = html + "    }\n"
  html = html + "    .empty-panel {\n"
  html = html + "      padding: 14px 8px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "    }\n"
  html = html + "    .kv-table td:first-child {\n"
  html = html + "      width: 92px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "    }\n"
  html = html + "    .section-block + .section-block {\n"
  html = html + "      margin-top: 10px;\n"
  html = html + "    }\n"
  html = html + "    .section-block h3 {\n"
  html = html + "      margin: 0 0 5px;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "      font-weight: 700;\n"
  html = html + "    }\n"
  html = html + "    .register-toolbar {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: center;\n"
  html = html + "      justify-content: space-between;\n"
  html = html + "      gap: 8px;\n"
  html = html + "      margin-bottom: 8px;\n"
  html = html + "    }\n"
  html = html + "    .register-group + .register-group { margin-top: 10px; }\n"
  html = html + "    .group-title {\n"
  html = html + "      margin-bottom: 4px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "    }\n"
  html = html + "    .register-table td:first-child {\n"
  html = html + "      width: 74px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "    }\n"
  html = html + "    .register-table td:last-child {\n"
  html = html + "      width: 88px;\n"
  html = html + "      text-align: right;\n"
  html = html + "    }\n"
  html = html + "    .output-box {\n"
  html = html + "      margin-top: 8px;\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      background: #fff;\n"
  html = html + "    }\n"
  html = html + "    .output-head {\n"
  html = html + "      padding: 4px 6px;\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      background: #fbfbfc;\n"
  html = html + "    }\n"
  html = html + "    .output-body {\n"
  html = html + "      margin: 0;\n"
  html = html + "      padding: 8px;\n"
  html = html + "      white-space: pre-wrap;\n"
  html = html + "      word-break: break-word;\n"
  html = html + "    }\n"
  html = html + "    .cfg-grid {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));\n"
  html = html + "      gap: 8px;\n"
  html = html + "      margin-bottom: 10px;\n"
  html = html + "    }\n"
  html = html + "    .cfg-card {\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      background: #fff;\n"
  html = html + "      padding: 8px;\n"
  html = html + "    }\n"
  html = html + "    .cfg-card.active {\n"
  html = html + "      background: var(--pc);\n"
  html = html + "      border-color: #d4bc68;\n"
  html = html + "    }\n"
  html = html + "    .cfg-card-title {\n"
  html = html + "      font-weight: 700;\n"
  html = html + "      margin-bottom: 4px;\n"
  html = html + "    }\n"
  html = html + "    .io-table td:first-child,\n"
  html = html + "    .trace-table td:first-child,\n"
  html = html + "    .trace-table td:nth-child(2),\n"
  html = html + "    .memory-table td:first-child,\n"
  html = html + "    .memory-table td:nth-child(2) {\n"
  html = html + "      white-space: nowrap;\n"
  html = html + "    }\n"
  html = html + "    .collapsed-pane {\n"
  html = html + "      display: none;\n"
  html = html + "    }\n"
  html = html + "    @media (max-width: 1180px) {\n"
  html = html + "      .toolbar {\n"
  html = html + "        grid-template-columns: 1fr;\n"
  html = html + "      }\n"
  html = html + "      .toolbar-controls {\n"
  html = html + "        grid-template-columns: repeat(2, minmax(0, 1fr));\n"
  html = html + "      }\n"
  html = html + "    }\n"
  html = html + "    @media (max-width: 1100px) {\n"
  html = html + "      .workbench-shell {\n"
  html = html + "        grid-template-columns: 1fr;\n"
  html = html + "      }\n"
  html = html + "      .splitter {\n"
  html = html + "        display: none;\n"
  html = html + "      }\n"
  html = html + "      .center-shell {\n"
  html = html +
    "        grid-template-rows: minmax(260px, 1fr) minmax(220px, 280px);\n"
  html = html + "        border-left: 0;\n"
  html = html + "        border-right: 0;\n"
  html = html + "      }\n"
  html = html + "      .nav-pane,\n"
  html = html + "      .inspector-pane,\n"
  html = html + "      .main-pane,\n"
  html = html + "      .result-pane {\n"
  html = html + "        border-bottom: 1px solid var(--line);\n"
  html = html + "      }\n"
  html = html + "    }\n"
  html = html + "    @media (max-width: 760px) {\n"
  html = html + "      .toolbar-controls {\n"
  html = html + "        grid-template-columns: 1fr;\n"
  html = html + "      }\n"
  html = html + "      .summary-grid {\n"
  html = html + "        grid-template-columns: 1fr;\n"
  html = html + "      }\n"
  html = html + "      .column-index,\n"
  html = html + "      .column-category,\n"
  html = html + "      .column-next {\n"
  html = html + "        display: none;\n"
  html = html + "      }\n"
  html = html + "    }\n"
  html = html + "  </style>\n"
  html = html + "</head>\n"
  html = html + "<body>\n"
  html = html + "  <div class=\"workbench-app\">\n"
  html = html + "    <header class=\"toolbar\">\n"
  html = html + "      <div class=\"toolbar-title\">\n"
  html = html + "        <div class=\"title-row\">\n"
  html = html + "          <h1 id=\"title\"></h1>\n"
  html = html + "          <span class=\"pill\" id=\"status-pill\"></span>\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"path-row\" id=\"source\"></div>\n"
  html = html + "      </div>\n"
  html = html + "      <div class=\"toolbar-controls\">\n"
  html = html + "        <div class=\"toolbar-field\">\n"
  html = html + "          <span>函数</span>\n"
  html = html + "          <select id=\"function-select\"></select>\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"toolbar-field\">\n"
  html = html + "          <span>搜索</span>\n"
  html = html +
    "          <input id=\"search-input\" type=\"search\" placeholder=\"地址 / 函数 / 指令 / category\" />\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"toolbar-buttons\">\n"
  html = html + "          <button id=\"reset-btn\">Reset</button>\n"
  html = html + "          <button id=\"prev-btn\">Prev</button>\n"
  html = html +
    "          <button id=\"next-btn\" class=\"primary\">Next</button>\n"
  html = html + "          <button id=\"play-btn\">Play</button>\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"toolbar-toggles\">\n"
  html = html +
    "          <button id=\"follow-pc\" class=\"toggle-btn\">Follow PC</button>\n"
  html = html +
    "          <button id=\"current-function-only\" class=\"toggle-btn\">Show Only Current Function</button>\n"
  html = html + "        </div>\n"
  html = html + "      </div>\n"
  html = html + "    </header>\n"
  html = html +
    "    <div class=\"status-strip\" id=\"truncated-banner\"></div>\n"
  html = html + "    <main class=\"workbench-shell\">\n"
  html = html + "      <aside class=\"pane nav-pane\" id=\"nav-pane\">\n"
  html = html + "        <div class=\"pane-head\">\n"
  html = html + "          <div>\n"
  html = html + "            <div class=\"pane-title\">导航</div>\n"
  html = html +
    "            <div class=\"pane-subtitle\">函数 / 节区 / 摘要</div>\n"
  html = html + "          </div>\n"
  html = html + "          <div class=\"pane-actions\">\n"
  html = html + "            <button id=\"toggle-nav-pane\">折叠</button>\n"
  html = html + "          </div>\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"pane-scroll pane-body\">\n"
  html = html +
    "          <div class=\"summary-grid\" id=\"summary-grid\"></div>\n"
  html = html +
    "          <div class=\"list-header\"><span>Functions</span><span class=\"muted\" id=\"function-list-count\"></span></div>\n"
  html = html +
    "          <div class=\"compact-list\" id=\"function-list\"></div>\n"
  html = html +
    "          <div class=\"list-header\"><span>Sections</span><span class=\"muted\" id=\"section-list-count\"></span></div>\n"
  html = html +
    "          <div class=\"compact-list\" id=\"section-list\"></div>\n"
  html = html + "        </div>\n"
  html = html + "      </aside>\n"
  html = html +
    "      <div class=\"splitter splitter-x\" id=\"nav-splitter\"></div>\n"
  html = html + "      <section class=\"center-shell\">\n"
  html = html + "        <section class=\"pane main-pane\">\n"
  html = html + "          <div class=\"pane-head\">\n"
  html = html + "            <div>\n"
  html = html + "              <div class=\"pane-title\">Disassembly</div>\n"
  html = html +
    "              <div class=\"pane-subtitle\" id=\"disasm-subtitle\"></div>\n"
  html = html + "            </div>\n"
  html = html + "            <div class=\"pane-actions\">\n"
  html = html + "              <span class=\"pill\" id=\"view-pill\"></span>\n"
  html = html + "            </div>\n"
  html = html + "          </div>\n"
  html = html + "          <div class=\"pane-scroll\">\n"
  html = html + "            <table class=\"interactive mono\">\n"
  html = html + "              <thead>\n"
  html = html +
    "                <tr><th class=\"column-index\">#</th><th class=\"column-addr\">地址</th><th class=\"column-category\">分类</th><th>指令</th></tr>\n"
  html = html + "              </thead>\n"
  html = html + "              <tbody id=\"disasm-body\"></tbody>\n"
  html = html + "            </table>\n"
  html = html + "          </div>\n"
  html = html + "        </section>\n"
  html = html +
    "        <div class=\"splitter splitter-y\" id=\"bottom-splitter\"></div>\n"
  html = html +
    "        <section class=\"pane result-pane\" id=\"result-pane\">\n"
  html = html + "          <div class=\"pane-head\">\n"
  html = html + "            <div>\n"
  html = html + "              <div class=\"pane-title\">Results</div>\n"
  html = html +
    "              <div class=\"pane-subtitle\">CFG / Trace / Memory Writes / Syscalls</div>\n"
  html = html + "            </div>\n"
  html = html + "            <div class=\"pane-actions\">\n"
  html = html +
    "              <button id=\"toggle-bottom-pane\">折叠</button>\n"
  html = html + "            </div>\n"
  html = html + "          </div>\n"
  html = html + "          <div class=\"pane-tabs\" id=\"pane-tabs\">\n"
  html = html +
    "            <button class=\"pane-tab\" data-tab=\"cfg\">CFG</button>\n"
  html = html +
    "            <button class=\"pane-tab\" data-tab=\"trace\">Trace</button>\n"
  html = html +
    "            <button class=\"pane-tab\" data-tab=\"memory\">Memory Writes</button>\n"
  html = html +
    "            <button class=\"pane-tab\" data-tab=\"syscalls\">Syscalls/Output</button>\n"
  html = html + "          </div>\n"
  html = html +
    "          <div class=\"tab-panel\" data-tab-panel=\"cfg\"><div class=\"tab-scroll\" id=\"cfg-view\"></div></div>\n"
  html = html +
    "          <div class=\"tab-panel\" data-tab-panel=\"trace\"><div class=\"tab-scroll\"><table class=\"interactive trace-table mono\"><thead><tr><th class=\"column-index\">step</th><th class=\"column-addr\">pc</th><th>instruction</th><th>writes</th><th>syscall/stop</th></tr></thead><tbody id=\"trace-body\"></tbody></table></div></div>\n"
  html = html +
    "          <div class=\"tab-panel\" data-tab-panel=\"memory\"><div class=\"tab-scroll\"><table class=\"memory-table mono\"><thead><tr><th class=\"column-index\">step</th><th class=\"column-addr\">addr</th><th class=\"column-index\">size</th><th>before</th><th>after</th></tr></thead><tbody id=\"memory-body\"></tbody></table></div></div>\n"
  html = html +
    "          <div class=\"tab-panel\" data-tab-panel=\"syscalls\"><div class=\"tab-scroll\"><table class=\"io-table mono\"><thead><tr><th class=\"column-index\">step</th><th class=\"column-category\">kind</th><th>detail</th></tr></thead><tbody id=\"syscall-body\"></tbody></table><div class=\"output-box\"><div class=\"output-head\">stdout</div><pre class=\"output-body\" id=\"stdout-output\"></pre></div><div class=\"output-box\"><div class=\"output-head\">stderr</div><pre class=\"output-body\" id=\"stderr-output\"></pre></div></div></div>\n"
  html = html + "        </section>\n"
  html = html + "      </section>\n"
  html = html +
    "      <div class=\"splitter splitter-x\" id=\"inspector-splitter\"></div>\n"
  html = html +
    "      <aside class=\"pane inspector-pane\" id=\"inspector-pane\">\n"
  html = html + "        <div class=\"pane-head\">\n"
  html = html + "          <div>\n"
  html = html + "            <div class=\"pane-title\">Inspector</div>\n"
  html = html +
    "            <div class=\"pane-subtitle\">State / Registers / Execution</div>\n"
  html = html + "          </div>\n"
  html = html + "          <div class=\"pane-actions\">\n"
  html = html +
    "            <button id=\"toggle-inspector-pane\">折叠</button>\n"
  html = html + "          </div>\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"pane-scroll pane-body\">\n"
  html = html + "          <div class=\"section-block\">\n"
  html = html + "            <h3>State</h3>\n"
  html = html +
    "            <div class=\"summary-grid\" id=\"runtime-summary\"></div>\n"
  html = html + "          </div>\n"
  html = html + "          <div class=\"section-block\">\n"
  html = html + "            <h3>Execution</h3>\n"
  html = html +
    "            <table class=\"kv-table mono\"><tbody id=\"execution-body\"></tbody></table>\n"
  html = html + "          </div>\n"
  html = html + "          <div class=\"section-block\">\n"
  html = html + "            <div class=\"register-toolbar\">\n"
  html = html + "              <h3 style=\"margin:0\">Registers</h3>\n"
  html = html +
    "              <button id=\"changed-registers-toggle\" class=\"toggle-btn\">仅变化</button>\n"
  html = html + "            </div>\n"
  html = html + "            <div id=\"register-groups\"></div>\n"
  html = html + "          </div>\n"
  html = html + "        </div>\n"
  html = html + "      </aside>\n"
  html = html + "    </main>\n"
  html = html + "  </div>\n"
  html = html + "  <script>\n"
  html = html + "    const RVLAB_DATA = "
  html = html + data_json
  html = html + ";\n"
  html = html + "  </script>\n"
  html = html + "  <script>\n"
  html = html + "    (() => {\n"
  html = html + "      const data = RVLAB_DATA;\n"
  html = html + "      const refs = {\n"
  html = html + "        title: document.getElementById('title'),\n"
  html = html + "        source: document.getElementById('source'),\n"
  html = html + "        statusPill: document.getElementById('status-pill'),\n"
  html = html +
    "        summaryGrid: document.getElementById('summary-grid'),\n"
  html = html +
    "        runtimeSummary: document.getElementById('runtime-summary'),\n"
  html = html +
    "        executionBody: document.getElementById('execution-body'),\n"
  html = html +
    "        functionSelect: document.getElementById('function-select'),\n"
  html = html +
    "        functionListCount: document.getElementById('function-list-count'),\n"
  html = html +
    "        functionList: document.getElementById('function-list'),\n"
  html = html +
    "        sectionListCount: document.getElementById('section-list-count'),\n"
  html = html +
    "        sectionList: document.getElementById('section-list'),\n"
  html = html +
    "        searchInput: document.getElementById('search-input'),\n"
  html = html +
    "        disasmSubtitle: document.getElementById('disasm-subtitle'),\n"
  html = html + "        viewPill: document.getElementById('view-pill'),\n"
  html = html + "        disasmBody: document.getElementById('disasm-body'),\n"
  html = html + "        cfgView: document.getElementById('cfg-view'),\n"
  html = html + "        traceBody: document.getElementById('trace-body'),\n"
  html = html + "        memoryBody: document.getElementById('memory-body'),\n"
  html = html +
    "        syscallBody: document.getElementById('syscall-body'),\n"
  html = html +
    "        stdoutOutput: document.getElementById('stdout-output'),\n"
  html = html +
    "        stderrOutput: document.getElementById('stderr-output'),\n"
  html = html +
    "        registerGroups: document.getElementById('register-groups'),\n"
  html = html +
    "        truncatedBanner: document.getElementById('truncated-banner'),\n"
  html = html + "        resetBtn: document.getElementById('reset-btn'),\n"
  html = html + "        prevBtn: document.getElementById('prev-btn'),\n"
  html = html + "        nextBtn: document.getElementById('next-btn'),\n"
  html = html + "        playBtn: document.getElementById('play-btn'),\n"
  html = html + "        followPc: document.getElementById('follow-pc'),\n"
  html = html +
    "        currentFunctionOnly: document.getElementById('current-function-only'),\n"
  html = html +
    "        changedRegistersToggle: document.getElementById('changed-registers-toggle'),\n"
  html = html + "        paneTabs: document.getElementById('pane-tabs'),\n"
  html = html + "        navPane: document.getElementById('nav-pane'),\n"
  html = html +
    "        inspectorPane: document.getElementById('inspector-pane'),\n"
  html = html + "        resultPane: document.getElementById('result-pane'),\n"
  html = html +
    "        navSplitter: document.getElementById('nav-splitter'),\n"
  html = html +
    "        inspectorSplitter: document.getElementById('inspector-splitter'),\n"
  html = html +
    "        bottomSplitter: document.getElementById('bottom-splitter'),\n"
  html = html +
    "        toggleNavPane: document.getElementById('toggle-nav-pane'),\n"
  html = html +
    "        toggleBottomPane: document.getElementById('toggle-bottom-pane'),\n"
  html = html +
    "        toggleInspectorPane: document.getElementById('toggle-inspector-pane')\n"
  html = html + "      };\n"
  html = html + "\n"
  html = html + "      const REGISTER_ORDER = [\n"
  html = html +
    "        'zero','ra','sp','gp','tp','t0','t1','t2','s0','s1','a0','a1','a2','a3','a4','a5','a6','a7',\n"
  html = html +
    "        's2','s3','s4','s5','s6','s7','s8','s9','s10','s11','t3','t4','t5','t6'\n"
  html = html + "      ];\n"
  html = html + "      const REGISTER_GROUPS = [\n"
  html = html +
    "        { label: '基础', regs: ['zero', 'ra', 'sp', 'gp', 'tp'] },\n"
  html = html +
    "        { label: '参数 / 返回', regs: ['a0', 'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7'] },\n"
  html = html +
    "        { label: '保存', regs: ['s0', 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9', 's10', 's11'] },\n"
  html = html +
    "        { label: '临时', regs: ['t0', 't1', 't2', 't3', 't4', 't5', 't6'] }\n"
  html = html + "      ];\n"
  html = html +
    "      const STORAGE_KEY = `moonrv-workbench-ui:${data.meta.source_file || 'default'}`;\n"
  html = html + "\n"
  html = html +
    "      const INITIAL_REGISTERS = Object.fromEntries((data.runtime.initial_registers || []).map(item => [item.name, item.value]));\n"
  html = html + "      const EVENT_INDEX_BY_ADDR = new Map();\n"
  html = html + "      (data.events || []).forEach((event, index) => {\n"
  html = html + "        if (!EVENT_INDEX_BY_ADDR.has(event.addr)) {\n"
  html = html + "          EVENT_INDEX_BY_ADDR.set(event.addr, index);\n"
  html = html + "        }\n"
  html = html + "      });\n"
  html = html +
    "      const MAX_INSTRUCTION_ADDR = (data.instructions || []).length > 0\n"
  html = html +
    "        ? hexToBigInt(data.instructions[data.instructions.length - 1].addr) + 4n\n"
  html = html + "        : 0n;\n"
  html = html + "      const FUNCTION_RANGES = (data.functions || [])\n"
  html = html + "        .slice()\n"
  html = html +
    "        .sort((lhs, rhs) => (hexToBigInt(lhs.addr) < hexToBigInt(rhs.addr) ? -1 : 1))\n"
  html = html + "        .map((fn, index, items) => {\n"
  html = html + "          const start = hexToBigInt(fn.addr);\n"
  html = html + "          const size = hexToBigInt(fn.size || '0x0');\n"
  html = html +
    "          const next = index + 1 < items.length ? hexToBigInt(items[index + 1].addr) : (MAX_INSTRUCTION_ADDR + 4n);\n"
  html = html + "          const end = size > 0n ? start + size : next;\n"
  html = html + "          return { fn, start, end };\n"
  html = html + "        });\n"
  html = html + "      const storedUi = readUiState();\n"
  html = html + "      const state = {\n"
  html = html +
    "        selectedFunctionAddr: storedUi.selectedFunctionAddr || '',\n"
  html = html + "        searchText: storedUi.searchText || '',\n"
  html = html + "        activeTab: storedUi.activeTab || 'trace',\n"
  html = html + "        followPcEnabled: storedUi.followPcEnabled !== false,\n"
  html = html +
    "        currentFunctionOnlyEnabled: storedUi.currentFunctionOnlyEnabled === true,\n"
  html = html +
    "        showChangedRegistersOnly: storedUi.showChangedRegistersOnly === true,\n"
  html = html + "        layout: {\n"
  html = html +
    "          navWidth: clampNumber(storedUi.navWidth, 180, 420, 240),\n"
  html = html +
    "          inspectorWidth: clampNumber(storedUi.inspectorWidth, 240, 460, 320),\n"
  html = html +
    "          bottomHeight: clampNumber(storedUi.bottomHeight, 180, 420, 260),\n"
  html = html + "          navCollapsed: storedUi.navCollapsed === true,\n"
  html = html +
    "          bottomCollapsed: storedUi.bottomCollapsed === true,\n"
  html = html +
    "          inspectorCollapsed: storedUi.inspectorCollapsed === true\n"
  html = html + "        },\n"
  html = html + "        cursor: -1,\n"
  html = html + "        focusedAddr: data.runtime.initial_pc || '',\n"
  html = html + "        registers: {},\n"
  html = html + "        memoryHistory: [],\n"
  html = html + "        ioHistory: [],\n"
  html = html + "        stdout: '',\n"
  html = html + "        stderr: '',\n"
  html = html + "        timer: null\n"
  html = html + "      };\n"
  html = html + "\n"
  html = html + "      refs.searchInput.value = state.searchText;\n"
  html = html + "      function escapeHtml(value) {\n"
  html = html + "        return String(value)\n"
  html = html + "          .replaceAll('&', '&amp;')\n"
  html = html + "          .replaceAll('<', '&lt;')\n"
  html = html + "          .replaceAll('>', '&gt;')\n"
  html = html + "          .replaceAll('\"', '&quot;')\n"
  html = html + "          .replaceAll(\"'\", '&#39;');\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function hexToBigInt(hex) {\n"
  html = html + "        try {\n"
  html = html + "          return BigInt(hex);\n"
  html = html + "        } catch (_) {\n"
  html = html + "          return 0n;\n"
  html = html + "        }\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function clamp(value, min, max) {\n"
  html = html + "        return Math.max(min, Math.min(max, value));\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function clampNumber(value, min, max, fallback) {\n"
  html = html +
    "        return typeof value === 'number' && Number.isFinite(value)\n"
  html = html + "          ? clamp(value, min, max)\n"
  html = html + "          : fallback;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function readUiState() {\n"
  html = html + "        try {\n"
  html = html +
    "          const parsed = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');\n"
  html = html +
    "          return parsed && typeof parsed === 'object' ? parsed : {};\n"
  html = html + "        } catch (_) {\n"
  html = html + "          return {};\n"
  html = html + "        }\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function saveUiState() {\n"
  html = html + "        const payload = {\n"
  html = html + "          selectedFunctionAddr: state.selectedFunctionAddr,\n"
  html = html + "          searchText: state.searchText,\n"
  html = html + "          activeTab: state.activeTab,\n"
  html = html + "          followPcEnabled: state.followPcEnabled,\n"
  html = html +
    "          currentFunctionOnlyEnabled: state.currentFunctionOnlyEnabled,\n"
  html = html +
    "          showChangedRegistersOnly: state.showChangedRegistersOnly,\n"
  html = html + "          navWidth: state.layout.navWidth,\n"
  html = html + "          inspectorWidth: state.layout.inspectorWidth,\n"
  html = html + "          bottomHeight: state.layout.bottomHeight,\n"
  html = html + "          navCollapsed: state.layout.navCollapsed,\n"
  html = html + "          bottomCollapsed: state.layout.bottomCollapsed,\n"
  html = html +
    "          inspectorCollapsed: state.layout.inspectorCollapsed\n"
  html = html + "        };\n"
  html = html + "        try {\n"
  html = html +
    "          localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));\n"
  html = html + "        } catch (_) {\n"
  html = html + "        }\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function selectedFunction() {\n"
  html = html +
    "        return (data.functions || []).find(item => item.addr === state.selectedFunctionAddr) || null;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function functionRangeForAddr(addr) {\n"
  html = html +
    "        return FUNCTION_RANGES.find(item => item.fn.addr === addr) || null;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function functionForAddress(addr) {\n"
  html = html + "        const target = hexToBigInt(addr);\n"
  html = html +
    "        return FUNCTION_RANGES.find(item => target >= item.start && target < item.end)?.fn || (data.functions || []).find(item => item.addr === addr) || null;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function instructionsForFunction(target) {\n"
  html = html + "        if (!target) {\n"
  html = html + "          return data.instructions.slice();\n"
  html = html + "        }\n"
  html = html + "        const range = functionRangeForAddr(target.addr);\n"
  html = html + "        if (!range) {\n"
  html = html + "          return data.instructions.slice();\n"
  html = html + "        }\n"
  html = html + "        const exact = data.instructions.filter(inst => {\n"
  html = html + "          const addr = hexToBigInt(inst.addr);\n"
  html = html + "          return addr >= range.start && addr < range.end;\n"
  html = html + "        });\n"
  html = html +
    "        return exact.length > 0 ? exact : data.instructions.slice();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function filterInstructions(instructions) {\n"
  html = html + "        const query = state.searchText.trim().toLowerCase();\n"
  html = html + "        if (!query) {\n"
  html = html + "          return instructions;\n"
  html = html + "        }\n"
  html = html + "        return instructions.filter(inst => {\n"
  html = html + "          const fn = functionForAddress(inst.addr);\n"
  html = html + "          return inst.addr.toLowerCase().includes(query)\n"
  html = html + "            || inst.asm.toLowerCase().includes(query)\n"
  html = html + "            || inst.category.toLowerCase().includes(query)\n"
  html = html +
    "            || (fn && fn.name.toLowerCase().includes(query));\n"
  html = html + "        });\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function visibleInstructions() {\n"
  html = html +
    "        const scoped = state.currentFunctionOnlyEnabled ? instructionsForFunction(selectedFunction()) : data.instructions.slice();\n"
  html = html + "        return filterInstructions(scoped);\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function resetRuntimeState() {\n"
  html = html + "        state.registers = { ...INITIAL_REGISTERS };\n"
  html = html + "        for (const r of REGISTER_ORDER) {\n"
  html = html +
    "          if (!(r in state.registers)) state.registers[r] = '0x0';\n"
  html = html + "        }\n"
  html = html + "        state.memoryHistory = [];\n"
  html = html + "        state.ioHistory = [];\n"
  html = html + "        state.stdout = '';\n"
  html = html + "        state.stderr = '';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function currentEvent() {\n"
  html = html +
    "        return state.cursor >= 0 && state.cursor < data.events.length ? data.events[state.cursor] : null;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function summaryItems() {\n"
  html = html + "        return [\n"
  html = html + "          ['入口', data.meta.entry_point],\n"
  html = html + "          ['函数', data.meta.function_count],\n"
  html = html + "          ['节区', data.meta.section_count],\n"
  html = html + "          ['指令(展示)', data.meta.instruction_count],\n"
  html = html + "          ['基本块', data.meta.basic_block_count],\n"
  html = html + "          ['CFG 边', data.meta.cfg_edge_count]\n"
  html = html + "        ];\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderSummary() {\n"
  html = html +
    "        refs.summaryGrid.innerHTML = summaryItems().map(([k, v]) => (\n"
  html = html +
    "          `<div class=\"stat\"><div class=\"k\">${escapeHtml(k)}</div><div class=\"v\">${escapeHtml(v)}</div></div>`\n"
  html = html + "        )).join('');\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderRuntimeSummary() {\n"
  html = html + "        const current = currentEvent();\n"
  html = html +
    "        const currentFunction = functionForAddress(current ? current.addr : data.runtime.initial_pc);\n"
  html = html +
    "        const stopText = current && current.stop_reason ? current.stop_reason : (state.cursor < 0 ? 'ready' : 'running');\n"
  html = html + "        refs.runtimeSummary.innerHTML = [\n"
  html = html +
    "          ['PC', current ? current.addr : data.runtime.initial_pc],\n"
  html = html +
    "          ['步骤', `${Math.max(0, state.cursor + 1)}/${data.events.length}`],\n"
  html = html + "          ['模式', state.timer ? 'Play' : 'Step'],\n"
  html = html + "          ['停止原因', stopText],\n"
  html = html +
    "          ['当前函数', currentFunction ? currentFunction.name : 'N/A'],\n"
  html = html + "          ['stdout', String(state.stdout.length)]\n"
  html = html +
    "        ].map(([k, v]) => `<div class=\"stat\"><div class=\"k\">${escapeHtml(k)}</div><div class=\"v\">${escapeHtml(v)}</div></div>`).join('');\n"
  html = html + "        refs.statusPill.textContent = stopText;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderSections() {\n"
  html = html +
    "        refs.sectionListCount.textContent = `${(data.sections || []).length} items`;\n"
  html = html +
    "        refs.sectionList.innerHTML = (data.sections || []).map(section => (\n"
  html = html +
    "          `<button class=\"nav-row\" data-section-query=\"${escapeHtml(section.addr)}\"><div class=\"nav-row-title\"><span>#${section.index} ${escapeHtml(section.name)}</span></div><div class=\"nav-row-meta\">${escapeHtml(section.addr)} / ${escapeHtml(section.size)}</div></button>`\n"
  html = html +
    "        )).join('') || '<div class=\"empty-panel\">无节区信息</div>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderFunctions() {\n"
  html = html + "        refs.functionSelect.innerHTML = '';\n"
  html = html + "        const allOption = document.createElement('option');\n"
  html = html + "        allOption.value = '__all__';\n"
  html = html + "        allOption.textContent = '全部指令视图';\n"
  html = html + "        refs.functionSelect.appendChild(allOption);\n"
  html = html + "        for (const fn of data.functions) {\n"
  html = html + "          const option = document.createElement('option');\n"
  html = html + "          option.value = fn.addr;\n"
  html = html + "          option.textContent = `${fn.name} @ ${fn.addr}`;\n"
  html = html + "          refs.functionSelect.appendChild(option);\n"
  html = html + "        }\n"
  html = html +
    "        refs.functionSelect.value = state.selectedFunctionAddr || '__all__';\n"
  html = html +
    "        refs.functionListCount.textContent = `${(data.functions || []).length} items`;\n"
  html = html +
    "        const currentFn = functionForAddress(currentEvent() ? currentEvent().addr : data.runtime.initial_pc);\n"
  html = html +
    "        refs.functionList.innerHTML = (data.functions || []).map(fn => {\n"
  html = html +
    "          const active = state.selectedFunctionAddr === fn.addr;\n"
  html = html +
    "          const current = currentFn && currentFn.addr === fn.addr;\n"
  html = html +
    "          const badges = [current ? '<span class=\"badge current\">PC</span>' : ''].join('');\n"
  html = html +
    "          return `<button class=\"nav-row${active ? ' active' : ''}${current ? ' current' : ''}\" data-fn-addr=\"${fn.addr}\"><div class=\"nav-row-title\"><span>${escapeHtml(fn.name)}</span>${badges}</div><div class=\"nav-row-meta\">${escapeHtml(fn.addr)} / ${escapeHtml(fn.size)}</div></button>`;\n"
  html = html +
    "        }).join('') || '<div class=\"empty-panel\">无函数符号</div>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function applyEvent(event) {\n"
  html = html + "        for (const delta of event.register_writes || []) {\n"
  html = html + "          state.registers[delta.name] = delta.after;\n"
  html = html + "        }\n"
  html = html + "        for (const mem of event.memory_writes || []) {\n"
  html = html +
    "          state.memoryHistory.unshift({ step: event.step, addr: mem.addr, size: mem.size, before: mem.before, after: mem.after });\n"
  html = html +
    "          if (state.memoryHistory.length > 160) state.memoryHistory.pop();\n"
  html = html + "        }\n"
  html = html + "        if (event.syscall) {\n"
  html = html +
    "          state.ioHistory.unshift({ step: event.step, kind: 'syscall', detail: event.syscall });\n"
  html = html + "        }\n"
  html = html + "        if (event.stdout_append) {\n"
  html = html + "          state.stdout += event.stdout_append;\n"
  html = html +
    "          state.ioHistory.unshift({ step: event.step, kind: 'stdout', detail: event.stdout_append });\n"
  html = html + "        }\n"
  html = html + "        if (event.stderr_append) {\n"
  html = html + "          state.stderr += event.stderr_append;\n"
  html = html +
    "          state.ioHistory.unshift({ step: event.step, kind: 'stderr', detail: event.stderr_append });\n"
  html = html + "        }\n"
  html = html + "        if (state.ioHistory.length > 160) {\n"
  html = html + "          state.ioHistory = state.ioHistory.slice(0, 160);\n"
  html = html + "        }\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function rebuildToCursor(cursor) {\n"
  html = html + "        resetRuntimeState();\n"
  html = html + "        if (cursor < 0) return;\n"
  html = html +
    "        for (let i = 0; i <= cursor && i < data.events.length; i += 1) {\n"
  html = html + "          applyEvent(data.events[i]);\n"
  html = html + "        }\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderExecution() {\n"
  html = html + "        const current = currentEvent();\n"
  html = html +
    "        const target = current || { step: '-', addr: data.runtime.initial_pc, next_addr: '-', block_start: '-', category: '-', stop_reason: data.runtime.stop_reason, asm: '未执行' };\n"
  html = html + "        refs.executionBody.innerHTML = [\n"
  html = html + "          ['step', target.step],\n"
  html = html + "          ['pc', target.addr],\n"
  html = html + "          ['next', target.next_addr || '-'],\n"
  html = html + "          ['block', target.block_start || '-'],\n"
  html = html + "          ['category', target.category || '-'],\n"
  html = html +
    "          ['stop', target.stop_reason || data.runtime.stop_reason || '-'],\n"
  html = html + "          ['asm', target.asm || '-']\n"
  html = html +
    "        ].map(([key, value]) => `<tr><td>${escapeHtml(String(key))}</td><td>${escapeHtml(String(value))}</td></tr>`).join('');\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderToolbarState() {\n"
  html = html + "        refs.prevBtn.disabled = state.cursor < 0;\n"
  html = html + "        refs.resetBtn.disabled = state.cursor < 0;\n"
  html = html +
    "        refs.nextBtn.disabled = state.cursor >= data.events.length - 1;\n"
  html = html +
    "        refs.playBtn.textContent = state.timer ? 'Pause' : 'Play';\n"
  html = html +
    "        refs.followPc.classList.toggle('active', state.followPcEnabled);\n"
  html = html +
    "        refs.currentFunctionOnly.classList.toggle('active', state.currentFunctionOnlyEnabled);\n"
  html = html +
    "        refs.changedRegistersToggle.classList.toggle('active', state.showChangedRegistersOnly);\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderDisasm() {\n"
  html = html + "        const current = currentEvent();\n"
  html = html + "        const viewInstructions = visibleInstructions();\n"
  html = html + "        const currentFn = selectedFunction();\n"
  html = html +
    "        refs.disasmSubtitle.textContent = `${viewInstructions.length} rows | ${state.searchText.trim() ? `search=${state.searchText.trim()}` : 'no filter'}`;\n"
  html = html + "        refs.viewPill.textContent = currentFn\n"
  html = html +
    "          ? `${currentFn.name} ${state.currentFunctionOnlyEnabled ? '(scoped)' : '(selected)'}`\n"
  html = html + "          : 'All instructions';\n"
  html = html +
    "        refs.disasmBody.innerHTML = viewInstructions.length > 0\n"
  html = html + "          ? viewInstructions.map((inst) => {\n"
  html = html +
    "              const active = current && current.addr === inst.addr;\n"
  html = html + "              const focus = state.focusedAddr === inst.addr;\n"
  html = html +
    "              return `<tr data-addr=\"${inst.addr}\" class=\"${active ? 'active' : ''} ${focus && !active ? 'focus' : ''}\"><td>${inst.index}</td><td>${escapeHtml(inst.addr)}</td><td>${escapeHtml(inst.category)}</td><td class=\"code-cell\">${escapeHtml(inst.asm)}</td></tr>`;\n"
  html = html + "            }).join('')\n"
  html = html +
    "          : '<tr><td colspan=\"4\" class=\"empty-panel\">当前过滤条件下没有指令</td></tr>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderCfg() {\n"
  html = html + "        const fn = selectedFunction();\n"
  html = html +
    "        const scopedBlocks = state.currentFunctionOnlyEnabled && fn\n"
  html = html + "          ? data.blocks.filter(block => {\n"
  html = html + "              const range = functionRangeForAddr(fn.addr);\n"
  html = html + "              if (!range) return true;\n"
  html = html + "              const start = hexToBigInt(block.start_addr);\n"
  html = html +
    "              return start >= range.start && start < range.end;\n"
  html = html + "            })\n"
  html = html + "          : data.blocks;\n"
  html = html + "        const current = currentEvent();\n"
  html = html +
    "        const currentAddr = current ? hexToBigInt(current.addr) : null;\n"
  html = html +
    "        const cards = scopedBlocks.slice(0, 180).map(block => {\n"
  html = html + "          const start = hexToBigInt(block.start_addr);\n"
  html = html + "          const end = hexToBigInt(block.end_addr);\n"
  html = html +
    "          const active = currentAddr !== null && currentAddr >= start && currentAddr <= end;\n"
  html = html +
    "          return `<div class=\"cfg-card${active ? ' active' : ''}\"><div class=\"cfg-card-title\">${escapeHtml(block.start_addr)} - ${escapeHtml(block.end_addr)}</div><div class=\"muted\">inst=${block.instruction_count}, term=${block.is_terminated}</div></div>`;\n"
  html = html + "        }).join('');\n"
  html = html + "\n"
  html = html +
    "        const allowedStarts = new Set(scopedBlocks.map(block => block.start_addr));\n"
  html = html +
    "        const edges = data.edges.filter(edge => allowedStarts.size === 0 || allowedStarts.has(edge.from_block) || allowedStarts.has(edge.to_block)).slice(0, 220).map(edge => (\n"
  html = html +
    "          `<tr><td>${escapeHtml(edge.from_block)}</td><td>${escapeHtml(edge.to_block)}</td><td>${escapeHtml(edge.edge_type)}</td></tr>`\n"
  html = html + "        )).join('');\n"
  html = html + "\n"
  html = html +
    "        refs.cfgView.innerHTML = `<div class=\"cfg-grid\">${cards || '<div class=\"empty-panel\">无 CFG block</div>'}</div><table class=\"mono\"><thead><tr><th>from</th><th>to</th><th>edge</th></tr></thead><tbody>${edges || '<tr><td colspan=\"3\" class=\"empty-panel\">无边关系</td></tr>'}</tbody></table>`;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderRegisters() {\n"
  html = html + "        const current = currentEvent();\n"
  html = html +
    "        const changedMap = new Map((current?.register_writes || []).map(delta => [delta.name, delta]));\n"
  html = html + "        const sections = REGISTER_GROUPS.map(group => {\n"
  html = html +
    "          const regs = group.regs.filter(name => !state.showChangedRegistersOnly || changedMap.has(name));\n"
  html = html + "          if (regs.length === 0) {\n"
  html = html + "            return '';\n"
  html = html + "          }\n"
  html = html + "          const rows = regs.map(name => {\n"
  html = html + "            const delta = changedMap.get(name);\n"
  html = html +
    "            const badge = delta ? '<span class=\"badge changed\">changed</span>' : '';\n"
  html = html +
    "            const detail = delta ? `${escapeHtml(delta.before)} -> ${escapeHtml(delta.after)}` : escapeHtml(state.registers[name] || '0x0');\n"
  html = html +
    "            return `<tr><td>${escapeHtml(name)}</td><td>${detail}</td><td>${badge}</td></tr>`;\n"
  html = html + "          }).join('');\n"
  html = html +
    "          return `<div class=\"register-group\"><div class=\"group-title\">${escapeHtml(group.label)}</div><table class=\"register-table mono\"><tbody>${rows}</tbody></table></div>`;\n"
  html = html + "        }).join('');\n"
  html = html +
    "        refs.registerGroups.innerHTML = sections || '<div class=\"empty-panel\">当前 step 没有寄存器变化</div>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderTrace() {\n"
  html = html +
    "        refs.traceBody.innerHTML = (data.events || []).length > 0\n"
  html = html + "          ? data.events.map((event, index) => {\n"
  html = html + "              const active = index === state.cursor;\n"
  html = html + "              const writes = [];\n"
  html = html +
    "              if ((event.register_writes || []).length > 0) writes.push((event.register_writes || []).map(item => item.name).join(', '));\n"
  html = html +
    "              if ((event.memory_writes || []).length > 0) writes.push(`mem x${event.memory_writes.length}`);\n"
  html = html +
    "              const note = [event.syscall, event.stop_reason && event.stop_reason !== 'running' ? event.stop_reason : '', event.stdout_append ? `stdout +${event.stdout_append.length}` : '', event.stderr_append ? `stderr +${event.stderr_append.length}` : ''].filter(Boolean).join(' | ');\n"
  html = html +
    "              return `<tr data-event-index=\"${index}\" class=\"${active ? 'active' : ''}\"><td>${event.step}</td><td>${escapeHtml(event.addr)}</td><td class=\"code-cell\">${escapeHtml(event.asm)}</td><td>${escapeHtml(writes.join(' | ') || '-')}</td><td>${escapeHtml(note || '-')}</td></tr>`;\n"
  html = html + "            }).join('')\n"
  html = html +
    "          : '<tr><td colspan=\"5\" class=\"empty-panel\">暂无轨迹</td></tr>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderMemoryWrites() {\n"
  html = html +
    "        refs.memoryBody.innerHTML = state.memoryHistory.length > 0\n"
  html = html +
    "          ? state.memoryHistory.map(item => `<tr><td>${item.step}</td><td>${escapeHtml(item.addr)}</td><td>${item.size}</td><td>${escapeHtml(item.before)}</td><td>${escapeHtml(item.after)}</td></tr>`).join('')\n"
  html = html +
    "          : '<tr><td colspan=\"5\" class=\"empty-panel\">暂无访存写入</td></tr>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderSyscalls() {\n"
  html = html +
    "        refs.syscallBody.innerHTML = state.ioHistory.length > 0\n"
  html = html +
    "          ? state.ioHistory.map(item => `<tr><td>${item.step}</td><td>${escapeHtml(item.kind)}</td><td class=\"code-cell\">${escapeHtml(item.detail)}</td></tr>`).join('')\n"
  html = html +
    "          : '<tr><td colspan=\"3\" class=\"empty-panel\">暂无 syscall / 输出</td></tr>';\n"
  html = html +
    "        refs.stdoutOutput.textContent = state.stdout || '(empty)';\n"
  html = html +
    "        refs.stderrOutput.textContent = state.stderr || '(empty)';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderTabs() {\n"
  html = html +
    "        document.querySelectorAll('[data-tab]').forEach((element) => {\n"
  html = html +
    "          element.classList.toggle('active', element.getAttribute('data-tab') === state.activeTab);\n"
  html = html + "        });\n"
  html = html +
    "        document.querySelectorAll('[data-tab-panel]').forEach((element) => {\n"
  html = html +
    "          element.classList.toggle('active', element.getAttribute('data-tab-panel') === state.activeTab);\n"
  html = html + "        });\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function applyLayout() {\n"
  html = html + "        const root = document.documentElement;\n"
  html = html +
    "        root.style.setProperty('--nav-width', state.layout.navCollapsed ? '0px' : `${state.layout.navWidth}px`);\n"
  html = html +
    "        root.style.setProperty('--inspector-width', state.layout.inspectorCollapsed ? '0px' : `${state.layout.inspectorWidth}px`);\n"
  html = html +
    "        root.style.setProperty('--bottom-height', state.layout.bottomCollapsed ? '0px' : `${state.layout.bottomHeight}px`);\n"
  html = html +
    "        root.style.setProperty('--nav-split-size', state.layout.navCollapsed ? '0px' : 'var(--splitter-size)');\n"
  html = html +
    "        root.style.setProperty('--inspector-split-size', state.layout.inspectorCollapsed ? '0px' : 'var(--splitter-size)');\n"
  html = html +
    "        root.style.setProperty('--bottom-split-size', state.layout.bottomCollapsed ? '0px' : 'var(--splitter-size)');\n"
  html = html +
    "        refs.navPane.classList.toggle('collapsed-pane', state.layout.navCollapsed && window.innerWidth > 1100);\n"
  html = html +
    "        refs.inspectorPane.classList.toggle('collapsed-pane', state.layout.inspectorCollapsed && window.innerWidth > 1100);\n"
  html = html +
    "        refs.resultPane.classList.toggle('collapsed-pane', state.layout.bottomCollapsed && window.innerWidth > 1100);\n"
  html = html +
    "        refs.navSplitter.classList.toggle('collapsed-pane', state.layout.navCollapsed && window.innerWidth > 1100);\n"
  html = html +
    "        refs.inspectorSplitter.classList.toggle('collapsed-pane', state.layout.inspectorCollapsed && window.innerWidth > 1100);\n"
  html = html +
    "        refs.bottomSplitter.classList.toggle('collapsed-pane', state.layout.bottomCollapsed && window.innerWidth > 1100);\n"
  html = html +
    "        refs.toggleNavPane.textContent = state.layout.navCollapsed ? '展开' : '折叠';\n"
  html = html +
    "        refs.toggleBottomPane.textContent = state.layout.bottomCollapsed ? '展开' : '折叠';\n"
  html = html +
    "        refs.toggleInspectorPane.textContent = state.layout.inspectorCollapsed ? '展开' : '折叠';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function maybeFollowPc() {\n"
  html = html + "        if (!state.followPcEnabled) {\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html + "        const current = currentEvent();\n"
  html = html + "        if (!current) {\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html +
    "        refs.disasmBody.querySelector(`tr[data-addr=\"${current.addr}\"]`)?.scrollIntoView({ block: 'nearest' });\n"
  html = html +
    "        refs.traceBody.querySelector(`tr[data-event-index=\"${state.cursor}\"]`)?.scrollIntoView({ block: 'nearest' });\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderAll() {\n"
  html = html + "        renderSummary();\n"
  html = html + "        renderFunctions();\n"
  html = html + "        renderSections();\n"
  html = html + "        renderRuntimeSummary();\n"
  html = html + "        renderExecution();\n"
  html = html + "        renderToolbarState();\n"
  html = html + "        renderDisasm();\n"
  html = html + "        renderCfg();\n"
  html = html + "        renderRegisters();\n"
  html = html + "        renderTrace();\n"
  html = html + "        renderMemoryWrites();\n"
  html = html + "        renderSyscalls();\n"
  html = html + "        renderTabs();\n"
  html = html + "        applyLayout();\n"
  html = html + "        maybeFollowPc();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function stopPlay() {\n"
  html = html + "        if (!state.timer) {\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html + "        clearInterval(state.timer);\n"
  html = html + "        state.timer = null;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function setCursor(next) {\n"
  html = html +
    "        const clamped = Math.max(-1, Math.min(data.events.length - 1, next));\n"
  html = html + "        if (clamped === state.cursor) {\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html + "        state.cursor = clamped;\n"
  html = html +
    "        state.focusedAddr = clamped >= 0 ? data.events[clamped].addr : data.runtime.initial_pc;\n"
  html = html + "        rebuildToCursor(state.cursor);\n"
  html = html + "        renderAll();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function step(delta) {\n"
  html = html + "        if (data.events.length === 0) return;\n"
  html = html + "        setCursor(state.cursor + delta);\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function togglePlay() {\n"
  html = html + "        if (state.timer) {\n"
  html = html + "          stopPlay();\n"
  html = html + "          renderAll();\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html + "        if (state.cursor >= data.events.length - 1) {\n"
  html = html + "          setCursor(-1);\n"
  html = html + "        }\n"
  html = html + "        state.timer = setInterval(() => {\n"
  html = html + "          if (state.cursor >= data.events.length - 1) {\n"
  html = html + "            stopPlay();\n"
  html = html + "            renderAll();\n"
  html = html + "            return;\n"
  html = html + "          }\n"
  html = html + "          step(1);\n"
  html = html + "        }, 350);\n"
  html = html + "        renderAll();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function selectFunctionByAddr(addr) {\n"
  html = html + "        state.selectedFunctionAddr = addr || '';\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html +
    "      function bindSplitter(handle, axis, direction, getValue, setValue, getBounds) {\n"
  html = html +
    "        handle.addEventListener('mousedown', (downEvent) => {\n"
  html = html + "          if (window.innerWidth <= 1100) {\n"
  html = html + "            return;\n"
  html = html + "          }\n"
  html = html + "          downEvent.preventDefault();\n"
  html = html +
    "          const startPosition = axis === 'x' ? downEvent.clientX : downEvent.clientY;\n"
  html = html + "          const startValue = getValue();\n"
  html = html + "          const onMove = (moveEvent) => {\n"
  html = html +
    "            const currentPosition = axis === 'x' ? moveEvent.clientX : moveEvent.clientY;\n"
  html = html +
    "            const delta = (currentPosition - startPosition) * direction;\n"
  html = html + "            const [min, max] = getBounds();\n"
  html = html + "            setValue(clamp(startValue + delta, min, max));\n"
  html = html + "            applyLayout();\n"
  html = html + "            saveUiState();\n"
  html = html + "          };\n"
  html = html + "          const onUp = () => {\n"
  html = html + "            window.removeEventListener('mousemove', onMove);\n"
  html = html + "            window.removeEventListener('mouseup', onUp);\n"
  html = html + "          };\n"
  html = html + "          window.addEventListener('mousemove', onMove);\n"
  html = html + "          window.addEventListener('mouseup', onUp);\n"
  html = html + "        });\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html +
    "      refs.functionList.addEventListener('click', (event) => {\n"
  html = html + "        const row = event.target.closest('[data-fn-addr]');\n"
  html = html + "        if (!row) return;\n"
  html = html +
    "        selectFunctionByAddr(row.getAttribute('data-fn-addr') || '');\n"
  html = html + "      });\n"
  html = html +
    "      refs.sectionList.addEventListener('click', (event) => {\n"
  html = html +
    "        const row = event.target.closest('[data-section-query]');\n"
  html = html + "        if (!row) return;\n"
  html = html +
    "        state.searchText = row.getAttribute('data-section-query') || '';\n"
  html = html + "        refs.searchInput.value = state.searchText;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html + "      refs.disasmBody.addEventListener('click', (event) => {\n"
  html = html + "        const row = event.target.closest('tr[data-addr]');\n"
  html = html + "        if (!row) return;\n"
  html = html + "        const addr = row.getAttribute('data-addr') || '';\n"
  html = html + "        state.focusedAddr = addr;\n"
  html = html + "        if (EVENT_INDEX_BY_ADDR.has(addr)) {\n"
  html = html + "          setCursor(EVENT_INDEX_BY_ADDR.get(addr));\n"
  html = html + "        } else {\n"
  html = html + "          renderAll();\n"
  html = html + "        }\n"
  html = html + "      });\n"
  html = html + "      refs.traceBody.addEventListener('click', (event) => {\n"
  html = html +
    "        const row = event.target.closest('tr[data-event-index]');\n"
  html = html + "        if (!row) return;\n"
  html = html +
    "        setCursor(Number(row.getAttribute('data-event-index')));\n"
  html = html + "      });\n"
  html = html + "      refs.paneTabs.addEventListener('click', (event) => {\n"
  html = html + "        const button = event.target.closest('[data-tab]');\n"
  html = html + "        if (!button) return;\n"
  html = html +
    "        state.activeTab = button.getAttribute('data-tab') || 'trace';\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderTabs();\n"
  html = html + "      });\n"
  html = html +
    "      refs.functionSelect.addEventListener('change', (event) => {\n"
  html = html + "        const value = event.target.value;\n"
  html = html +
    "        selectFunctionByAddr(value === '__all__' ? '' : value);\n"
  html = html + "      });\n"
  html = html +
    "      refs.searchInput.addEventListener('input', (event) => {\n"
  html = html + "        state.searchText = event.target.value;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html + "      refs.resetBtn.addEventListener('click', () => {\n"
  html = html + "        stopPlay();\n"
  html = html + "        setCursor(-1);\n"
  html = html + "      });\n"
  html = html +
    "      refs.prevBtn.addEventListener('click', () => step(-1));\n"
  html = html + "      refs.nextBtn.addEventListener('click', () => step(1));\n"
  html = html + "      refs.playBtn.addEventListener('click', togglePlay);\n"
  html = html + "      refs.followPc.addEventListener('click', () => {\n"
  html = html + "        state.followPcEnabled = !state.followPcEnabled;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html +
    "      refs.currentFunctionOnly.addEventListener('click', () => {\n"
  html = html + "        if (!state.selectedFunctionAddr) {\n"
  html = html +
    "          const inferred = functionForAddress(currentEvent() ? currentEvent().addr : data.runtime.initial_pc);\n"
  html = html +
    "          state.selectedFunctionAddr = inferred ? inferred.addr : '';\n"
  html = html + "        }\n"
  html = html +
    "        state.currentFunctionOnlyEnabled = !state.currentFunctionOnlyEnabled;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html +
    "      refs.changedRegistersToggle.addEventListener('click', () => {\n"
  html = html +
    "        state.showChangedRegistersOnly = !state.showChangedRegistersOnly;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html + "      refs.toggleNavPane.addEventListener('click', () => {\n"
  html = html +
    "        state.layout.navCollapsed = !state.layout.navCollapsed;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html +
    "      refs.toggleBottomPane.addEventListener('click', () => {\n"
  html = html +
    "        state.layout.bottomCollapsed = !state.layout.bottomCollapsed;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html +
    "      refs.toggleInspectorPane.addEventListener('click', () => {\n"
  html = html +
    "        state.layout.inspectorCollapsed = !state.layout.inspectorCollapsed;\n"
  html = html + "        saveUiState();\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html +
    "      bindSplitter(refs.navSplitter, 'x', 1, () => state.layout.navWidth, (value) => { state.layout.navWidth = value; }, () => [180, Math.max(220, Math.floor(window.innerWidth * 0.35))]);\n"
  html = html +
    "      bindSplitter(refs.inspectorSplitter, 'x', -1, () => state.layout.inspectorWidth, (value) => { state.layout.inspectorWidth = value; }, () => [240, Math.max(280, Math.floor(window.innerWidth * 0.42))]);\n"
  html = html +
    "      bindSplitter(refs.bottomSplitter, 'y', -1, () => state.layout.bottomHeight, (value) => { state.layout.bottomHeight = value; }, () => [180, Math.max(240, Math.floor(window.innerHeight * 0.55))]);\n"
  html = html + "      window.addEventListener('resize', applyLayout);\n"
  html = html + "\n"
  html = html + "      refs.title.textContent = data.meta.title;\n"
  html = html +
    "      refs.source.textContent = `${data.meta.source_file} | ${data.meta.file_class} ${data.meta.architecture}`;\n"
  html = html + "      if (data.meta.truncated) {\n"
  html = html + "        refs.truncatedBanner.style.display = 'block';\n"
  html = html +
    "        refs.truncatedBanner.textContent = `当前页面仅展示前 ${data.meta.instruction_count} 条指令（总计 ${data.meta.total_instruction_count} 条）。可通过 CLI 参数 --max-inst 调整。`;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      resetRuntimeState();\n"
  html = html +
    "      if (state.selectedFunctionAddr && !(data.functions || []).some(fn => fn.addr === state.selectedFunctionAddr)) {\n"
  html = html + "        state.selectedFunctionAddr = '';\n"
  html = html + "      }\n"
  html = html + "      rebuildToCursor(state.cursor);\n"
  html = html + "      renderAll();\n"
  html = html + "    })();\n"
  html = html + "  </script>\n"
  html = html + "</body>\n"
  html = html + "</html>\n"
  html
}

///|
fn read_file_bytes(path : String) -> FixedArray[Byte]? {
  if !@fs.path_exists(path) {
    None
  } else {
    try {
      let bytes = @fs.read_file_to_bytes(path)
      Some(bytes.to_fixedarray())
    } catch {
      _ => None
    }
  }
}

///|
fn write_output_file(path : String, content : String) -> Bool {
  try {
    @fs.write_string_to_file(path, content)
    true
  } catch {
    _ => false
  }
}

///|
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut v = value
    while v > 0U {
      let digit = (v % 16U).reinterpret_as_int()
      let ch = if digit < 10 {
        (digit + 48).unsafe_to_char()
      } else {
        (digit + 87).unsafe_to_char()
      }
      result = ch.to_string() + result
      v = v / 16U
    }
    result
  }
}

///|
fn format_hex(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
fn parse_hex_uint(value : String) -> UInt? {
  if value.length() < 3 {
    return None
  }
  if value[0] != '0' || (value[1] != 'x' && value[1] != 'X') {
    return None
  }

  let mut result : UInt = 0U
  for i = 2; i < value.length(); i = i + 1 {
    let c = value[i]
    let digit = match c {
      '0' => Some(0U)
      '1' => Some(1U)
      '2' => Some(2U)
      '3' => Some(3U)
      '4' => Some(4U)
      '5' => Some(5U)
      '6' => Some(6U)
      '7' => Some(7U)
      '8' => Some(8U)
      '9' => Some(9U)
      'a' | 'A' => Some(10U)
      'b' | 'B' => Some(11U)
      'c' | 'C' => Some(12U)
      'd' | 'D' => Some(13U)
      'e' | 'E' => Some(14U)
      'f' | 'F' => Some(15U)
      _ => None
    }
    match digit {
      Some(v) => result = result * 16U + v
      None => return None
    }
  }
  Some(result)
}
