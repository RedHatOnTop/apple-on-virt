#!/bin/bash
# Build Phase 5c timebase smoke test payload
# Requires: aarch64-linux-gnu-as/ld/objcopy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../../output"

for tool in aarch64-linux-gnu-as aarch64-linux-gnu-ld aarch64-linux-gnu-objcopy; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: $tool not found"
    exit 1
  fi
done

SRC="$SCRIPT_DIR/phase5c_timebase_smoketest.s"
OBJ="$OUTPUT_DIR/phase5c_timebase_smoketest.o"
ELF="$OUTPUT_DIR/phase5c_timebase_smoketest.elf"
BIN="$OUTPUT_DIR/phase5c_timebase_smoketest.bin"

# Assemble

aarch64-linux-gnu-as -o "$OBJ" "$SRC"

# Link at APPLE_IBOOT_BASE (0x8_0010_0000)
aarch64-linux-gnu-ld -Ttext=0x800100000 -o "$ELF" "$OBJ"

# Raw binary
aarch64-linux-gnu-objcopy -O binary "$ELF" "$BIN"

echo "Built: $BIN ($(stat -c%s "$BIN" 2>/dev/null || stat -f%z "$BIN") bytes)"
