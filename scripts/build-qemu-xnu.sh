#!/bin/bash
# QEMU XNU Build Script for WSL
# Last updated: 2025-12-16
#
# This script builds a patched QEMU with Apple XNU kernel support for macOS emulation.
# Based on analysis of macos-arm64-emulation project, adapted for QEMU 10.x.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/qemu-build"
PATCHES_DIR="${PROJECT_ROOT}/patches"

# QEMU version to build
QEMU_VERSION="10.0.0"
QEMU_URL="https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

check_dependencies() {
    log_step "Checking build dependencies..."
    
    local deps=(
        "gcc"
        "make"
        "pkg-config"
        "python3"
        "ninja-build"
        "meson"
        "git"
        "wget"
        "tar"
        "xz-utils"
    )
    
    local libs=(
        "libglib2.0-dev"
        "libpixman-1-dev"
        "libgtk-3-dev"
        "libsdl2-dev"
        "libspice-server-dev"
        "libusb-1.0-0-dev"
        "libaio-dev"
        "libcap-ng-dev"
        "libattr1-dev"
    )
    
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing build tools: ${missing[*]}"
        log_info "Install with:"
        log_info "  sudo apt update"
        log_info "  sudo apt install build-essential ninja-build meson pkg-config python3 git wget"
        exit 1
    fi
    
    log_info "Build tools: OK"
}

download_qemu() {
    log_step "Downloading QEMU ${QEMU_VERSION}..."
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    if [ -f "qemu-${QEMU_VERSION}.tar.xz" ]; then
        log_info "QEMU source already downloaded"
    else
        wget -c "$QEMU_URL"
    fi
    
    if [ -d "qemu-${QEMU_VERSION}" ]; then
        log_info "QEMU source already extracted"
    else
        log_info "Extracting QEMU source..."
        tar xf "qemu-${QEMU_VERSION}.tar.xz"
    fi
    
    cd "qemu-${QEMU_VERSION}"
    log_info "QEMU source ready at: $(pwd)"
}

apply_patches() {
    log_step "Applying XNU compatibility patches..."
    
    cd "$BUILD_DIR/qemu-${QEMU_VERSION}"
    
    # Check if patches exist
    if [ -d "$PATCHES_DIR" ] && [ -f "$PATCHES_DIR/01-apple-sysregs.patch" ]; then
        log_info "Applying Apple system registers patch..."
        git apply "$PATCHES_DIR/01-apple-sysregs.patch" 2>/dev/null || {
            log_warn "Patch may already be applied or needs manual integration"
        }
    else
        log_warn "No patches found in $PATCHES_DIR"
        log_warn "Building standard QEMU without XNU modifications"
        log_info ""
        log_info "For XNU boot support, create patches based on:"
        log_info "  - Apple-specific ARM64 system registers (HID, EHID, PMC, etc.)"
        log_info "  - Apple machine type with XNU boot support"
        log_info "  - Mach-O kernel loading capability"
        log_info ""
        log_info "See docs/spec/WSL_QEMU_Implementation_Guide.md for details"
    fi
}

configure_qemu() {
    log_step "Configuring QEMU for ARM64 target..."
    
    cd "$BUILD_DIR/qemu-${QEMU_VERSION}"
    
    # Configure for aarch64 target with GTK display
    ./configure \
        --target-list=aarch64-softmmu \
        --enable-gtk \
        --enable-sdl \
        --enable-spice \
        --enable-usb-redir \
        --enable-libusb \
        --prefix="$BUILD_DIR/install" \
        --disable-werror
    
    log_info "Configuration complete"
}

build_qemu() {
    log_step "Building QEMU..."
    
    cd "$BUILD_DIR/qemu-${QEMU_VERSION}"
    
    # Build with parallel jobs
    local jobs=$(nproc)
    log_info "Building with $jobs parallel jobs..."
    
    make -j"$jobs"
    
    log_info "Build complete"
    
    # Optionally install
    if [ "$1" == "--install" ]; then
        log_step "Installing QEMU..."
        make install
        log_info "Installed to: $BUILD_DIR/install"
    fi
}

print_result() {
    log_step "Build Summary"
    echo ""
    
    local qemu_bin="$BUILD_DIR/qemu-${QEMU_VERSION}/build/qemu-system-aarch64"
    
    if [ -f "$qemu_bin" ]; then
        log_info "QEMU binary: $qemu_bin"
        "$qemu_bin" --version
    else
        qemu_bin="$BUILD_DIR/qemu-${QEMU_VERSION}/qemu-system-aarch64"
        if [ -f "$qemu_bin" ]; then
            log_info "QEMU binary: $qemu_bin"
            "$qemu_bin" --version
        else
            log_warn "QEMU binary not found in expected locations"
        fi
    fi
    
    echo ""
    log_info "To use the built QEMU, add to your launch script:"
    log_info "  QEMU_BINARY=$qemu_bin"
}

usage() {
    echo "QEMU XNU Build Script for WSL"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all         Full build (download, patch, configure, build)"
    echo "  download    Download QEMU source"
    echo "  patch       Apply XNU compatibility patches"
    echo "  configure   Configure build"
    echo "  build       Build QEMU"
    echo "  clean       Clean build directory"
    echo "  help        Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  QEMU_VERSION  QEMU version to build (default: $QEMU_VERSION)"
    echo ""
}

main() {
    echo ""
    echo "========================================"
    echo "  QEMU XNU Build Script"
    echo "  Project: apple-on-virt"
    echo "========================================"
    echo ""
    
    case "${1:-all}" in
        all)
            check_dependencies
            download_qemu
            apply_patches
            configure_qemu
            build_qemu
            print_result
            ;;
        download)
            download_qemu
            ;;
        patch)
            apply_patches
            ;;
        configure)
            configure_qemu
            ;;
        build)
            build_qemu "$2"
            print_result
            ;;
        clean)
            log_info "Cleaning build directory..."
            rm -rf "$BUILD_DIR"
            log_info "Done"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            log_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
