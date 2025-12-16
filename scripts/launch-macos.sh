#!/bin/bash
# macOS Monterey ARM64 QEMU Launch Script
# Last updated: 2025-12-16
#
# This script launches macOS Monterey ARM64 in QEMU with optimal settings
# for Apple Silicon hosts using HVF (Hypervisor.Framework) acceleration.

set -e

# Configuration Variables
QEMU_BINARY="qemu-system-aarch64"
VM_NAME="macOS-Monterey-ARM64"
RAM_SIZE="4G"
CPU_CORES="4"

# Paths (adjust as needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
UEFI_FIRMWARE="/usr/share/edk2/aarch64/QEMU_EFI.fd"
MACOS_DISK="${PROJECT_ROOT}/output/mac_hdd.img"
INSTALLER_IMG="${PROJECT_ROOT}/output/BaseSystem.img"

# Check if running on Apple Silicon
check_apple_silicon() {
    if [[ "$(uname -m)" != "arm64" ]]; then
        echo "Warning: Not running on ARM64 architecture."
        echo "Performance will be significantly reduced without native virtualization."
    fi
}

# Check for required files
check_requirements() {
    if ! command -v "$QEMU_BINARY" &> /dev/null; then
        echo "Error: $QEMU_BINARY not found. Please install QEMU."
        exit 1
    fi

    if [[ ! -f "$UEFI_FIRMWARE" ]]; then
        # Try alternative paths
        for fw_path in \
            "/opt/homebrew/share/qemu/edk2-aarch64-code.fd" \
            "/usr/local/share/qemu/edk2-aarch64-code.fd" \
            "/usr/share/OVMF/OVMF_CODE.fd"; do
            if [[ -f "$fw_path" ]]; then
                UEFI_FIRMWARE="$fw_path"
                break
            fi
        done
        
        if [[ ! -f "$UEFI_FIRMWARE" ]]; then
            echo "Error: UEFI firmware not found at $UEFI_FIRMWARE"
            echo "Please install edk2-aarch64 or specify the correct path."
            exit 1
        fi
    fi

    if [[ ! -f "$MACOS_DISK" ]]; then
        echo "Error: macOS disk image not found at $MACOS_DISK"
        echo "Create one with: qemu-img create -f qcow2 $MACOS_DISK 128G"
        exit 1
    fi
}

# Create virtual disk if it doesn't exist
create_disk() {
    local disk_path="$1"
    local disk_size="${2:-128G}"
    
    if [[ ! -f "$disk_path" ]]; then
        echo "Creating virtual disk: $disk_path ($disk_size)"
        qemu-img create -f qcow2 "$disk_path" "$disk_size"
    fi
}

# Launch QEMU with macOS configuration
launch_qemu() {
    local accel_option=""
    
    # Detect acceleration method
    if [[ "$(uname)" == "Darwin" ]]; then
        accel_option="-accel hvf"
    elif [[ -e /dev/kvm ]]; then
        accel_option="-accel kvm"
    else
        accel_option="-accel tcg"
        echo "Warning: No hardware acceleration available. Using TCG (software emulation)."
    fi

    echo "Starting $VM_NAME..."
    echo "  RAM: $RAM_SIZE"
    echo "  CPUs: $CPU_CORES"
    echo "  Acceleration: $accel_option"

    # QEMU Command
    # Reference: Technical Specification Section 1.2
    $QEMU_BINARY \
        -M virt,highmem=on \
        -cpu host \
        $accel_option \
        -m "$RAM_SIZE" \
        -smp "$CPU_CORES" \
        -bios "$UEFI_FIRMWARE" \
        -drive file="$MACOS_DISK",if=virtio,format=qcow2,cache=writethrough \
        ${INSTALLER_IMG:+-drive file="$INSTALLER_IMG",if=mtd,format=raw,readonly=on} \
        -device ramfb \
        -device virtio-gpu-pci \
        -nic user,model=virtio-net-pci \
        -device usb-ehci \
        -device usb-kbd \
        -device usb-mouse \
        -display cocoa,gl=on \
        -name "$VM_NAME"
}

# Main execution
main() {
    check_apple_silicon
    check_requirements
    launch_qemu
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
