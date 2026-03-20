///|
/// Online API server for MoonRV Lab (Luna + Mars)

///|
const DEFAULT_HOST : String = "127.0.0.1"

///|
const DEFAULT_PORT : Int = 18080

///|
const DEFAULT_MAX_INST : Int = 1200

///|
const DEFAULT_MAX_EVENTS : Int = 400

///|
const DEFAULT_INTERVAL_MS : Int = 350

///|
const INDEX_STYLE : String =
  #|:root {
  #|  --bg: #f7fafc;
  #|  --ink: #0f172a;
  #|  --muted: #475569;
  #|  --line: #dbe3ee;
  #|  --panel: #ffffff;
  #|  --accent: #0f766e;
  #|}
  #|* { box-sizing: border-box; }
  #|body {
  #|  margin: 0;
  #|  background: linear-gradient(180deg, #f8fbff 0%, #eef4fb 100%);
  #|  color: var(--ink);
  #|  font-family: "SFMono-Regular", "Iosevka", "JetBrains Mono", monospace;
  #|}
  #|#root { padding: 12px; }
  #|#app {
  #|  margin-top: 12px;
  #|  border: 1px solid var(--line);
  #|  border-radius: 12px;
  #|  background: var(--panel);
  #|  padding: 12px;
  #|}
  #|.toolbar {
  #|  display: grid;
  #|  grid-template-columns: minmax(220px, 1fr) repeat(3, auto);
  #|  gap: 8px;
  #|  align-items: center;
  #|  margin-bottom: 10px;
  #|}
  #|input, button {
  #|  border: 1px solid var(--line);
  #|  border-radius: 8px;
  #|  padding: 8px 10px;
  #|  background: white;
  #|  color: var(--ink);
  #|  font-family: inherit;
  #|  font-size: 12px;
  #|}
  #|button { cursor: pointer; }
  #|button.primary {
  #|  background: var(--accent);
  #|  color: #fff;
  #|  border-color: var(--accent);
  #|}
  #|.split {
  #|  display: grid;
  #|  grid-template-columns: 1fr 1fr;
  #|  gap: 10px;
  #|}
  #|pre, .trace {
  #|  border: 1px solid var(--line);
  #|  border-radius: 10px;
  #|  background: #fff;
  #|  padding: 8px;
  #|  margin: 0;
  #|  overflow: auto;
  #|  max-height: 260px;
  #|  font-size: 12px;
  #|}
  #|table { width: 100%; border-collapse: collapse; font-size: 12px; }
  #|th, td { border-bottom: 1px solid var(--line); padding: 4px 6px; text-align: left; }
  #|tr.active td { background: #e6fff6; }
  #|.hint { color: var(--muted); font-size: 12px; margin: 8px 0; }
  #|@media (max-width: 1024px) {
  #|  .toolbar { grid-template-columns: 1fr 1fr; }
  #|  .split { grid-template-columns: 1fr; }
  #|}

///|
const CLIENT_BOOTSTRAP_JS : String =
  #|(function() {
  #|  const cfg = window.__RVR_CONFIG__ || {};
  #|  const DEFAULT_FILE = String(cfg.defaultFile || "example/simple.elf");
  #|  const DEFAULT_MAX_INST = Number(cfg.defaultMaxInst || 1200);
  #|  const DEFAULT_MAX_EVENTS = Number(cfg.defaultMaxEvents || 400);
  #|  const DEFAULT_INTERVAL_MS = Number(cfg.defaultIntervalMs || 350);
  #|  const app = document.getElementById("app");
  #|  if (!app) return;
  #|  app.innerHTML =
  #|    "<div class=\"toolbar\">" +
  #|      "<input id=\"file\" value=\"" + DEFAULT_FILE + "\" placeholder=\"ELF file path\" />" +
  #|      "<button id=\"load\" class=\"primary\">Load Snapshot</button>" +
  #|      "<button id=\"start\">Start Stream</button>" +
  #|      "<button id=\"stop\">Stop Stream</button>" +
  #|    "</div>" +
  #|    "<div class=\"hint\" id=\"status\">Ready</div>" +
  #|    "<div class=\"split\">" +
  #|      "<div>" +
  #|        "<h3>Snapshot Meta</h3>" +
  #|        "<pre id=\"summary\"></pre>" +
  #|        "<h3>Instructions (first 120)</h3>" +
  #|        "<div style=\"max-height:300px;overflow:auto;\">" +
  #|          "<table>" +
  #|            "<thead><tr><th>#</th><th>Address</th><th>Instruction</th><th>Category</th></tr></thead>" +
  #|            "<tbody id=\"inst-body\"></tbody>" +
  #|          "</table>" +
  #|        "</div>" +
  #|      "</div>" +
  #|      "<div>" +
  #|        "<h3>Realtime Stream</h3>" +
  #|        "<div class=\"trace\" id=\"trace\"></div>" +
  #|      "</div>" +
  #|    "</div>";
  #|
  #|  const statusEl = document.getElementById("status");
  #|  const summaryEl = document.getElementById("summary");
  #|  const fileEl = document.getElementById("file");
  #|  const instBody = document.getElementById("inst-body");
  #|  const traceEl = document.getElementById("trace");
  #|  const loadBtn = document.getElementById("load");
  #|  const startBtn = document.getElementById("start");
  #|  const stopBtn = document.getElementById("stop");
  #|  let source = null;
  #|  let currentAddr = "";
  #|  let snapshotData = null;
  #|
  #|  const setStatus = (text) => { statusEl.textContent = text; };
  #|
  #|  function renderInstructions() {
  #|    const rows = (snapshotData?.instructions || []).slice(0, 120).map((inst) => {
  #|      const active = inst.addr === currentAddr ? " class=\\\"active\\\"" : "";
  #|      return "<tr" + active + "><td>" + inst.index + "</td><td>" + inst.addr + "</td><td>" + inst.asm + "</td><td>" + inst.category + "</td></tr>";
  #|    }).join("");
  #|    instBody.innerHTML = rows;
  #|  }
  #|
  #|  async function loadSnapshot() {
  #|    const file = fileEl.value.trim();
  #|    if (!file) {
  #|      setStatus("file path is required");
  #|      return;
  #|    }
  #|    setStatus("loading snapshot...");
  #|    const url = "/api/snapshot?file=" + encodeURIComponent(file) + "&max_inst=" + String(DEFAULT_MAX_INST);
  #|    try {
  #|      const resp = await fetch(url);
  #|      const payload = await resp.json();
  #|      if (!payload.ok) {
  #|        setStatus("snapshot failed: " + (payload.error || "unknown"));
  #|        return;
  #|      }
  #|      snapshotData = payload.data;
  #|      summaryEl.textContent = JSON.stringify(snapshotData.meta, null, 2);
  #|      currentAddr = "";
  #|      renderInstructions();
  #|      setStatus("snapshot loaded");
  #|    } catch (err) {
  #|      setStatus("request failed: " + String(err));
  #|    }
  #|  }
  #|
  #|  function appendTrace(text) {
  #|    const line = document.createElement("div");
  #|    line.textContent = text;
  #|    traceEl.prepend(line);
  #|    while (traceEl.childNodes.length > 120) {
  #|      traceEl.removeChild(traceEl.lastChild);
  #|    }
  #|  }
  #|
  #|  function stopStream() {
  #|    if (source) {
  #|      source.close();
  #|      source = null;
  #|    }
  #|  }
  #|
  #|  function startStream() {
  #|    stopStream();
  #|    const file = fileEl.value.trim();
  #|    if (!file) {
  #|      setStatus("file path is required");
  #|      return;
  #|    }
  #|    traceEl.textContent = "";
  #|    const url = "/api/stream?file=" + encodeURIComponent(file) +
  #|      "&max_inst=" + String(DEFAULT_MAX_INST) +
  #|      "&max_events=" + String(DEFAULT_MAX_EVENTS) +
  #|      "&interval_ms=" + String(DEFAULT_INTERVAL_MS);
  #|    source = new EventSource(url);
  #|    source.addEventListener("step", (event) => {
  #|      const payload = JSON.parse(event.data);
  #|      currentAddr = payload.addr || "";
  #|      appendTrace(payload.trace || event.data);
  #|      renderInstructions();
  #|    });
  #|    source.addEventListener("done", () => {
  #|      setStatus("stream completed");
  #|      stopStream();
  #|    });
  #|    source.onerror = () => {
  #|      setStatus("stream connection error");
  #|    };
  #|    setStatus("stream connecting...");
  #|  }
  #|
  #|  loadBtn.addEventListener("click", loadSnapshot);
  #|  startBtn.addEventListener("click", startStream);
  #|  stopBtn.addEventListener("click", () => {
  #|    stopStream();
  #|    setStatus("stream stopped");
  #|  });
  #|  loadSnapshot();
  #|})();

///|
struct ServeOptions {
  host : String
  port : Int
  default_file : String
  max_inst : Int
  max_events : Int
  interval_ms : Int
}

///|
fn default_options() -> ServeOptions {
  {
    host: DEFAULT_HOST,
    port: DEFAULT_PORT,
    default_file: "example/simple.elf",
    max_inst: DEFAULT_MAX_INST,
    max_events: DEFAULT_MAX_EVENTS,
    interval_ms: DEFAULT_INTERVAL_MS,
  }
}

///|
fn parse_uint_dec(s : String) -> UInt? {
  let mut result : UInt = 0U
  for c in s {
    let digit = match c {
      '0' => Some(0U)
      '1' => Some(1U)
      '2' => Some(2U)
      '3' => Some(3U)
      '4' => Some(4U)
      '5' => Some(5U)
      '6' => Some(6U)
      '7' => Some(7U)
      '8' => Some(8U)
      '9' => Some(9U)
      _ => None
    }
    match digit {
      Some(d) => result = result * 10U + d
      None => return None
    }
  }
  Some(result)
}

///|
fn parse_int_dec(s : String) -> Int? {
  match parse_uint_dec(s) {
    Some(v) => Some(v.reinterpret_as_int())
    None => None
  }
}

///|
fn parse_args(args : Array[String]) -> ServeOptions? {
  let mut options = default_options()
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      return None
    } else if arg == "--host" {
      if i + 1 < args.length() {
        options = { ..options, host: args[i + 1] }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--port" {
      if i + 1 < args.length() {
        match parse_int_dec(args[i + 1]) {
          Some(port) => options = { ..options, port, }
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--file" {
      if i + 1 < args.length() {
        options = { ..options, default_file: args[i + 1] }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--max-inst" {
      if i + 1 < args.length() {
        match parse_int_dec(args[i + 1]) {
          Some(max_inst) => options = { ..options, max_inst, }
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--max-events" {
      if i + 1 < args.length() {
        match parse_int_dec(args[i + 1]) {
          Some(max_events) => options = { ..options, max_events, }
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else if arg == "--interval-ms" {
      if i + 1 < args.length() {
        match parse_int_dec(args[i + 1]) {
          Some(interval_ms) => options = { ..options, interval_ms, }
          None => return None
        }
        i = i + 2
      } else {
        return None
      }
    } else {
      i = i + 1
    }
  }
  Some(options)
}

///|
fn print_usage() -> Unit {
  println("MoonRV Lab Online API Server (Luna + Mars)")
  println("")
  println("Usage:")
  println("  moon run cmd/server --target native -- [options]")
  println("")
  println("Options:")
  println("  --host <host>           Bind host (default: 127.0.0.1)")
  println("  --port <port>           Bind port (default: 18080)")
  println(
    "  --file <path>           Default ELF path (default: example/simple.elf)",
  )
  println("  --max-inst <n>          Default snapshot instruction limit")
  println("  --max-events <n>        Default stream event limit")
  println("  --interval-ms <ms>      Stream interval in milliseconds")
  println("")
  println("API:")
  println("  GET /api/health")
  println("  GET /api/snapshot?file=<path>&max_inst=<n>")
  println(
    "  GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>",
  )
}

///|
fn render_page_body() -> String {
  let shell : @luna.Node[Unit, String] = @luna.h(
    "div",
    [("id", @luna.attr_static("root"))],
    [
      @luna.h("h1", [], [@luna.text("MoonRV Lab Online Workbench")]),
      @luna.h("p", [], [
        @luna.text("Luna SSR shell + Mars online API + MoonBit analysis engine"),
      ]),
      @luna.h("ul", [], [
        @luna.h("li", [], [@luna.text("GET /api/health")]),
        @luna.h("li", [], [
          @luna.text("GET /api/snapshot?file=<path>&max_inst=<n>"),
        ]),
        @luna.h("li", [], [
          @luna.text(
            "GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>",
          ),
        ]),
      ]),
      @luna.h("div", [("id", @luna.attr_static("app"))], [
        @luna.text("Initializing..."),
      ]),
    ],
  )
  let sb = StringBuilder::new(size_hint=1024)
  render_luna_node(sb, shell)
  sb.to_string()
}

///|
fn build_index_html(opts : ServeOptions) -> String {
  let body_html = render_page_body()
  let config_json = "{" +
    "\"defaultFile\":" +
    json_string(opts.default_file) +
    ",\"defaultMaxInst\":" +
    opts.max_inst.to_string() +
    ",\"defaultMaxEvents\":" +
    opts.max_events.to_string() +
    ",\"defaultIntervalMs\":" +
    opts.interval_ms.to_string() +
    "}"

  "<!doctype html>\n" +
  "<html lang=\"en\">\n" +
  "<head>\n" +
  "  <meta charset=\"utf-8\" />\n" +
  "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n" +
  "  <title>MoonRV Lab Online Workbench</title>\n" +
  "  <style>\n" +
  INDEX_STYLE +
  "\n  </style>\n" +
  "</head>\n" +
  "<body>\n" +
  body_html +
  "\n" +
  "  <script>window.__RVR_CONFIG__ = " +
  config_json +
  ";</script>\n" +
  "  <script>\n" +
  CLIENT_BOOTSTRAP_JS +
  "\n  </script>\n" +
  "</body>\n" +
  "</html>"
}

///|
fn render_luna_node(
  sb : StringBuilder,
  node : @luna.Node[Unit, String],
) -> Unit {
  match node {
    @luna.Text(text) => escape_html_to(sb, text)
    @luna.DynamicText(getter) => escape_html_to(sb, getter())
    @luna.RawHtml(html) => sb.write_string(html)
    @luna.Fragment(children) =>
      for child in children {
        render_luna_node(sb, child)
      }
    @luna.Element(elem) => {
      sb.write_char('<')
      sb.write_string(elem.tag)
      for pair in elem.attrs {
        let (name, attr) = pair
        render_luna_attr(sb, name, attr)
      }
      if is_void_tag(elem.tag) {
        sb.write_string(" />")
      } else {
        sb.write_char('>')
        for child in elem.children {
          render_luna_node(sb, child)
        }
        sb.write_string("</")
        sb.write_string(elem.tag)
        sb.write_char('>')
      }
    }
    @luna.Show(condition~, child~) =>
      if condition() {
        render_luna_node(sb, child())
      }
    @luna.For(render~) =>
      for child in render() {
        render_luna_node(sb, child)
      }
    @luna.Component(render~) => render_luna_node(sb, render())
    @luna.Island(island) =>
      for child in island.children {
        render_luna_node(sb, child)
      }
    @luna.WcIsland(island) =>
      for child in island.children {
        render_luna_node(sb, child)
      }
    @luna.InternalRef(iref) =>
      for child in iref.children {
        render_luna_node(sb, child)
      }
    @luna.Async(async_node) => render_luna_node(sb, (async_node.fallback)())
    @luna.ErrorBoundary(boundary) =>
      render_luna_node(sb, (boundary.children)()) catch {
        err => {
          let reset = fn() { () }
          render_luna_node(sb, (boundary.fallback)(err, reset)) catch {
            _ => ()
          }
        }
      }
    @luna.Switch(switch_node) => {
      let mut rendered = false
      for case in switch_node.cases {
        if not(rendered) && (case.when)() {
          rendered = true
          render_luna_node(sb, (case.render)())
        }
      }
      if not(rendered) {
        match switch_node.fallback {
          Some(fallback) => render_luna_node(sb, fallback())
          None => ()
        }
      }
    }
  }
}

///|
fn render_luna_attr(
  sb : StringBuilder,
  name : String,
  attr : @luna.Attr[Unit, String],
) -> Unit {
  match attr {
    @luna.VStatic(value) => render_attr_value(sb, name, value)
    @luna.VDynamic(getter) => render_attr_value(sb, name, getter())
    @luna.VHandler(_) => ()
    @luna.VAction(_) => ()
  }
}

///|
fn render_attr_value(sb : StringBuilder, name : String, value : String) -> Unit {
  sb.write_char(' ')
  sb.write_string(name)
  if value != "" {
    sb.write_string("=\"")
    escape_attr_to(sb, value)
    sb.write_char('"')
  }
}

///|
fn escape_html_to(sb : StringBuilder, value : String) -> Unit {
  for c in value {
    match c {
      '&' => sb.write_string("&amp;")
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
      _ => sb.write_char(c)
    }
  }
}

///|
fn escape_attr_to(sb : StringBuilder, value : String) -> Unit {
  escape_html_to(sb, value)
}

///|
fn is_void_tag(tag : String) -> Bool {
  match tag {
    "area" => true
    "base" => true
    "br" => true
    "col" => true
    "embed" => true
    "hr" => true
    "img" => true
    "input" => true
    "link" => true
    "meta" => true
    "param" => true
    "source" => true
    "track" => true
    "wbr" => true
    _ => false
  }
}

///|
fn escape_json(value : String) -> String {
  let mut escaped = ""
  for c in value {
    match c {
      '"' => escaped = escaped + "\\\""
      '\\' => escaped = escaped + "\\\\"
      '\n' => escaped = escaped + "\\n"
      '\r' => escaped = escaped + "\\r"
      '\t' => escaped = escaped + "\\t"
      _ => escaped = escaped + c.to_string()
    }
  }
  escaped
}

///|
fn json_string(value : String) -> String {
  "\"" + escape_json(value) + "\""
}

///|
fn choose_file(value : String?, default_file : String) -> String {
  match value {
    Some(file) => if file == "" { default_file } else { file }
    None => default_file
  }
}

///|
fn choose_positive_int(value : String?, default_value : Int) -> Int {
  match value {
    Some(raw) =>
      match parse_int_dec(raw) {
        Some(parsed) => if parsed > 0 { parsed } else { default_value }
        None => default_value
      }
    None => default_value
  }
}

///|
fn status_from_payload(payload : Json) -> Int {
  match payload {
    Object(obj) =>
      match obj.get("ok") {
        Some(True) => 200
        Some(False) => 400
        _ => 200
      }
    _ => 200
  }
}

///|
async fn respond_payload_json(
  ctx : @mars.Context,
  payload_text : String,
) -> Unit {
  match (try? @json.parse(payload_text)) {
    Ok(payload) => {
      let status = status_from_payload(payload)
      ctx.json(payload, status~)
    }
    Err(_) =>
      ctx.json({ "ok": false, "error": "invalid backend payload" }, status=500)
  }
}

///|
fn format_sse_event(event_name : String, data : String) -> String {
  "event: " + event_name + "\n" + "data: " + data + "\n\n"
}

///|
async fn stream_events(
  ctx : @mars.Context,
  events : Array[String],
  interval_ms : Int,
) -> Unit {
  ctx.write_raw(": stream-open\n\n") catch {
    _ => return
  }
  let mut connected = true
  for payload in events {
    if not(connected) {
      break
    }
    ctx.write_raw(format_sse_event("step", payload)) catch {
      _ => connected = false
    }
    if connected && interval_ms > 0 {
      @async.sleep(interval_ms) catch {
        _ => connected = false
      }
    }
  }

  if connected {
    ctx.write_raw(format_sse_event("done", "{\"ok\":true}")) catch {
      _ => ()
    }
  }
  ctx.end_response() catch {
    _ => ()
  }
}

///|
async fn run_server(opts : ServeOptions) -> Unit {
  let app = @mars.Server::new()
  let index_html = build_index_html(opts)

  app.get("/", @mars.handler(async fn(ctx) { ctx.html(index_html) }))

  app.get("/index.html", @mars.handler(async fn(ctx) { ctx.html(index_html) }))

  app.get(
    "/api/health",
    @mars.handler(async fn(ctx) { ctx.json({ "ok": true }) }),
  )

  app.get(
    "/api/snapshot",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let max_inst = choose_positive_int(ctx.query("max_inst"), opts.max_inst)
      let payload_text = @workbench.snapshot_api_json_from_file(file, max_inst)
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.get(
    "/api/stream",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let max_inst = choose_positive_int(ctx.query("max_inst"), opts.max_inst)
      let max_events = choose_positive_int(
        ctx.query("max_events"),
        opts.max_events,
      )
      let interval_ms = choose_positive_int(
        ctx.query("interval_ms"),
        opts.interval_ms,
      )

      match
        @workbench.stream_event_payloads_from_file(file, max_inst, max_events) {
        @workbench.StreamEventsOk(events) => {
          ctx.sse_start()
          stream_events(ctx, events, interval_ms)
        }
        @workbench.StreamEventsErr(err) =>
          ctx.json({ "ok": false, "error": err }, status=400)
      }
    }),
  )

  println(
    "[rvlab] mars server listening at http://" +
    opts.host +
    ":" +
    opts.port.to_string(),
  )
  app.serve(host=opts.host, port=opts.port)
}

///|
async fn main {
  let all_args = @sys.get_cli_args()
  let args = if all_args.length() > 1 {
    let values : Array[String] = []
    for i = 1; i < all_args.length(); i = i + 1 {
      values.push(all_args[i])
    }
    values
  } else {
    []
  }

  match parse_args(args) {
    Some(opts) =>
      run_server(opts) catch {
        err => println("server failed: \{err}")
      }
    None => print_usage()
  }
}
