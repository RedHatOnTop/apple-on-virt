#!/bin/bash
# macOS ARM64 QEMU Launch Script for WSL
# Last updated: 2025-12-16
#
# This script launches macOS ARM64 (Monterey/Big Sur) in QEMU within WSL environment.
# WSL constraints: x86_64 host (no HVF/KVM), TCG emulation only, GTK display.
#
# NOTE: Standard QEMU cannot boot macOS XNU kernel without modifications.
# This script provides a baseline for UEFI testing and development.
# For actual XNU boot, a patched QEMU with Apple hardware emulation is required.

set -e

# Configuration Variables
QEMU_BINARY="${QEMU_BINARY:-qemu-system-aarch64}"
VM_NAME="macOS-ARM64-WSL"
RAM_SIZE="${RAM_SIZE:-6G}"
CPU_CORES="${CPU_CORES:-4}"

# Paths (WSL paths - adjust as needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# EDK2 firmware path for WSL
UEFI_FIRMWARE=""

# Disk images
MACOS_DISK="${PROJECT_ROOT}/output/mac_hdd.img"
INSTALLER_IMG="${PROJECT_ROOT}/output/BaseSystem.img"

# Debug log
DEBUG_LOG="${PROJECT_ROOT}/output/qemu_debug.log"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Find UEFI firmware
find_firmware() {
    local fw_paths=(
        "/usr/local/share/qemu/edk2-aarch64-code.fd"
        "/usr/share/qemu/edk2-aarch64-code.fd"
        "/usr/share/AAVMF/AAVMF_CODE.fd"
        "/usr/share/edk2/aarch64/QEMU_EFI.fd"
        "/usr/share/OVMF/OVMF.fd"
    )
    
    for fw_path in "${fw_paths[@]}"; do
        if [[ -f "$fw_path" ]]; then
            UEFI_FIRMWARE="$fw_path"
            return 0
        fi
    done
    return 1
}

# Check for required files
check_requirements() {
    log_info "Checking requirements..."
    
    # Check QEMU binary
    if ! command -v "$QEMU_BINARY" &> /dev/null; then
        log_error "$QEMU_BINARY not found."
        log_info "Install with: sudo apt install qemu-system-arm"
        exit 1
    fi
    
    # Get QEMU version
    local qemu_version
    qemu_version=$($QEMU_BINARY --version | head -1)
    log_info "QEMU: $qemu_version"
    
    # Find firmware
    if ! find_firmware; then
        log_error "UEFI firmware not found."
        log_info "Install with: sudo apt install qemu-efi-aarch64"
        exit 1
    fi
    log_info "Firmware: $UEFI_FIRMWARE"
    
    # Create output directory
    mkdir -p "$(dirname "$MACOS_DISK")"
    
    # Create virtual disk if needed
    if [[ ! -f "$MACOS_DISK" ]]; then
        log_info "Creating virtual disk: $MACOS_DISK (128G)"
        qemu-img create -f qcow2 "$MACOS_DISK" 128G
    else
        log_info "Virtual disk: $MACOS_DISK"
    fi
    
    # Check for installer image
    if [[ -f "$INSTALLER_IMG" ]]; then
        log_info "Installer image: $INSTALLER_IMG"
    else
        log_warn "No installer image found at $INSTALLER_IMG"
        log_warn "UEFI shell will boot instead."
    fi
}

# Print QEMU command for reference
print_command() {
    echo ""
    echo "=== QEMU Command ==="
    echo "$QEMU_BINARY \\"
    echo "  -M virt,highmem=on \\"
    echo "  -cpu max \\"
    echo "  -accel tcg,thread=multi \\"
    echo "  -m $RAM_SIZE \\"
    echo "  -smp $CPU_CORES \\"
    echo "  -bios $UEFI_FIRMWARE \\"
    echo "  -drive file=$MACOS_DISK,if=virtio,format=qcow2,cache=writethrough \\"
    if [[ -f "$INSTALLER_IMG" ]]; then
        echo "  -drive file=$INSTALLER_IMG,if=none,format=raw,id=installer \\"
        echo "  -device usb-storage,drive=installer \\"
    fi
    echo "  -device ramfb \\"
    echo "  -device virtio-gpu-pci \\"
    echo "  -device qemu-xhci \\"
    echo "  -device usb-kbd \\"
    echo "  -device usb-tablet \\"
    echo "  -display gtk \\"
    echo "  -serial mon:stdio \\"
    echo "  -d guest_errors,unimp \\"
    echo "  -D $DEBUG_LOG \\"
    echo "  -name $VM_NAME"
    echo ""
    echo "Note: Network (-nic user) omitted. Add if available in your QEMU build."
    echo ""
}

# Launch QEMU with WSL-optimized configuration
launch_qemu() {
    echo ""
    echo "=== Launching macOS ARM64 Emulator (WSL) ==="
    echo ""
    log_info "VM Name: $VM_NAME"
    log_info "RAM: $RAM_SIZE"
    log_info "CPUs: $CPU_CORES"
    log_info "Acceleration: TCG (software emulation)"
    log_info "Display: GTK (WSLg)"
    echo ""
    log_warn "Performance Notice:"
    log_warn "  ARM64 emulation on x86_64 is approximately 10-100x slower than native."
    log_warn "  Boot process may take hours. For practical use, native ARM64 host is recommended."
    echo ""
    log_warn "XNU Boot Notice:"
    log_warn "  Standard QEMU cannot boot macOS XNU kernel without modifications."
    log_warn "  This script boots to UEFI shell for testing infrastructure."
    log_warn "  See docs/spec/WSL_QEMU_Implementation_Guide.md for XNU boot requirements."
    echo ""

    # Build installer drive arguments
    local installer_args=""
    if [[ -f "$INSTALLER_IMG" ]]; then
        installer_args="-drive file=$INSTALLER_IMG,if=none,format=raw,id=installer -device usb-storage,drive=installer"
    fi

    # QEMU Command optimized for WSL
    # - No HVF/KVM (x86_64 host cannot accelerate ARM64)
    # - TCG with multi-threaded emulation
    # - GTK display for WSLg support
    # - Serial console for debugging
    # - Debug logging enabled
    # - Network omitted if not available (add -nic user,model=virtio-net-pci if supported)
    $QEMU_BINARY \
        -M virt,highmem=on \
        -cpu max \
        -accel tcg,thread=multi \
        -m "$RAM_SIZE" \
        -smp "$CPU_CORES" \
        -bios "$UEFI_FIRMWARE" \
        -drive file="$MACOS_DISK",if=virtio,format=qcow2,cache=writethrough \
        $installer_args \
        -device ramfb \
        -device virtio-gpu-pci \
        -device qemu-xhci \
        -device usb-kbd \
        -device usb-tablet \
        -display gtk \
        -serial mon:stdio \
        -d guest_errors,unimp \
        -D "$DEBUG_LOG" \
        -name "$VM_NAME"
}

# Print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --command  Print QEMU command without executing"
    echo "  -m RAM         Set RAM size (default: 6G)"
    echo "  -s CORES       Set CPU cores (default: 4)"
    echo ""
    echo "Environment Variables:"
    echo "  QEMU_BINARY    Path to qemu-system-aarch64 (default: qemu-system-aarch64)"
    echo "  RAM_SIZE       RAM allocation (default: 6G)"
    echo "  CPU_CORES      Number of CPU cores (default: 4)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Launch with defaults"
    echo "  $0 -c                 # Print command only"
    echo "  RAM_SIZE=8G $0       # Launch with 8G RAM"
}

# Main execution
main() {
    local print_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--command)
                print_only=true
                shift
                ;;
            -m)
                RAM_SIZE="$2"
                shift 2
                ;;
            -s)
                CPU_CORES="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    echo ""
    echo "========================================"
    echo "  macOS ARM64 Emulator for WSL"
    echo "  Project: apple-on-virt"
    echo "========================================"
    echo ""
    
    check_requirements
    
    if $print_only; then
        print_command
    else
        print_command
        read -p "Press Enter to launch QEMU (Ctrl+C to cancel)..."
        launch_qemu
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
