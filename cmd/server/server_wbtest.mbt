///|
test "index html exposes online workbench entry" {
  let html = build_index_html(default_options())
  assert_true(html.contains("MoonRV Lab Online Workbench"))
  assert_true(
    html.contains("面向演示、回归和课堂实验的在线入口"),
  )
  assert_true(html.contains("/workbench?file=out/simple.elf"))
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
  assert_true(html.contains("GET /workbench?file=&lt;path&gt;"))
  assert_true(html.contains("/api/workbench/overview"))
  assert_true(html.contains("/api/workbench/function"))
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
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("id=\"file-input\""))
  assert_true(html.contains("id=\"file-load-btn\""))
  assert_true(html.contains("\"default_file\":\"out/simple.elf\""))
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
