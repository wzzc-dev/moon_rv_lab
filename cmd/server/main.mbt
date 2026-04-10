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
const DEFAULT_RAW_BASE : UInt = @program.DEFAULT_RAW_BASE

///|
const DEFAULT_RAW_XLEN : Int = @program.DEFAULT_RAW_XLEN

///|
const UPLOAD_DIR : String = "/tmp/moonrv_uploads"

///|
const MAX_UPLOAD_BYTES : Int = 2 * 1024 * 1024

///|
const INDEX_STYLE : String =
  #|:root {
  #|  --bg: #eef5f4;
  #|  --bg-strong: #dce9e6;
  #|  --ink: #13232f;
  #|  --muted: #49606d;
  #|  --line: #c7d8d5;
  #|  --panel: rgba(255, 255, 255, 0.88);
  #|  --panel-strong: #ffffff;
  #|  --accent: #0f766e;
  #|  --accent-2: #164e63;
  #|  --accent-soft: #d7f0ea;
  #|  --shadow: 0 18px 48px rgba(19, 35, 47, 0.10);
  #|}
  #|* { box-sizing: border-box; }
  #|body {
  #|  margin: 0;
  #|  min-height: 100vh;
  #|  background:
  #|    radial-gradient(circle at top left, rgba(15, 118, 110, 0.14), transparent 32%),
  #|    radial-gradient(circle at top right, rgba(22, 78, 99, 0.12), transparent 28%),
  #|    linear-gradient(180deg, var(--bg) 0%, #f8fbfa 100%);
  #|  color: var(--ink);
  #|  font-family: "SFMono-Regular", "Iosevka", "JetBrains Mono", monospace;
  #|}
  #|a {
  #|  color: inherit;
  #|}
  #|#root {
  #|  max-width: 1120px;
  #|  margin: 0 auto;
  #|  padding: 24px 16px 40px;
  #|}
  #|.hero {
  #|  position: relative;
  #|  overflow: hidden;
  #|  border: 1px solid rgba(19, 35, 47, 0.08);
  #|  border-radius: 28px;
  #|  padding: 28px;
  #|  background:
  #|    linear-gradient(145deg, rgba(255, 255, 255, 0.92) 0%, rgba(231, 245, 242, 0.96) 100%);
  #|  box-shadow: var(--shadow);
  #|}
  #|.hero::after {
  #|  content: "";
  #|  position: absolute;
  #|  inset: auto -12% -34% auto;
  #|  width: 280px;
  #|  height: 280px;
  #|  border-radius: 50%;
  #|  background: radial-gradient(circle, rgba(15, 118, 110, 0.16), transparent 68%);
  #|  pointer-events: none;
  #|}
  #|.eyebrow {
  #|  display: inline-flex;
  #|  align-items: center;
  #|  gap: 8px;
  #|  padding: 6px 10px;
  #|  border-radius: 999px;
  #|  background: var(--accent-soft);
  #|  color: var(--accent);
  #|  font-size: 12px;
  #|  font-weight: 700;
  #|  letter-spacing: 0.02em;
  #|  text-transform: uppercase;
  #|}
  #|.hero h1 {
  #|  margin: 14px 0 10px;
  #|  font-size: clamp(30px, 5vw, 46px);
  #|  line-height: 1.08;
  #|}
  #|.subtitle {
  #|  max-width: 760px;
  #|  margin: 0;
  #|  color: var(--muted);
  #|  font-size: 14px;
  #|  line-height: 1.7;
  #|}
  #|.hero-strip {
  #|  display: grid;
  #|  grid-template-columns: repeat(3, minmax(0, 1fr));
  #|  gap: 12px;
  #|  align-items: center;
  #|  margin: 18px 0 0;
  #|}
  #|.stat {
  #|  border: 1px solid rgba(19, 35, 47, 0.08);
  #|  border-radius: 16px;
  #|  padding: 12px 14px;
  #|  background: rgba(255, 255, 255, 0.72);
  #|}
  #|.stat-label {
  #|  display: block;
  #|  color: var(--muted);
  #|  font-size: 11px;
  #|  margin-bottom: 6px;
  #|  text-transform: uppercase;
  #|  letter-spacing: 0.06em;
  #|}
  #|.stat-value {
  #|  font-size: 14px;
  #|  line-height: 1.5;
  #|  word-break: break-word;
  #|}
  #|.cta-row {
  #|  display: flex;
  #|  flex-wrap: wrap;
  #|  gap: 10px;
  #|  margin-top: 18px;
  #|}
  #|.button,
  #|button,
  #|input {
  #|  border: 1px solid var(--line);
  #|  border-radius: 12px;
  #|  padding: 10px 14px;
  #|  background: var(--panel-strong);
  #|  color: var(--ink);
  #|  font-family: inherit;
  #|  font-size: 12px;
  #|}
  #|.button {
  #|  display: inline-flex;
  #|  align-items: center;
  #|  justify-content: center;
  #|  text-decoration: none;
  #|}
  #|button { cursor: pointer; }
  #|.button.primary,
  #|button.primary {
  #|  background: var(--accent);
  #|  color: #fff;
  #|  border-color: var(--accent);
  #|}
  #|.button.secondary {
  #|  background: rgba(255, 255, 255, 0.66);
  #|}
  #|.section {
  #|  margin-top: 18px;
  #|  border: 1px solid rgba(19, 35, 47, 0.08);
  #|  border-radius: 22px;
  #|  background: var(--panel);
  #|  box-shadow: var(--shadow);
  #|  backdrop-filter: blur(8px);
  #|}
  #|.section-body {
  #|  padding: 22px;
  #|}
  #|.section-head {
  #|  display: flex;
  #|  justify-content: space-between;
  #|  gap: 12px;
  #|  align-items: end;
  #|  margin-bottom: 16px;
  #|}
  #|.section-head h2 {
  #|  margin: 0;
  #|  font-size: 18px;
  #|}
  #|.section-head p {
  #|  margin: 0;
  #|  color: var(--muted);
  #|  font-size: 12px;
  #|  line-height: 1.6;
  #|}
  #|.grid-3,
  #|.grid-2 {
  #|  display: grid;
  #|  gap: 12px;
  #|}
  #|.grid-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
  #|.grid-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  #|.card {
  #|  border: 1px solid rgba(19, 35, 47, 0.08);
  #|  border-radius: 18px;
  #|  padding: 16px;
  #|  background: var(--panel-strong);
  #|}
  #|.card h3 {
  #|  margin: 0 0 10px;
  #|  font-size: 15px;
  #|}
  #|.card p {
  #|  margin: 0;
  #|  color: var(--muted);
  #|  font-size: 12px;
  #|  line-height: 1.65;
  #|}
  #|.code-block {
  #|  margin-top: 12px;
  #|  border-radius: 14px;
  #|  background: #0f1d26;
  #|  color: #e9fbf8;
  #|  padding: 12px;
  #|  white-space: pre-wrap;
  #|  word-break: break-word;
  #|  font-size: 12px;
  #|  line-height: 1.7;
  #|}
  #|.route-list,
  #|.steps {
  #|  margin: 0;
  #|  padding-left: 18px;
  #|}
  #|.route-list li,
  #|.steps li {
  #|  margin: 8px 0;
  #|  color: var(--muted);
  #|  font-size: 12px;
  #|  line-height: 1.6;
  #|}
  #|code {
  #|  padding: 2px 6px;
  #|  border-radius: 999px;
  #|  background: var(--bg-strong);
  #|  color: var(--accent-2);
  #|}
  #|.small-note {
  #|  color: var(--muted);
  #|  font-size: 12px;
  #|  line-height: 1.6;
  #|}
  #|@media (max-width: 1024px) {
  #|  .hero-strip,
  #|  .grid-3,
  #|  .grid-2 {
  #|    grid-template-columns: 1fr;
  #|  }
  #|  .section-head {
  #|    align-items: start;
  #|    flex-direction: column;
  #|  }
  #|}
  #|@media (max-width: 720px) {
  #|  #root { padding: 16px 12px 28px; }
  #|  .hero,
  #|  .section-body { padding: 18px; }
  #|}

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
priv struct WorkbenchRouteInput {
  file : String
  raw_mode : Bool
  base_addr : UInt
  xlen : Int
}

///|
priv enum WorkbenchRouteParseResult {
  WorkbenchRouteOk(WorkbenchRouteInput)
  WorkbenchRouteErr(String)
}

///|
priv struct UploadPayload {
  filename : String
  content_base64 : String
  input_format : String
  base_addr : UInt
  xlen : Int
} derive(Show)

///|
priv enum UploadPayloadParseResult {
  UploadPayloadOk(UploadPayload)
  UploadPayloadErr(String)
}

///|
fn default_options() -> ServeOptions {
  {
    host: DEFAULT_HOST,
    port: DEFAULT_PORT,
    default_file: "out/simple.elf",
    max_inst: DEFAULT_MAX_INST,
    max_events: DEFAULT_MAX_EVENTS,
    interval_ms: DEFAULT_INTERVAL_MS,
  }
}

///|
fn default_workbench_route_input(file : String) -> WorkbenchRouteInput {
  { file, raw_mode: false, base_addr: DEFAULT_RAW_BASE, xlen: DEFAULT_RAW_XLEN }
}

///|
fn workbench_request_to_input(
  request : @program.WorkbenchRequest,
) -> WorkbenchRouteInput {
  {
    file: request.input.file_path,
    raw_mode: request.input.is_raw(),
    base_addr: request.input.base_addr,
    xlen: request.input.xlen,
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
fn parse_hex_uint(s : String) -> UInt? {
  if s.length() >= 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X') {
    let mut result : UInt = 0U
    for i = 2; i < s.length(); i = i + 1 {
      let digit = match s[i] {
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
        'a' | 'A' => Some(10U)
        'b' | 'B' => Some(11U)
        'c' | 'C' => Some(12U)
        'd' | 'D' => Some(13U)
        'e' | 'E' => Some(14U)
        'f' | 'F' => Some(15U)
        _ => None
      }
      match digit {
        Some(d) => result = result * 16U + d
        None => return None
      }
    }
    Some(result)
  } else {
    None
  }
}

///|
fn parse_number(value : String) -> UInt? {
  match parse_hex_uint(value) {
    Some(parsed) => Some(parsed)
    None => parse_uint_dec(value)
  }
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
    "  --file <path>           Default ELF path (default: out/simple.elf)",
  )
  println("  --max-inst <n>          Default snapshot instruction limit")
  println("  --max-events <n>        Default stream event limit")
  println("  --interval-ms <ms>      Stream interval in milliseconds")
  println("")
  println("API:")
  println("  GET /workbench?file=<path>[&raw=1&base=<addr>&xlen=32|64]")
  println("  GET /api/health")
  println(
    "  GET /api/workbench/overview?file=<path>&max_events=<n>[&raw=1&base=<addr>&xlen=32|64]",
  )
  println(
    "  GET /api/workbench/function?file=<path>&addr=<hex-or-name>[&raw=1&base=<addr>&xlen=32|64]",
  )
  println("  GET /api/snapshot?file=<path>&max_inst=<n>")
  println(
    "  GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>",
  )
}

///|
fn render_page_body(opts : ServeOptions) -> String {
  let workbench_href = build_workbench_href(opts.default_file)
  let shell : @luna.Node[Unit, String] = @luna.h(
    "div",
    [("id", @luna.attr_static("root"))],
    [
      @luna.h("section", [("class", @luna.attr_static("hero"))], [
        @luna.h("div", [("class", @luna.attr_static("eyebrow"))], [
          @luna.text("Quick Start"),
        ]),
        @luna.h("h1", [], [@luna.text("MoonRV Lab Online Workbench")]),
        @luna.h("p", [("class", @luna.attr_static("subtitle"))], [
          @luna.text(
            "面向演示、回归和课堂实验的在线入口。推荐先打开在线 workbench，再按需在 ELF / RAW 间切换；离线路径和 API 契约也在这里给出。",
          ),
        ]),
        @luna.h("div", [("class", @luna.attr_static("cta-row"))], [
          @luna.h(
            "a",
            [
              ("class", @luna.attr_static("button primary")),
              ("href", @luna.attr_static(workbench_href)),
            ],
            [@luna.text("Open Online Workbench")],
          ),
          @luna.h(
            "a",
            [
              ("class", @luna.attr_static("button secondary")),
              ("href", @luna.attr_static("#quick-start")),
            ],
            [@luna.text("查看 Quick Start")],
          ),
        ]),
        @luna.h("div", [("class", @luna.attr_static("hero-strip"))], [
          @luna.h("div", [("class", @luna.attr_static("stat"))], [
            @luna.h("span", [("class", @luna.attr_static("stat-label"))], [
              @luna.text("默认文件"),
            ]),
            @luna.h("span", [("class", @luna.attr_static("stat-value"))], [
              @luna.text(opts.default_file),
            ]),
          ]),
          @luna.h("div", [("class", @luna.attr_static("stat"))], [
            @luna.h("span", [("class", @luna.attr_static("stat-label"))], [
              @luna.text("推荐入口"),
            ]),
            @luna.h("span", [("class", @luna.attr_static("stat-value"))], [
              @luna.text("/workbench?file=<path>"),
            ]),
          ]),
          @luna.h("div", [("class", @luna.attr_static("stat"))], [
            @luna.h("span", [("class", @luna.attr_static("stat-label"))], [
              @luna.text("接口定位"),
            ]),
            @luna.h("span", [("class", @luna.attr_static("stat-value"))], [
              @luna.text(
                "overview/function 为主接口，snapshot/stream 为兼容接口",
              ),
            ]),
          ]),
        ]),
      ]),
      @luna.h(
        "section",
        [
          ("class", @luna.attr_static("section")),
          ("id", @luna.attr_static("quick-start")),
        ],
        [
          @luna.h("div", [("class", @luna.attr_static("section-body"))], [
            @luna.h("div", [("class", @luna.attr_static("section-head"))], [
              @luna.h("div", [], [
                @luna.h("h2", [], [@luna.text("Quick Start")]),
                @luna.h("p", [], [
                  @luna.text(
                    "首页优先解决“先做什么”。在线与离线两条路径都给出最短闭环。",
                  ),
                ]),
              ]),
            ]),
            @luna.h("div", [("class", @luna.attr_static("grid-3"))], [
              @luna.h("article", [("class", @luna.attr_static("card"))], [
                @luna.h("h3", [], [@luna.text("在线工作台")]),
                @luna.h("p", [], [
                  @luna.text(
                    "直接打开浏览器工作台，适合演示、调试，以及在 ELF / RAW 间切换。默认文件会自动带入查询参数。",
                  ),
                ]),
                @luna.h("div", [("class", @luna.attr_static("code-block"))], [
                  @luna.text(
                    "/workbench?file=out/simple.elf\n/workbench?file=out/simple.raw&raw=1&base=0x10000&xlen=64",
                  ),
                ]),
              ]),
              @luna.h("article", [("class", @luna.attr_static("card"))], [
                @luna.h("h3", [], [@luna.text("离线工作台")]),
                @luna.h("p", [], [
                  @luna.text(
                    "生成单文件 HTML，适合录屏、分享和不依赖 server 的场景。",
                  ),
                ]),
                @luna.h("div", [("class", @luna.attr_static("code-block"))], [
                  @luna.text(
                    "moon run cmd/main -- workbench out/simple.elf -o out/workbench.html",
                  ),
                ]),
              ]),
              @luna.h("article", [("class", @luna.attr_static("card"))], [
                @luna.h("h3", [], [@luna.text("CLI 运行")]),
                @luna.h("p", [], [
                  @luna.text(
                    "先汇编，再执行，确认样例和默认 RV64 链路可用。",
                  ),
                ]),
                @luna.h("div", [("class", @luna.attr_static("code-block"))], [
                  @luna.text(
                    "moon run cmd/main -- asm example/simple.s -o out/simple.elf\nmoon run cmd/main -- run out/simple.elf --max-steps 20",
                  ),
                ]),
              ]),
            ]),
            @luna.h("div", [("class", @luna.attr_static("grid-2"))], [
              @luna.h("article", [("class", @luna.attr_static("card"))], [
                @luna.h("h3", [], [@luna.text("在线使用步骤")]),
                @luna.h("ol", [("class", @luna.attr_static("steps"))], [
                  @luna.h("li", [], [
                    @luna.text(
                      "启动 server，并确认默认文件已经生成。",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "打开 online workbench，按输入格式选择 ELF 或 RAW，再查看 overview 与函数。",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "使用搜索框按地址、函数名、指令文本或 category 过滤。",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "通过 Reset / Prev / Next / Play 和 Follow PC 浏览执行轨迹。",
                    ),
                  ]),
                ]),
              ]),
              @luna.h("article", [("class", @luna.attr_static("card"))], [
                @luna.h("h3", [], [
                  @luna.text("Primary APIs 与 Compatibility APIs"),
                ]),
                @luna.h("p", [], [
                  @luna.text(
                    "Primary APIs: /api/workbench/overview 提供首屏概要，/api/workbench/function 提供函数切片；Compatibility APIs: /api/snapshot 与 /api/stream 继续服务现有集成，当前保持 ELF-only 兼容接口。",
                  ),
                ]),
                @luna.h("ul", [("class", @luna.attr_static("route-list"))], [
                  @luna.h("li", [], [
                    @luna.text(
                      "GET /workbench?file=<path>[&raw=1&base=<addr>&xlen=32|64]",
                    ),
                  ]),
                  @luna.h("li", [], [@luna.text("GET /api/health")]),
                  @luna.h("li", [], [
                    @luna.text(
                      "GET /api/workbench/overview?file=<path>&max_events=<n>[&raw=1&base=<addr>&xlen=32|64]",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "GET /api/workbench/function?file=<path>&addr=<hex-or-name>[&raw=1&base=<addr>&xlen=32|64]",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text("GET /api/snapshot?file=<path>&max_inst=<n>"),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>",
                    ),
                  ]),
                ]),
              ]),
            ]),
            @luna.h("p", [("class", @luna.attr_static("small-note"))], [
              @luna.text(
                "Windows 上的 server 原生回归依赖 MSVC 工具链；普通 PowerShell + GCC 不在支持路径内。",
              ),
            ]),
          ]),
        ],
      ),
    ],
  )
  let sb = StringBuilder::new(size_hint=1024)
  render_luna_node(sb, shell)
  sb.to_string()
}

///|
fn build_index_html(opts : ServeOptions) -> String {
  let body_html = render_page_body(opts)

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
fn build_workbench_href(file : String) -> String {
  if file == "" {
    "/workbench"
  } else {
    "/workbench?file=" + url_query_escape(file)
  }
}

///|
fn build_workbench_options_from_input(
  max_instructions : Int,
  input : @program.InputSpec,
) -> @workbench.WorkbenchOptions {
  @workbench.create_input_options(
    "",
    max_instructions,
    input.is_raw(),
    input.base_addr,
    input.xlen,
  )
}

///|
fn build_workbench_options(
  max_instructions : Int,
  input : WorkbenchRouteInput,
) -> @workbench.WorkbenchOptions {
  build_workbench_options_from_input(
    max_instructions,
    @program.create_input_spec(
      input.file,
      input.raw_mode,
      input.base_addr,
      input.xlen,
    ),
  )
}

///|
fn build_workbench_route_html_with_input(
  opts : ServeOptions,
  input : WorkbenchRouteInput,
) -> String {
  @workbench.online_page_html_with_request(
    opts.default_file,
    @program.parse_workbench_request_lenient(
      input.file,
      if input.raw_mode {
        Some("1")
      } else {
        None
      },
      Some(input.base_addr.to_string()),
      Some(input.xlen.to_string()),
      "",
      opts.max_events,
      opts.max_inst,
    ),
    "/api/workbench/overview",
    "/api/workbench/function",
  )
}

///|
fn build_workbench_route_html_with_upload(
  opts : ServeOptions,
  input : WorkbenchRouteInput,
) -> String {
  @workbench.online_page_html_with_request_and_upload(
    opts.default_file,
    @program.parse_workbench_request_lenient(
      input.file,
      if input.raw_mode {
        Some("1")
      } else {
        None
      },
      Some(input.base_addr.to_string()),
      Some(input.xlen.to_string()),
      "",
      opts.max_events,
      opts.max_inst,
    ),
    "/api/workbench/overview",
    "/api/workbench/function",
    "/api/workbench/upload",
  )
}

///|
fn build_workbench_route_html(opts : ServeOptions, file : String) -> String {
  build_workbench_route_html_with_upload(
    opts,
    default_workbench_route_input(file),
  )
}

///|
fn url_query_escape(value : String) -> String {
  let mut escaped = ""
  for c in value {
    let encoded = match c {
      ' ' => "%20"
      '%' => "%25"
      '#' => "%23"
      '&' => "%26"
      '+' => "%2B"
      '?' => "%3F"
      '=' => "%3D"
      _ => c.to_string()
    }
    escaped = escaped + encoded
  }
  escaped
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
fn raw_query_enabled(value : String?) -> Bool {
  match value {
    Some("1") => true
    Some("true") => true
    Some("TRUE") => true
    Some("True") => true
    _ => false
  }
}

///|
fn parse_raw_base_strict(value : String?) -> UInt? {
  match value {
    Some(raw) => parse_number(raw)
    None => Some(DEFAULT_RAW_BASE)
  }
}

///|
fn choose_raw_base_lenient(value : String?) -> UInt {
  match parse_raw_base_strict(value) {
    Some(base_addr) => base_addr
    None => DEFAULT_RAW_BASE
  }
}

///|
fn parse_raw_xlen_strict(value : String?) -> Int? {
  match value {
    Some("32") => Some(32)
    Some("64") => Some(64)
    None => Some(DEFAULT_RAW_XLEN)
    _ => None
  }
}

///|
fn choose_raw_xlen_lenient(value : String?) -> Int {
  match parse_raw_xlen_strict(value) {
    Some(xlen) => xlen
    None => DEFAULT_RAW_XLEN
  }
}

///|
fn parse_workbench_route_input_lenient(
  file : String,
  raw : String?,
  base : String?,
  xlen : String?,
) -> WorkbenchRouteInput {
  workbench_request_to_input(
    @program.parse_workbench_request_lenient(
      file,
      raw,
      base,
      xlen,
      "",
      DEFAULT_MAX_EVENTS,
      DEFAULT_MAX_INST,
    ),
  )
}

///|
fn parse_workbench_route_input_strict(
  file : String,
  raw : String?,
  base : String?,
  xlen : String?,
) -> WorkbenchRouteParseResult {
  match
    @program.parse_workbench_request_strict(
      file,
      raw,
      base,
      xlen,
      "",
      DEFAULT_MAX_EVENTS,
      DEFAULT_MAX_INST,
    ) {
    @program.WorkbenchRequestOk(request) =>
      WorkbenchRouteOk(workbench_request_to_input(request))
    @program.WorkbenchRequestErr(err) => WorkbenchRouteErr(err)
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
  try @json.parse(payload_text) catch {
    _ =>
      ctx.json({ "ok": false, "error": "invalid backend payload" }, status=500)
  } noraise {
    payload => {
      let status = status_from_payload(payload)
      ctx.json(payload, status~)
    }
  }
}

///|
fn parse_upload_input_format(value : Json?) -> String? {
  match value {
    Some(String("elf")) | Some(String("ELF")) => Some("elf")
    Some(String("raw")) | Some(String("RAW")) => Some("raw")
    Some(String(text)) =>
      match text.trim().to_string() {
        "elf" | "ELF" => Some("elf")
        "raw" | "RAW" => Some("raw")
        _ => None
      }
    _ => None
  }
}

///|
fn parse_upload_base_addr(value : Json?) -> UInt? {
  match value {
    Some(String(text)) => parse_number(text.trim().to_string())
    Some(Number(n, ..)) =>
      if n >= 0 { Some(n.to_int().reinterpret_as_uint()) } else { None }
    None => Some(DEFAULT_RAW_BASE)
    _ => None
  }
}

///|
fn parse_upload_xlen(value : Json?) -> Int? {
  match value {
    Some(String("32")) => Some(32)
    Some(String("64")) => Some(64)
    Some(Number(n, ..)) => {
      let parsed = n.to_int()
      if parsed == 32 || parsed == 64 {
        Some(parsed)
      } else {
        None
      }
    }
    None => Some(DEFAULT_RAW_XLEN)
    _ => None
  }
}

///|
fn parse_upload_payload(body : Json) -> UploadPayloadParseResult {
  match body {
    Object(obj) => {
      let filename = match obj.get("filename") {
        Some(String(value)) => value.trim().to_string()
        _ => ""
      }
      let content_base64 = match obj.get("content_base64") {
        Some(String(value)) => value.trim().to_string()
        _ => ""
      }
      if filename == "" {
        return UploadPayloadErr("missing filename")
      }
      if content_base64 == "" {
        return UploadPayloadErr("missing content_base64")
      }
      let input_format = match parse_upload_input_format(obj.get("input_format")) {
        Some(value) => value
        None => return UploadPayloadErr("invalid input_format: expected elf or raw")
      }
      let base_addr = match parse_upload_base_addr(obj.get("base_addr")) {
        Some(value) => value
        None =>
          return UploadPayloadErr(
            "invalid base_addr: expected decimal or 0x-prefixed address",
          )
      }
      let xlen = match parse_upload_xlen(obj.get("xlen")) {
        Some(value) => value
        None => return UploadPayloadErr("invalid xlen: expected 32 or 64")
      }
      UploadPayloadOk({
        filename,
        content_base64,
        input_format,
        base_addr,
        xlen,
      })
    }
    _ => UploadPayloadErr("invalid upload payload")
  }
}

///|
fn sanitize_upload_filename(name : String) -> String {
  let mut sanitized = ""
  for c in name {
    let safe = match c {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '.' | '_' | '-' => c.to_string()
      _ => "_"
    }
    sanitized = sanitized + safe
  }
  if sanitized == "" { "upload.elf" } else { sanitized }
}

///|
fn ensure_upload_dir() -> Bool {
  if @fs.path_exists(UPLOAD_DIR) {
    true
  } else {
    @fs.create_dir(UPLOAD_DIR) catch {
      _ => return false
    }
    true
  }
}

///|
fn upload_path(filename : String) -> String {
  let safe_name = sanitize_upload_filename(filename)
  let suffix = (@fs.read_dir(UPLOAD_DIR).length().to_string()) catch {
    _ => "0"
  }
  UPLOAD_DIR + "/" + suffix + "_" + safe_name
}

///|
fn uploaded_input_spec(path : String, payload : UploadPayload) -> @program.InputSpec {
  if payload.input_format == "raw" {
    @program.raw_input_spec(path, payload.base_addr, payload.xlen)
  } else {
    @program.elf_input_spec(path)
  }
}

///|
fn cleanup_uploaded_file(path : String) -> Unit {
  if @fs.path_exists(path) {
    @fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
fn upload_error_message(err : @program.ProgramLoadError, input : @program.InputSpec) -> String {
  match err {
    @program.ProgramLoadError::FileNotFound(_) => "uploaded file is not readable"
    @program.ProgramLoadError::InvalidElf(_) | @program.ProgramLoadError::ParseElfFailed(_) =>
      if input.is_raw() {
        "uploaded RAW payload could not be decoded; please check input format, base and xlen"
      } else {
        "uploaded file is not a valid RISC-V ELF"
      }
    @program.ProgramLoadError::NotRiscV(_) =>
      "uploaded file is not a RISC-V ELF"
    @program.ProgramLoadError::NoCodeSection(_) =>
      if input.is_raw() {
        "uploaded RAW file does not contain decodable executable code"
      } else {
        "uploaded ELF does not contain executable code"
      }
  }
}

///|
async fn handle_workbench_upload(ctx : @mars.Context) -> Unit {
  match ctx.body_json() {
    Some(body) =>
      match parse_upload_payload(body) {
        UploadPayloadErr(err) =>
          ctx.json({ "ok": false, "error": err }, status=400)
        UploadPayloadOk(payload) => {
          let decoded = @base64.decode(payload.content_base64[:]) catch {
            _ => {
              ctx.json(
                { "ok": false, "error": "invalid base64 upload body" },
                status=400,
              )
              return
            }
          }
          if decoded.length() <= 0 {
            ctx.json({ "ok": false, "error": "empty upload body" }, status=400)
            return
          }
          if decoded.length() > MAX_UPLOAD_BYTES {
            ctx.json(
              { "ok": false, "error": "uploaded file exceeds size limit" },
              status=400,
            )
            return
          }
          if payload.input_format == "raw" &&
            (payload.xlen != 32 && payload.xlen != 64) {
            ctx.json(
              { "ok": false, "error": "invalid xlen: expected 32 or 64" },
              status=400,
            )
            return
          }
          if !ensure_upload_dir() {
            ctx.json(
              { "ok": false, "error": "failed to prepare upload directory" },
              status=500,
            )
            return
          }
          let path = upload_path(payload.filename)
          @fs.write_bytes_to_file(path, decoded) catch {
            _ => {
              ctx.json(
                { "ok": false, "error": "failed to write uploaded file" },
                status=500,
              )
              return
            }
          }
          let input = uploaded_input_spec(path, payload)
          match @program.load_program(input) {
            @program.ProgramLoaded(program) =>
              ctx.json({
                "ok": true,
                "file": path,
                "filename": payload.filename,
                "display_name": payload.filename,
                "input_format": program.input_format_name(),
                "base_addr": if input.is_raw() {
                  input.base_addr.to_string()
                } else {
                  ""
                },
                "xlen": program.xlen,
              })
            @program.ProgramLoadFailed(err) => {
              cleanup_uploaded_file(path)
              ctx.json(
                { "ok": false, "error": upload_error_message(err, input) },
                status=400,
              )
            }
          }
        }
      }
    None => ctx.json({ "ok": false, "error": "invalid json body" }, status=400)
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
    "/workbench",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let request = @program.parse_workbench_request_lenient(
        file,
        ctx.query("raw"),
        ctx.query("base"),
        ctx.query("xlen"),
        "",
        opts.max_events,
        opts.max_inst,
      )
      if request.input.is_raw() {
        ctx.html(
          build_workbench_route_html_with_input(
            opts,
            workbench_request_to_input(request),
          ),
        )
      } else {
        ctx.html(build_workbench_route_html(opts, request.input.file_path))
      }
    }),
  )

  app.get(
    "/api/health",
    @mars.handler(async fn(ctx) { ctx.json({ "ok": true }) }),
  )

  app.post(
    "/api/workbench/upload",
    @mars.handler(async fn(ctx) { handle_workbench_upload(ctx) }),
  )

  app.get(
    "/api/workbench/overview",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let max_events = choose_positive_int(
        ctx.query("max_events"),
        opts.max_events,
      )
      match
        @program.parse_workbench_request_strict(
          file,
          ctx.query("raw"),
          ctx.query("base"),
          ctx.query("xlen"),
          "",
          max_events,
          opts.max_inst,
        ) {
        @program.WorkbenchRequestOk(request) =>
          respond_payload_json(ctx, @workbench.overview_api_json(request))
        @program.WorkbenchRequestErr(err) =>
          ctx.json({ "ok": false, "error": err }, status=400)
      }
    }),
  )

  app.get(
    "/api/workbench/function",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let addr = choose_file(ctx.query("addr"), "")
      match
        @program.parse_workbench_request_strict(
          file,
          ctx.query("raw"),
          ctx.query("base"),
          ctx.query("xlen"),
          addr,
          opts.max_events,
          opts.max_inst,
        ) {
        @program.WorkbenchRequestOk(request) =>
          respond_payload_json(ctx, @workbench.function_api_json(request))
        @program.WorkbenchRequestErr(err) =>
          ctx.json({ "ok": false, "error": err }, status=400)
      }
    }),
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
