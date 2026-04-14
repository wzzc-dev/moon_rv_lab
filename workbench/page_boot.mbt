///|
fn embedded_boot_json(
  overview_json : String,
  function_slices_json : String,
  max_instructions : Int,
) -> String {
  "{\"mode\":\"embedded\",\"default_file\":\"\",\"initial_file\":\"\",\"max_inst\":" +
  normalize_max_instructions(max_instructions).to_string() +
  ",\"overview_endpoint\":\"/api/workbench/overview\",\"function_endpoint\":\"/api/workbench/function\",\"embedded_overview\":" +
  overview_json +
  ",\"embedded_function_slices\":" +
  function_slices_json +
  ",\"raw_mode\":false,\"base_addr\":\"0x10000\",\"xlen\":64" +
  "}"
}

///|
fn remote_boot_json(
  default_file : String,
  initial_file : String,
  max_instructions : Int,
  overview_endpoint : String,
  function_endpoint : String,
  upload_endpoint : String,
  raw_mode : Bool,
  base_addr : UInt,
  xlen : Int,
) -> String {
  let max_inst = normalize_max_instructions(max_instructions)
  let resolved_overview_endpoint = if overview_endpoint == "" {
    "/api/workbench/overview"
  } else {
    overview_endpoint
  }
  let resolved_function_endpoint = if function_endpoint == "" {
    "/api/workbench/function"
  } else {
    function_endpoint
  }
  let resolved_upload_endpoint = if upload_endpoint == "" {
    "/api/workbench/upload"
  } else {
    upload_endpoint
  }
  "{\"mode\":\"remote\",\"default_file\":" +
  json_string(default_file) +
  ",\"initial_file\":" +
  json_string(initial_file) +
  ",\"max_inst\":" +
  max_inst.to_string() +
  ",\"overview_endpoint\":" +
  json_string(resolved_overview_endpoint) +
  ",\"function_endpoint\":" +
  json_string(resolved_function_endpoint) +
  ",\"upload_endpoint\":" +
  json_string(resolved_upload_endpoint) +
  ",\"raw_mode\":" +
  bool_to_json(raw_mode) +
  ",\"base_addr\":" +
  json_string(format_hex(base_addr)) +
  ",\"xlen\":" +
  normalize_remote_xlen(xlen).to_string() +
  ",\"embedded_overview\":null,\"embedded_function_slices\":{}}"
}

///|
fn normalize_remote_xlen(xlen : Int) -> Int {
  if xlen == 32 {
    32
  } else {
    64
  }
}
