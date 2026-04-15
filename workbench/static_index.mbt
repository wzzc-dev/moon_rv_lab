///|
/// Static program loading and index construction helpers.

///|
priv enum LoadStaticProgramResult {
  StaticProgramOk(StaticProgramIndex)
  StaticProgramErr(WorkbenchError)
}

///|
fn resolve_page_title(title : String) -> String {
  if title == "" {
    "MoonRV Lab Workbench"
  } else {
    title
  }
}

///|
fn load_static_program_index(
  input_file : String,
  title : String,
) -> LoadStaticProgramResult {
  load_static_program_index_input(@program.elf_input_spec(input_file), title)
}

///|
fn load_static_program_index_with_options(
  input_file : String,
  title : String,
  options : WorkbenchOptions,
) -> LoadStaticProgramResult {
  load_static_program_index_input(
    input_spec_from_options(input_file, options),
    title,
  )
}

///|
fn load_static_program_index_input(
  input : @program.InputSpec,
  title : String,
) -> LoadStaticProgramResult {
  match @program.load_program(input) {
    @program.ProgramLoaded(program) =>
      build_static_program_index(program, title)
    @program.ProgramLoadFailed(err) =>
      StaticProgramErr(workbench_error_from_program_error(err))
  }
}

///|
fn workbench_error_from_program_error(
  err : @program.ProgramLoadError,
) -> WorkbenchError {
  match err {
    @program.ProgramLoadError::FileNotFound(path) =>
      WorkbenchError::FileNotFound(path)
    @program.ProgramLoadError::InvalidElf(path) =>
      WorkbenchError::InvalidElf(path)
    @program.ProgramLoadError::ParseElfFailed(path) =>
      WorkbenchError::ParseElfFailed(path)
    @program.ProgramLoadError::NotRiscV(path) => WorkbenchError::NotRiscV(path)
    @program.ProgramLoadError::NoCodeSection(path) =>
      WorkbenchError::NoCodeSection(path)
  }
}

///|
fn build_static_program_index(
  program : @program.LoadedProgram,
  title : String,
) -> LoadStaticProgramResult {
  let sections : Array[WorkbenchSection] = []
  for section in program.sections {
    sections.push({
      index: section.index,
      name: section.name,
      addr: format_hex(section.addr),
      size: format_hex(section.size),
    })
  }

  let code_sections : Array[ProgramSectionIndex] = []
  for section in program.code_sections {
    code_sections.push({
      instructions: section.instructions,
      blocks: collect_blocks(section.cfg),
      edges: collect_edges(section.cfg),
    })
  }

  let function_ranges : Array[FunctionRange] = []
  for range in @program.collect_function_ranges(program) {
    function_ranges.push({
      name: range.name,
      addr: range.addr,
      size: range.size,
      end_addr: range.end_addr,
    })
  }

  let all_instructions = collect_all_program_instructions(code_sections)
  let blocks = collect_all_program_blocks(code_sections)
  let edges = collect_all_program_edges(code_sections)
  StaticProgramOk({
    title,
    source_file: program.input.file_path,
    input_format: program.input_format_name(),
    entry_point: program.entry_point,
    file_class: program.file_class,
    xlen: program.xlen,
    architecture: program.architecture,
    section_count: program.section_count,
    program_count: program.program_count,
    sections,
    all_instructions,
    blocks,
    edges,
    function_ranges,
  })
}

///|
fn collect_all_program_instructions(
  code_sections : Array[ProgramSectionIndex],
) -> FixedArray[@analysis.DecodedInst] {
  let result : Array[@analysis.DecodedInst] = []
  for section in code_sections {
    for inst in section.instructions {
      result.push(inst)
    }
  }
  result.sort_by((lhs, rhs) => lhs.addr.compare(rhs.addr))
  FixedArray::from_array(result)
}

///|
fn collect_all_program_blocks(
  code_sections : Array[ProgramSectionIndex],
) -> Array[WorkbenchBlock] {
  let result : Array[WorkbenchBlock] = []
  for section in code_sections {
    for block in section.blocks {
      result.push(block)
    }
  }
  result.sort_by((lhs, rhs) => {
    match parse_hex_uint(lhs.start_addr) {
      Some(lhs_addr) =>
        match parse_hex_uint(rhs.start_addr) {
          Some(rhs_addr) => lhs_addr.compare(rhs_addr)
          None => -1
        }
      None =>
        match parse_hex_uint(rhs.start_addr) {
          Some(_) => 1
          None => 0
        }
    }
  })
  result
}

///|
fn collect_all_program_edges(
  code_sections : Array[ProgramSectionIndex],
) -> Array[WorkbenchEdge] {
  let result : Array[WorkbenchEdge] = []
  for section in code_sections {
    for edge in section.edges {
      result.push(edge)
    }
  }
  result.sort_by((lhs, rhs) => {
    match parse_hex_uint(lhs.from_block) {
      Some(lhs_addr) =>
        match parse_hex_uint(rhs.from_block) {
          Some(rhs_addr) => lhs_addr.compare(rhs_addr)
          None => -1
        }
      None =>
        match parse_hex_uint(rhs.from_block) {
          Some(_) => 1
          None => 0
        }
    }
  })
  result
}
