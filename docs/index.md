# Documentation Directory Structure

This repository's documentation is organized into three distinct categories to ensure clear separation between external sources, collected research, and internal project documentation.

## Categories

### [`external/`](external/)
**Purpose:** Store documents that existed BEFORE this project, authored by third parties.

**Examples:**
- Apple Platform Security documentation
- Asahi Linux documentation  
- ARM Architecture manuals
- OpenCore documentation

**Rules:**
- Content must be preserved verbatim
- No project-specific conclusions here
- Each document must record its origin

### [`collected/`](collected/)
**Purpose:** Store materials WE obtained during this project, raw or lightly processed data.

**Examples:**
- Emulator logs
- GDB dumps
- Notes taken while reading hardware behavior
- Extracted Device Tree blobs
- Boot traces

**Rules:**
- No interpretation required
- Timestamped when possible
- May be incomplete or messy

### [`internal/`](internal/)
**Purpose:** Store documents WE wrote for THIS project, derived from external + collected materials.

**Examples:**
- Boot chain models
- Platform constraints
- Phase scope definitions
- Design rationales
- Architecture notes

**Rules:**
- Must reference source material
- Must reflect current project status
- Allowed to evolve over time

## Document Flow

Documents flow from **external** sources through **collected** research to **internal** project documentation:

```
External Documents → Collected Research → Internal Documentation
     (Third party)     (Our observations)    (Our conclusions)
```

- **External** documents provide the foundation of knowledge about Apple Silicon, ARM architecture, and existing implementations.
- **Collected** materials represent our direct observations, experiments, and extracted information from hardware and software analysis.
- **Internal** documents synthesize this knowledge into project-specific architecture, design decisions, and implementation guidance.

## Quality Criteria

After organization, it must be possible to:

- Delete `docs/internal/` and still retain all raw knowledge
- Audit every internal document back to its sources
- Distinguish clearly between:
  - "What others said" (external)
  - "What we observed" (collected)  
  - "What we concluded" (internal)

## Default Behavior

If you are unsure where a document belongs:
- Place it in `docs/collected/`
- Mark status as draft
- Note uncertainty in metadata

## Priority Principle

Prioritize clarity of separation over convenience. When in doubt, separate.