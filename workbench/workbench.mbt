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
struct WorkbenchData {
  meta : WorkbenchMeta
  functions : Array[WorkbenchFunction]
  sections : Array[WorkbenchSection]
  instructions : Array[WorkbenchInstruction]
  blocks : Array[WorkbenchBlock]
  edges : Array[WorkbenchEdge]
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
      StreamEventsOk(
        build_stream_event_payloads(data.instructions, data.blocks, event_limit),
      )
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
            truncated: shown_count < all_instructions.length(),
          }

          Ok({ meta, functions, sections, instructions, blocks, edges })
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
  instructions : Array[WorkbenchInstruction],
  blocks : Array[WorkbenchBlock],
  max_events : Int,
) -> Array[String] {
  let payloads : Array[String] = []
  let limit = if instructions.length() < max_events {
    instructions.length()
  } else {
    max_events
  }
  for i = 0; i < limit; i = i + 1 {
    let inst = instructions[i]
    let block_start = find_block_start_for_addr(blocks, inst.addr)
    let trace = inst.addr + ": " + inst.asm_text
    let mut json = "{"
    json = json + "\"step\":" + i.to_string()
    json = json + ",\"addr\":" + json_string(inst.addr)
    json = json + ",\"asm\":" + json_string(inst.asm_text)
    json = json + ",\"category\":" + json_string(inst.category)
    json = json + ",\"block_start\":" + json_string(block_start)
    json = json + ",\"trace\":" + json_string(trace)
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
  html = html + "      --bg: #f4f6fb;\n"
  html = html + "      --ink: #0b1328;\n"
  html = html + "      --muted: #5d6a85;\n"
  html = html + "      --panel: #ffffff;\n"
  html = html + "      --line: #d6deec;\n"
  html = html + "      --accent: #0f766e;\n"
  html = html + "      --accent-soft: #dcf4f2;\n"
  html = html + "      --warning: #92400e;\n"
  html = html + "      --shadow: 0 8px 24px rgba(19, 35, 79, 0.08);\n"
  html = html + "    }\n"
  html = html + "    * { box-sizing: border-box; }\n"
  html = html + "    body {\n"
  html = html + "      margin: 0;\n"
  html = html +
    "      font-family: \"SFMono-Regular\", \"Iosevka\", \"JetBrains Mono\", monospace;\n"
  html = html +
    "      background: radial-gradient(circle at 8% 10%, #f5fbff 0%, var(--bg) 42%, #eef2ff 100%);\n"
  html = html + "      color: var(--ink);\n"
  html = html + "    }\n"
  html = html + "    .app {\n"
  html = html + "      display: grid;\n"
  html = html + "      grid-template-rows: auto 1fr auto;\n"
  html = html + "      min-height: 100vh;\n"
  html = html + "      gap: 10px;\n"
  html = html + "      padding: 10px;\n"
  html = html + "    }\n"
  html = html + "    .panel {\n"
  html = html + "      background: var(--panel);\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      border-radius: 14px;\n"
  html = html + "      box-shadow: var(--shadow);\n"
  html = html + "    }\n"
  html = html + "    .toolbar {\n"
  html = html + "      display: flex;\n"
  html = html + "      align-items: flex-start;\n"
  html = html + "      justify-content: space-between;\n"
  html = html + "      gap: 12px;\n"
  html = html + "      padding: 12px 14px;\n"
  html = html + "    }\n"
  html = html + "    .toolbar h1 {\n"
  html = html + "      margin: 0 0 4px 0;\n"
  html = html + "      font-size: 18px;\n"
  html = html + "      line-height: 1.25;\n"
  html = html + "    }\n"
  html = html + "    .toolbar .sub {\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-size: 12px;\n"
  html = html + "      max-width: 760px;\n"
  html = html + "      word-break: break-all;\n"
  html = html + "    }\n"
  html = html + "    .controls {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-columns: minmax(220px, 1fr) repeat(4, auto);\n"
  html = html + "      gap: 8px;\n"
  html = html + "      align-items: center;\n"
  html = html + "      min-width: min(100%, 680px);\n"
  html = html + "    }\n"
  html = html + "    button, select {\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      border-radius: 10px;\n"
  html = html + "      background: #fff;\n"
  html = html + "      padding: 8px 10px;\n"
  html = html + "      color: var(--ink);\n"
  html = html +
    "      font-family: \"SFMono-Regular\", \"Iosevka\", \"JetBrains Mono\", monospace;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "      cursor: pointer;\n"
  html = html + "    }\n"
  html = html + "    button.primary {\n"
  html = html + "      background: var(--accent);\n"
  html = html + "      color: #fff;\n"
  html = html + "      border-color: var(--accent);\n"
  html = html + "    }\n"
  html = html + "    .main {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-columns: minmax(220px, 260px) 1fr minmax(240px, 300px);\n"
  html = html + "      gap: 10px;\n"
  html = html + "      min-height: 0;\n"
  html = html + "    }\n"
  html = html + "    .pane {\n"
  html = html + "      display: flex;\n"
  html = html + "      flex-direction: column;\n"
  html = html + "      min-height: 0;\n"
  html = html + "      overflow: hidden;\n"
  html = html + "    }\n"
  html = html + "    .pane h2 {\n"
  html = html + "      margin: 0;\n"
  html = html + "      padding: 10px 12px;\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      font-size: 13px;\n"
  html = html + "      letter-spacing: 0.4px;\n"
  html = html +
    "      background: linear-gradient(180deg, #ffffff 0%, #f9fbff 100%);\n"
  html = html + "    }\n"
  html = html + "    .pane .scroll {\n"
  html = html + "      overflow: auto;\n"
  html = html + "      min-height: 0;\n"
  html = html + "      padding: 8px;\n"
  html = html + "    }\n"
  html = html + "    .function-item {\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      border-radius: 8px;\n"
  html = html + "      padding: 6px 8px;\n"
  html = html + "      margin-bottom: 6px;\n"
  html = html + "      cursor: pointer;\n"
  html = html + "      background: #fff;\n"
  html = html + "    }\n"
  html = html + "    .function-item.active {\n"
  html = html + "      border-color: var(--accent);\n"
  html = html + "      background: var(--accent-soft);\n"
  html = html + "    }\n"
  html = html + "    .summary-grid {\n"
  html = html + "      display: grid;\n"
  html = html + "      grid-template-columns: repeat(2, minmax(0, 1fr));\n"
  html = html + "      gap: 6px;\n"
  html = html + "      margin-bottom: 8px;\n"
  html = html + "    }\n"
  html = html + "    .stat {\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      border-radius: 8px;\n"
  html = html + "      padding: 6px;\n"
  html = html + "      background: #fff;\n"
  html = html + "    }\n"
  html = html + "    .stat .k { color: var(--muted); font-size: 11px; }\n"
  html = html + "    .stat .v { font-size: 13px; margin-top: 4px; }\n"
  html = html + "    .center {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-rows: minmax(260px, 1fr) minmax(220px, 1fr);\n"
  html = html + "      gap: 10px;\n"
  html = html + "      min-height: 0;\n"
  html = html + "    }\n"
  html = html + "    table {\n"
  html = html + "      width: 100%;\n"
  html = html + "      border-collapse: collapse;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "    }\n"
  html = html + "    th, td {\n"
  html = html + "      border-bottom: 1px solid var(--line);\n"
  html = html + "      padding: 5px 6px;\n"
  html = html + "      text-align: left;\n"
  html = html + "      vertical-align: top;\n"
  html = html + "    }\n"
  html = html + "    tr.active td {\n"
  html = html + "      background: #fff8db;\n"
  html = html + "    }\n"
  html = html + "    tr:hover td {\n"
  html = html + "      background: #f5f8ff;\n"
  html = html + "    }\n"
  html = html + "    .cfg-grid {\n"
  html = html + "      display: grid;\n"
  html = html +
    "      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));\n"
  html = html + "      gap: 8px;\n"
  html = html + "      margin-bottom: 10px;\n"
  html = html + "    }\n"
  html = html + "    .cfg-block {\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      border-radius: 10px;\n"
  html = html + "      padding: 7px;\n"
  html = html + "      background: #fff;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "    }\n"
  html = html + "    .cfg-block.active {\n"
  html = html + "      border-color: var(--accent);\n"
  html = html + "      box-shadow: 0 0 0 2px var(--accent-soft) inset;\n"
  html = html + "    }\n"
  html = html + "    .edge-list {\n"
  html = html + "      margin: 0;\n"
  html = html + "      padding-left: 18px;\n"
  html = html + "      color: var(--muted);\n"
  html = html + "      font-size: 12px;\n"
  html = html + "    }\n"
  html = html + "    .reg-grid {\n"
  html = html + "      display: grid;\n"
  html = html + "      grid-template-columns: repeat(2, minmax(0, 1fr));\n"
  html = html + "      gap: 6px;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "    }\n"
  html = html + "    .reg {\n"
  html = html + "      border: 1px solid var(--line);\n"
  html = html + "      border-radius: 8px;\n"
  html = html + "      padding: 6px;\n"
  html = html + "      background: #fff;\n"
  html = html + "    }\n"
  html = html + "    .reg .name { color: var(--muted); font-size: 11px; }\n"
  html = html + "    .reg .value { font-size: 12px; margin-top: 4px; }\n"
  html = html + "    .trace {\n"
  html = html + "      min-height: 160px;\n"
  html = html + "      max-height: 220px;\n"
  html = html + "      overflow: auto;\n"
  html = html + "      padding: 8px;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "    }\n"
  html = html + "    .trace-item {\n"
  html = html + "      border-left: 3px solid var(--accent);\n"
  html = html + "      padding: 5px 8px;\n"
  html = html + "      margin-bottom: 5px;\n"
  html = html + "      background: #f8fcfb;\n"
  html = html + "      border-radius: 6px;\n"
  html = html + "    }\n"
  html = html + "    .warning {\n"
  html = html + "      margin: 0 8px 8px;\n"
  html = html + "      border: 1px solid #f4c483;\n"
  html = html + "      background: #fff7ea;\n"
  html = html + "      color: var(--warning);\n"
  html = html + "      border-radius: 8px;\n"
  html = html + "      padding: 7px 9px;\n"
  html = html + "      font-size: 12px;\n"
  html = html + "    }\n"
  html = html + "    @media (max-width: 1100px) {\n"
  html = html + "      .main {\n"
  html = html + "        grid-template-columns: 1fr;\n"
  html = html + "      }\n"
  html = html + "      .center {\n"
  html = html +
    "        grid-template-rows: minmax(220px, 1fr) minmax(220px, 1fr);\n"
  html = html + "      }\n"
  html = html + "      .controls {\n"
  html = html + "        grid-template-columns: repeat(2, minmax(0, 1fr));\n"
  html = html + "      }\n"
  html = html + "    }\n"
  html = html + "  </style>\n"
  html = html + "</head>\n"
  html = html + "<body>\n"
  html = html + "  <div class=\"app\">\n"
  html = html + "    <header class=\"toolbar panel\">\n"
  html = html + "      <div>\n"
  html = html + "        <h1 id=\"title\"></h1>\n"
  html = html + "        <div class=\"sub\" id=\"source\"></div>\n"
  html = html + "      </div>\n"
  html = html + "      <div class=\"controls\">\n"
  html = html + "        <select id=\"function-select\"></select>\n"
  html = html + "        <button id=\"reset-btn\">重置</button>\n"
  html = html + "        <button id=\"prev-btn\">上一步</button>\n"
  html = html +
    "        <button id=\"next-btn\" class=\"primary\">下一步</button>\n"
  html = html + "        <button id=\"play-btn\">自动播放</button>\n"
  html = html + "      </div>\n"
  html = html + "    </header>\n"
  html = html + "    <div class=\"main\">\n"
  html = html + "      <aside class=\"pane panel\">\n"
  html = html + "        <h2>导航与摘要</h2>\n"
  html = html + "        <div class=\"scroll\">\n"
  html = html +
    "          <div class=\"summary-grid\" id=\"summary-grid\"></div>\n"
  html = html + "          <h3>函数列表</h3>\n"
  html = html + "          <div id=\"function-list\"></div>\n"
  html = html + "          <h3>节区</h3>\n"
  html = html + "          <div id=\"section-list\"></div>\n"
  html = html + "        </div>\n"
  html = html + "      </aside>\n"
  html = html + "      <section class=\"center\">\n"
  html = html + "        <div class=\"pane panel\">\n"
  html = html + "          <h2>反汇编视图</h2>\n"
  html = html +
    "          <div id=\"truncated-banner\" class=\"warning\" style=\"display:none\"></div>\n"
  html = html + "          <div class=\"scroll\">\n"
  html = html + "            <table>\n"
  html = html + "              <thead>\n"
  html = html +
    "                <tr><th>#</th><th>地址</th><th>指令</th><th>分类</th></tr>\n"
  html = html + "              </thead>\n"
  html = html + "              <tbody id=\"disasm-body\"></tbody>\n"
  html = html + "            </table>\n"
  html = html + "          </div>\n"
  html = html + "        </div>\n"
  html = html + "        <div class=\"pane panel\">\n"
  html = html + "          <h2>CFG 视图</h2>\n"
  html = html + "          <div class=\"scroll\" id=\"cfg-view\"></div>\n"
  html = html + "        </div>\n"
  html = html + "      </section>\n"
  html = html + "      <aside class=\"pane panel\">\n"
  html = html + "        <h2>状态面板</h2>\n"
  html = html + "        <div class=\"scroll\">\n"
  html = html +
    "          <div class=\"summary-grid\" id=\"runtime-summary\"></div>\n"
  html = html + "          <h3>寄存器（教学模拟）</h3>\n"
  html = html +
    "          <div class=\"reg-grid\" id=\"register-grid\"></div>\n"
  html = html + "          <h3>最近访存事件</h3>\n"
  html = html + "          <ul class=\"edge-list\" id=\"memory-events\"></ul>\n"
  html = html + "          <h3>调用栈摘要</h3>\n"
  html = html + "          <ul class=\"edge-list\" id=\"call-stack\"></ul>\n"
  html = html + "        </div>\n"
  html = html + "      </aside>\n"
  html = html + "    </div>\n"
  html = html + "    <footer class=\"panel\">\n"
  html = html +
    "      <h2 style=\"margin:0;padding:10px 12px;border-bottom:1px solid var(--line);font-size:13px;\">执行轨迹</h2>\n"
  html = html + "      <div class=\"trace\" id=\"trace\"></div>\n"
  html = html + "    </footer>\n"
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
  html = html +
    "        summaryGrid: document.getElementById('summary-grid'),\n"
  html = html +
    "        runtimeSummary: document.getElementById('runtime-summary'),\n"
  html = html +
    "        functionSelect: document.getElementById('function-select'),\n"
  html = html +
    "        functionList: document.getElementById('function-list'),\n"
  html = html +
    "        sectionList: document.getElementById('section-list'),\n"
  html = html + "        disasmBody: document.getElementById('disasm-body'),\n"
  html = html + "        cfgView: document.getElementById('cfg-view'),\n"
  html = html +
    "        registerGrid: document.getElementById('register-grid'),\n"
  html = html +
    "        memoryEvents: document.getElementById('memory-events'),\n"
  html = html + "        callStack: document.getElementById('call-stack'),\n"
  html = html + "        trace: document.getElementById('trace'),\n"
  html = html +
    "        truncatedBanner: document.getElementById('truncated-banner'),\n"
  html = html + "        resetBtn: document.getElementById('reset-btn'),\n"
  html = html + "        prevBtn: document.getElementById('prev-btn'),\n"
  html = html + "        nextBtn: document.getElementById('next-btn'),\n"
  html = html + "        playBtn: document.getElementById('play-btn')\n"
  html = html + "      };\n"
  html = html + "\n"
  html = html + "      const REGISTER_ORDER = [\n"
  html = html +
    "        'zero','ra','sp','gp','tp','t0','t1','t2','s0','s1','a0','a1','a2','a3','a4','a5','a6','a7',\n"
  html = html +
    "        's2','s3','s4','s5','s6','s7','s8','s9','s10','s11','t3','t4','t5','t6'\n"
  html = html + "      ];\n"
  html = html + "\n"
  html = html + "      const state = {\n"
  html = html + "        selectedFunction: null,\n"
  html = html + "        viewInstructions: data.instructions.slice(),\n"
  html = html + "        cursor: data.instructions.length() > 0 ? 0 : -1,\n"
  html = html + "        registers: {},\n"
  html = html + "        memoryEvents: [],\n"
  html = html + "        trace: [],\n"
  html = html + "        callStack: [],\n"
  html = html + "        timer: null\n"
  html = html + "      };\n"
  html = html + "\n"
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
  html = html + "      function resetRuntimeState() {\n"
  html = html + "        state.registers = {};\n"
  html = html + "        for (const r of REGISTER_ORDER) {\n"
  html = html + "          state.registers[r] = '0x0';\n"
  html = html + "        }\n"
  html = html + "        state.memoryEvents = [];\n"
  html = html + "        state.trace = [];\n"
  html = html + "        state.callStack = [];\n"
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
  html = html +
    "        const current = state.cursor >= 0 ? state.viewInstructions[state.cursor] : null;\n"
  html = html + "        refs.runtimeSummary.innerHTML = [\n"
  html = html + "          ['PC', current ? current.addr : 'N/A'],\n"
  html = html +
    "          ['游标', current ? `${state.cursor + 1}/${state.viewInstructions.length}` : '0/0'],\n"
  html = html +
    "          ['模式', state.timer ? '自动播放' : '单步'],\n"
  html = html + "          ['轨迹事件', state.trace.length]\n"
  html = html +
    "        ].map(([k, v]) => `<div class=\"stat\"><div class=\"k\">${escapeHtml(k)}</div><div class=\"v\">${escapeHtml(v)}</div></div>`).join('');\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderSections() {\n"
  html = html +
    "        refs.sectionList.innerHTML = data.sections.map(section => (\n"
  html = html +
    "          `<div class=\"function-item\"><div>#${section.index} ${escapeHtml(section.name)}</div><div class=\"sub\">${escapeHtml(section.addr)} / ${escapeHtml(section.size)}</div></div>`\n"
  html = html + "        )).join('');\n"
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
    "        refs.functionList.innerHTML = data.functions.map(fn => (\n"
  html = html +
    "          `<div class=\"function-item\" data-addr=\"${fn.addr}\"><div>${escapeHtml(fn.name)}</div><div class=\"sub\">${escapeHtml(fn.addr)} / ${escapeHtml(fn.size)}</div></div>`\n"
  html = html + "        )).join('');\n"
  html = html + "\n"
  html = html +
    "        refs.functionList.querySelectorAll('.function-item').forEach((element) => {\n"
  html = html + "          element.addEventListener('click', () => {\n"
  html = html + "            const addr = element.getAttribute('data-addr');\n"
  html = html +
    "            const target = data.functions.find(x => x.addr === addr);\n"
  html = html + "            selectFunction(target ?? null);\n"
  html = html + "          });\n"
  html = html + "        });\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function instructionsForFunction(target) {\n"
  html = html + "        if (!target) {\n"
  html = html + "          return data.instructions.slice();\n"
  html = html + "        }\n"
  html = html + "        const start = hexToBigInt(target.addr);\n"
  html = html + "        const size = hexToBigInt(target.size || '0x0');\n"
  html = html + "        if (size > 0n) {\n"
  html = html + "          const end = start + size;\n"
  html = html + "          const exact = data.instructions.filter(inst => {\n"
  html = html + "            const addr = hexToBigInt(inst.addr);\n"
  html = html + "            return addr >= start && addr < end;\n"
  html = html + "          });\n"
  html = html + "          if (exact.length > 0) {\n"
  html = html + "            return exact;\n"
  html = html + "          }\n"
  html = html + "        }\n"
  html = html +
    "        const nearest = data.instructions.findIndex(inst => hexToBigInt(inst.addr) >= start);\n"
  html = html +
    "        const begin = nearest >= 0 ? Math.max(0, nearest - 10) : 0;\n"
  html = html +
    "        return data.instructions.slice(begin, Math.min(data.instructions.length, begin + 120));\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function selectFunction(target) {\n"
  html = html + "        state.selectedFunction = target;\n"
  html = html +
    "        state.viewInstructions = instructionsForFunction(target);\n"
  html = html +
    "        state.cursor = state.viewInstructions.length > 0 ? 0 : -1;\n"
  html = html +
    "        refs.functionSelect.value = target ? target.addr : '__all__';\n"
  html = html +
    "        refs.functionList.querySelectorAll('.function-item').forEach((element) => {\n"
  html = html +
    "          const selected = target && element.getAttribute('data-addr') === target.addr;\n"
  html = html + "          element.classList.toggle('active', !!selected);\n"
  html = html + "        });\n"
  html = html + "        rebuildToCursor(state.cursor);\n"
  html = html + "        renderAll();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function parseInstruction(inst) {\n"
  html = html + "        const parts = inst.asm.trim().split(/\\s+/, 2);\n"
  html = html + "        const mnemonic = parts[0] || '';\n"
  html = html + "        const operands = parts.length > 1\n"
  html = html +
    "          ? parts[1].split(',').map(x => x.trim()).filter(Boolean)\n"
  html = html + "          : [];\n"
  html = html + "        return { mnemonic, operands };\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function inferDestRegister(mnemonic, operands) {\n"
  html = html + "        if (operands.length === 0) return null;\n"
  html = html +
    "        const stores = new Set(['sb','sh','sw','sd','fsw','fsd','c.sw','c.sd']);\n"
  html = html +
    "        const noWrite = new Set(['ret','ecall','ebreak','fence','fence.i']);\n"
  html = html +
    "        if (stores.has(mnemonic) || noWrite.has(mnemonic)) return null;\n"
  html = html + "        if (mnemonic.startsWith('b')) return null;\n"
  html = html + "        const dest = operands[0].replace(/[()]/g, '');\n"
  html = html + "        if (!dest) return null;\n"
  html = html + "        return dest;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function applyInstruction(inst) {\n"
  html = html +
    "        const { mnemonic, operands } = parseInstruction(inst);\n"
  html = html + "        const dest = inferDestRegister(mnemonic, operands);\n"
  html = html + "        if (dest && dest !== 'zero' && dest !== 'x0') {\n"
  html = html + "          state.registers[dest] = inst.addr;\n"
  html = html + "        }\n"
  html = html +
    "        if (mnemonic.includes('w') || mnemonic.includes('d')) {\n"
  html = html +
    "          if (['sw','sd','sb','sh','c.sw','c.sd','fsw','fsd'].includes(mnemonic)) {\n"
  html = html +
    "            state.memoryEvents.unshift(`${inst.addr}: ${inst.asm}`);\n"
  html = html +
    "            if (state.memoryEvents.length > 14) state.memoryEvents.pop();\n"
  html = html + "          }\n"
  html = html + "        }\n"
  html = html +
    "        if (mnemonic === 'jal' || mnemonic === 'call' || mnemonic === 'c.jal') {\n"
  html = html +
    "          state.callStack.unshift(`${inst.addr} -> ${operands.length > 1 ? operands[1] : 'target'}`);\n"
  html = html +
    "          if (state.callStack.length > 8) state.callStack.pop();\n"
  html = html + "        }\n"
  html = html +
    "        if (mnemonic === 'ret' || (mnemonic === 'jalr' && inst.asm.includes('zero, ra'))) {\n"
  html = html +
    "          if (state.callStack.length > 0) state.callStack.shift();\n"
  html = html + "        }\n"
  html = html + "        state.trace.unshift(`${inst.addr}: ${inst.asm}`);\n"
  html = html + "        if (state.trace.length > 60) state.trace.pop();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function rebuildToCursor(cursor) {\n"
  html = html + "        resetRuntimeState();\n"
  html = html + "        if (cursor < 0) return;\n"
  html = html +
    "        for (let i = 0; i <= cursor && i < state.viewInstructions.length; i += 1) {\n"
  html = html + "          applyInstruction(state.viewInstructions[i]);\n"
  html = html + "        }\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderDisasm() {\n"
  html = html +
    "        refs.disasmBody.innerHTML = state.viewInstructions.map((inst, index) => {\n"
  html = html +
    "          const active = index === state.cursor ? ' class=\"active\"' : '';\n"
  html = html +
    "          return `<tr data-index=\"${index}\"${active}><td>${index}</td><td>${escapeHtml(inst.addr)}</td><td>${escapeHtml(inst.asm)}</td><td>${escapeHtml(inst.category)}</td></tr>`;\n"
  html = html + "        }).join('');\n"
  html = html +
    "        refs.disasmBody.querySelectorAll('tr').forEach((tr) => {\n"
  html = html + "          tr.addEventListener('click', () => {\n"
  html = html +
    "            const index = Number(tr.getAttribute('data-index'));\n"
  html = html + "            if (!Number.isNaN(index)) {\n"
  html = html + "              state.cursor = index;\n"
  html = html + "              rebuildToCursor(state.cursor);\n"
  html = html + "              renderAll();\n"
  html = html + "            }\n"
  html = html + "          });\n"
  html = html + "        });\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderCfg() {\n"
  html = html + "        const blocks = data.blocks;\n"
  html = html +
    "        const current = state.cursor >= 0 ? state.viewInstructions[state.cursor] : null;\n"
  html = html +
    "        const currentAddr = current ? hexToBigInt(current.addr) : null;\n"
  html = html + "        const cards = blocks.slice(0, 180).map(block => {\n"
  html = html + "          const start = hexToBigInt(block.start_addr);\n"
  html = html + "          const end = hexToBigInt(block.end_addr);\n"
  html = html +
    "          const active = currentAddr !== null && currentAddr >= start && currentAddr <= end;\n"
  html = html +
    "          return `<div class=\"cfg-block${active ? ' active' : ''}\"><div>${escapeHtml(block.start_addr)} - ${escapeHtml(block.end_addr)}</div><div class=\"sub\">inst=${block.instruction_count}, term=${block.is_terminated}</div></div>`;\n"
  html = html + "        }).join('');\n"
  html = html + "\n"
  html = html + "        const edges = data.edges.slice(0, 220).map(edge => (\n"
  html = html +
    "          `<li>${escapeHtml(edge.from_block)} -> ${escapeHtml(edge.to_block)} [${escapeHtml(edge.edge_type)}]</li>`\n"
  html = html + "        )).join('');\n"
  html = html + "\n"
  html = html +
    "        refs.cfgView.innerHTML = `<div class=\"cfg-grid\">${cards}</div><h3>边关系</h3><ul class=\"edge-list\">${edges || '<li>无</li>'}</ul>`;\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderRegisters() {\n"
  html = html +
    "        refs.registerGrid.innerHTML = REGISTER_ORDER.map(name => {\n"
  html = html + "          const value = state.registers[name] || '0x0';\n"
  html = html +
    "          return `<div class=\"reg\"><div class=\"name\">${escapeHtml(name)}</div><div class=\"value\">${escapeHtml(value)}</div></div>`;\n"
  html = html + "        }).join('');\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderMemoryAndCalls() {\n"
  html = html +
    "        refs.memoryEvents.innerHTML = state.memoryEvents.length > 0\n"
  html = html +
    "          ? state.memoryEvents.map(item => `<li>${escapeHtml(item)}</li>`).join('')\n"
  html = html + "          : '<li>暂无访存写事件</li>';\n"
  html = html +
    "        refs.callStack.innerHTML = state.callStack.length > 0\n"
  html = html +
    "          ? state.callStack.map(item => `<li>${escapeHtml(item)}</li>`).join('')\n"
  html = html + "          : '<li>暂无调用轨迹</li>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderTrace() {\n"
  html = html + "        refs.trace.innerHTML = state.trace.length > 0\n"
  html = html +
    "          ? state.trace.map(item => `<div class=\"trace-item\">${escapeHtml(item)}</div>`).join('')\n"
  html = html + "          : '<div class=\"trace-item\">暂无轨迹</div>';\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function renderAll() {\n"
  html = html + "        renderRuntimeSummary();\n"
  html = html + "        renderDisasm();\n"
  html = html + "        renderCfg();\n"
  html = html + "        renderRegisters();\n"
  html = html + "        renderMemoryAndCalls();\n"
  html = html + "        renderTrace();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function step(delta) {\n"
  html = html + "        if (state.viewInstructions.length === 0) return;\n"
  html = html +
    "        const next = Math.max(0, Math.min(state.viewInstructions.length - 1, state.cursor + delta));\n"
  html = html + "        if (next === state.cursor) return;\n"
  html = html + "        state.cursor = next;\n"
  html = html + "        rebuildToCursor(state.cursor);\n"
  html = html + "        renderAll();\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html + "      function togglePlay() {\n"
  html = html + "        if (state.timer) {\n"
  html = html + "          clearInterval(state.timer);\n"
  html = html + "          state.timer = null;\n"
  html = html + "          refs.playBtn.textContent = '自动播放';\n"
  html = html + "          renderRuntimeSummary();\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html + "        refs.playBtn.textContent = '暂停';\n"
  html = html + "        state.timer = setInterval(() => {\n"
  html = html +
    "          if (state.cursor >= state.viewInstructions.length - 1) {\n"
  html = html + "            togglePlay();\n"
  html = html + "            return;\n"
  html = html + "          }\n"
  html = html + "          step(1);\n"
  html = html + "        }, 400);\n"
  html = html + "      }\n"
  html = html + "\n"
  html = html +
    "      refs.functionSelect.addEventListener('change', (event) => {\n"
  html = html + "        const value = event.target.value;\n"
  html = html + "        if (value === '__all__') {\n"
  html = html + "          selectFunction(null);\n"
  html = html + "          return;\n"
  html = html + "        }\n"
  html = html +
    "        const target = data.functions.find(fn => fn.addr === value);\n"
  html = html + "        selectFunction(target ?? null);\n"
  html = html + "      });\n"
  html = html + "      refs.resetBtn.addEventListener('click', () => {\n"
  html = html +
    "        state.cursor = state.viewInstructions.length > 0 ? 0 : -1;\n"
  html = html + "        rebuildToCursor(state.cursor);\n"
  html = html + "        renderAll();\n"
  html = html + "      });\n"
  html = html +
    "      refs.prevBtn.addEventListener('click', () => step(-1));\n"
  html = html + "      refs.nextBtn.addEventListener('click', () => step(1));\n"
  html = html + "      refs.playBtn.addEventListener('click', togglePlay);\n"
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
  html = html + "      renderSummary();\n"
  html = html + "      renderSections();\n"
  html = html + "      renderFunctions();\n"
  html = html + "      selectFunction(null);\n"
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
