#!/usr/bin/env python3
"""
Simple IMG4 payload extractor.

IMG4 format is ASN.1 DER encoded:
SEQUENCE {
    IM4P (tag)
    type (4 chars)
    description (string)
    data (OCTET STRING) <- this is what we want
    ...
}
"""

import sys
import struct

def parse_der_length(data, offset):
    """Parse DER length field."""
    length_byte = data[offset]
    
    if length_byte & 0x80 == 0:
        # Short form: length is in the byte itself
        return length_byte, offset + 1
    else:
        # Long form: length_byte & 0x7F gives number of length bytes
        num_length_bytes = length_byte & 0x7F
        length = 0
        for i in range(num_length_bytes):
            length = (length << 8) | data[offset + 1 + i]
        return length, offset + 1 + num_length_bytes

def find_octet_string(data):
    """Find the largest OCTET STRING in the data (likely the payload)."""
    i = 0
    candidates = []
    
    while i < len(data) - 2:
        if data[i] == 0x04:  # OCTET STRING tag
            length, next_offset = parse_der_length(data, i + 1)
            if next_offset + length <= len(data):
                candidates.append((next_offset, length))
                print(f"Found OCTET STRING at offset {i}: length={length} bytes", file=sys.stderr)
                i = next_offset + length
            else:
                i += 1
        else:
            i += 1
    
    if not candidates:
        return None, None
    
    # Return the largest one
    candidates.sort(key=lambda x: x[1], reverse=True)
    return candidates[0]

def main():
    if len(sys.argv) != 3:
        print("Usage: python extract_im4p.py input.im4p output.bin", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # Read input
    with open(input_file, 'rb') as f:
        data = f.read()
    
    print(f"Input file size: {len(data)} bytes", file=sys.stderr)
    
    # Check for IM4P magic
    if b'IM4P' not in data[:20]:
        print("Warning: IM4P magic not found in expected location", file=sys.stderr)
    
    # Find and extract largest OCTET STRING (payload)
    offset, length = find_octet_string(data)
    
    if offset is None:
        print("Error: No OCTET STRING found", file=sys.stderr)
        sys.exit(1)
    
    payload = data[offset:offset+length]
    
    # Check if payload looks like Mach-O
    if len(payload) >= 4:
        magic = struct.unpack('<I', payload[:4])[0]
        if magic == 0xFEEDFACF:
            print("Payload appears to be Mach-O 64-bit", file=sys.stderr)
        elif magic == 0xFEEDFACE:
            print("Payload appears to be Mach-O 32-bit", file=sys.stderr)
        else:
            print(f"Payload magic: 0x{magic:08X}", file=sys.stderr)
            print("Warning: Payload may be compressed or encrypted", file=sys.stderr)
    
    # Write output
    with open(output_file, 'wb') as f:
        f.write(payload)
    
    print(f"Extracted {len(payload)} bytes to {output_file}", file=sys.stderr)

if __name__ == '__main__':
    main()
