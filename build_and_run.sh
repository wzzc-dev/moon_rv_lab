#!/bin/bash
# Build and run RISC-V assembly with runtime library

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <source.s> [args...]"
    exit 1
fi

SOURCE="$1"
shift

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER="$SCRIPT_DIR/tools/build/rvrunner"
OUTPUT="/tmp/riscv_program.elf"

# Compile with runtime library
echo "Compiling $SOURCE..."
riscv64-unknown-elf-gcc -march=rv64imac -mabi=lp64 -ffreestanding -nostdlib -static \
    -I "$SCRIPT_DIR/riscv_rt" \
    "$SCRIPT_DIR/riscv_rt/start.S" \
    "$SCRIPT_DIR/riscv_rt/start.c" \
    "$SCRIPT_DIR/riscv_rt/lib_simple.c" \
    "$SOURCE" \
    -o "$OUTPUT"

echo "Running..."
echo "---"
"$RUNNER" "$OUTPUT" "$@"
