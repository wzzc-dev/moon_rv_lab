///|
pub const DEFAULT_RAW_BASE : UInt = 0x10000U

///|
pub const DEFAULT_RAW_XLEN : Int = 64

///|
pub enum ProgramFormat {
  Elf
  Raw
} derive(Show, Eq)

///|
pub enum CapabilityTier {
  FullyExecutable
  DecodeOnly
  Unsupported
} derive(Show, Eq)

///|
pub enum CapabilityDomain {
  Decode
  Disasm
  Analyze
  Execute
  OfflineWorkbench
  OnlineWorkbench
} derive(Show, Eq)

///|
pub struct CapabilityEntry {
  domain : CapabilityDomain
  tier : CapabilityTier
  formats : String
  xlen : String
  isa : String
  notes : String
} derive(Show)

///|
pub struct InputSpec {
  file_path : String
  format : ProgramFormat
  base_addr : UInt
  xlen : Int
} derive(Show)

///|
pub struct SectionInfo {
  index : Int
  name : String
  addr : UInt
  size : UInt
} derive(Show)

///|
pub struct LoadedCodeSection {
  index : Int
  name : String
  start_addr : UInt
  end_addr : UInt
  bytes : FixedArray[Byte]
  instructions : FixedArray[@analysis.DecodedInst]
  cfg : @analysis.CFG
} derive(Show)

///|
pub struct LoadedProgram {
  input : InputSpec
  entry_point : UInt
  file_class : String
  xlen : Int
  architecture : String
  section_count : Int
  program_count : Int
  sections : Array[SectionInfo]
  code_sections : Array[LoadedCodeSection]
  all_instructions : FixedArray[@analysis.DecodedInst]
  symbols : Array[@format.Symbol]
} derive(Show)

///|
pub struct FunctionRange {
  name : String
  addr : UInt
  size : UInt
  end_addr : UInt
  section_index : Int
} derive(Show)

///|
pub struct WorkbenchRequest {
  input : InputSpec
  function_selector : String
  max_events : Int
  max_instructions : Int
} derive(Show)

///|
pub enum ProgramLoadError {
  FileNotFound(String)
  InvalidElf(String)
  ParseElfFailed(String)
  NotRiscV(String)
  NoCodeSection(String)
} derive(Show)

///|
pub enum ProgramLoadResult {
  ProgramLoaded(LoadedProgram)
  ProgramLoadFailed(ProgramLoadError)
} derive(Show)

///|
pub enum WorkbenchRequestParseResult {
  WorkbenchRequestOk(WorkbenchRequest)
  WorkbenchRequestErr(String)
} derive(Show)

///|
pub fn create_input_spec(
  file_path : String,
  raw_mode : Bool,
  base_addr : UInt,
  xlen : Int,
) -> InputSpec {
  if raw_mode {
    raw_input_spec(file_path, base_addr, xlen)
  } else {
    elf_input_spec(file_path)
  }
}

///|
pub fn elf_input_spec(file_path : String) -> InputSpec {
  {
    file_path,
    format: ProgramFormat::Elf,
    base_addr: DEFAULT_RAW_BASE,
    xlen: DEFAULT_RAW_XLEN,
  }
}

///|
pub fn raw_input_spec(
  file_path : String,
  base_addr : UInt,
  xlen : Int,
) -> InputSpec {
  { file_path, format: ProgramFormat::Raw, base_addr, xlen }
}

///|
pub fn InputSpec::is_raw(self : InputSpec) -> Bool {
  self.format == ProgramFormat::Raw
}

///|
pub fn InputSpec::format_name(self : InputSpec) -> String {
  match self.format {
    ProgramFormat::Elf => "elf"
    ProgramFormat::Raw => "raw"
  }
}

///|
pub fn InputSpec::normalized_xlen(self : InputSpec) -> Int {
  if self.xlen == 32 {
    32
  } else {
    64
  }
}

///|
pub fn capability_tier_name(tier : CapabilityTier) -> String {
  match tier {
    CapabilityTier::FullyExecutable => "fully_executable"
    CapabilityTier::DecodeOnly => "decode_only"
    CapabilityTier::Unsupported => "unsupported"
  }
}

///|
pub fn fully_executable_tier() -> CapabilityTier {
  CapabilityTier::FullyExecutable
}

///|
pub fn decode_only_tier() -> CapabilityTier {
  CapabilityTier::DecodeOnly
}

///|
pub fn unsupported_tier() -> CapabilityTier {
  CapabilityTier::Unsupported
}

///|
pub fn capability_matrix() -> Array[CapabilityEntry] {
  [
    {
      domain: CapabilityDomain::Decode,
      tier: CapabilityTier::DecodeOnly,
      formats: "ELF, RAW",
      xlen: "RV32, RV64",
      isa: "RV32/64I + M/C + partial V/F decode coverage",
      notes: "Decoding coverage is broader than execution support.",
    },
    {
      domain: CapabilityDomain::Disasm,
      tier: CapabilityTier::DecodeOnly,
      formats: "ELF, RAW",
      xlen: "RV32, RV64",
      isa: "Decoded instruction set",
      notes: "Disassembly follows decoder coverage.",
    },
    {
      domain: CapabilityDomain::Analyze,
      tier: CapabilityTier::DecodeOnly,
      formats: "ELF, RAW",
      xlen: "RV32, RV64",
      isa: "Static CFG/callgraph/dataflow/decompile",
      notes: "RAW analysis remains conservative where symbol or function metadata is unavailable.",
    },
    {
      domain: CapabilityDomain::Execute,
      tier: CapabilityTier::FullyExecutable,
      formats: "ELF, RAW",
      xlen: "RV32, RV64",
      isa: "Integer/M + supported compressed subset + Linux-style syscall demo path",
      notes: "Vector and floating-point execution remain decode-only.",
    },
    {
      domain: CapabilityDomain::OfflineWorkbench,
      tier: CapabilityTier::FullyExecutable,
      formats: "ELF, RAW",
      xlen: "RV32, RV64",
      isa: "Shared static index + runtime trace",
      notes: "RAW uses synthetic entry function slices.",
    },
    {
      domain: CapabilityDomain::OnlineWorkbench,
      tier: CapabilityTier::FullyExecutable,
      formats: "ELF, RAW (overview/function)",
      xlen: "RV32, RV64",
      isa: "Shared workbench data model",
      notes: "/api/snapshot and /api/stream remain ELF-only compatibility endpoints.",
    },
  ]
}

///|
pub fn load_program(input : InputSpec) -> ProgramLoadResult {
  match read_file_bytes(input.file_path) {
    None => ProgramLoadFailed(ProgramLoadError::FileNotFound(input.file_path))
    Some(bytes) =>
      if input.is_raw() {
        load_raw_program(input, bytes)
      } else {
        load_elf_program(input, bytes)
      }
  }
}

///|
pub fn LoadedProgram::primary_code(self : LoadedProgram) -> LoadedCodeSection? {
  if self.code_sections.length() == 0 {
    None
  } else {
    Some(self.code_sections[0])
  }
}

///|
pub fn LoadedProgram::input_format_name(self : LoadedProgram) -> String {
  self.input.format_name()
}

///|
pub fn LoadedProgram::supports_symbols(self : LoadedProgram) -> Bool {
  !self.input.is_raw()
}

///|
pub fn collect_function_ranges(program : LoadedProgram) -> Array[FunctionRange] {
  if program.input.is_raw() {
    match program.primary_code() {
      Some(section) =>
        [
          {
            name: "entry",
            addr: section.start_addr,
            size: section.end_addr - section.start_addr,
            end_addr: section.end_addr,
            section_index: section.index,
          },
        ]
      None => []
    }
  } else {
    collect_symbol_function_ranges(program)
  }
}

///|
pub fn load_error_message(
  err : ProgramLoadError,
  input : InputSpec,
  show_raw_hint : Bool,
) -> String {
  match err {
    ProgramLoadError::FileNotFound(file_path) =>
      "Error: Cannot read file: \{file_path}"
    ProgramLoadError::InvalidElf(file_path) =>
      if show_raw_hint && !input.is_raw() {
        "Error: Not a valid ELF file: \{file_path}\nUse --raw --base <addr> --xlen <32|64> for raw binary files"
      } else {
        "Error: Not a valid ELF file: \{file_path}"
      }
    ProgramLoadError::ParseElfFailed(_file_path) =>
      "Error: Failed to parse ELF file"
    ProgramLoadError::NotRiscV(_file_path) => "Error: Not a RISC-V ELF file"
    ProgramLoadError::NoCodeSection(_file_path) =>
      if input.is_raw() {
        "Error: No executable code decoded from RAW input"
      } else {
        "Error: No executable code sections found"
      }
  }
}

///|
pub fn raw_symbols_unavailable_text() -> String {
  "Symbols\n=======\n\nRAW input does not provide a symbol table.\nNo symbols available.\n"
}

///|
pub fn raw_symbols_unavailable_json() -> String {
  "{\n" +
  "  \"input_format\": \"raw\",\n" +
  "  \"supported\": false,\n" +
  "  \"tier\": \"unsupported\",\n" +
  "  \"message\": \"RAW input does not provide a symbol table.\",\n" +
  "  \"symbols\": []\n" +
  "}"
}

///|
pub fn raw_callgraph_unavailable_text() -> String {
  "Call Graph\n==========\n\nRAW input lacks reliable function boundaries, so call graph generation is unavailable.\n"
}

///|
pub fn raw_callgraph_unavailable_json() -> String {
  "{\n" +
  "  \"input_format\": \"raw\",\n" +
  "  \"supported\": false,\n" +
  "  \"tier\": \"unsupported\",\n" +
  "  \"message\": \"RAW input lacks reliable function boundaries, so call graph generation is unavailable.\",\n" +
  "  \"functions\": [],\n" +
  "  \"edges\": []\n" +
  "}"
}

///|
pub fn raw_selector_error(
  flag : String,
  selector : String,
  input : InputSpec,
) -> String {
  "Error: RAW input does not provide symbol metadata; use an address with \{flag} instead of '\{selector}'.\nCurrent RAW settings: base=\{format_hex(input.base_addr)}, xlen=\{input.normalized_xlen()}"
}

///|
pub fn default_workbench_request(
  file_path : String,
  function_selector : String,
  max_events : Int,
  max_instructions : Int,
) -> WorkbenchRequest {
  {
    input: elf_input_spec(file_path),
    function_selector,
    max_events,
    max_instructions,
  }
}

///|
pub fn parse_workbench_request_lenient(
  file_path : String,
  raw : String?,
  base : String?,
  xlen : String?,
  function_selector : String,
  max_events : Int,
  max_instructions : Int,
) -> WorkbenchRequest {
  if raw_query_enabled(raw) {
    {
      input: raw_input_spec(
        file_path,
        choose_raw_base_lenient(base),
        choose_raw_xlen_lenient(xlen),
      ),
      function_selector,
      max_events,
      max_instructions,
    }
  } else {
    default_workbench_request(
      file_path, function_selector, max_events, max_instructions,
    )
  }
}

///|
pub fn parse_workbench_request_strict(
  file_path : String,
  raw : String?,
  base : String?,
  xlen : String?,
  function_selector : String,
  max_events : Int,
  max_instructions : Int,
) -> WorkbenchRequestParseResult {
  if !raw_query_enabled(raw) {
    return WorkbenchRequestOk(
      default_workbench_request(
        file_path, function_selector, max_events, max_instructions,
      ),
    )
  }
  match parse_raw_base_strict(base) {
    Some(base_addr) =>
      match parse_raw_xlen_strict(xlen) {
        Some(parsed_xlen) =>
          WorkbenchRequestOk({
            input: raw_input_spec(file_path, base_addr, parsed_xlen),
            function_selector,
            max_events,
            max_instructions,
          })
        None => WorkbenchRequestErr("invalid raw xlen: expected 32 or 64")
      }
    None =>
      WorkbenchRequestErr(
        "invalid raw base: expected decimal or 0x-prefixed address",
      )
  }
}

///|
pub fn raw_query_enabled(value : String?) -> Bool {
  match value {
    Some("1") => true
    Some("true") => true
    Some("TRUE") => true
    Some("True") => true
    _ => false
  }
}

///|
fn load_elf_program(
  input : InputSpec,
  bytes : FixedArray[Byte],
) -> ProgramLoadResult {
  if !@format.is_elf(bytes) {
    return ProgramLoadFailed(ProgramLoadError::InvalidElf(input.file_path))
  }
  match @format.parse_elf(bytes) {
    None => ProgramLoadFailed(ProgramLoadError::ParseElfFailed(input.file_path))
    Some(elf) => {
      if !elf.is_riscv() {
        return ProgramLoadFailed(ProgramLoadError::NotRiscV(input.file_path))
      }
      let sections = collect_sections(elf)
      let code_sections = collect_program_code_sections(elf)
      if code_sections.length() == 0 {
        return ProgramLoadFailed(
          ProgramLoadError::NoCodeSection(input.file_path),
        )
      }
      ProgramLoaded({
        input,
        entry_point: elf.entry_point(),
        file_class: if elf.is_64bit {
          "ELF64"
        } else {
          "ELF32"
        },
        xlen: if elf.is_64bit {
          64
        } else {
          32
        },
        architecture: "RISC-V",
        section_count: elf.section_count(),
        program_count: elf.program_count(),
        sections,
        code_sections,
        all_instructions: collect_all_program_instructions(code_sections),
        symbols: elf.get_symbols(),
      })
    }
  }
}

///|
fn load_raw_program(
  input : InputSpec,
  bytes : FixedArray[Byte],
) -> ProgramLoadResult {
  let raw = @format.parse_raw_binary(bytes, input.base_addr)
  if raw.code.length() == 0 {
    return ProgramLoadFailed(ProgramLoadError::NoCodeSection(input.file_path))
  }

  let instructions = @analysis.decode_instructions(raw.code, raw.base_addr)
  if instructions.length() == 0 {
    return ProgramLoadFailed(ProgramLoadError::NoCodeSection(input.file_path))
  }

  let cfg = @analysis.build_cfg(instructions, raw.base_addr)
  let section = {
    index: 0,
    name: ".text.raw",
    start_addr: raw.base_addr,
    end_addr: raw.base_addr + raw.code.length().reinterpret_as_uint(),
    bytes: raw.code,
    instructions,
    cfg,
  }
  let code_sections = [section]
  ProgramLoaded({
    input,
    entry_point: raw.base_addr,
    file_class: "RAW",
    xlen: input.normalized_xlen(),
    architecture: "RISC-V",
    section_count: 1,
    program_count: 1,
    sections: [
      {
        index: 0,
        name: ".text.raw",
        addr: raw.base_addr,
        size: raw.code.length().reinterpret_as_uint(),
      },
    ],
    code_sections,
    all_instructions: collect_all_program_instructions(code_sections),
    symbols: [],
  })
}

///|
fn collect_sections(elf : @format.ElfFile) -> Array[SectionInfo] {
  let result : Array[SectionInfo] = []
  for i = 0; i < elf.section_count(); i = i + 1 {
    match elf.get_section(i) {
      Some((addr, _offset, size)) =>
        result.push({ index: i, name: elf.get_section_name(i), addr, size })
      None => ()
    }
  }
  result
}

///|
fn collect_program_code_sections(
  elf : @format.ElfFile,
) -> Array[LoadedCodeSection] {
  let result : Array[LoadedCodeSection] = []

  if elf.is_64bit {
    for i = 0; i < elf.sections64.length(); i = i + 1 {
      let sh = elf.sections64[i]
      if (sh.sh_flags & @format.SHF_EXECINSTR) != 0U && sh.sh_size > 0U {
        match elf.extract_bytes(sh.sh_offset, sh.sh_size) {
          Some(code) => {
            let instructions = @analysis.decode_instructions(code, sh.sh_addr)
            let cfg = @analysis.build_cfg(instructions, sh.sh_addr)
            result.push({
              index: i,
              name: elf.get_section_name(i),
              start_addr: sh.sh_addr,
              end_addr: sh.sh_addr + sh.sh_size,
              bytes: code,
              instructions,
              cfg,
            })
          }
          None => ()
        }
      }
    }
  } else {
    for i = 0; i < elf.sections32.length(); i = i + 1 {
      let sh = elf.sections32[i]
      if (sh.sh_flags & @format.SHF_EXECINSTR) != 0U && sh.sh_size > 0U {
        match elf.extract_bytes(sh.sh_offset, sh.sh_size) {
          Some(code) => {
            let instructions = @analysis.decode_instructions(code, sh.sh_addr)
            let cfg = @analysis.build_cfg(instructions, sh.sh_addr)
            result.push({
              index: i,
              name: elf.get_section_name(i),
              start_addr: sh.sh_addr,
              end_addr: sh.sh_addr + sh.sh_size,
              bytes: code,
              instructions,
              cfg,
            })
          }
          None => ()
        }
      }
    }
  }

  if result.length() == 0 {
    let fallback = elf.get_code_sections()
    for i = 0; i < fallback.length(); i = i + 1 {
      let (addr, code) = fallback[i]
      let instructions = @analysis.decode_instructions(code, addr)
      let cfg = @analysis.build_cfg(instructions, addr)
      result.push({
        index: i,
        name: "segment_" + i.to_string(),
        start_addr: addr,
        end_addr: addr + code.length().reinterpret_as_uint(),
        bytes: code,
        instructions,
        cfg,
      })
    }
  }

  result.sort_by((lhs, rhs) => {
    let by_addr = lhs.start_addr.compare(rhs.start_addr)
    if by_addr != 0 {
      by_addr
    } else {
      lhs.index.compare(rhs.index)
    }
  })
  result
}

///|
fn collect_all_program_instructions(
  code_sections : Array[LoadedCodeSection],
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
priv struct FunctionSymbolCandidate {
  name : String
  addr : UInt
  size : UInt
  section_index : Int
}

///|
fn collect_symbol_function_ranges(
  program : LoadedProgram,
) -> Array[FunctionRange] {
  let candidates : Array[FunctionSymbolCandidate] = []
  for sym in program.symbols {
    match sym.sym_type {
      @format.SymbolType::Func =>
        if sym.name != "" && sym.size > 0U {
          let section_slot = find_code_section_index_for_addr(
            program.code_sections,
            sym.value,
          )
          if section_slot >= 0 {
            let section = program.code_sections[section_slot]
            if sym.section_index.reinterpret_as_int() == section.index {
              candidates.push({
                name: sym.name,
                addr: sym.value,
                size: sym.size,
                section_index: section.index,
              })
            }
          }
        }
      _ => ()
    }
  }

  candidates.sort_by((lhs, rhs) => {
    let by_section = lhs.section_index.compare(rhs.section_index)
    if by_section != 0 {
      by_section
    } else {
      let by_addr = lhs.addr.compare(rhs.addr)
      if by_addr != 0 {
        by_addr
      } else {
        lhs.name.compare(rhs.name)
      }
    }
  })

  let deduped : Array[FunctionSymbolCandidate] = []
  for candidate in candidates {
    let mut duplicated = false
    for existing in deduped {
      if existing.section_index == candidate.section_index &&
        existing.addr == candidate.addr {
        duplicated = true
        break
      }
    }
    if !duplicated {
      deduped.push(candidate)
    }
  }

  let result : Array[FunctionRange] = []
  for i = 0; i < deduped.length(); i = i + 1 {
    let candidate = deduped[i]
    match
      find_code_section_by_index(program.code_sections, candidate.section_index) {
      Some(section) => {
        let mut end_addr = if candidate.size > 0U {
          candidate.addr + candidate.size
        } else {
          section.end_addr
        }
        if candidate.size == 0U {
          for j = i + 1; j < deduped.length(); j = j + 1 {
            let next = deduped[j]
            if next.section_index == candidate.section_index &&
              next.addr > candidate.addr {
              end_addr = next.addr
              break
            }
          }
        }
        if end_addr > section.end_addr {
          end_addr = section.end_addr
        }
        if end_addr <= candidate.addr {
          end_addr = section.end_addr
        }
        if end_addr > candidate.addr {
          result.push({
            name: candidate.name,
            addr: candidate.addr,
            size: end_addr - candidate.addr,
            end_addr,
            section_index: candidate.section_index,
          })
        }
      }
      None => ()
    }
  }

  if result.length() == 0 {
    for section in program.code_sections {
      let synthetic_name = if program.entry_point >= section.start_addr &&
        program.entry_point < section.end_addr {
        "entry"
      } else if section.name != "" {
        section.name
      } else {
        "sub_" + uint_to_hex(section.start_addr)
      }
      result.push({
        name: synthetic_name,
        addr: section.start_addr,
        size: section.end_addr - section.start_addr,
        end_addr: section.end_addr,
        section_index: section.index,
      })
    }
  }

  result.sort_by((lhs, rhs) => lhs.addr.compare(rhs.addr))
  result
}

///|
fn find_code_section_index_for_addr(
  code_sections : Array[LoadedCodeSection],
  addr : UInt,
) -> Int {
  for i = 0; i < code_sections.length(); i = i + 1 {
    let section = code_sections[i]
    if addr >= section.start_addr && addr < section.end_addr {
      return i
    }
  }
  -1
}

///|
fn find_code_section_by_index(
  code_sections : Array[LoadedCodeSection],
  section_index : Int,
) -> LoadedCodeSection? {
  for section in code_sections {
    if section.index == section_index {
      return Some(section)
    }
  }
  None
}

///|
fn read_file_bytes(path : String) -> FixedArray[Byte]? {
  if !@fs.path_exists(path) {
    return None
  }
  Some(@fs.read_file_to_bytes(path).to_fixedarray()) catch {
    _ => None
  }
}

///|
fn parse_uint_dec(s : String) -> UInt? {
  let mut result : UInt = 0U
  for c in s {
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
      _ => None
    }
    match digit {
      Some(d) => result = result * 10U + d
      None => return None
    }
  }
  Some(result)
}

///|
fn parse_hex_uint(s : String) -> UInt? {
  if s.length() >= 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X') {
    let mut result : UInt = 0U
    for i = 2; i < s.length(); i = i + 1 {
      let digit = match s[i] {
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
        Some(d) => result = result * 16U + d
        None => return None
      }
    }
    Some(result)
  } else {
    None
  }
}

///|
fn parse_number(value : String) -> UInt? {
  match parse_hex_uint(value) {
    Some(parsed) => Some(parsed)
    None => parse_uint_dec(value)
  }
}

///|
fn parse_raw_base_strict(value : String?) -> UInt? {
  match value {
    Some(raw) => parse_number(raw)
    None => Some(DEFAULT_RAW_BASE)
  }
}

///|
fn choose_raw_base_lenient(value : String?) -> UInt {
  match parse_raw_base_strict(value) {
    Some(base_addr) => base_addr
    None => DEFAULT_RAW_BASE
  }
}

///|
fn parse_raw_xlen_strict(value : String?) -> Int? {
  match value {
    Some("32") => Some(32)
    Some("64") => Some(64)
    None => Some(DEFAULT_RAW_XLEN)
    _ => None
  }
}

///|
fn choose_raw_xlen_lenient(value : String?) -> Int {
  match parse_raw_xlen_strict(value) {
    Some(xlen) => xlen
    None => DEFAULT_RAW_XLEN
  }
}

///|
fn format_hex(value : UInt) -> String {
  "0x" + uint_to_hex(value)
}

///|
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    return "0"
  }
  let mut digits = ""
  let mut current = value
  while current > 0U {
    let digit = (current & 0xFU).reinterpret_as_int()
    let ch = if digit < 10 {
      ('0'.to_int() + digit).unsafe_to_char().to_string()
    } else {
      ('a'.to_int() + digit - 10).unsafe_to_char().to_string()
    }
    digits = ch + digits
    current = current >> 4
  }
  digits
}
