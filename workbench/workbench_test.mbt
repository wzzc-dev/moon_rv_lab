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
  let elf = @format.assemble_to_elf(@asm.encode_to_bytes(assembled), TEST_BASE)
  @fs.write_bytes_to_file(path, Bytes::from_array(elf)) catch {
    _ => abort("failed to write elf")
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
  assert_true(json.contains("\"instruction_count\":5"))
  assert_true(json.contains("\"runtime_event_count\":4"))
  assert_true(json.contains("\"initial_registers\""))
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
  assert_true(html.contains("class=\"splitter splitter-x\""))
  assert_true(html.contains("class=\"pane-tabs\""))
  assert_true(html.contains("class=\"main-grid\""))
  assert_true(html.contains("id=\"follow-pc\""))
  assert_true(html.contains("id=\"cfg-subtitle\""))
  assert_true(html.contains("id=\"recent-writes\""))
  assert_true(html.contains("class=\"pane result-pane\""))
  assert_true(html.contains("localStorage"))
  assert_true(html.contains("\"embedded_overview\""))
  assert_true(html.contains("\"embedded_function_slices\""))
  assert_true(html.contains("overview.events"))
  assert_true(html.contains("overview.runtime.initial_registers"))
  assert_false(html.contains("id=\"current-function-only\""))
}

///|
test "overview api json includes hello navigation metadata" {
  let json = overview_api_json_from_file("example/hello-riscv64", 200)
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"function_count\":66"))
  assert_true(json.contains("\"total_instruction_count\":3430"))
  assert_true(json.contains("\"functions\""))
  assert_true(json.contains("\"sections\""))
  assert_true(json.contains("\"runtime\""))
  assert_true(json.contains("\"events\""))
}

///|
test "function api json returns per-function slice payload" {
  let json = function_api_json_from_file("example/hello-riscv64", "main")
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("\"function\":{\"name\":\"main\""))
  assert_true(json.contains("\"instructions\""))
  assert_true(json.contains("\"blocks\""))
  assert_true(json.contains("\"edges\""))
  assert_true(json.contains("\"available\":true"))
}

///|
test "online workbench html bootstraps from overview and function apis" {
  let html = online_page_html(
    "example/simple.elf", "example/simple.elf", 64, "/api/workbench/overview",
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
  assert_true(html.contains("id=\"file-input\""))
  assert_true(html.contains("id=\"file-load-btn\""))
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("class=\"pane-tabs\""))
  assert_true(
    html.contains(
      "loadOverview(state.currentFile || boot.default_file || \"\", false)",
    ),
  )
  assert_true(html.contains("id=\"cfg-subtitle\""))
}
