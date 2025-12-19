# Apple Device Tree (ADT) Binary Structure

**Source**: m1n1 project (proxyclient/m1n1/adt.py, rust/src/adt.rs, src/adt.h)  
**Status**: OBSERVED FACTS ONLY  
**Date**: 2025-12-19

---

## 1. GLOBAL STRUCTURE

### 1.1 Format Overview

```
ADT Binary Layout:
┌─────────────────────────┐
│   Root Node             │  ← Always starts at offset 0
│   (ADTNode structure)   │
└─────────────────────────┘
```

- **NO MAGIC NUMBER**: ADT has no global header or magic bytes
- **NO VERSION FIELD**: No observable version identifier
- **Endianness**: Little-endian (LE) throughout
- **Start**: First node begins at offset 0 in the binary blob

### 1.2 Total Size

- ADT size is NOT stored in the ADT itself
- Size is passed externally (e.g., via `boot_args.devtree_size` in m1n1)
- Parser must receive size from external context

---

## 2. NODE REPRESENTATION

### 2.1 Node Header

```c
struct ADTNode {
    u32 property_count;   // Number of properties in this node
    u32 child_count;      // Number of child nodes
};
```

**Size**: 8 bytes  
**Alignment**: 4-byte aligned  
**Location**: Always at the start of a node's memory region

### 2.2 Node Structure in Memory

```
Node Layout:
┌─────────────────────────┐ ← Node base address (4-byte aligned)
│ property_count (u32)    │
│ child_count (u32)       │
├─────────────────────────┤ ← +8 bytes
│ Property 1              │
│ Property 2              │
│ ...                     │
│ Property N              │
├─────────────────────────┤
│ Child Node 1            │
│ Child Node 2            │
│ ...                     │
│ Child Node M            │
└─────────────────────────┘
```

**Ordering**:
1. Node header (8 bytes)
2. All properties (contiguous, count = property_count)
3. All child nodes (contiguous, count = child_count)

### 2.3 Node Name

- Nodes do NOT have inline names
- Name is stored as a **required property** called `"name"`
- Every valid node MUST have a `"name"` property
- Name property follows standard property encoding

### 2.4 Node Traversal

**First Property**:
```
property_offset = node_offset + 8
```

**First Child**:
```
Walk through all properties (using alignment rules)
child_offset = last_property_end
```

**Next Sibling**:
```
If current node has children:
    Recursively skip all descendants
Next sibling immediately follows last descendant
```

---

## 3. PROPERTY REPRESENTATION

### 3.1 Property Header

```c
struct ADTProperty {
    char name[32];        // Fixed-size name field (NUL-padded)
    u32  size;            // Value size in bytes (see size encoding)
    u8   value[size];     // Raw byte array (variable length)
};
```

**Total Size**: `32 + 4 + value_length`  
**Alignment**: Value is 4-byte aligned (padded)

### 3.2 Property Name Encoding

- **Length**: Exactly 32 bytes
- **Format**: ASCII NUL-terminated string
- **Padding**: Remaining bytes after NUL are zeroed
- **Example**: `"compatible\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"`

### 3.3 Property Size Encoding

**Format**:
```
size field (u32):
  Bits [0:30]  - Actual value size in bytes
  Bit  [31]    - Template flag (0x80000000)
```

**Size Extraction**:
```c
actual_size = size & 0x7FFFFFFF;
is_template = size & 0x80000000;
```

**Template Flag**:
- Observed in m1n1 parser (adt.py line 530)
- When set, property value is interpreted differently
- UNKNOWN: Exact semantics of template properties

### 3.4 Property Value Encoding

- **Format**: Raw untyped byte array
- **Length**: Determined by `size & 0x7FFFFFFF`
- **Alignment**: Value start is NOT necessarily aligned
- **Padding**: Property as a whole is 4-byte aligned

### 3.5 Property Alignment

**Total Property Size**:
```c
property_size = 32 + 4 + value_size;
aligned_size = (property_size + 3) & ~3;  // Round up to 4-byte boundary
padding = aligned_size - property_size;
```

**Next Property Offset**:
```
next_property = current_property + aligned_size
```

---

## 4. BINARY LAYOUT DIAGRAM

### 4.1 Simple Example

```
ADT with one node containing two properties:

Offset  | Content                    | Notes
--------+----------------------------+--------------------------------
0x0000  | 0x02 00 00 00             | property_count = 2
0x0004  | 0x00 00 00 00             | child_count = 0
--------+----------------------------+--------------------------------
0x0008  | "name\0\0\0...\0"         | Property 1 name (32 bytes)
0x0028  | 0x04 00 00 00             | Property 1 size = 4
0x002C  | "root"                    | Property 1 value
--------+----------------------------+--------------------------------
0x0030  | "compatible\0\0...\0"     | Property 2 name (32 bytes)
0x0050  | 0x0E 00 00 00             | Property 2 size = 14
0x0054  | "device-tree\0\0"         | Property 2 value (14 bytes)
0x0062  | 0x00 0x00                 | Padding (2 bytes to align)
--------+----------------------------+--------------------------------
0x0064  | (End of node)             |
```

### 4.2 Nested Node Example

```
Parent node with one property and one child:

Offset  | Content                    | Notes
--------+----------------------------+--------------------------------
0x0000  | 0x01 00 00 00             | property_count = 1
0x0004  | 0x01 00 00 00             | child_count = 1
--------+----------------------------+--------------------------------
0x0008  | "name\0\0\0...\0"         | Property name (32 bytes)
0x0028  | 0x07 00 00 00             | Property size = 7
0x002C  | "parent\0"                | Property value (7 bytes)
0x0033  | 0x00                      | Padding (1 byte)
--------+----------------------------+--------------------------------
0x0034  | 0x01 00 00 00             | Child: property_count = 1
0x0038  | 0x00 00 00 00             | Child: child_count = 0
0x003C  | "name\0\0\0...\0"         | Child property name
0x005C  | 0x06 00 00 00             | Child property size = 6
0x0060  | "child\0"                 | Child property value
0x0066  | 0x00 0x00                 | Padding
--------+----------------------------+--------------------------------
0x0068  | (End of tree)             |
```

---

## 5. TRAVERSAL RULES

### 5.1 Parser Algorithm (Observed)

**From m1n1 adt.rs (lines 366-388)**:

```rust
fn next_node(&self) -> &ADTNode {
    // 1. Get first property
    let mut p = self.first_property();
    
    // 2. Walk through remaining properties
    for _ in 0..(self.property_count - 1) {
        p = p.next_property();
    }
    
    // 3. Calculate aligned end of last property
    let node_addr = p.base + 32 + 4 + aligned(p.size);
    
    // 4. Next byte is start of next node
    return ADTNode::from_ptr(node_addr);
}
```

### 5.2 Sibling Access

**If node has NO children**:
- Next sibling = next_node()

**If node HAS children**:
- Must recursively traverse ALL descendants
- Next sibling follows last descendant

### 5.3 Depth-First Ordering

- Properties are ALWAYS before children
- Children appear in sequential order
- Tree is stored in depth-first pre-order

---

## 6. CONSTRAINTS AND SANITY CHECKS

### 6.1 Observed Limits (from m1n1 adt.rs)

```rust
// Node validation (lines 250-261)
property_count <= 2048
property_count >= 1        // At least "name" property
child_count <= 2048

// Property validation (line 497)
size & 0x7FF00000 == 0     // Size < 1 MB

// Alignment
node_offset % 4 == 0
property_offset % 4 == 0   (after padding)
```

### 6.2 Required Properties

**Every node MUST have**:
- `"name"` property (32-byte field, NUL-terminated value)

**Root node typically has**:
- `"#address-cells"` (u32)
- `"#size-cells"` (u32)
- `"compatible"` (NUL-separated string list)

---

## 7. PROPERTY VALUE TYPES (SEMANTIC ONLY)

**NOTE**: ADT has NO type system. All values are raw bytes.

The following types are **interpretations** applied by parsers:

| Type        | Encoding                          | Example Properties      |
|-------------|-----------------------------------|-------------------------|
| u32         | 4 bytes LE                       | `#address-cells`        |
| u64         | 8 bytes LE                       | `reg` (address)         |
| String      | NUL-terminated ASCII             | `name`, `model`         |
| String List | Multiple NUL-terminated strings  | `compatible`            |
| Byte Array  | Raw bytes                        | Binary blobs            |

---

## 8. UNKNOWNS

### 8.1 Template Properties

- **Observation**: Bit 31 of size field can be set (adt.py line 530)
- **Semantics**: UNKNOWN
- **Usage**: Appears to affect value interpretation
- **Parsing**: Must mask size: `actual_size = size & 0x7FFFFFFF`

### 8.2 Property Ordering

- **Observation**: Properties appear in ADT in some order
- **Requirement**: UNKNOWN if order is significant
- **Safe Assumption**: Treat as unordered dictionary

### 8.3 Empty Values

- **Observation**: Properties can have size = 0
- **Semantics**: UNKNOWN if this differs from absence
- **Parsing**: Return empty byte array

### 8.4 Name Collisions

- **Observation**: No duplicate property names observed in same node
- **Enforcement**: UNKNOWN if duplicates are forbidden
- **Safe Assumption**: Names are unique within a node

---

## 9. PARSING CHECKLIST

To write a complete ADT parser:

**KNOWN**:
- [x] Node header structure (8 bytes)
- [x] Property header structure (36 bytes + value)
- [x] 4-byte alignment rules
- [x] Little-endian encoding
- [x] Depth-first node ordering
- [x] Size field masking (template bit)

**UNKNOWN** (must handle conservatively):
- [ ] Template property semantics
- [ ] Property ordering significance
- [ ] Whether duplicate names are valid
- [ ] Global format version/magic (none observed)
- [ ] Maximum tree depth (8 observed, no formal limit)

---

## 10. IMPLEMENTATION NOTES

### 10.1 Minimum Viable Parser

```c
typedef struct {
    u32 property_count;
    u32 child_count;
} adt_node_t;

typedef struct {
    char name[32];
    u32 size;
    u8 value[];
} adt_property_t;

// Parse property
adt_property_t *get_property(u8 *base) {
    // Property is at base
    u32 size = ((adt_property_t*)base)->size & 0x7FFFFFFF;
    u32 total = 32 + 4 + ((size + 3) & ~3);
    return (adt_property_t*)base;
}

// Get next property
u8 *next_property(u8 *current) {
    adt_property_t *prop = (adt_property_t*)current;
    u32 size = prop->size & 0x7FFFFFFF;
    u32 aligned = (32 + 4 + size + 3) & ~3;
    return current + aligned;
}

// Get first child
u8 *first_child(u8 *node_base) {
    adt_node_t *node = (adt_node_t*)node_base;
    u8 *p = node_base + 8;  // Skip header
    
    for (u32 i = 0; i < node->property_count; i++) {
        p = next_property(p);
    }
    
    return p;  // First child node
}
```

### 10.2 References

**Primary Sources**:
- m1n1/proxyclient/m1n1/adt.py (Python parser)
- m1n1/rust/src/adt.rs (Rust parser)
- m1n1/src/adt.h (C structures)

**Key Functions**:
- `ADTNode.next_node()` (adt.rs:368-388) - Node traversal
- `ADTProperty.next_property()` (adt.rs:540-550) - Property traversal
- `ADTNodeStruct` definition (adt.py:16-21) - Node structure
- `ADTPropertyStruct` definition (adt.py:10-14) - Property structure

---

## END OF DOCUMENT
