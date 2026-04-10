///|
const TEST_BASE : UInt = 0x10000U

///|
const TEST_DIR : String = "tmp_workbench_tests"

///|
fn ensure_test_dir() -> Unit {
  if !@fs.path_exists(TEST_DIR) {
    @fs.create_dir(TEST_DIR) catch {
      _ => abort("failed to create workbench test dir")
    }
  }
}

///|
fn write_test_elf(name : String, source : String) -> String {
  write_test_elf_with_xlen(name, source, 64)
}

///|
fn write_test_elf_with_xlen(
  name : String,
  source : String,
  xlen : Int,
) -> String {
  ensure_test_dir()
  let path = TEST_DIR + "/" + name + ".elf"
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
  let assembled = @asm.assemble_with_symbols(source, TEST_BASE)
  if assembled.errors.length() != 0 {
    abort("assembly failed")
  }
  let bytes = @asm.encode_to_bytes(assembled)
  let elf = if xlen == 32 {
    @format.assemble_to_elf32(bytes, TEST_BASE)
  } else {
    @format.assemble_to_elf64(bytes, TEST_BASE)
  }
  @fs.write_bytes_to_file(path, Bytes::from_array(elf)) catch {
    _ => abort("failed to write elf")
  }
  path
}

///|
fn write_test_raw(name : String, source : String) -> String {
  ensure_test_dir()
  let path = TEST_DIR + "/" + name + ".raw"
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
  let assembled = @asm.assemble_with_symbols(source, TEST_BASE)
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
fn branch_trace_program() -> String {
  "addi a0, x0, 1\nbeq a0, a0, 8\naddi a1, x0, 9\naddi a2, x0, 3\nebreak"
}

///|
fn read_text_file(path : String) -> String {
  let bytes = @fs.read_file_to_bytes(path).to_fixedarray() catch {
    _ => abort("failed to read text file")
  }
  let mut content = ""
  for i = 0; i < bytes.length(); i = i + 1 {
    content = content + bytes[i].to_int().unsafe_to_char().to_string()
  }
  content
}

///|
test "workbench snapshot json includes runtime metadata" {
  let path = write_test_elf("snapshot_runtime", branch_trace_program())
  let json = snapshot_api_json_from_file(path, 20)
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"initial_pc\":\"0x10000\""))
  assert_true(json.contains("\"file_class\":\"ELF64\""))
  assert_true(json.contains("\"xlen\":64"))
  assert_true(json.contains("\"instruction_count\":5"))
  assert_true(json.contains("\"runtime_event_count\":4"))
  assert_true(json.contains("\"initial_registers\""))
}

///|
test "workbench snapshot json preserves rv32 xlen metadata" {
  let path = write_test_elf_with_xlen(
    "snapshot_runtime_rv32",
    branch_trace_program(),
    32,
  )
  let json = snapshot_api_json_from_file(path, 20)
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"file_class\":\"ELF32\""))
  assert_true(json.contains("\"xlen\":32"))
  assert_true(json.contains("\"instruction_count\":5"))
}

///|
test "workbench stream payloads follow execution order instead of disasm order" {
  let path = write_test_elf("stream_runtime", branch_trace_program())
  match stream_event_payloads_from_file(path, 20, 20) {
    StreamEventsOk(events) => {
      assert_eq(events.length(), 4)
      assert_true(events[0].contains("\"addr\":\"0x10000\""))
      assert_true(events[1].contains("\"addr\":\"0x10004\""))
      assert_true(events[2].contains("\"addr\":\"0x1000c\""))
      let mut skipped_seen = false
      for event in events {
        if event.contains("\"addr\":\"0x10008\"") {
          skipped_seen = true
        }
      }
      assert_false(skipped_seen)
    }
    StreamEventsErr(err) => abort(err)
  }
}

///|
test "generated workbench html includes godbolt style panes and controls" {
  let path = write_test_elf("godbolt_layout", branch_trace_program())
  let output = TEST_DIR + "/godbolt_layout.html"
  match
    generate_from_file(path, output, create_options("Godbolt Workbench", 20)) {
    None => ()
    Some(err) => abort(err.to_string())
  }

  let html = read_text_file(output)
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("id=\"help-panel\""))
  assert_true(html.contains("id=\"help-toggle\""))
  assert_true(html.contains("How to use"))
  assert_true(html.contains("Reset / Prev / Next / Play"))
  assert_true(html.contains("Follow PC"))
  assert_true(html.contains("class=\"splitter splitter-x\""))
  assert_true(html.contains("class=\"pane-tabs\""))
  assert_true(html.contains("class=\"main-grid\""))
  assert_true(html.contains("id=\"follow-pc\""))
  assert_true(html.contains("id=\"toolbar-toggle-nav\""))
  assert_true(html.contains("id=\"toolbar-toggle-bottom\""))
  assert_true(html.contains("id=\"toolbar-toggle-inspector\""))
  assert_true(html.contains("id=\"cfg-subtitle\""))
  assert_true(html.contains("id=\"recent-writes\""))
  assert_true(html.contains("id=\"breakpoint-summary\""))
  assert_true(html.contains("id=\"breakpoint-list\""))
  assert_true(html.contains("id=\"breakpoint-clear-btn\""))
  assert_true(html.contains("State Compare"))
  assert_true(html.contains("id=\"compare-body\""))
  assert_true(html.contains("id=\"compare-prev-btn\""))
  assert_true(html.contains("id=\"compare-initial-btn\""))
  assert_true(html.contains("class=\"pane result-pane\""))
  assert_true(html.contains("localStorage"))
  assert_true(html.contains("helpCollapsed"))
  assert_true(html.contains("helpCollapsed: true"))
  assert_true(html.contains("\"embedded_overview\""))
  assert_true(html.contains("\"embedded_function_slices\""))
  assert_true(html.contains("\"xlen\":64"))
  assert_true(html.contains("overview.events"))
  assert_true(html.contains("overview.runtime.initial_registers"))
  assert_true(html.contains("height: 100dvh;"))
  assert_true(html.contains("min-height: 100dvh;"))
  assert_true(html.contains("overscroll-behavior: none;"))
  assert_true(html.contains("overscroll-behavior: contain;"))
  assert_true(html.contains("max-height: min(38vh, 420px);"))
  assert_true(html.contains("state.breakpoints"))
  assert_true(html.contains("replayBreakpointHit"))
  assert_true(html.contains("compareMode"))
  assert_true(html.contains("renderStateCompare"))
  assert_true(html.contains("toggleNavPaneVisibility"))
  assert_true(html.contains("toggleBottomPaneVisibility"))
  assert_true(html.contains("toggleInspectorPaneVisibility"))
  assert_false(html.contains("id=\"current-function-only\""))
}

///|
test "generated workbench html keeps navigation and actionable hint hooks" {
  let path = write_test_elf("workbench_copy", branch_trace_program())
  let output = TEST_DIR + "/workbench_copy.html"
  match
    generate_from_file(path, output, create_options("Guided Workbench", 20)) {
    None => ()
    Some(err) => abort(err.to_string())
  }

  let html = read_text_file(output)
  assert_true(html.contains("6. Trace / Memory / Syscalls"))
  assert_true(html.contains("click to focus"))
  assert_true(html.contains("selected"))
  assert_true(html.contains("current pc"))
  assert_true(html.contains("--max-inst"))
  assert_true(html.contains("focus="))
  assert_true(html.contains("step=0 pc=initial"))
  assert_true(html.contains("filter="))
  assert_true(html.contains("Replay breakpoint @"))
  assert_true(html.contains("data-breakpoint-addr"))
  assert_true(html.contains("clearAllReplayBreakpoints"))
  assert_true(html.contains("setReplayBreakpoint"))
  assert_true(html.contains("Prev step baseline"))
  assert_true(html.contains("Initial baseline"))
  assert_true(html.contains("compareRegistersToInitial"))
}

///|
test "generated workbench html supports raw offline inputs" {
  let path = write_test_raw("raw_workbench", branch_trace_program())
  let output = TEST_DIR + "/raw_workbench.html"
  match
    generate_from_file(
      path,
      output,
      create_input_options("Raw Workbench", 20, true, TEST_BASE, 64),
    ) {
    None => ()
    Some(err) => abort(err.to_string())
  }

  let html = read_text_file(output)
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("\"file_class\":\"RAW\""))
  assert_true(html.contains("\"xlen\":64"))
  assert_true(html.contains("\"entry_point\":\"0x10000\""))
  assert_true(html.contains("\"name\":\"entry\""))
  assert_true(
    html.contains("\"source_file\":\"tmp_workbench_tests/raw_workbench.raw\""),
  )
}

///|
test "overview api json includes hello navigation metadata" {
  let path = write_test_elf("overview_api", branch_trace_program())
  let json = overview_api_json_from_file(path, 200)
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"file_class\":\"ELF64\""))
  assert_true(json.contains("\"xlen\":64"))
  assert_true(json.contains("\"function_count\":1"))
  assert_true(json.contains("\"instruction_count\":5"))
  assert_true(json.contains("\"total_instruction_count\":5"))
  assert_true(json.contains("\"functions\""))
  assert_true(json.contains("\"name\":\"entry\""))
  assert_true(json.contains("\"sections\""))
  assert_true(json.contains("\"runtime\""))
  assert_true(json.contains("\"events\""))
}

///|
test "overview api json preserves rv32 xlen metadata" {
  let path = write_test_elf_with_xlen(
    "overview_api_rv32",
    branch_trace_program(),
    32,
  )
  let json = overview_api_json_from_file(path, 200)
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"file_class\":\"ELF32\""))
  assert_true(json.contains("\"xlen\":32"))
  assert_true(json.contains("\"function_count\":1"))
  assert_true(json.contains("\"instruction_count\":5"))
}

///|
test "overview api json supports raw online inputs" {
  let path = write_test_raw("overview_api_raw", branch_trace_program())
  let json = overview_api_json_from_file_with_options(
    path,
    200,
    create_input_options("", 200, true, TEST_BASE, 64),
  )
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"input_format\":\"raw\""))
  assert_true(json.contains("\"file_class\":\"RAW\""))
  assert_true(json.contains("\"entry_point\":\"0x10000\""))
  assert_true(json.contains("\"name\":\"entry\""))
  assert_true(json.contains("\"xlen\":64"))
}

///|
test "function api json returns per-function slice payload" {
  let path = write_test_elf("function_api", branch_trace_program())
  let json = function_api_json_from_file(path, "0x10000")
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"function\":{\"name\":\"entry\""))
  assert_true(json.contains("\"addr\":\"0x10000\""))
  assert_true(json.contains("\"instructions\""))
  assert_true(json.contains("\"blocks\""))
  assert_true(json.contains("\"edges\""))
  assert_true(json.contains("\"available\":true"))
}

///|
test "function api json supports raw synthetic entry slices" {
  let path = write_test_raw("function_api_raw", branch_trace_program())
  let json = function_api_json_from_file_with_options(
    path,
    "entry",
    create_input_options("", 200, true, TEST_BASE, 64),
  )
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"function\":{\"name\":\"entry\""))
  assert_true(json.contains("\"addr\":\"0x10000\""))
  assert_true(json.contains("\"available\":true"))
  assert_true(json.contains("\"instructions\""))
}

///|
test "online workbench html bootstraps from overview and function apis" {
  let html = online_page_html(
    "out/simple.elf", "out/simple.elf", 64, "/api/workbench/overview",
  )

  assert_true(html.contains("WORKBENCH_BOOT"))
  assert_true(html.contains("\"mode\":\"remote\""))
  assert_true(
    html.contains("\"overview_endpoint\":\"/api/workbench/overview\""),
  )
  assert_true(
    html.contains("\"function_endpoint\":\"/api/workbench/function\""),
  )
  assert_true(html.contains("boot.overview_endpoint"))
  assert_true(html.contains("boot.function_endpoint"))
  assert_true(html.contains("xlen: 0"))
  assert_true(html.contains("\"raw_mode\":false"))
  assert_true(html.contains("\"base_addr\":\"0x10000\""))
  assert_true(html.contains("\"xlen\":64"))
  assert_true(html.contains("id=\"file-input\""))
  assert_true(html.contains("id=\"file-load-btn\""))
  assert_true(html.contains("id=\"input-mode-field\""))
  assert_true(html.contains("id=\"input-mode\""))
  assert_true(html.contains("id=\"raw-base-field\""))
  assert_true(html.contains("id=\"raw-base-input\""))
  assert_true(html.contains("id=\"raw-xlen-field\""))
  assert_true(html.contains("id=\"raw-xlen-input\""))
  assert_true(html.contains("\"default_file\":\"out/simple.elf\""))
  assert_true(html.contains("boot.default_file"))
  assert_true(html.contains("id=\"help-panel\""))
  assert_true(html.contains("id=\"help-toggle\""))
  assert_true(html.contains("How to use"))
  assert_true(html.contains("在线模式可切换 ELF / RAW"))
  assert_true(html.contains("3. 搜索 / 跳转"))
  assert_true(html.contains("6. Trace / Memory / Syscalls"))
  assert_true(html.contains("点击地址同步搜索"))
  assert_true(html.contains("当前过滤条件下没有匹配函数。"))
  assert_true(
    html.contains(
      "可清空搜索，或输入精确地址后按 Enter 跳转。",
    ),
  )
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("class=\"pane-tabs\""))
  assert_true(
    html.contains(
      "loadOverview(state.currentFile || boot.default_file || \"\", false)",
    ),
  )
  assert_false(html.contains("loadSnapshot("))
  assert_false(html.contains("snapshot_endpoint"))
  assert_false(html.contains("snapshot failed"))
  assert_false(html.contains("\"embedded_data\""))
  assert_false(html.contains("/api/snapshot"))
  assert_true(html.contains("id=\"cfg-subtitle\""))
}

///|
test "online workbench html preserves raw boot metadata" {
  let html = online_page_html_with_options(
    "out/simple.elf",
    "out/simple.raw",
    64,
    "/api/workbench/overview",
    "/api/workbench/function",
    "/api/workbench/upload",
    create_input_options("", 64, true, TEST_BASE, 32),
  )

  assert_true(html.contains("\"initial_file\":\"out/simple.raw\""))
  assert_true(html.contains("\"raw_mode\":true"))
  assert_true(html.contains("\"base_addr\":\"0x10000\""))
  assert_true(html.contains("\"xlen\":32"))
  assert_true(html.contains("\"upload_endpoint\":\"/api/workbench/upload\""))
  assert_true(html.contains("Upload RAW"))
  assert_true(html.contains("buildRemoteParams"))
  assert_true(html.contains("id=\"input-mode\""))
  assert_true(html.contains("id=\"raw-base-input\""))
  assert_true(html.contains("id=\"raw-xlen-input\""))
}
