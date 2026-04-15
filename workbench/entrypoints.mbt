///|
/// Public workbench entrypoints for HTML and API generation.

///|
/// Generate a standalone Web workbench page from an input program.
/// Returns `Some(error)` on failure; `None` means success.
pub fn generate_from_file(
  input_file : String,
  output_file : String,
  options : WorkbenchOptions,
) -> WorkbenchError? {
  generate_from_input(
    input_spec_from_options(input_file, options),
    output_file,
    options,
  )
}

///|
fn generate_from_input(
  input : @program.InputSpec,
  output_file : String,
  options : WorkbenchOptions,
) -> WorkbenchError? {
  let page_title = resolve_page_title(options.title)
  let max_inst = normalize_max_instructions(options.max_instructions)
  match load_static_program_index_input(input, page_title) {
    StaticProgramErr(err) => Some(err)
    StaticProgramOk(index) => {
      let (runtime, events) = load_runtime_trace_with_options(
        input.file_path,
        max_inst,
        index.blocks,
        options,
      )
      let functions = build_workbench_functions(index, events)
      let overview = build_workbench_overview(
        index,
        functions,
        runtime,
        events,
        DEFAULT_MAX_INSTRUCTIONS,
      )
      let slices = build_embedded_function_slices(
        index,
        functions,
        DEFAULT_MAX_INSTRUCTIONS,
      )
      let html = build_html_page(
        overview.meta.title,
        embedded_boot_json(
          to_json_overview(overview),
          to_json_function_slices_map(slices),
          max_inst,
        ),
      )
      if write_output_file(output_file, html) {
        None
      } else {
        Some(WorkbenchError::WriteFailed(output_file))
      }
    }
  }
}

///|
/// Build a JSON payload for `/api/snapshot`.
pub fn snapshot_api_json_from_file(
  input_file : String,
  max_instructions : Int,
) -> String {
  let options = create_options("", max_instructions)
  match load_workbench_data(input_file, options) {
    Ok(data) => "{\"ok\":true,\"data\":" + to_json(data) + "}"
    Err(err) => api_error_json(err)
  }
}

///|
pub fn overview_api_json_from_file(
  input_file : String,
  max_events : Int,
) -> String {
  overview_api_json(
    @program.default_workbench_request(
      input_file,
      "",
      max_events,
      DEFAULT_MAX_INSTRUCTIONS,
    ),
  )
}

///|
pub fn overview_api_json(request : @program.WorkbenchRequest) -> String {
  overview_api_json_from_file_with_options(
    request.input.file_path,
    request.max_events,
    create_api_options(
      request.input.is_raw(),
      request.input.base_addr,
      request.input.xlen,
    ),
  )
}

///|
pub fn overview_api_json_from_file_with_options(
  input_file : String,
  max_events : Int,
  options : WorkbenchOptions,
) -> String {
  let request = @program.parse_workbench_request_lenient(
    input_file,
    if options.raw_mode {
      Some("1")
    } else {
      None
    },
    Some(format_hex(options.base_addr)),
    Some(options.xlen.to_string()),
    "",
    normalize_max_events(max_events),
    options.max_instructions,
  )
  let page_title = resolve_page_title("")
  match load_static_program_index_input(request.input, page_title) {
    StaticProgramErr(err) => api_error_json(err)
    StaticProgramOk(index) => {
      let (runtime, events) = load_runtime_trace_input(
        request.input,
        request.max_events,
        index.blocks,
      )
      let functions = build_workbench_functions(index, events)
      let overview = build_workbench_overview(
        index,
        functions,
        runtime,
        events,
        DEFAULT_MAX_INSTRUCTIONS,
      )
      "{\"ok\":true,\"data\":" + to_json_overview(overview) + "}"
    }
  }
}

///|
pub fn function_api_json_from_file(
  input_file : String,
  function : String,
) -> String {
  function_api_json(
    @program.default_workbench_request(
      input_file,
      function,
      DEFAULT_MAX_INSTRUCTIONS,
      DEFAULT_MAX_INSTRUCTIONS,
    ),
  )
}

///|
pub fn function_api_json(request : @program.WorkbenchRequest) -> String {
  function_api_json_from_file_with_options(
    request.input.file_path,
    request.function_selector,
    create_api_options(
      request.input.is_raw(),
      request.input.base_addr,
      request.input.xlen,
    ),
  )
}

///|
pub fn function_api_json_from_file_with_options(
  input_file : String,
  function : String,
  options : WorkbenchOptions,
) -> String {
  let page_title = resolve_page_title("")
  match
    load_static_program_index_input(
      input_spec_from_options(input_file, options),
      page_title,
    ) {
    StaticProgramErr(err) => api_error_json(err)
    StaticProgramOk(index) =>
      match build_function_slice_response(index, function, true) {
        Some(slice) =>
          "{\"ok\":true,\"data\":" + to_json_function_slice(slice) + "}"
        None =>
          "{\"ok\":false,\"error\":" +
          json_string("function not found: " + function) +
          "}"
      }
  }
}

///|
/// Build a JSON payload for `/api/stream`.
pub fn stream_api_json_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int,
) -> String {
  match
    stream_event_payloads_from_file(input_file, max_instructions, max_events) {
    StreamEventsOk(events) =>
      "{\"ok\":true,\"events\":" +
      join_json_values(events) +
      ",\"total_events\":" +
      events.length().to_string() +
      "}"
    StreamEventsErr(err) => "{\"ok\":false,\"error\":" + json_string(err) + "}"
  }
}

///|
pub enum StreamEventsLoadResult {
  StreamEventsOk(Array[String])
  StreamEventsErr(String)
} derive(Show)

///|
/// Build stream event payloads for SSE APIs.
pub fn stream_event_payloads_from_file(
  input_file : String,
  max_instructions : Int,
  max_events : Int,
) -> StreamEventsLoadResult {
  let page_title = resolve_page_title("")
  let event_limit = normalize_max_events(max_events)
  let step_limit = normalize_max_instructions(max_instructions)
  match load_static_program_index(input_file, page_title) {
    StaticProgramErr(err) => StreamEventsErr(err.to_string())
    StaticProgramOk(index) => {
      let (_, events) = load_runtime_trace(input_file, step_limit, index.blocks)
      StreamEventsOk(build_stream_event_payloads(events, event_limit))
    }
  }
}

///|
/// Build a standalone online workbench page that loads data from workbench APIs.
pub fn online_page_html(
  default_file : String,
  initial_file : String,
  max_instructions : Int,
  overview_endpoint : String,
) -> String {
  online_page_html_with_request(
    default_file,
    @program.default_workbench_request(
      initial_file,
      "",
      DEFAULT_MAX_INSTRUCTIONS,
      max_instructions,
    ),
    overview_endpoint,
    "/api/workbench/function",
  )
}

///|
pub fn online_page_html_with_request(
  default_file : String,
  request : @program.WorkbenchRequest,
  overview_endpoint : String,
  function_endpoint : String,
) -> String {
  online_page_html_with_request_and_upload(
    default_file, request, overview_endpoint, function_endpoint, "/api/workbench/upload",
  )
}

///|
pub fn online_page_html_with_request_and_upload(
  default_file : String,
  request : @program.WorkbenchRequest,
  overview_endpoint : String,
  function_endpoint : String,
  upload_endpoint : String,
) -> String {
  online_page_html_with_options(
    default_file,
    request.input.file_path,
    request.max_instructions,
    overview_endpoint,
    function_endpoint,
    upload_endpoint,
    create_api_options(
      request.input.is_raw(),
      request.input.base_addr,
      request.input.xlen,
    ),
  )
}

///|
pub fn online_page_html_with_options(
  default_file : String,
  initial_file : String,
  max_instructions : Int,
  overview_endpoint : String,
  function_endpoint : String,
  upload_endpoint : String,
  options : WorkbenchOptions,
) -> String {
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
  build_html_page(
    "MoonRV Lab Online Workbench",
    remote_boot_json(
      default_file,
      initial_file,
      max_instructions,
      resolved_overview_endpoint,
      resolved_function_endpoint,
      resolved_upload_endpoint,
      options.raw_mode,
      options.base_addr,
      options.xlen,
    ),
  )
}
