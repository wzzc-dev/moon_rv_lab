///|
test "index html exposes online workbench entry" {
  let html = build_index_html(default_options())
  assert_true(html.contains("/workbench?file=example/simple.elf"))
  assert_true(html.contains("Open Online Workbench"))
  assert_true(html.contains("GET /workbench?file=&lt;path&gt;"))
  assert_true(html.contains("/api/workbench/overview"))
  assert_true(html.contains("/api/workbench/function"))
  assert_false(html.contains("window.__RVR_CONFIG__"))
}

///|
test "workbench route html embeds online bootstrap config" {
  let opts = {
    ..default_options(),
    default_file: "example/simple.elf",
    max_inst: 96,
  }
  let html = build_workbench_route_html(opts, "example/simple.elf")
  assert_true(html.contains("WORKBENCH_BOOT"))
  assert_true(html.contains("\"mode\":\"remote\""))
  assert_true(html.contains("\"initial_file\":\"example/simple.elf\""))
  assert_true(
    html.contains("\"overview_endpoint\":\"/api/workbench/overview\""),
  )
  assert_true(
    html.contains("\"function_endpoint\":\"/api/workbench/function\""),
  )
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("id=\"file-input\""))
  assert_true(html.contains("id=\"cfg-subtitle\""))
}
