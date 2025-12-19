#!/bin/bash
#
# Run QEMU test environment for Phase 4-pre
#
# This script launches QEMU with:
# - Minimal virt machine
# - 256MB RAM at 0x8_0000_0000
# - Test payload loaded
# - ADT loaded at known offset
# - Serial output enabled
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../../output"
PROJECT_ROOT="$SCRIPT_DIR/../.."

# Check required files
if [ ! -f "$OUTPUT_DIR/test_payload.bin" ]; then
    echo "Error: test_payload.bin not found"
    echo "Run: ./build_test_payload.sh"
    exit 1
fi

if [ ! -f "$OUTPUT_DIR/minimal_adt.bin" ]; then
    echo "Error: minimal_adt.bin not found"
    echo "Run: python scripts/phase4/minimal_adt_gen.py output/minimal_adt.bin"
    exit 1
fi

# QEMU configuration
QEMU_BIN="qemu-system-aarch64"
MACHINE="virt"
CPU="cortex-a72"  # Generic ARMv8-A, not arm64e but sufficient for testing
RAM_SIZE="256M"
RAM_BASE="0x800000000"  # Note: virt machine may use different base

# Check QEMU availability
if ! command -v $QEMU_BIN &> /dev/null; then
    echo "Error: $QEMU_BIN not found"
    echo "Install with: sudo apt-get install qemu-system-aarch64"
    exit 1
fi

echo "Phase 4-pre: Minimal Boot Environment Test"
echo "==========================================="
echo ""
echo "Configuration:"
echo "  Machine: $MACHINE"
echo "  CPU:     $CPU"
echo "  RAM:     $RAM_SIZE"
echo "  Payload: $(stat -f%z "$OUTPUT_DIR/test_payload.bin" 2>/dev/null || stat -c%s "$OUTPUT_DIR/test_payload.bin") bytes"
echo "  ADT:     $(stat -f%z "$OUTPUT_DIR/minimal_adt.bin" 2>/dev/null || stat -c%s "$OUTPUT_DIR/minimal_adt.bin") bytes"
echo ""
echo "Memory layout:"
echo "  0x4000_0000: Payload load address (virt machine default)"
echo "  0x4001_0000: ADT location (64KB offset)"
echo ""
echo "Starting QEMU..."
echo ""

# Create temporary bootloader that jumps to payload
# This is needed because QEMU virt machine doesn't load at arbitrary addresses
cat > "$OUTPUT_DIR/bootloader.s" << 'EOF'
.global _start
.section .text

_start:
    /* Set up minimal state */
    msr     DAIFSet, #0xF          // Mask all interrupts
    
    /* x0 = pointer to ADT (at 0x4001_0000) */
    mov     x0, #0x4000
    movk    x0, #0x1, lsl #16
    movk    x0, #0x0, lsl #32
    movk    x0, #0x0, lsl #48
    
    /* Jump to test payload at 0x4000_1000 */
    mov     x1, #0x4000
    movk    x1, #0x1, lsl #16
    br      x1
EOF

# Build bootloader
aarch64-linux-gnu-as -o "$OUTPUT_DIR/bootloader.o" "$OUTPUT_DIR/bootloader.s"
aarch64-linux-gnu-ld -Ttext=0x40000000 -o "$OUTPUT_DIR/bootloader.elf" "$OUTPUT_DIR/bootloader.o"
aarch64-linux-gnu-objcopy -O binary "$OUTPUT_DIR/bootloader.elf" "$OUTPUT_DIR/bootloader.bin"

# Create combined image: bootloader + padding + payload + padding + ADT
dd if="$OUTPUT_DIR/bootloader.bin" of="$OUTPUT_DIR/boot_image.bin" bs=1 2>/dev/null
dd if=/dev/zero bs=1 count=$((0x1000 - $(stat -f%z "$OUTPUT_DIR/bootloader.bin" 2>/dev/null || stat -c%s "$OUTPUT_DIR/bootloader.bin"))) >> "$OUTPUT_DIR/boot_image.bin" 2>/dev/null
dd if="$OUTPUT_DIR/test_payload.bin" >> "$OUTPUT_DIR/boot_image.bin" bs=1 2>/dev/null
dd if=/dev/zero bs=1 count=$((0x10000 - 0x1000 - $(stat -f%z "$OUTPUT_DIR/test_payload.bin" 2>/dev/null || stat -c%s "$OUTPUT_DIR/test_payload.bin"))) >> "$OUTPUT_DIR/boot_image.bin" 2>/dev/null
dd if="$OUTPUT_DIR/minimal_adt.bin" >> "$OUTPUT_DIR/boot_image.bin" bs=1 2>/dev/null

echo "Boot image created: $(stat -f%z "$OUTPUT_DIR/boot_image.bin" 2>/dev/null || stat -c%s "$OUTPUT_DIR/boot_image.bin") bytes"
echo ""

# Run QEMU
$QEMU_BIN \
    -machine $MACHINE \
    -cpu $CPU \
    -m $RAM_SIZE \
    -nographic \
    -monitor none \
    -serial stdio \
    -kernel "$OUTPUT_DIR/boot_image.bin" \
    -d guest_errors,unimp,cpu_reset \
    -D "$OUTPUT_DIR/qemu_log.txt" \
    $@
