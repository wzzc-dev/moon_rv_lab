///|
const CLI_TEST_DIR : String = "tmp_cli_tests"

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
fn simple_run_options(
  format : OutputFormat,
  trace : String,
  breakpoints : Array[String],
) -> RunOptions {
  {
    file_path: "example/simple.elf",
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
      "run", "example/simple.elf", "--entry", "_start", "--max-steps", "55", "--break",
      "0x10010", "--break", "0x10018", "--trace", "out/trace.json", "--format", "json",
    ]) {
    Some(Command::Run(opts)) => {
      assert_eq(opts.file_path, "example/simple.elf")
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
test "run command text output summarizes execution" {
  match execute_run_result(simple_run_options(OutputFormat::Text, "", [])) {
    Success(output) => {
      assert_true(output.contains("Execution Summary"))
      assert_true(output.contains("Entry: 0x10000"))
      assert_true(output.contains("PC: 0x1002c"))
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
  match execute_run_result(simple_run_options(OutputFormat::Json, "", [])) {
    Success(output) => {
      assert_true(output.contains("\"entry\":\"0x10000\""))
      assert_true(output.contains("\"xlen\":32"))
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
    execute_run_result(simple_run_options(OutputFormat::Text, "", ["0x10010"])) {
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
    execute_run_result(simple_run_options(OutputFormat::Text, trace_path, [])) {
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
test "workbench command generates offline html artifact" {
  ensure_cli_test_dir()
  let output_path = CLI_TEST_DIR + "/simple_workbench.html"
  reset_cli_test_file(output_path)

  match
    execute_workbench_result({
      file_path: "example/simple.elf",
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
      assert_true(html.contains("\"embedded_data\""))
    }
    Failure(err) => abort(err)
  }
}
