///|
const PROGRAM_TEST_DIR : String = "tmp_program_tests"

///|
fn ensure_program_test_dir() -> Unit {
  if !@fs.path_exists(PROGRAM_TEST_DIR) {
    @fs.create_dir(PROGRAM_TEST_DIR) catch {
      _ => abort("failed to create program test dir")
    }
  }
}

///|
fn write_test_program_elf(name : String, source : String, xlen : Int) -> String {
  ensure_program_test_dir()
  let path = PROGRAM_TEST_DIR + "/" + name + ".elf"
  let assembled = @asm.assemble_with_symbols(source, DEFAULT_RAW_BASE)
  if assembled.errors.length() != 0 {
    abort("assembly failed")
  }
  let bytes = @asm.encode_to_bytes(assembled)
  let elf = if xlen == 32 {
    @format.assemble_to_elf32(bytes, DEFAULT_RAW_BASE)
  } else {
    @format.assemble_to_elf64(bytes, DEFAULT_RAW_BASE)
  }
  @fs.write_bytes_to_file(path, Bytes::from_array(elf)) catch {
    _ => abort("failed to write elf")
  }
  path
}

///|
fn write_test_program_raw(name : String, source : String) -> String {
  ensure_program_test_dir()
  let path = PROGRAM_TEST_DIR + "/" + name + ".raw"
  let assembled = @asm.assemble_with_symbols(source, DEFAULT_RAW_BASE)
  if assembled.errors.length() != 0 {
    abort("assembly failed")
  }
  let bytes = @asm.encode_to_bytes(assembled)
  @fs.write_bytes_to_file(path, Bytes::from_array(bytes)) catch {
    _ => abort("failed to write raw")
  }
  path
}

///|
test "load_program normalizes ELF and RAW metadata through one model" {
  let elf_path = write_test_program_elf(
    "simple64", "addi a0, x0, 1\nebreak", 64,
  )
  let raw_path = write_test_program_raw("simple_raw", "addi a0, x0, 1\nebreak")

  match load_program(elf_input_spec(elf_path)) {
    ProgramLoaded(program) => {
      assert_eq(program.input_format_name(), "elf")
      assert_eq(program.file_class, "ELF64")
      assert_eq(program.xlen, 64)
      assert_eq(program.entry_point, DEFAULT_RAW_BASE)
      assert_true(program.primary_code() is Some(_))
      assert_true(program.section_count > 0)
      assert_true(program.code_sections.length() > 0)
    }
    ProgramLoadFailed(err) => abort("expected elf program to load: \{err}")
  }

  match load_program(raw_input_spec(raw_path, 0x20000U, 32)) {
    ProgramLoaded(program) => {
      assert_eq(program.input_format_name(), "raw")
      assert_eq(program.file_class, "RAW")
      assert_eq(program.xlen, 32)
      assert_eq(program.entry_point, 0x20000U)
      assert_eq(program.sections.length(), 1)
      assert_eq(program.symbols.length(), 0)
      match program.primary_code() {
        Some(section) => assert_eq(section.start_addr, 0x20000U)
        None => abort("expected raw primary code")
      }
    }
    ProgramLoadFailed(err) => abort("expected raw program to load: \{err}")
  }
}

///|
test "collect_function_ranges synthesizes raw entry and keeps ELF functions" {
  let elf_path = write_test_program_elf(
    "call_chain", "entry:\naddi a0, x0, 1\njal ra, helper\nebreak\nhelper:\naddi a0, x0, 7\nebreak",
    64,
  )
  let raw_path = write_test_program_raw("entry_raw", "addi a0, x0, 1\nebreak")

  match load_program(elf_input_spec(elf_path)) {
    ProgramLoaded(program) => {
      let ranges = collect_function_ranges(program)
      assert_true(ranges.length() >= 1)
      let mut found_entry = false
      for range in ranges {
        if range.name == "entry" {
          found_entry = true
        }
      }
      assert_true(found_entry)
    }
    ProgramLoadFailed(err) => abort("expected elf program to load: \{err}")
  }

  match load_program(raw_input_spec(raw_path, DEFAULT_RAW_BASE, 64)) {
    ProgramLoaded(program) => {
      let ranges = collect_function_ranges(program)
      assert_eq(ranges.length(), 1)
      assert_eq(ranges[0].name, "entry")
      assert_eq(ranges[0].addr, DEFAULT_RAW_BASE)
    }
    ProgramLoadFailed(err) => abort("expected raw program to load: \{err}")
  }
}

///|
test "workbench request parsing shares RAW metadata rules" {
  match
    parse_workbench_request_strict(
      "out/simple.raw",
      Some("1"),
      Some("0x20000"),
      Some("32"),
      "entry",
      20,
      120,
    ) {
    WorkbenchRequestOk(request) => {
      assert_true(request.input.is_raw())
      assert_eq(request.input.base_addr, 0x20000U)
      assert_eq(request.input.xlen, 32)
      assert_eq(request.function_selector, "entry")
    }
    WorkbenchRequestErr(err) => abort(err)
  }

  match
    parse_workbench_request_strict(
      "out/simple.raw",
      Some("1"),
      Some("bad"),
      Some("64"),
      "",
      20,
      120,
    ) {
    WorkbenchRequestOk(_) => abort("expected invalid base")
    WorkbenchRequestErr(err) => assert_true(err.contains("invalid raw base"))
  }
}

///|
test "capability matrix exposes decode-only and unsupported tiers clearly" {
  let entries = capability_matrix()
  let mut execute_found = false
  let mut online_found = false
  for entry in entries {
    match entry.domain {
      CapabilityDomain::Execute => {
        execute_found = true
        assert_eq(capability_tier_name(entry.tier), "fully_executable")
      }
      CapabilityDomain::OnlineWorkbench => {
        online_found = true
        assert_true(entry.notes.contains("ELF-only"))
      }
      _ => ()
    }
  }
  assert_true(execute_found)
  assert_true(online_found)
}
