#!/bin/bash
# IPSW Extraction Script for macOS ARM64
# Last updated: 2025-12-16
#
# Extracts BaseSystem.dmg and other required files from Apple IPSW files.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IPSW_DIR="${PROJECT_ROOT}/local_storage/ipsw"
OUTPUT_DIR="${PROJECT_ROOT}/output"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

check_dependencies() {
    local missing=()
    
    for cmd in unzip 7z; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: sudo apt install unzip p7zip-full"
        exit 1
    fi
}

list_ipsw_files() {
    log_info "Available IPSW files:"
    if [ -d "$IPSW_DIR" ]; then
        ls -la "$IPSW_DIR"/*.ipsw 2>/dev/null || log_warn "No IPSW files found in $IPSW_DIR"
    else
        log_error "IPSW directory not found: $IPSW_DIR"
    fi
}

extract_ipsw() {
    local ipsw_file="$1"
    local temp_dir="${OUTPUT_DIR}/ipsw_temp"
    
    if [ ! -f "$ipsw_file" ]; then
        log_error "IPSW file not found: $ipsw_file"
        exit 1
    fi
    
    log_info "Extracting: $ipsw_file"
    
    # Create temp directory
    mkdir -p "$temp_dir"
    mkdir -p "$OUTPUT_DIR"
    
    # IPSW is a ZIP file
    log_info "Unzipping IPSW..."
    unzip -o "$ipsw_file" -d "$temp_dir" 2>/dev/null || {
        log_error "Failed to unzip IPSW"
        exit 1
    }
    
    # List contents
    log_info "IPSW contents:"
    ls -la "$temp_dir"
    
    # Find and extract BaseSystem.dmg
    local basesystem=""
    
    # Try to find BaseSystem.dmg directly
    if [ -f "$temp_dir/BaseSystem.dmg" ]; then
        basesystem="$temp_dir/BaseSystem.dmg"
    fi
    
    # Try to find it inside other DMG files
    if [ -z "$basesystem" ]; then
        for dmg in "$temp_dir"/*.dmg; do
            if [ -f "$dmg" ]; then
                log_info "Checking: $dmg"
                # Check if it contains BaseSystem
                if 7z l "$dmg" 2>/dev/null | grep -qi "basesystem"; then
                    log_info "Found BaseSystem in: $dmg"
                fi
            fi
        done
    fi
    
    # Copy BaseSystem.dmg if found
    if [ -n "$basesystem" ] && [ -f "$basesystem" ]; then
        local output_file="${OUTPUT_DIR}/BaseSystem.dmg"
        log_info "Copying BaseSystem.dmg to: $output_file"
        cp "$basesystem" "$output_file"
        log_info "BaseSystem.dmg extracted successfully"
        
        # Convert to raw img format for QEMU
        log_info "Converting to raw format for QEMU..."
        qemu-img convert -f raw -O raw "$output_file" "${OUTPUT_DIR}/BaseSystem.img" 2>/dev/null || {
            # If qemu-img fails, just copy as-is
            log_warn "qemu-img conversion failed, copying as-is"
            cp "$output_file" "${OUTPUT_DIR}/BaseSystem.img"
        }
        log_info "Created: ${OUTPUT_DIR}/BaseSystem.img"
    else
        log_warn "BaseSystem.dmg not found directly."
        log_info "IPSW may require additional extraction steps."
        log_info "Files found in IPSW:"
        find "$temp_dir" -type f -name "*.dmg" -o -name "*.im4p" | head -20
    fi
    
    # Cleanup
    log_info "Cleaning up temporary files..."
    rm -rf "$temp_dir"
    
    log_info "Extraction complete."
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -l, --list        List available IPSW files"
    echo "  -e, --extract FILE  Extract specified IPSW file"
    echo "  -a, --auto        Auto-extract first available IPSW"
    echo ""
    echo "Examples:"
    echo "  $0 -l                    # List IPSW files"
    echo "  $0 -e file.ipsw          # Extract specific IPSW"
    echo "  $0 -a                    # Extract first IPSW found"
}

main() {
    check_dependencies
    
    if [ $# -eq 0 ]; then
        usage
        exit 0
    fi
    
    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -l|--list)
                list_ipsw_files
                exit 0
                ;;
            -e|--extract)
                if [ -n "$2" ]; then
                    extract_ipsw "$2"
                else
                    log_error "No file specified"
                    exit 1
                fi
                shift 2
                ;;
            -a|--auto)
                local first_ipsw
                first_ipsw=$(ls "$IPSW_DIR"/*.ipsw 2>/dev/null | head -1)
                if [ -n "$first_ipsw" ]; then
                    extract_ipsw "$first_ipsw"
                else
                    log_error "No IPSW files found"
                    exit 1
                fi
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

main "$@"
