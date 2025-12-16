# Custom Kext Development Roadmap

Last updated: 2025-12-16

## Overview

This document outlines the development roadmap for the 4 custom Kexts required to enable GUI and optimized I/O for ARM64 macOS emulation in QEMU/WSL.

## Deliverable Structure

```
./kexts/
├── ARM64QEMUSupport/            # Custom Kext package
│   ├── Build.sh                 # Build script
│   ├── ARM64QEMUGraphics/
│   │   ├── Info.plist
│   │   ├── MacOS/
│   │   │   └── ARM64QEMUGraphics
│   │   └── Contents/
│   ├── ARM64QEMUTRC/
│   │   ├── Info.plist
│   │   ├── MacOS/
│   │   │   └── ARM64QEMUTRC
│   │   └── Contents/
│   ├── ARM64QEMUStorage/
│   │   ├── Info.plist
│   │   ├── MacOS/
│   │   │   └── ARM64QEMUStorage
│   │   └── Contents/
│   └── ARM64QEMUDeviceStubs/
│       ├── Info.plist
│       ├── MacOS/
│       │   └── ARM64QEMUDeviceStubs
│       └── Contents/
└── [Reference documentation]
```

## Kext Specifications

### 1. ARM64QEMUDeviceStubs.kext (Priority: FIRST)

**Status:** Not Started
**Complexity:** Medium
**Estimated Size:** 5-10 KB binary

**Purpose:** Foundation for device detection and matching

**Key Classes to Implement:**
```
- QEMUPlatformExpert (inherits from IOPlatformExpert)
- QEMUDeviceProvider
- QEMUInterruptController
- QEMUGPIOController
- QEMUThermalSensor
```

**Device Tree Compatibility Strings:**
```
QEMU Generic:
  "qemu,virtual-machine"
  "qemu,arm-virt"
  
Display:
  "qemu,ramfb"
  "qemu,virtio-gpu"
  
Storage:
  "qemu,virtio-blk"
  
Serial:
  "qemu,uart-16550"
  "qemu,samsung-uart"
  
Interrupt:
  "qemu,gic"
  "qemu,aic"
```

**Data Structures:**
```cpp
struct QEMUDeviceInfo {
    const char *compatible;
    const char *service_name;
    const char *provider_class;
    uint32_t irq_count;
    uint64_t base_address;
};

const QEMUDeviceInfo qemu_devices[] = {
    { "qemu,ramfb", "QEMURAMFB", "IOMemoryFamily", 1, 0xc0000000 },
    { "qemu,virtio-blk", "QEMUVirtIOBlk", "IOVirtIOBlockFamily", 1, 0x100000 },
    { "qemu,uart-16550", "QEMUUART", "IOSerialFamily", 1, 0x100000 },
    // ...
};
```

**Build Commands:**
```bash
# Compile
arm64-apple-darwin-cc -arch arm64 -c ARM64QEMUDeviceStubs.c
arm64-apple-darwin-c++ -arch arm64 -c ARM64QEMUDeviceStubs.cpp

# Link
arm64-apple-darwin-ld -arch arm64 -r -o ARM64QEMUDeviceStubs \
    ARM64QEMUDeviceStubs.o \
    -lSystem -lc++ -lstdc++
```

### 2. ARM64QEMUTRC.kext (Priority: SECOND)

**Status:** Not Started
**Complexity:** High
**Estimated Size:** 20-30 KB binary

**Purpose:** SMC emulation for power management and thermal monitoring

**Key Classes to Implement:**
```
- QEMUSMCDevice (inherits from IOService)
- QEMUSMCDriver
- QEMUSensorMonitor
- QEMUThermalController
```

**SMC Protocol Interface:**
```cpp
// SMC Key Codes (common)
#define SMC_KEY_CPU_TEMP    0x54634950  // 'TcIP'
#define SMC_KEY_GPU_TEMP    0x54636750  // 'TgPU'
#define SMC_KEY_FAN_SPEED   0x46486950  // 'FhIP'
#define SMC_KEY_POWER       0x504f5745  // 'POWE'

// SMC Commands
typedef enum {
    SMC_CMD_READ_KEY = 0x10,
    SMC_CMD_WRITE_KEY = 0x11,
    SMC_CMD_GET_KEY_INFO = 0x09,
} SMCCommand;

struct SMCKey {
    uint32_t key;
    uint16_t result;
    uint8_t data[32];
    uint32_t data_size;
};
```

**Stub Responses:**
```
CPU Temperature: 45°C (always)
GPU Temperature: 50°C (always)
Fan Speed: 2000 RPM (always)
Power Budget: 50W (always)
```

### 3. ARM64QEMUGraphics.kext (Priority: THIRD)

**Status:** Not Started
**Complexity:** Very High
**Estimated Size:** 50-100 KB binary

**Purpose:** Framebuffer display support for GUI rendering

**Key Classes to Implement:**
```
- QEMUFramebuffer (inherits from IOFramebuffer)
- QEMUFramebufferDriver
- QEMUDisplay
- QEMURamFBDriver (for ramfb)
- QEMUVirtIOGPUDriver (for virtio-gpu)
```

**Framebuffer Protocol:**
```cpp
// Display Configuration
struct QEMUFramebufferConfig {
    uint32_t width;
    uint32_t height;
    uint32_t bits_per_pixel;
    uint32_t bytes_per_row;
    uint8_t *framebuffer_addr;
    uint32_t framebuffer_size;
};

// Modes
typedef enum {
    QEMU_MODE_800x600_32 = 0,
    QEMU_MODE_1024x768_32 = 1,
    QEMU_MODE_1280x1024_32 = 2,
} QEMUDisplayMode;
```

**IOFramebuffer Methods to Implement:**
```cpp
- IOReturn getPixelInformation(...)  // Report 32-bit ARGB
- IOReturn getTimingInfoForDisplayMode(...)
- IOReturn setDisplayMode(...)
- IOReturn setStartupDisplayMode(...)
- IOReturn setAttribute(IOIndex index, uintptr_t value)
- IOReturn getSync(...)  // Vertical sync detection
```

### 4. ARM64QEMUStorage.kext (Priority: FOURTH)

**Status:** Not Started
**Complexity:** High
**Estimated Size:** 30-50 KB binary

**Purpose:** Optimize storage I/O for QEMU virtio-blk devices

**Key Classes to Implement:**
```
- QEMUStorageOptimizer
- QEMUVirtIOBlockController
- QEMUBlockRequestHandler
```

**Optimizations to Apply:**
```cpp
// 1. Queue Depth Tuning
const uint32_t OPTIMAL_QUEUE_DEPTH = 128;  // For QEMU

// 2. Request Batching
struct BatchedRequest {
    IOMemoryDescriptor *descriptors[16];
    uint32_t descriptor_count;
    uint64_t deadline;
};

// 3. Timeout Adjustment
const uint32_t QEMU_IO_TIMEOUT_MS = 60000;  // Longer for emulation

// 4. Large I/O Support
const uint32_t MAX_IO_SIZE = 1 << 20;  // 1 MB
```

**Patches to Apply:**
```
1. Disable write barriers (safe in QEMU)
2. Increase I/O request timeout
3. Enable command batching
4. Optimize queue management
5. Tune thread pool size
```

## Implementation Strategy

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Get ARM64QEMUDeviceStubs.kext working

1. Set up Xcode project for ARM64 Kext development
2. Create device matching infrastructure
3. Implement platform expert service
4. Test device detection with boot args: `debug=0x14e keepsyms=1`

**Success Criteria:**
- Kext loads without kernel panic
- Device tree nodes are recognized
- IOService hierarchy established

### Phase 2: SMC Support (Weeks 3-4)

**Goal:** Get ARM64QEMUTRC.kext working

1. Implement SMC device driver
2. Create sensor reporting
3. Handle SMC queries
4. Test with `smc-util` tool if available

**Success Criteria:**
- Thermal sensors report reasonable values
- No power management errors
- System doesn't attempt emergency shutdown

### Phase 3: Graphics (Weeks 5-8)

**Goal:** Get ARM64QEMUGraphics.kext working

1. Implement IOFramebuffer protocol
2. Add ramfb device support
3. Create display mode support
4. Test with basic GUI rendering

**Success Criteria:**
- Window Server starts
- Framebuffer is accessible
- Display mode switching works
- GUI elements are visible

### Phase 4: Storage (Weeks 9-10)

**Goal:** Get ARM64QEMUStorage.kext working

1. Analyze virtio-blk performance characteristics
2. Implement optimization patches
3. Tune parameters for QEMU
4. Test with disk benchmarks

**Success Criteria:**
- Disk I/O performance improves
- Timeout errors decrease
- System remains stable under load

## Development Environment Setup

### Required Tools

```bash
# On macOS host (if available)
xcode-select --install
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# macOS SDK headers
xcode-select --install

# On Linux/WSL (for cross-compilation)
# Install arm64-apple-darwin toolchain
```

### Build Configuration

**Makefile template:**
```make
KEXT_NAME = ARM64QEMUDeviceStubs
BUNDLE_NAME = com.apple.driver.qemu.device-stubs
FRAMEWORK_SEARCH_PATHS = -F/System/Library/Frameworks
KERNEL_EXTENSION_HEADER_SEARCH_PATHS = -I/System/Library/Frameworks/Kernel.framework/Headers

all:
	$(CC) -arch arm64 $(FRAMEWORK_SEARCH_PATHS) $(KERNEL_EXTENSION_HEADER_SEARCH_PATHS) \
		-c $(KEXT_NAME).c -o $(KEXT_NAME).o
	$(LD) -arch arm64 -r -o $(BUNDLE_NAME) $(KEXT_NAME).o
```

## Testing Strategy

### Unit Testing

```cpp
// Test device matching
void test_device_matching() {
    IORegistryEntry *device = IORegistryEntryFromPath(kIODeviceTreePlane, 
        "/qemu/ramfb");
    assert(device != NULL);
}

// Test SMC commands
void test_smc_commands() {
    SMCKey key;
    key.key = SMC_KEY_CPU_TEMP;
    IOReturn ret = smc_read_key(&key);
    assert(ret == kIOReturnSuccess);
    assert(key.data[0] > 30 && key.data[0] < 100);  // Temp should be reasonable
}
```

### Integration Testing

```bash
# Boot with verbose logging
qemu-system-aarch64 ... -append "debug=0x14e keepsyms=1 kextlog=0xfff"

# Check kext loading
log show --predicate 'process == "kernel" AND message CONTAINS[c] "ARM64QEMU"' \
    --style syslog
```

### Performance Testing

```bash
# Disk benchmark
iozone -R -l 4 -u 1 -i 0 -i 1 -s 100m

# GUI responsiveness
# Use Quartz Debug to measure frame rate
# Check window server performance with `spindump`
```

## Quality Gate Checklist

### Per Kext

- [ ] Compiles without warnings (ARM64 architecture)
- [ ] Loads without kernel panic
- [ ] Creates expected IOService hierarchy
- [ ] Responds to appropriate device tree nodes
- [ ] Handles edge cases gracefully
- [ ] No memory leaks or use-after-free
- [ ] Proper error handling and logging

### System Level

- [ ] Boot completes successfully
- [ ] All 4 Kexts load in proper order
- [ ] No unresolved kernel extensions
- [ ] System reaches GUI
- [ ] Input/output functioning
- [ ] Stable under load (no panics or hangs)

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Kext incompatibility with future macOS | Use IOKit abstraction layer, version checks |
| Device tree format changes | Create compatibility layer for parsing |
| Performance regressions | Benchmark at each phase, profile hot paths |
| Security/code signing issues | Sign with development key, use boot args to bypass checks |

## Success Criteria

**Primary Goal:** Reach GUI (Finder visible and responsive)

**Metrics:**
- Boot time from QEMU start to GUI visible: < 60 seconds
- Frame rate: > 20 FPS
- System responsiveness: Sub-second latency for user actions
- Stability: 24-hour uptime without crashes

## References

- Apple IOKit Documentation
- macOS Kernel Extension Programming Guide
- QEMU Virtio Specification
- Device Tree Specification
