///|
test "index html exposes online workbench entry" {
  let html = build_index_html(default_options())
  assert_true(html.contains("/workbench?file=example/simple.elf"))
  assert_true(html.contains("Open Online Workbench"))
  assert_true(html.contains("GET /workbench?file=<path>"))
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
  assert_true(html.contains("\"snapshot_endpoint\":\"/api/snapshot\""))
  assert_true(html.contains("class=\"workbench-shell\""))
  assert_true(html.contains("id=\"file-input\""))
}
