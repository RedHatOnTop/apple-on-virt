#!/usr/bin/env python3
"""
ADT Verification Script

Verifies that generated ADT is structurally valid by:
1. Parsing with m1n1's ADT parser
2. Checking structural constraints
3. Reporting any format errors

This does NOT verify semantic correctness.
"""

import sys
import os
from pathlib import Path as PathLib

# Add m1n1 to path
script_dir = PathLib(__file__).parent
sys.path.insert(0, str(script_dir.parent.parent / "local_storage" / "m1n1" / "proxyclient"))

from construct import *
from m1n1.adt import ADTNodeStruct, load_adt

def verify_adt(adt_path):
    """Verify ADT structural validity"""
    print(f"Verifying ADT: {adt_path}")
    print("=" * 60)
    
    # Read binary
    with open(adt_path, 'rb') as f:
        data = f.read()
    
    print(f"✓ File size: {len(data)} bytes")
    
    # Attempt to parse
    try:
        adt = load_adt(data)
        print("✓ ADT parsed successfully")
    except Exception as e:
        print(f"✗ Parse failed: {e}")
        return False
    
    # Verify structure
    try:
        print(f"✓ Root node name: {adt.name}")
        print(f"✓ Root properties: {len(adt._properties)}")
        print(f"✓ Root children: {len(adt._children)}")
        
        # List properties
        print("\nRoot properties:")
        for key, value in adt._properties.items():
            if isinstance(value, bytes):
                if len(value) == 0:
                    print(f"  - {key}: (empty)")
                else:
                    print(f"  - {key}: {value[:50]}...")
            else:
                print(f"  - {key}: {value}")
        
        # List children
        if adt._children:
            print("\nChild nodes:")
            for child in adt._children:
                print(f"  - {child.name}")
        
        print("\n✓ ADT structure is valid")
        return True
        
    except Exception as e:
        print(f"✗ Structure validation failed: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: verify_adt.py <adt.bin>")
        sys.exit(1)
    
    adt_path = sys.argv[1]
    if not PathLib(adt_path).exists():
        print(f"Error: File not found: {adt_path}")
        sys.exit(1)
    
    success = verify_adt(adt_path)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
