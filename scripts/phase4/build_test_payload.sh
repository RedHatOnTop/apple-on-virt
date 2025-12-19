#!/bin/bash
#
# Build test payload for Phase 4-pre
# Requires: aarch64 cross-compiler
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../../output"

# Check for aarch64 toolchain
if ! command -v aarch64-linux-gnu-as &> /dev/null; then
    echo "Error: aarch64-linux-gnu-as not found"
    echo "Install with: sudo apt-get install binutils-aarch64-linux-gnu"
    exit 1
fi

echo "Building test payload..."

# Assemble
aarch64-linux-gnu-as \
    -o "$OUTPUT_DIR/test_payload.o" \
    "$SCRIPT_DIR/test_payload.s"

# Link at specific address
aarch64-linux-gnu-ld \
    -Ttext=0x800100000 \
    -o "$OUTPUT_DIR/test_payload.elf" \
    "$OUTPUT_DIR/test_payload.o"

# Extract raw binary
aarch64-linux-gnu-objcopy \
    -O binary \
    "$OUTPUT_DIR/test_payload.elf" \
    "$OUTPUT_DIR/test_payload.bin"

echo "✓ Test payload built:"
echo "  ELF:    $OUTPUT_DIR/test_payload.elf"
echo "  Binary: $OUTPUT_DIR/test_payload.bin"
echo "  Size:   $(stat -f%z "$OUTPUT_DIR/test_payload.bin" 2>/dev/null || stat -c%s "$OUTPUT_DIR/test_payload.bin") bytes"

# Disassemble for verification
aarch64-linux-gnu-objdump -d "$OUTPUT_DIR/test_payload.elf" > "$OUTPUT_DIR/test_payload.dis"
echo "  Disasm: $OUTPUT_DIR/test_payload.dis"
