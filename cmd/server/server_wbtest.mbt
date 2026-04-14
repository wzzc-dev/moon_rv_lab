///|
test "index html exposes online workbench entry" {
  let html = build_index_html(default_options())
  assert_true(html.contains("MoonRV Lab Online Workbench"))
  assert_true(
    html.contains("面向演示、回归和课堂实验的在线入口"),
  )
  assert_true(html.contains("/workbench?file=out/simple.elf"))
  assert_true(
    html.contains(
      "/workbench?file=out/simple.raw&amp;raw=1&amp;base=0x10000&amp;xlen=64",
    ),
  )
  assert_true(html.contains("Open Online Workbench"))
  assert_true(html.contains("查看 Quick Start"))
  assert_true(html.contains("Quick Start"))
  assert_true(html.contains("默认文件"))
  assert_true(html.contains("在线工作台"))
  assert_true(html.contains("离线工作台"))
  assert_true(
    html.contains(
      "moon run cmd/main -- workbench out/simple.elf -o out/workbench.html",
    ),
  )
  assert_true(
    html.contains("moon run cmd/main -- asm example/simple.s -o out/simple.elf"),
  )
  assert_true(html.contains("Primary APIs"))
  assert_true(html.contains("Compatibility APIs"))
  assert_true(
    html.contains(
      "overview/function 为主接口，snapshot/stream 为兼容接口",
    ),
  )
  assert_true(
    html.contains("Windows 上的 server 原生回归依赖 MSVC 工具链"),
  )
  assert_true(
    html.contains(
      "GET /workbench?file=&lt;path&gt;[&amp;raw=1&amp;base=&lt;addr&gt;&amp;xlen=32|64]",
    ),
  )
  assert_true(
    html.contains(
      "/api/workbench/overview?file=&lt;path&gt;&amp;max_events=&lt;n&gt;[&amp;raw=1&amp;base=&lt;addr&gt;&amp;xlen=32|64]",
    ),
  )
  assert_true(
    html.contains(
      "/api/workbench/function?file=&lt;path&gt;&amp;addr=&lt;hex-or-name&gt;[&amp;raw=1&amp;base=&lt;addr&gt;&amp;xlen=32|64]",
    ),
  )
  assert_true(html.contains("/api/snapshot"))
  assert_true(html.contains("/api/stream"))
  assert_false(html.contains("window.__RVR_CONFIG__"))
}

///|
test "workbench route html embeds online bootstrap config" {
  let opts = {
    ..default_options(),
    default_file: "out/simple.elf",
    max_inst: 96,
  }
  let html = build_workbench_route_html(opts, "out/simple.elf")
  assert_true(html.contains("WORKBENCH_BOOT"))
  assert_true(html.contains("\"mode\":\"remote\""))
  assert_true(html.contains("\"initial_file\":\"out/simple.elf\""))
  assert_true(
    html.contains("\"overview_endpoint\":\"/api/workbench/overview\""),
  )
  assert_true(
    html.contains("\"function_endpoint\":\"/api/workbench/function\""),
  )
  assert_true(html.contains("\"upload_endpoint\":\"/api/workbench/upload\""))
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("id=\"file-input\""))
  assert_true(html.contains("id=\"file-load-btn\""))
  assert_true(html.contains("id=\"file-picker\""))
  assert_true(html.contains("id=\"file-upload-btn\""))
  assert_true(html.contains("Upload ELF"))
  assert_true(html.contains("id=\"input-mode\""))
  assert_true(html.contains("id=\"raw-base-input\""))
  assert_true(html.contains("id=\"raw-xlen-input\""))
  assert_true(html.contains("\"default_file\":\"out/simple.elf\""))
  assert_true(html.contains("\"raw_mode\":false"))
  assert_true(html.contains("\"base_addr\":\"0x10000\""))
  assert_true(html.contains("\"xlen\":64"))
  assert_true(html.contains("boot.default_file"))
  assert_true(html.contains("id=\"help-panel\""))
  assert_true(html.contains("How to use"))
  assert_true(html.contains("Replay Breakpoints"))
  assert_true(html.contains("Replay breakpoint @"))
  assert_true(html.contains("State Compare"))
  assert_true(html.contains("id=\"toolbar-toggle-nav\""))
  assert_true(html.contains("id=\"toolbar-toggle-bottom\""))
  assert_true(html.contains("id=\"toolbar-toggle-inspector\""))
  assert_true(html.contains("Prev step"))
  assert_true(html.contains("Initial"))
  assert_true(html.contains("data-breakpoint-addr"))
  assert_false(html.contains("loadSnapshot("))
  assert_false(html.contains("snapshot_endpoint"))
  assert_false(html.contains("snapshot failed"))
  assert_false(html.contains("\"embedded_data\""))
  assert_false(html.contains("/api/snapshot"))
  assert_true(html.contains("id=\"cfg-subtitle\""))
}

///|
test "workbench route html embeds raw bootstrap config" {
  let opts = {
    ..default_options(),
    default_file: "out/simple.elf",
    max_inst: 96,
  }
  let html = build_workbench_route_html_with_input(opts, {
    file: "out/simple.raw",
    raw_mode: true,
    base_addr: 0x10000U,
    xlen: 32,
  })
  assert_true(html.contains("\"initial_file\":\"out/simple.raw\""))
  assert_true(html.contains("\"raw_mode\":true"))
  assert_true(html.contains("\"base_addr\":\"0x10000\""))
  assert_true(html.contains("\"xlen\":32"))
  assert_true(html.contains("id=\"input-mode\""))
  assert_true(html.contains("id=\"raw-base-input\""))
  assert_true(html.contains("id=\"raw-xlen-input\""))
}

///|
test "workbench route query parsing validates raw parameters" {
  match
    parse_workbench_route_input_strict(
      "out/simple.raw",
      Some("1"),
      Some("0x20000"),
      Some("32"),
    ) {
    WorkbenchRouteOk(input) => {
      assert_true(input.raw_mode)
      assert_eq(input.file, "out/simple.raw")
      assert_eq(input.base_addr, 0x20000U)
      assert_eq(input.xlen, 32)
    }
    WorkbenchRouteErr(err) => abort(err)
  }

  match
    parse_workbench_route_input_strict(
      "out/simple.raw",
      Some("1"),
      Some("bad"),
      Some("64"),
    ) {
    WorkbenchRouteOk(_) => abort("expected raw base parse failure")
    WorkbenchRouteErr(err) => assert_true(err.contains("invalid raw base"))
  }

  match
    parse_workbench_route_input_strict(
      "out/simple.raw",
      Some("1"),
      Some("0x10000"),
      Some("128"),
    ) {
    WorkbenchRouteOk(_) => abort("expected raw xlen parse failure")
    WorkbenchRouteErr(err) => assert_true(err.contains("invalid raw xlen"))
  }
}

///|
test "upload payload parsing supports elf and raw metadata" {
  match
    parse_upload_payload({
      "filename": "demo.elf",
      "content_base64": "AA==",
      "input_format": "elf",
    }) {
    UploadPayloadOk(payload) => {
      assert_eq(payload.filename, "demo.elf")
      assert_eq(payload.input_format, "elf")
      assert_eq(payload.base_addr, 0x10000U)
      assert_eq(payload.xlen, 64)
    }
    UploadPayloadErr(err) => abort(err)
  }

  match
    parse_upload_payload({
      "filename": "demo.raw",
      "content_base64": "AA==",
      "input_format": "raw",
      "base_addr": "0x20000",
      "xlen": 32,
    }) {
    UploadPayloadOk(payload) => {
      assert_eq(payload.input_format, "raw")
      assert_eq(payload.base_addr, 0x20000U)
      assert_eq(payload.xlen, 32)
    }
    UploadPayloadErr(err) => abort(err)
  }
}

///|
test "upload payload parsing rejects invalid raw metadata" {
  match
    parse_upload_payload({
      "filename": "demo.raw",
      "content_base64": "AA==",
      "input_format": "raw",
      "base_addr": "bad",
      "xlen": 128,
    }) {
    UploadPayloadOk(_) => abort("expected invalid raw upload payload")
    UploadPayloadErr(err) =>
      assert_true(err.contains("base_addr") || err.contains("xlen"))
  }
}
