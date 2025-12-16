#!/usr/bin/env python3
"""
IPSW Extraction Tool for macOS ARM64
Last updated: 2025-12-16

Extracts BaseSystem.dmg from Apple IPSW files for use with QEMU.
"""

import os
import sys
import zipfile
import shutil
import argparse
from pathlib import Path

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'

def log_info(msg):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")

def log_warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")

def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")

def get_project_root():
    """Get project root directory."""
    script_dir = Path(__file__).resolve().parent
    return script_dir.parent

def list_ipsw_files(ipsw_dir):
    """List available IPSW files."""
    log_info("Available IPSW files:")
    ipsw_path = Path(ipsw_dir)
    
    if not ipsw_path.exists():
        log_error(f"IPSW directory not found: {ipsw_dir}")
        return []
    
    ipsw_files = list(ipsw_path.glob("*.ipsw"))
    
    if not ipsw_files:
        log_warn(f"No IPSW files found in {ipsw_dir}")
        return []
    
    for f in ipsw_files:
        size_mb = f.stat().st_size / (1024 * 1024)
        print(f"  {f.name} ({size_mb:.1f} MB)")
    
    return ipsw_files

def extract_ipsw(ipsw_file, output_dir):
    """Extract BaseSystem.dmg from IPSW file."""
    ipsw_path = Path(ipsw_file)
    output_path = Path(output_dir)
    
    if not ipsw_path.exists():
        log_error(f"IPSW file not found: {ipsw_file}")
        return False
    
    log_info(f"Extracting: {ipsw_path.name}")
    
    # Create output directory
    output_path.mkdir(parents=True, exist_ok=True)
    temp_dir = output_path / "ipsw_temp"
    temp_dir.mkdir(exist_ok=True)
    
    try:
        # IPSW is a ZIP file
        log_info("Opening IPSW archive...")
        with zipfile.ZipFile(ipsw_path, 'r') as zf:
            # List contents
            log_info("IPSW contents:")
            dmg_files = []
            for name in zf.namelist():
                if name.endswith('.dmg'):
                    dmg_files.append(name)
                    print(f"  [DMG] {name}")
                elif name.endswith('.im4p'):
                    print(f"  [IM4P] {name}")
            
            # Look for BaseSystem.dmg
            basesystem = None
            for name in zf.namelist():
                lower_name = name.lower()
                if 'basesystem.dmg' in lower_name:
                    basesystem = name
                    break
            
            if basesystem:
                log_info(f"Found BaseSystem: {basesystem}")
                log_info("Extracting BaseSystem.dmg...")
                
                # Extract the file
                zf.extract(basesystem, temp_dir)
                extracted_path = temp_dir / basesystem
                
                # Copy to output
                output_dmg = output_path / "BaseSystem.dmg"
                output_img = output_path / "BaseSystem.img"
                
                shutil.copy2(extracted_path, output_dmg)
                log_info(f"Created: {output_dmg}")
                
                # Also copy as .img for QEMU
                shutil.copy2(extracted_path, output_img)
                log_info(f"Created: {output_img}")
                
                return True
            else:
                log_warn("BaseSystem.dmg not found directly in IPSW.")
                log_info("DMG files found:")
                for dmg in dmg_files:
                    print(f"  {dmg}")
                log_info("")
                log_info("The IPSW may require additional extraction steps.")
                log_info("For Universal Mac IPSWs, BaseSystem is typically in")
                log_info("SharedSupport.dmg or similar container.")
                return False
                
    except zipfile.BadZipFile:
        log_error("Failed to open IPSW - not a valid ZIP file")
        return False
    except Exception as e:
        log_error(f"Extraction failed: {e}")
        return False
    finally:
        # Cleanup
        if temp_dir.exists():
            shutil.rmtree(temp_dir, ignore_errors=True)

def main():
    parser = argparse.ArgumentParser(
        description="Extract BaseSystem.dmg from Apple IPSW files"
    )
    parser.add_argument(
        "-l", "--list",
        action="store_true",
        help="List available IPSW files"
    )
    parser.add_argument(
        "-e", "--extract",
        metavar="FILE",
        help="Extract specified IPSW file"
    )
    parser.add_argument(
        "-a", "--auto",
        action="store_true",
        help="Auto-extract first available IPSW"
    )
    parser.add_argument(
        "-o", "--output",
        metavar="DIR",
        help="Output directory (default: output/)"
    )
    
    args = parser.parse_args()
    
    project_root = get_project_root()
    ipsw_dir = project_root / "local_storage" / "ipsw"
    output_dir = Path(args.output) if args.output else project_root / "output"
    
    if args.list:
        list_ipsw_files(ipsw_dir)
        return 0
    
    if args.extract:
        ipsw_file = Path(args.extract)
        if not ipsw_file.is_absolute():
            # Check if it's in the ipsw directory
            if (ipsw_dir / ipsw_file).exists():
                ipsw_file = ipsw_dir / ipsw_file
        
        success = extract_ipsw(ipsw_file, output_dir)
        return 0 if success else 1
    
    if args.auto:
        ipsw_files = list(ipsw_dir.glob("*.ipsw"))
        if not ipsw_files:
            log_error("No IPSW files found")
            return 1
        
        # Prefer Monterey (12.x) over Big Sur (11.x)
        ipsw_files.sort(key=lambda x: x.name, reverse=True)
        success = extract_ipsw(ipsw_files[0], output_dir)
        return 0 if success else 1
    
    parser.print_help()
    return 0

if __name__ == "__main__":
    sys.exit(main())
