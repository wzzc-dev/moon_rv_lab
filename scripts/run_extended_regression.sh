#!/usr/bin/env bash

set -euo pipefail

MOON_BIN="${MOON_BIN:-moon}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/out/extended_regression"

require_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    echo "Expected to find '$needle' in $file" >&2
    exit 1
  fi
}

echo "==> Preparing extended regression workspace"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*

echo "==> Updating dependencies"
"$MOON_BIN" update

echo "==> Running package regression tests"
"$MOON_BIN" test analysis
"$MOON_BIN" test decode
"$MOON_BIN" test format
"$MOON_BIN" test simulator --target native
"$MOON_BIN" test cmd/main --target native
"$MOON_BIN" test workbench --target native

echo "==> Verifying RV64 and RV32 baseline outputs"
"$MOON_BIN" run cmd/main -- asm example/simple.s -o "$OUT_DIR/simple.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/simple.elf" --format json > "$OUT_DIR/simple.run.json"
require_contains "$OUT_DIR/simple.run.json" '"xlen":64'
require_contains "$OUT_DIR/simple.run.json" '"entry":"0x10000"'
require_contains "$OUT_DIR/simple.run.json" '"stop_reason":"ebreak @0x1002c"'

"$MOON_BIN" run cmd/main -- workbench "$OUT_DIR/simple.elf" -o "$OUT_DIR/simple.workbench.html"
require_contains "$OUT_DIR/simple.workbench.html" '"xlen":64'
require_contains "$OUT_DIR/simple.workbench.html" '"stop_reason":"ebreak @0x1002c"'

"$MOON_BIN" run cmd/main -- asm example/simple.s -o "$OUT_DIR/simple32.elf" --xlen 32
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/simple32.elf" --format json > "$OUT_DIR/simple32.run.json"
require_contains "$OUT_DIR/simple32.run.json" '"xlen":32'
require_contains "$OUT_DIR/simple32.run.json" '"stop_reason":"ebreak @0x1002c"'

"$MOON_BIN" run cmd/main -- workbench "$OUT_DIR/simple32.elf" -o "$OUT_DIR/simple32.workbench.html"
require_contains "$OUT_DIR/simple32.workbench.html" '"xlen":32'
require_contains "$OUT_DIR/simple32.workbench.html" '"stop_reason":"ebreak @0x1002c"'

echo "==> Verifying analysis-oriented sample programs"
"$MOON_BIN" run cmd/main -- asm example/branch_loop.s -o "$OUT_DIR/branch_loop.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/branch_loop.elf" --max-steps 20 --format json > "$OUT_DIR/branch_loop.run.json"
require_contains "$OUT_DIR/branch_loop.run.json" '"xlen":64'
require_contains "$OUT_DIR/branch_loop.run.json" '"trace":['

"$MOON_BIN" run cmd/main -- asm example/memory_roundtrip.s -o "$OUT_DIR/memory_roundtrip.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/memory_roundtrip.elf" --trace "$OUT_DIR/memory_roundtrip.trace.json" --format json > "$OUT_DIR/memory_roundtrip.run.json"
require_contains "$OUT_DIR/memory_roundtrip.run.json" '"memory_writes":['
require_contains "$OUT_DIR/memory_roundtrip.trace.json" '"memory_writes":['

"$MOON_BIN" run cmd/main -- asm example/call_chain.s -o "$OUT_DIR/call_chain.elf"
"$MOON_BIN" run cmd/main -- workbench "$OUT_DIR/call_chain.elf" -o "$OUT_DIR/call_chain.workbench.html"
require_contains "$OUT_DIR/call_chain.workbench.html" '"embedded_overview"'
require_contains "$OUT_DIR/call_chain.workbench.html" '"embedded_function_slices"'

"$MOON_BIN" run cmd/main -- asm example/print_42.s -o "$OUT_DIR/print_42.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/print_42.elf" --trace "$OUT_DIR/print_42.trace.json" --format json > "$OUT_DIR/print_42.run.json"
require_contains "$OUT_DIR/print_42.run.json" '"stdout":"42\n"'
require_contains "$OUT_DIR/print_42.run.json" '"name":"write"'
require_contains "$OUT_DIR/print_42.trace.json" '"name":"write"'

echo "==> Verifying file and syscall samples"
"$MOON_BIN" run cmd/main -- asm example/file_open_read_close.s -o "$OUT_DIR/file_open_read_close.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/file_open_read_close.elf" --trace "$OUT_DIR/file_open_read_close.trace.json" --format json > "$OUT_DIR/file_open_read_close.run.json"
require_contains "$OUT_DIR/file_open_read_close.run.json" '"name":"openat"'
require_contains "$OUT_DIR/file_open_read_close.run.json" '"name":"read"'
require_contains "$OUT_DIR/file_open_read_close.run.json" '"name":"close"'

"$MOON_BIN" run cmd/main -- asm example/file_lseek_read.s -o "$OUT_DIR/file_lseek_read.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/file_lseek_read.elf" --trace "$OUT_DIR/file_lseek_read.trace.json" --format json > "$OUT_DIR/file_lseek_read.run.json"
require_contains "$OUT_DIR/file_lseek_read.run.json" '"name":"lseek"'
require_contains "$OUT_DIR/file_lseek_read.run.json" '"name":"read"'

"$MOON_BIN" run cmd/main -- asm example/file_fstat_close.s -o "$OUT_DIR/file_fstat_close.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/file_fstat_close.elf" --trace "$OUT_DIR/file_fstat_close.trace.json" --format json > "$OUT_DIR/file_fstat_close.run.json"
require_contains "$OUT_DIR/file_fstat_close.run.json" '"name":"fstat"'
require_contains "$OUT_DIR/file_fstat_close.run.json" '"memory_writes":['

"$MOON_BIN" run cmd/main -- asm example/sys_brk_ioctl.s -o "$OUT_DIR/sys_brk_ioctl.elf"
"$MOON_BIN" run cmd/main -- run "$OUT_DIR/sys_brk_ioctl.elf" --trace "$OUT_DIR/sys_brk_ioctl.trace.json" --format json > "$OUT_DIR/sys_brk_ioctl.run.json"
require_contains "$OUT_DIR/sys_brk_ioctl.run.json" '"name":"brk"'
require_contains "$OUT_DIR/sys_brk_ioctl.run.json" '"name":"ioctl"'

echo "Extended regression completed successfully."
