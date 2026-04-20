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
priv struct Ref[T] {
  mut val : T
}

///|
fn[T] Ref::new(val : T) -> Ref[T] {
  { val, }
}

///|
priv struct DebugSession {
  id : String
  file : String
  entry_addr : UInt
  active : Bool
  state : @simulator.ExecState
}

///|
priv struct DebugSessionStore {
  sessions : Ref[Map[String, DebugSession]]
  next_id : Ref[Int]
}

///|
fn make_debug_session_store() -> DebugSessionStore {
  { sessions: Ref::new(Map::new()), next_id: Ref::new(1) }
}

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
fn parse_hex_uint(s : String) -> UInt? {
  if s.length() < 3 {
    return None
  }
  if s[0] != '0' || (s[1] != 'x' && s[1] != 'X') {
    return None
  }

  let mut result : UInt = 0U
  for i = 2; i < s.length(); i = i + 1 {
    let c = s[i]
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
      'a' | 'A' => Some(10U)
      'b' | 'B' => Some(11U)
      'c' | 'C' => Some(12U)
      'd' | 'D' => Some(13U)
      'e' | 'E' => Some(14U)
      'f' | 'F' => Some(15U)
      _ => None
    }
    match digit {
      Some(v) => result = result * 16U + v
      None => return None
    }
  }
  Some(result)
}

///|
fn parse_uint_value(s : String) -> UInt? {
  match parse_hex_uint(s) {
    Some(value) => Some(value)
    None => parse_uint_dec(s)
  }
}

///|
fn uint_to_hex(value : UInt) -> String {
  if value == 0U {
    "0"
  } else {
    let mut result = ""
    let mut current = value
    while current > 0U {
      let digit = (current % 16U).reinterpret_as_int()
      let ch = if digit < 10 {
        (digit + 48).unsafe_to_char()
      } else {
        (digit + 87).unsafe_to_char()
      }
      result = ch.to_string() + result
      current = current / 16U
    }
    result
  }
}

///|
fn format_hex(value : UInt) -> String {
  "0x" + uint_to_hex(value)
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
fn is_ascii_space(c : Char) -> Bool {
  match c {
    ' ' | '\t' | '\n' | '\r' => true
    _ => false
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
  println("  GET /workbench?file=<path>")
  println("  GET /api/health")
  println("  GET /api/workbench/overview?file=<path>&max_events=<n>")
  println("  GET /api/workbench/function?file=<path>&addr=<hex-or-name>")
  println("  GET /api/snapshot?file=<path>&max_inst=<n>")
  println(
    "  GET /api/stream?file=<path>&max_inst=<n>&max_events=<n>&interval_ms=<ms>",
  )
  println("  GET /api/debug/state?id=<session>")
  println("  POST /api/debug/start?file=<path>&entry=<addr>&breakpoints=<csv>")
  println("  POST /api/debug/step?id=<session>&breakpoints=<csv>")
  println(
    "  POST /api/debug/continue?id=<session>&max_steps=<n>&breakpoints=<csv>",
  )
  println("  POST /api/debug/reset?id=<session>&breakpoints=<csv>")
  println("  POST /api/debug/stop?id=<session>")
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
            "面向演示、回归和课堂实验的在线入口。推荐先打开在线 workbench，再按需切换 ELF；离线路径和 API 契约也在这里给出。",
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
                    "直接打开浏览器工作台，适合演示、调试和多 ELF 切换。默认文件会自动带入查询参数。",
                  ),
                ]),
                @luna.h("div", [("class", @luna.attr_static("code-block"))], [
                  @luna.text("/workbench?file=out/simple.elf"),
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
                      "打开 online workbench，先看 overview，再选择函数。",
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
                    "Primary APIs: /api/workbench/overview 提供首屏概要，/api/workbench/function 提供函数切片；Compatibility APIs: /api/snapshot 与 /api/stream 继续服务现有集成；Debug APIs: /api/debug/* 提供 stateful step / continue / reset。",
                  ),
                ]),
                @luna.h("ul", [("class", @luna.attr_static("route-list"))], [
                  @luna.h("li", [], [@luna.text("GET /workbench?file=<path>")]),
                  @luna.h("li", [], [@luna.text("GET /api/health")]),
                  @luna.h("li", [], [
                    @luna.text(
                      "GET /api/workbench/overview?file=<path>&max_events=<n>",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "GET /api/workbench/function?file=<path>&addr=<hex-or-name>",
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
                  @luna.h("li", [], [
                    @luna.text(
                      "POST /api/debug/start?file=<path>&entry=<addr>&breakpoints=<csv>",
                    ),
                  ]),
                  @luna.h("li", [], [
                    @luna.text("GET /api/debug/state?id=<session>"),
                  ]),
                  @luna.h("li", [], [
                    @luna.text(
                      "POST /api/debug/continue?id=<session>&max_steps=<n>&breakpoints=<csv>",
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
fn build_workbench_route_html(opts : ServeOptions, file : String) -> String {
  @workbench.online_page_html(
    opts.default_file,
    file,
    opts.max_inst,
    "/api/workbench/overview",
    "/api/workbench/function",
    "/api/debug/start",
    "/api/debug/state",
    "/api/debug/step",
    "/api/debug/continue",
    "/api/debug/reset",
    "/api/debug/stop",
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
fn parse_breakpoint_query(value : String?) -> Array[@simulator.Breakpoint] {
  let breakpoints : Array[@simulator.Breakpoint] = []
  let seen : Map[UInt, Bool] = {}
  match value {
    None => ()
    Some(raw) => {
      let mut token = ""
      for c in raw {
        if c == ',' || c == ';' {
          if token != "" {
            match parse_uint_value(token) {
              Some(addr) =>
                if !seen.contains(addr) {
                  seen[addr] = true
                  breakpoints.push(@simulator.breakpoint(addr))
                }
              None => ()
            }
          }
          token = ""
        } else if !is_ascii_space(c) {
          token = token + c.to_string()
        }
      }
      if token != "" {
        match parse_uint_value(token) {
          Some(addr) =>
            if !seen.contains(addr) {
              seen[addr] = true
              breakpoints.push(@simulator.breakpoint(addr))
            }
          None => ()
        }
      }
    }
  }
  breakpoints
}

///|
fn parse_debug_entry(value : String?, fallback : UInt) -> UInt {
  match value {
    Some(raw) =>
      match parse_uint_value(raw) {
        Some(parsed) => parsed
        None => fallback
      }
    None => fallback
  }
}

///|
fn breakpoints_to_json(breakpoints : Array[@simulator.Breakpoint]) -> String {
  let mut json = "["
  for i = 0; i < breakpoints.length(); i = i + 1 {
    if i > 0 {
      json = json + ","
    }
    json = json + json_string(format_hex(breakpoints[i].addr))
  }
  json = json + "]"
  json
}

///|
fn trace_tail_to_json(
  events : Array[@simulator.TraceEvent],
  limit : Int,
) -> String {
  let tail_limit = if limit <= 0 { 1 } else { limit }
  let start = if events.length() > tail_limit {
    events.length() - tail_limit
  } else {
    0
  }
  let mut json = "["
  let mut first = true
  for i = start; i < events.length(); i = i + 1 {
    if !first {
      json = json + ","
    }
    json = json + @simulator.trace_event_to_json(events[i])
    first = false
  }
  json = json + "]"
  json
}

///|
fn session_error_json(message : String) -> String {
  "{\"ok\":false,\"error\":" + json_string(message) + "}"
}

///|
fn session_payload_json(session : DebugSession) -> String {
  let snapshot_json = @simulator.exec_snapshot_to_json(
    @simulator.snapshot(session.state),
  )
  let last_event_json = if session.state.trace.length() == 0 {
    "null"
  } else {
    @simulator.trace_event_to_json(
      session.state.trace[session.state.trace.length() - 1],
    )
  }
  "{\"ok\":true,\"data\":{\"session_id\":" +
  json_string(session.id) +
  ",\"file\":" +
  json_string(session.file) +
  ",\"entry\":" +
  json_string(format_hex(session.entry_addr)) +
  ",\"xlen\":" +
  session.state.image.xlen.to_string() +
  ",\"active\":" +
  (if session.active { "true" } else { "false" }) +
  ",\"breakpoints\":" +
  breakpoints_to_json(session.state.breakpoints) +
  ",\"snapshot\":" +
  snapshot_json +
  ",\"last_event\":" +
  last_event_json +
  ",\"trace_tail\":" +
  trace_tail_to_json(session.state.trace, 20) +
  ",\"trace_len\":" +
  session.state.trace.length().to_string() +
  "}}"
}

///|
fn next_debug_session_id(store : DebugSessionStore) -> String {
  let current = store.next_id.val
  store.next_id.val = current + 1
  "dbg-" + current.to_string()
}

///|
fn store_debug_session(
  store : DebugSessionStore,
  session : DebugSession,
) -> Unit {
  store.sessions.val[session.id] = session
}

///|
fn active_debug_session(
  store : DebugSessionStore,
  session_id : String,
) -> DebugSession? {
  match store.sessions.val.get(session_id) {
    Some(session) => if session.active { Some(session) } else { None }
    None => None
  }
}

///|
fn find_debug_session(
  store : DebugSessionStore,
  session_id : String,
) -> DebugSession? {
  store.sessions.val.get(session_id)
}

///|
fn resumable_debug_state(state : @simulator.ExecState) -> @simulator.ExecState {
  @simulator.with_entry(state, state.pc)
}

///|
fn debug_state_json(store : DebugSessionStore, session_id : String) -> String {
  match find_debug_session(store, session_id) {
    Some(session) => session_payload_json(session)
    None => session_error_json("debug session not found: " + session_id)
  }
}

///|
fn debug_step_state(state : @simulator.ExecState) -> @simulator.ExecState {
  match state.stop_reason {
    Some(@simulator.StopReason::Breakpoint(_))
    | Some(@simulator.StopReason::MaxSteps(_)) =>
      @simulator.step(resumable_debug_state(state))
    Some(_) => state
    None => @simulator.step(state)
  }
}

///|
fn debug_continue_state(
  state : @simulator.ExecState,
  max_steps : Int,
) -> @simulator.ExecState {
  let limit = if max_steps <= 0 { 128 } else { max_steps }
  match state.stop_reason {
    Some(@simulator.StopReason::Breakpoint(_)) => {
      let resumed = @simulator.step(resumable_debug_state(state))
      match resumed.stop_reason {
        Some(_) => resumed
        None =>
          if limit <= 1 {
            resumed
          } else {
            @simulator.run_until_break(resumed, limit - 1)
          }
      }
    }
    Some(@simulator.StopReason::MaxSteps(_)) =>
      @simulator.run_until_break(resumable_debug_state(state), limit)
    Some(_) => state
    None => @simulator.run_until_break(state, limit)
  }
}

///|
fn parse_optional_debug_breakpoints(
  value : String?,
) -> Array[@simulator.Breakpoint]? {
  match value {
    Some(raw) => Some(parse_breakpoint_query(Some(raw)))
    None => None
  }
}

///|
fn start_debug_session_json(
  store : DebugSessionStore,
  file : String,
  entry_addr : UInt,
  breakpoints : Array[@simulator.Breakpoint],
) -> String {
  match @simulator.load(file, entry_override=entry_addr) {
    @simulator.LoadFailed(err) => session_error_json(err.to_string())
    @simulator.Loaded(state) => {
      let resolved_entry = if entry_addr == 0U { state.pc } else { entry_addr }
      let session = {
        id: next_debug_session_id(store),
        file,
        entry_addr: resolved_entry,
        active: true,
        state: @simulator.with_breakpoints(state, breakpoints),
      }
      store_debug_session(store, session)
      session_payload_json(session)
    }
  }
}

///|
fn reset_debug_session_json(
  store : DebugSessionStore,
  session_id : String,
  breakpoints : Array[@simulator.Breakpoint]?,
) -> String {
  match active_debug_session(store, session_id) {
    None => session_error_json("debug session not found: " + session_id)
    Some(session) => {
      let next_breakpoints = match breakpoints {
        Some(values) => values
        None => session.state.breakpoints
      }
      match @simulator.load(session.file, entry_override=session.entry_addr) {
        @simulator.LoadFailed(err) => session_error_json(err.to_string())
        @simulator.Loaded(state) => {
          let next = {
            ..session,
            state: @simulator.with_breakpoints(state, next_breakpoints),
          }
          store_debug_session(store, next)
          session_payload_json(next)
        }
      }
    }
  }
}

///|
fn step_debug_session_json(
  store : DebugSessionStore,
  session_id : String,
  breakpoints : Array[@simulator.Breakpoint]?,
) -> String {
  match active_debug_session(store, session_id) {
    None => session_error_json("debug session not found: " + session_id)
    Some(session) => {
      let next_breakpoints = match breakpoints {
        Some(values) => values
        None => session.state.breakpoints
      }
      let next_state = debug_step_state(
        @simulator.with_breakpoints(session.state, next_breakpoints),
      )
      let next = { ..session, state: next_state }
      store_debug_session(store, next)
      session_payload_json(next)
    }
  }
}

///|
fn continue_debug_session_json(
  store : DebugSessionStore,
  session_id : String,
  max_steps : Int,
  breakpoints : Array[@simulator.Breakpoint]?,
) -> String {
  match active_debug_session(store, session_id) {
    None => session_error_json("debug session not found: " + session_id)
    Some(session) => {
      let next_breakpoints = match breakpoints {
        Some(values) => values
        None => session.state.breakpoints
      }
      let next_state = debug_continue_state(
        @simulator.with_breakpoints(session.state, next_breakpoints),
        max_steps,
      )
      let next = { ..session, state: next_state }
      store_debug_session(store, next)
      session_payload_json(next)
    }
  }
}

///|
fn stop_debug_session_json(
  store : DebugSessionStore,
  session_id : String,
) -> String {
  match find_debug_session(store, session_id) {
    None => session_error_json("debug session not found: " + session_id)
    Some(session) => {
      let next = { ..session, active: false }
      store_debug_session(store, next)
      "{\"ok\":true,\"data\":{\"session_id\":" +
      json_string(session_id) +
      ",\"stopped\":true}}"
    }
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
  let debug_store = make_debug_session_store()

  app.get("/", @mars.handler(async fn(ctx) { ctx.html(index_html) }))

  app.get("/index.html", @mars.handler(async fn(ctx) { ctx.html(index_html) }))

  app.get(
    "/workbench",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      ctx.html(build_workbench_route_html(opts, file))
    }),
  )

  app.get(
    "/api/health",
    @mars.handler(async fn(ctx) { ctx.json({ "ok": true }) }),
  )

  app.get(
    "/api/workbench/overview",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let max_events = choose_positive_int(
        ctx.query("max_events"),
        opts.max_events,
      )
      let payload_text = @workbench.overview_api_json_from_file(
        file, max_events,
      )
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.get(
    "/api/workbench/function",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let addr = choose_file(ctx.query("addr"), "")
      let payload_text = @workbench.function_api_json_from_file(file, addr)
      respond_payload_json(ctx, payload_text)
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

  app.post(
    "/api/debug/start",
    @mars.handler(async fn(ctx) {
      let file = choose_file(ctx.query("file"), opts.default_file)
      let entry_addr = parse_debug_entry(ctx.query("entry"), 0U)
      let breakpoints = parse_breakpoint_query(ctx.query("breakpoints"))
      let payload_text = start_debug_session_json(
        debug_store, file, entry_addr, breakpoints,
      )
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.get(
    "/api/debug/state",
    @mars.handler(async fn(ctx) {
      let session_id = choose_file(ctx.query("id"), "")
      let payload_text = debug_state_json(debug_store, session_id)
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.post(
    "/api/debug/step",
    @mars.handler(async fn(ctx) {
      let session_id = choose_file(ctx.query("id"), "")
      let breakpoints = parse_optional_debug_breakpoints(
        ctx.query("breakpoints"),
      )
      let payload_text = step_debug_session_json(
        debug_store, session_id, breakpoints,
      )
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.post(
    "/api/debug/continue",
    @mars.handler(async fn(ctx) {
      let session_id = choose_file(ctx.query("id"), "")
      let max_steps = choose_positive_int(ctx.query("max_steps"), 128)
      let breakpoints = parse_optional_debug_breakpoints(
        ctx.query("breakpoints"),
      )
      let payload_text = continue_debug_session_json(
        debug_store, session_id, max_steps, breakpoints,
      )
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.post(
    "/api/debug/reset",
    @mars.handler(async fn(ctx) {
      let session_id = choose_file(ctx.query("id"), "")
      let breakpoints = parse_optional_debug_breakpoints(
        ctx.query("breakpoints"),
      )
      let payload_text = reset_debug_session_json(
        debug_store, session_id, breakpoints,
      )
      respond_payload_json(ctx, payload_text)
    }),
  )

  app.post(
    "/api/debug/stop",
    @mars.handler(async fn(ctx) {
      let session_id = choose_file(ctx.query("id"), "")
      let payload_text = stop_debug_session_json(debug_store, session_id)
      respond_payload_json(ctx, payload_text)
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
