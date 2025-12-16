#!/usr/bin/env python3
"""
Kext Analysis Tool for macOS ARM64 Kernelcache
Last updated: 2025-12-16

This script analyzes boot logs and kernelcache files to extract
information about loaded Kexts for macOS ARM64 emulation.
"""

import re
import sys
import argparse
from pathlib import Path
from collections import defaultdict

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

def log_info(msg):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")

def log_warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")

def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")

def analyze_boot_log(log_file):
    """Analyze macOS boot log for Kext loading information."""
    
    if not Path(log_file).exists():
        log_error(f"Log file not found: {log_file}")
        return None
    
    log_info(f"Analyzing boot log: {log_file}")
    
    kexts = defaultdict(dict)
    load_order = []
    
    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            # Match Kext loading
            match = re.search(r'Loading kext ([^\s.]+(?:\.[^\s.]+)*)', line)
            if match:
                bundle_id = match.group(1)
                if bundle_id not in kexts:
                    kexts[bundle_id]['load_order'] = len(load_order)
                    load_order.append(bundle_id)
            
            # Match Kext executable loaded with address
            match = re.search(r'Kext ([^\s]+) executable loaded; (\d+) pages at (0x[0-9a-f]+)', line)
            if match:
                bundle_id = match.group(1)
                pages = int(match.group(2))
                address = match.group(3)
                kexts[bundle_id]['pages'] = pages
                kexts[bundle_id]['address'] = address
                kexts[bundle_id]['loaded'] = True
            
            # Match registered class
            match = re.search(r'Kext ([^\s]+) registered class ([^\s.]+)', line)
            if match:
                bundle_id = match.group(1)
                class_name = match.group(2)
                if 'classes' not in kexts[bundle_id]:
                    kexts[bundle_id]['classes'] = []
                kexts[bundle_id]['classes'].append(class_name)
    
    return kexts, load_order

def categorize_kexts(kexts):
    """Categorize Kexts by their function."""
    
    categories = {
        'KPI': [],
        'Platform': [],
        'Security': [],
        'Storage': [],
        'USB': [],
        'Network': [],
        'Graphics': [],
        'Audio': [],
        'Other': []
    }
    
    for bundle_id in kexts:
        if bundle_id.startswith('com.apple.kpi.'):
            categories['KPI'].append(bundle_id)
        elif 'ARM' in bundle_id or 'Platform' in bundle_id or bundle_id.endswith('T8027'):
            categories['Platform'].append(bundle_id)
        elif 'Security' in bundle_id or 'Integrity' in bundle_id or 'CoreTrust' in bundle_id or 'Image4' in bundle_id:
            categories['Security'].append(bundle_id)
        elif 'Storage' in bundle_id or 'filesystem' in bundle_id or 'DiskImage' in bundle_id:
            categories['Storage'].append(bundle_id)
        elif 'USB' in bundle_id or 'usb' in bundle_id:
            categories['USB'].append(bundle_id)
        elif 'Network' in bundle_id or 'net' in bundle_id.lower() or 'Skywalk' in bundle_id:
            categories['Network'].append(bundle_id)
        elif 'Graphics' in bundle_id or 'Surface' in bundle_id or 'Scaler' in bundle_id:
            categories['Graphics'].append(bundle_id)
        elif 'Audio' in bundle_id or 'Sound' in bundle_id:
            categories['Audio'].append(bundle_id)
        else:
            categories['Other'].append(bundle_id)
    
    return categories

def print_kext_summary(kexts, load_order, categories):
    """Print a summary of loaded Kexts."""
    
    print("\n" + "=" * 60)
    print("KEXT ANALYSIS SUMMARY")
    print("=" * 60)
    
    print(f"\nTotal Kexts found: {len(kexts)}")
    print(f"Kexts with executable loaded: {sum(1 for k in kexts.values() if k.get('loaded'))}")
    
    print("\n--- Kexts by Category ---")
    for category, bundle_ids in categories.items():
        if bundle_ids:
            print(f"\n{Colors.BLUE}{category}{Colors.NC} ({len(bundle_ids)} kexts):")
            for bid in sorted(bundle_ids)[:10]:  # Show first 10
                info = kexts.get(bid, {})
                pages = info.get('pages', '?')
                print(f"  - {bid} ({pages} pages)")
            if len(bundle_ids) > 10:
                print(f"  ... and {len(bundle_ids) - 10} more")
    
    print("\n--- First 20 Kexts in Load Order ---")
    for i, bundle_id in enumerate(load_order[:20]):
        info = kexts[bundle_id]
        pages = info.get('pages', 'N/A')
        print(f"  {i+1:2}. {bundle_id} ({pages} pages)")

def export_kext_list(kexts, output_file):
    """Export Kext list to a file."""
    
    with open(output_file, 'w') as f:
        f.write("# Kext List from macOS ARM64 Boot Log\n")
        f.write("# Generated by analyze-kexts.py\n\n")
        
        f.write("| Bundle ID | Pages | Address | Classes |\n")
        f.write("|-----------|-------|---------|--------|\n")
        
        for bundle_id in sorted(kexts.keys()):
            info = kexts[bundle_id]
            pages = info.get('pages', 'N/A')
            address = info.get('address', 'N/A')
            classes = len(info.get('classes', []))
            f.write(f"| {bundle_id} | {pages} | {address} | {classes} |\n")
    
    log_info(f"Exported Kext list to: {output_file}")

def main():
    parser = argparse.ArgumentParser(
        description="Analyze macOS ARM64 boot logs for Kext information"
    )
    parser.add_argument(
        '-l', '--log',
        help='Path to boot log file',
        default='local_storage/macos-arm64-emulation-main/macos-qemu.log'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output file for Kext list (markdown format)',
        default=None
    )
    parser.add_argument(
        '-q', '--quiet',
        action='store_true',
        help='Quiet mode - only output essential information'
    )
    
    args = parser.parse_args()
    
    # Find project root
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    
    # Resolve log file path
    log_file = Path(args.log)
    if not log_file.is_absolute():
        log_file = project_root / log_file
    
    # Analyze boot log
    result = analyze_boot_log(log_file)
    if result is None:
        return 1
    
    kexts, load_order = result
    categories = categorize_kexts(kexts)
    
    if not args.quiet:
        print_kext_summary(kexts, load_order, categories)
    
    # Export if requested
    if args.output:
        output_file = Path(args.output)
        if not output_file.is_absolute():
            output_file = project_root / output_file
        export_kext_list(kexts, output_file)
    
    print(f"\n{Colors.GREEN}Analysis complete.{Colors.NC}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
