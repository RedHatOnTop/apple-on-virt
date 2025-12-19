#!/usr/bin/env python3
"""
Minimal ADT Generator for Phase 4a

Generates a structurally valid, semantically empty Apple Device Tree.

Design constraints:
- Complies with docs/models/adt-structure.md
- Contains ONLY required structural elements
- NO device descriptions
- NO Apple-specific semantics
- NO guessed properties

Success metric: ADT parses without format errors
"""

import struct
import sys
from pathlib import Path

# ADT alignment requirement
ADT_ALIGN = 4

def align(size, alignment=ADT_ALIGN):
    """Round size up to alignment boundary"""
    return (size + alignment - 1) & ~(alignment - 1)

class ADTProperty:
    """
    Property structure per docs/models/adt-structure.md:
    - name: 32 bytes (NUL-terminated, zero-padded)
    - size: u32 LE (bits 0-30: actual size, bit 31: template flag)
    - value: variable length bytes
    """
    def __init__(self, name, value, is_template=False):
        if len(name) > 31:
            raise ValueError(f"Property name too long: {name}")
        
        self.name = name
        # Ensure value is bytes and NUL-terminated for strings
        if isinstance(value, bytes):
            self.value = value
        else:
            # String values need NUL termination
            self.value = value.encode('utf-8') + b'\x00'
        self.is_template = is_template
    
    def encode(self):
        # Name: 32 bytes, NUL-terminated, zero-padded
        name_bytes = self.name.encode('utf-8')
        name_padded = name_bytes + b'\x00' * (32 - len(name_bytes))
        
        # Size: u32 with template flag
        size = len(self.value)
        if self.is_template:
            size |= 0x80000000
        size_bytes = struct.pack('<I', size)
        
        # Value: raw bytes
        value_bytes = self.value
        
        # Calculate total size with alignment
        total = len(name_padded) + len(size_bytes) + len(value_bytes)
        aligned_total = align(total)
        padding = aligned_total - total
        
        return name_padded + size_bytes + value_bytes + (b'\x00' * padding)

class ADTNode:
    """
    Node structure per docs/models/adt-structure.md:
    - property_count: u32 LE
    - child_count: u32 LE
    - properties: array of ADTProperty
    - children: array of ADTNode
    
    Ordering: header, properties, children (depth-first)
    """
    def __init__(self, name):
        self.properties = []
        self.children = []
        
        # Every node MUST have a "name" property
        self.add_property("name", name)
    
    def add_property(self, name, value, is_template=False):
        """Add property to this node"""
        self.properties.append(ADTProperty(name, value, is_template))
    
    def add_child(self, node):
        """Add child node"""
        self.children.append(node)
    
    def encode(self):
        """Encode node to bytes (recursive)"""
        # Header: property_count, child_count
        header = struct.pack('<II', len(self.properties), len(self.children))
        
        # Properties
        properties_bytes = b''.join(prop.encode() for prop in self.properties)
        
        # Children (recursive)
        children_bytes = b''.join(child.encode() for child in self.children)
        
        return header + properties_bytes + children_bytes

def create_minimal_adt():
    """
    Create MINIMAL structurally valid ADT.
    
    Structure:
    - Root node with name "device-tree"
    - Compatible property (empty string to satisfy parsers expecting it)
    - NO other properties
    - NO child nodes
    
    This is the absolute minimum to test ADT parsing.
    """
    root = ADTNode("device-tree")
    
    # Add compatible property (may be expected by boot chain)
    # Use empty string - NO Apple semantics
    root.add_property("compatible", "")
    
    return root

def create_minimal_with_memory_placeholder():
    """
    Create minimal ADT with memory node placeholder.
    
    If boot chain requires /chosen or /memory nodes to exist,
    this variant includes empty placeholders.
    
    Still NO semantic content.
    """
    root = ADTNode("device-tree")
    root.add_property("compatible", "")
    
    # Add empty chosen node (may be required for boot arguments)
    chosen = ADTNode("chosen")
    root.add_child(chosen)
    
    # Add empty memory node (may be required for DRAM detection)
    memory = ADTNode("memory")
    root.add_child(memory)
    
    return root

def write_adt(root, output_path):
    """Write ADT to binary file"""
    data = root.encode()
    
    with open(output_path, 'wb') as f:
        f.write(data)
    
    return len(data)

def main():
    if len(sys.argv) < 2:
        print("Usage: minimal_adt_gen.py <output.bin> [--with-placeholders]")
        sys.exit(1)
    
    output_path = Path(sys.argv[1])
    use_placeholders = "--with-placeholders" in sys.argv
    
    # Create ADT
    if use_placeholders:
        print("Generating minimal ADT with memory/chosen placeholders...")
        root = create_minimal_with_memory_placeholder()
    else:
        print("Generating absolute minimal ADT...")
        root = create_minimal_adt()
    
    # Write to file
    size = write_adt(root, output_path)
    
    print(f"✓ ADT written to: {output_path}")
    print(f"✓ Size: {size} bytes")
    print(f"✓ Root properties: {len(root.properties)}")
    print(f"✓ Root children: {len(root.children)}")
    
    # Validation
    with open(output_path, 'rb') as f:
        data = f.read()
        prop_count, child_count = struct.unpack('<II', data[:8])
        print(f"\nValidation:")
        print(f"  - Property count at offset 0: {prop_count}")
        print(f"  - Child count at offset 4: {child_count}")
        print(f"  - Total size: {len(data)} bytes")

if __name__ == "__main__":
    main()
