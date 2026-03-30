///|
const CLI_TEST_DIR : String = "tmp_cli_tests"

///|
const SIMPLE_SOURCE_PATH : String = "example/simple.s"

///|
const CALL_CHAIN_SOURCE_PATH : String = "example/call_chain.s"

///|
const SIMPLE_ELF_PATH : String = CLI_TEST_DIR + "/simple.elf"

///|
const SIMPLE_ELF32_PATH : String = CLI_TEST_DIR + "/simple32.elf"

///|
const SIMPLE_RAW_PATH : String = CLI_TEST_DIR + "/simple.raw"

///|
const CALL_CHAIN_ELF_PATH : String = CLI_TEST_DIR + "/call_chain.elf"

///|
fn ensure_cli_test_dir() -> Unit {
  if !@fs.path_exists(CLI_TEST_DIR) {
    @fs.create_dir(CLI_TEST_DIR) catch {
      _ => abort("failed to create cli test dir")
    }
  }
}

///|
fn reset_cli_test_file(path : String) -> Unit {
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => abort("failed to remove cli test file")
    }
  }
}

///|
fn must_read_text(path : String) -> String {
  match read_file_string(path) {
    Some(content) => content
    None => abort("failed to read text file")
  }
}

///|
fn must_prepare_elf_fixture(
  source_path : String,
  output_path : String,
  xlen : Int,
) -> String {
  ensure_cli_test_dir()
  reset_cli_test_file(output_path)
  match read_file_string(source_path) {
    Some(source) => {
      let result = @asm.assemble_with_symbols(source, 0x10000U)
      if result.errors.length() > 0 {
        abort("failed to assemble cli fixture")
      }
      let bytes = @asm.encode_to_bytes(result)
      let elf = if xlen == 32 {
        @format.assemble_to_elf32(bytes, 0x10000U)
      } else {
        @format.assemble_to_elf64(bytes, 0x10000U)
      }
      if !write_file_bytes(output_path, elf) {
        abort("failed to write simple elf fixture")
      }
      output_path
    }
    None => abort("failed to read cli fixture source")
  }
}

///|
fn must_prepare_simple_elf_with_xlen(xlen : Int) -> String {
  let output_path = if xlen == 32 { SIMPLE_ELF32_PATH } else { SIMPLE_ELF_PATH }
  must_prepare_elf_fixture(SIMPLE_SOURCE_PATH, output_path, xlen)
}

///|
fn must_prepare_simple_elf() -> String {
  must_prepare_simple_elf_with_xlen(64)
}

///|
fn must_prepare_call_chain_elf() -> String {
  must_prepare_elf_fixture(CALL_CHAIN_SOURCE_PATH, CALL_CHAIN_ELF_PATH, 64)
}

///|
fn must_prepare_simple_raw() -> String {
  ensure_cli_test_dir()
  reset_cli_test_file(SIMPLE_RAW_PATH)
  match read_file_string(SIMPLE_SOURCE_PATH) {
    Some(source) => {
      let result = @asm.assemble_with_symbols(source, 0x10000U)
      if result.errors.length() > 0 {
        abort("failed to assemble raw fixture")
      }
      let bytes = @asm.encode_to_bytes(result)
      if !write_file_bytes(SIMPLE_RAW_PATH, bytes) {
        abort("failed to write raw fixture")
      }
      SIMPLE_RAW_PATH
    }
    None => abort("failed to read raw fixture source")
  }
}

///|
fn simple_run_options(
  xlen : Int,
  format : OutputFormat,
  trace : String,
  breakpoints : Array[String],
) -> RunOptions {
  {
    file_path: must_prepare_simple_elf_with_xlen(xlen),
    entry: "",
    max_steps: 20,
    breakpoints,
    trace,
    format,
  }
}

///|
test "parse run args supports entry break trace and format" {
  match
    parse_run_args([
      "run", "out/simple.elf", "--entry", "_start", "--max-steps", "55", "--break",
      "0x10010", "--break", "0x10018", "--trace", "out/trace.json", "--format", "json",
    ]) {
    Some(Command::Run(opts)) => {
      assert_eq(opts.file_path, "out/simple.elf")
      assert_eq(opts.entry, "_start")
      assert_eq(opts.max_steps, 55)
      assert_eq(opts.breakpoints.length(), 2)
      assert_eq(opts.breakpoints[0], "0x10010")
      assert_eq(opts.breakpoints[1], "0x10018")
      assert_eq(opts.trace, "out/trace.json")
      assert_eq(opts.format, OutputFormat::Json)
    }
    _ => abort("expected run command")
  }
}

///|
test "parse asm args supports xlen selection" {
  match
    parse_asm_args([
      "asm", "example/simple.s", "-o", "out/simple.elf", "--xlen", "32",
    ]) {
    Some(Command::Asm(opts)) => {
      assert_eq(opts.input_file, "example/simple.s")
      assert_eq(opts.output_file, "out/simple.elf")
      assert_eq(opts.xlen, 32)
    }
    _ => abort("expected asm command")
  }
}

///|
test "info command writes elf metadata json" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/info.json"
  reset_cli_test_file(output_path)
  let simple_elf = must_prepare_simple_elf()

  execute_info({
    file_path: simple_elf,
    format: OutputFormat::Json,
    output: output_path,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("\"class\": \"ELF64\""))
  assert_true(output.contains("\"architecture\": \"RISC-V\""))
  assert_true(output.contains("\"entry_point\": \"0x10000\""))
}

///|
test "disasm command writes elf disassembly json" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/disasm.json"
  reset_cli_test_file(output_path)
  let simple_elf = must_prepare_simple_elf()

  execute_disasm({
    file_path: simple_elf,
    base_addr: 0U,
    format: OutputFormat::Json,
    raw_mode: false,
    output: output_path,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("\"addr\": \"0x10000\""))
  assert_true(output.contains("\"inst\": \"addi a0, zero, 42\""))
  assert_true(output.contains("\"addr\": \"0x1002c\""))
}

///|
test "disasm command keeps raw fixture support through shared loader" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/disasm_raw.txt"
  reset_cli_test_file(output_path)
  let simple_raw = must_prepare_simple_raw()

  execute_disasm({
    file_path: simple_raw,
    base_addr: 0x10000U,
    format: OutputFormat::Text,
    raw_mode: true,
    output: output_path,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("0x00010000: addi a0, zero, 42"))
  assert_true(output.contains("0x0001002c: ebreak"))
}

///|
test "cfg command writes elf cfg json" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/cfg.json"
  reset_cli_test_file(output_path)
  let simple_elf = must_prepare_simple_elf()

  execute_cfg({
    file_path: simple_elf,
    function: "",
    format: OutputFormat::Json,
    output: output_path,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("\"blocks\": ["))
  assert_true(output.contains("\"start_addr\": \"0x10000\""))
  assert_true(output.contains("\"entry_points\": ["))
}

///|
test "callgraph command writes elf callgraph json" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/callgraph.json"
  reset_cli_test_file(output_path)
  let call_chain_elf = must_prepare_call_chain_elf()

  execute_callgraph({
    file_path: call_chain_elf,
    format: OutputFormat::Json,
    output: output_path,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("\"entry_point\": \"0x10000\""))
  assert_true(output.contains("\"functions\": ["))
  assert_true(output.contains("\"address\": \"0x10000\""))
  assert_true(output.contains("\"name\": \"0x10000\""))
  assert_true(output.contains("\"size\": 16"))
}

///|
test "analyze command writes elf analysis json" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/analyze.json"
  reset_cli_test_file(output_path)
  let simple_elf = must_prepare_simple_elf()

  execute_analyze({
    file_path: simple_elf,
    format: OutputFormat::Json,
    output: output_path,
    detailed: true,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("\"file_type\": \"ELF64\""))
  assert_true(output.contains("\"architecture\": \"RISC-V\""))
  assert_true(output.contains("\"instruction_count\": 12"))
  assert_true(output.contains("\"basic_blocks\": 1"))
}

///|
test "decompile command writes elf control flow summary" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/decompile.txt"
  reset_cli_test_file(output_path)
  let simple_elf = must_prepare_simple_elf()

  execute_decompile({
    file_path: simple_elf,
    function: "",
    output: output_path,
    show_code: false,
  })

  assert_true(@fs.path_exists(output_path))
  let output = must_read_text(output_path)
  assert_true(output.contains("// Function: _start @ 0x10000"))
  assert_true(output.contains("// Basic Blocks: 1"))
  assert_true(output.contains("Block 0x10000:"))
}

///|
test "run command text output summarizes execution" {
  match execute_run_result(simple_run_options(64, OutputFormat::Text, "", [])) {
    Success(output) => {
      assert_true(output.contains("Execution Summary"))
      assert_true(output.contains("Entry: 0x10000"))
      assert_true(output.contains("PC: 0x1002c"))
      assert_true(output.contains("XLEN: 64"))
      assert_true(output.contains("Steps: 12"))
      assert_true(output.contains("Stop Reason: ebreak @0x1002c"))
      assert_true(output.contains("a0: 0x2a"))
      assert_true(output.contains("a2: 0x5e"))
      assert_true(output.contains("t0: 0x12345"))
    }
    Failure(err) => abort(err)
  }
}

///|
test "run command json output includes snapshot and trace" {
  match execute_run_result(simple_run_options(64, OutputFormat::Json, "", [])) {
    Success(output) => {
      assert_true(output.contains("\"entry\":\"0x10000\""))
      assert_true(output.contains("\"xlen\":64"))
      assert_true(output.contains("\"snapshot\":{\"pc\":\"0x1002c\""))
      assert_true(output.contains("\"stop_reason\":\"ebreak @0x1002c\""))
      assert_true(output.contains("\"trace\":["))
      assert_true(output.contains("\"addr\":\"0x10000\""))
      assert_true(output.contains("\"asm\":\"addi a0, zero, 42\""))
    }
    Failure(err) => abort(err)
  }
}

///|
test "run command stops before configured breakpoint" {
  match
    execute_run_result(
      simple_run_options(64, OutputFormat::Text, "", ["0x10010"]),
    ) {
    Success(output) => {
      assert_true(output.contains("PC: 0x10010"))
      assert_true(output.contains("Steps: 4"))
      assert_true(output.contains("Stop Reason: breakpoint @0x10010"))
      assert_true(output.contains("a3: 0xa"))
      assert_false(output.contains("a4:"))
    }
    Failure(err) => abort(err)
  }
}

///|
test "run command writes structured trace file" {
  ensure_cli_test_dir()
  let trace_path = CLI_TEST_DIR + "/simple_trace.json"
  reset_cli_test_file(trace_path)

  match
    execute_run_result(
      simple_run_options(64, OutputFormat::Text, trace_path, []),
    ) {
    Success(output) => {
      assert_true(output.contains("Execution Summary"))
      assert_true(@fs.path_exists(trace_path))
      let trace = must_read_text(trace_path)
      assert_true(trace.contains("\"step\":1"))
      assert_true(trace.contains("\"addr\":\"0x10000\""))
      assert_true(trace.contains("\"stop_reason\":\"ebreak @0x1002c\""))
    }
    Failure(err) => abort(err)
  }
}

///|
test "run command remains compatible with explicit rv32 fixtures" {
  match execute_run_result(simple_run_options(32, OutputFormat::Json, "", [])) {
    Success(output) => {
      assert_true(output.contains("\"xlen\":32"))
      assert_true(output.contains("\"entry\":\"0x10000\""))
      assert_true(output.contains("\"stop_reason\":\"ebreak @0x1002c\""))
    }
    Failure(err) => abort(err)
  }
}

///|
test "workbench command generates offline html artifact" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/simple_workbench.html"
  reset_cli_test_file(output_path)
  let simple_elf = must_prepare_simple_elf()

  match
    execute_workbench_result({
      file_path: simple_elf,
      output: output_path,
      title: "CLI Test Workbench",
      max_instructions: 64,
    }) {
    Success(output) => {
      assert_true(output.contains("Workbench generated: " + output_path))
      assert_true(output.contains("Open the HTML file in a browser"))
      assert_true(@fs.path_exists(output_path))
      let html = must_read_text(output_path)
      assert_true(html.contains("class=\"workbench-shell\""))
      assert_true(html.contains("const WORKBENCH_BOOT = "))
      assert_true(html.contains("\"mode\":\"embedded\""))
      assert_true(html.contains("\"embedded_overview\""))
    }
    Failure(err) => abort(err)
  }
}
