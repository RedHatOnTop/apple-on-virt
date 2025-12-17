# Project Directory Structure

This document defines the complete directory structure for Apple-on-Virt, with clear responsibility assignment for each directory.

## Principle: One Responsibility Per Directory

Each directory has exactly one purpose. No directory serves multiple unrelated functions. No generic "utility" or "common" directories exist. Every file has an obvious location based on its responsibility.

## Root Structure

```
apple-on-virt/
├── config/                 # Runtime configuration (no code)
├── docs/                   # Project documentation
├── emulator/               # Emulator source code
├── local_storage/          # External reference materials
├── output/                 # Build artifacts
├── scripts/                # Build and test automation
├── .git/                   # Git repository metadata
├── .gitignore              # Git ignore patterns
├── CONTRIBUTING.md         # Contribution guidelines
├── LICENSE                 # MIT license
└── README.md               # Project overview
```

## Documentation Structure

```
docs/
├── architecture.md                 # System architecture overview
├── boot-chain.md                   # Boot flow documentation
├── cpu-arm64e.md                   # CPU model specification
├── device-model.md                 # Device philosophy
├── directory-structure.md          # This document
├── failure-modes.md                # Expected failure catalog
├── kernel-policy.md                # Kernel intervention rules
├── platform-boot-layer.md          # Platform Boot Layer spec
├── qemu-decomposition.md           # QEMU subsystem analysis
├── responsibility-matrix.md        # Component responsibilities
├── security-model.md               # Security adaptation
├── terminology.md                  # Canonical terminology
└── versioning.md                   # Version compatibility strategy
```

**Responsibility:** All project documentation, specifications, and design decisions.

**Contains:** Markdown documents only. No code, no binaries, no generated files.

**Organization:** Flat structure with descriptive filenames. No subdirectories for document categories.

## Emulator Source Structure

```
emulator/
├── hw/
│   └── apple/                      # Apple machine model
│       ├── apple_machine.c         # Machine initialization
│       ├── apple_machine.h         # Machine interface
│       ├── platform_boot_layer.c   # Pre-boot synthesis
│       ├── platform_boot_layer.h   # Boot layer interface
│       ├── device_tree.c           # Device tree generation
│       ├── device_tree.h           # Device tree interface
│       ├── memory_map.c            # Memory layout
│       ├── memory_map.h            # Memory interface
│       ├── secure_boot.c           # Secure boot context
│       ├── secure_boot.h           # Secure boot interface
│       └── platform_identity.c/h   # Platform ID management
│
├── target/
│   └── apple-arm64e/               # Apple arm64e CPU
│       ├── cpu.c                   # CPU model
│       ├── cpu.h                   # CPU interface
│       ├── cpu_features.c          # Feature registers
│       ├── cpu_features.h          # Feature interface
│       ├── exception_levels.c      # EL management
│       ├── exception_levels.h      # EL interface
│       ├── pac.c                   # Pointer authentication
│       ├── pac.h                   # PAC interface
│       ├── system_registers.c      # System register access
│       └── system_registers.h      # System register interface
│
├── devices/
│   └── apple/                      # Apple device implementations
│       ├── aic.c                   # Apple Interrupt Controller
│       ├── aic.h                   # AIC interface
│       ├── apple_timer.c           # Apple timer
│       ├── apple_timer.h           # Timer interface
│       ├── apple_uart.c            # Apple serial
│       ├── apple_uart.h            # UART interface
│       └── apple_storage.c/h       # Apple storage device
│
├── include/
│   └── apple/                      # Public Apple headers
│       ├── apple_platform.h        # Platform definitions
│       ├── apple_arm64e.h          # CPU definitions
│       └── apple_devices.h         # Device definitions
│
└── docs/
    └── implementation/             # Implementation notes
        ├── memory_layout.md        # Address space details
        ├── device_tree_format.md   # DT structure details
        └── boot_sequence.md        # Init order details
```

### hw/apple/ - Apple Machine Model

**Responsibility:** Machine model implementation for apple-silicon-bringup.

**Contains:**
- Machine initialization and coordination.
- Platform Boot Layer implementation.
- Device tree generation.
- Memory map definition.
- Secure boot context synthesis.
- Platform identity management.

**Does NOT contain:**
- CPU implementation (that's in target/apple-arm64e/).
- Device implementations (that's in devices/apple/).
- Generic QEMU machine code.

**Key Files:**
- `apple_machine.c`: Machine model entry point and initialization.
- `platform_boot_layer.c`: Pre-boot environment synthesis.
- `device_tree.c`: Apple-format device tree generation.
- `memory_map.c`: Apple Silicon memory layout.
- `secure_boot.c`: Secure boot state synthesis.
- `platform_identity.c`: Platform/board/chip ID management.

### target/apple-arm64e/ - Apple arm64e CPU

**Responsibility:** CPU model implementation for apple-arm64e.

**Contains:**
- arm64e instruction execution.
- Exception level management.
- Pointer authentication semantics.
- System register access.
- CPU feature reporting.

**Does NOT contain:**
- Machine initialization (that's in hw/apple/).
- Device implementations (that's in devices/apple/).
- Generic ARM64 CPU code (only apple-arm64e).

**Key Files:**
- `cpu.c`: CPU model structure and initialization.
- `cpu_features.c`: Feature register implementation.
- `exception_levels.c`: EL transition handling.
- `pac.c`: PAC instruction semantics.
- `system_registers.c`: System register read/write.

### devices/apple/ - Apple Device Implementations

**Responsibility:** Device implementations with Apple-compatible interfaces.

**Contains:**
- Apple Interrupt Controller (AIC).
- Apple timer.
- Apple UART/serial.
- Apple storage device.
- Any other Apple-specific devices.

**Does NOT contain:**
- Generic virtio devices (may use internally but don't expose).
- Standard ARM peripherals (GIC, generic timer, etc.).
- PCI devices.

**Key Files:**
- `aic.c`: Apple Interrupt Controller implementation.
- `apple_timer.c`: Apple-specific timer.
- `apple_uart.c`: Apple serial console.
- `apple_storage.c`: Apple storage interface.

### include/apple/ - Public Apple Headers

**Responsibility:** Public header files for Apple-specific components.

**Contains:**
- Platform definitions shared across components.
- CPU definitions and interfaces.
- Device definitions and interfaces.
- Constants and types.

**Does NOT contain:**
- Implementation code.
- Internal-only definitions.
- Generic QEMU headers.

## Configuration Structure

```
config/
├── apple-silicon.conf              # Machine configuration
├── boot-args.conf                  # Boot argument templates
└── debug.conf                      # Debug configuration
```

**Responsibility:** Runtime configuration files (no code).

**Contains:**
- Machine configuration parameters.
- Boot argument templates.
- Debug options.

**Does NOT contain:**
- Source code.
- Generated files.
- Binary files.

## Script Structure

```
scripts/
├── build/
│   ├── build-emulator.sh           # Build main emulator
│   ├── configure-qemu.sh           # Configure QEMU base
│   └── clean.sh                    # Clean build artifacts
│
├── ipsw/
│   ├── extract-ipsw.sh             # Extract IPSW contents
│   ├── extract-ipsw.py             # Python IPSW extractor
│   └── verify-ipsw.sh              # Verify IPSW integrity
│
├── test/
│   ├── test-boot-chain.sh          # Test boot chain
│   ├── test-cpu-model.sh           # Test CPU model
│   └── test-platform-state.sh      # Test platform synthesis
│
└── launch/
    ├── launch-headless.sh          # Launch headless emulator
    └── launch-with-gdb.sh          # Launch with debugger
```

**Responsibility:** Build, test, and launch automation.

**Contains:**
- Shell scripts for building.
- Python scripts for IPSW extraction.
- Test scripts.
- Launch scripts.

**Organization:**
- `build/`: Build and configuration scripts.
- `ipsw/`: IPSW extraction and verification.
- `test/`: Test automation.
- `launch/`: Emulator launch scripts.

## Local Storage Structure

```
local_storage/
├── ipsw/
│   ├── extracted/                  # Extracted IPSW contents
│   │   ├── iBoot                   # iBoot binary
│   │   ├── bootlogo                # Boot logo
│   │   └── kernelcache             # Kernel cache
│   └── original/                   # Original IPSW files
│
├── m1n1-source/                    # m1n1 reference (read-only)
│   └── [m1n1 source tree]
│
├── xnu-source/                     # XNU reference (read-only)
│   └── [XNU source tree]
│
└── reference/
    ├── device-trees/               # Reference device trees
    ├── memory-dumps/               # Memory dumps for analysis
    └── boot-logs/                  # Boot logs from real hardware
```

**Responsibility:** External reference materials not committed to repository.

**Contains:**
- Extracted IPSW binaries.
- Reference source code (m1n1, XNU).
- Reference data (device trees, logs).

**Does NOT contain:**
- Project source code.
- Documentation (that's in docs/).
- Generated files (that's in output/).

**Note:** This directory is in `.gitignore`. Contents are user-provided.

## Output Structure

```
output/
├── bin/
│   └── apple-silicon-emulator      # Built emulator binary
│
├── device-trees/
│   └── generated.dtb               # Generated device tree blobs
│
├── logs/
│   ├── build.log                   # Build logs
│   ├── boot.log                    # Boot logs
│   └── debug.log                   # Debug output
│
└── test-results/
    └── [test output files]
```

**Responsibility:** Build artifacts and generated files.

**Contains:**
- Compiled binaries.
- Generated device trees.
- Logs.
- Test results.

**Does NOT contain:**
- Source code.
- Reference materials.
- Configuration templates.

**Note:** This directory is in `.gitignore`. Contents are build-generated.

## File Naming Conventions

### Source Files

- `lowercase_with_underscores.c`
- Descriptive names, not abbreviations.
- Match header file names (`foo.c` goes with `foo.h`).

### Header Files

- `lowercase_with_underscores.h`
- Public headers in `include/apple/`.
- Private headers alongside implementation.

### Documentation

- `lowercase-with-hyphens.md`
- Descriptive names indicating content.
- Flat structure in `docs/`.

### Scripts

- `lowercase-with-hyphens.sh` or `.py`
- Action-verb naming (`build-emulator.sh`, not `emulator.sh`).
- Extension indicates interpreter.

## Directory Creation Rules

### When to Create New Directory

Create a new directory when:
1. A distinct architectural component needs implementation.
2. The component has clear, non-overlapping responsibility.
3. Multiple files will belong to this component.
4. The directory name clearly indicates its purpose.

### When NOT to Create New Directory

Do NOT create directory if:
1. It would contain only one file.
2. Its purpose overlaps with existing directory.
3. It's a generic category ("utils", "common", "helpers").
4. The files could logically belong to existing directory.

### Example Decision Process

**Question:** Where does a new "boot argument parser" go?

**Analysis:**
- Is it part of Machine Model? (Machine uses boot args) → Yes
- Is it a separate component? → No, it's a helper for machine init
- Does it need its own directory? → No

**Answer:** `hw/apple/boot_args.c` alongside machine implementation.

## Code Organization Within Directories

### Principle: Related Code Together

Within each directory:
- Group related functionality in same file.
- Keep files focused on single responsibility.
- Limit file size to readable length (~1000 lines maximum).
- Split large components into multiple files by sub-function.

### Example: Platform Boot Layer

```
hw/apple/
├── platform_boot_layer.c       # Coordinator
├── device_tree.c               # DT generation
├── memory_map.c                # Memory layout
├── secure_boot.c               # Security context
└── platform_identity.c         # ID management
```

Each file has clear sub-responsibility within Platform Boot Layer.

## Validation Rules

### Directory Structure Validation

A contributor knows where to add code if:
1. The directory structure is self-explanatory.
2. Each directory has one clear purpose.
3. No directory name is ambiguous.
4. The structure matches documented responsibilities.

### File Placement Validation

A file is in the correct directory if:
1. Its responsibility matches the directory responsibility.
2. No other directory also claims this responsibility.
3. The file doesn't duplicate functionality elsewhere.

### Anti-Patterns to Avoid

**Generic Directories:**
- `common/` - What's common? Code should have specific purpose.
- `utils/` - Utilities for what? Should be with their users.
- `lib/` - Library of what? Should be organized by function.
- `misc/` - Miscellaneous means poorly understood responsibility.

**Overlapping Directories:**
- Both `machine/` and `platform/` exist with unclear distinction.
- Both `devices/` and `hardware/` contain device code.
- Multiple places for "boot code" or "initialization".

**Deep Nesting:**
- `hw/apple/machine/core/init/boot/` - Too deep, purpose unclear.
- Keep structure shallow (2-3 levels maximum).
- Deeper nesting indicates organizational confusion.

## Summary

The directory structure reflects architectural boundaries:
- `hw/apple/` = Machine Model responsibility
- `target/apple-arm64e/` = CPU Model responsibility
- `devices/apple/` = Device Layer responsibility
- `docs/` = Documentation responsibility
- `scripts/` = Automation responsibility

Every file has exactly one obvious location. Every directory has exactly one clear purpose. A contributor should never wonder "Where does this code go?"
