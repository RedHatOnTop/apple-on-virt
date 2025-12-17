# Device Model Philosophy

This document explains how devices are exposed to macOS in the emulator, emphasizing that device identity matters more than transport mechanism.

## Core Principle: Identity Over Transport

### Device Identity

From macOS's perspective, a device is defined by:

- What it claims to be (identity).
- What interfaces it provides (functionality).
- Where it appears in the system (topology).
- What properties describe it (characteristics).

### Transport Mechanism

The transport mechanism is how the emulator implements device communication:

- Memory-mapped I/O regions.
- Interrupt delivery mechanisms.
- DMA pathways.
- Internal emulation structures.

### The Principle

macOS cares about device identity, not transport mechanism. A storage device must appear as an Apple-compatible storage device, regardless of how the emulator implements it internally.

## Device Abstraction Layers

### Conceptual Architecture

```
+------------------------------------------------------------------+
|                     macOS Kernel View                             |
|                                                                   |
|  +-------------------+  +-------------------+  +----------------+ |
|  | Apple Storage     |  | Apple Timer       |  | Apple Serial   | |
|  | Device            |  | Device            |  | Device         | |
|  +-------------------+  +-------------------+  +----------------+ |
|           |                     |                     |           |
+-----------|---------------------|---------------------|----------+
            |                     |                     |
            | Device Identity     | Device Identity     | Device Identity
            |                     |                     |
+-----------|---------------------|---------------------|----------+
|           v                     v                     v           |
|  +------------------------------------------------------------------+
|  |                    Device Identity Layer                         |
|  |                                                                  |
|  |  - Presents Apple-compatible device nodes in device tree         |
|  |  - Reports Apple-expected device properties                      |
|  |  - Provides Apple-format register interfaces                     |
|  +------------------------------------------------------------------+
|                               |
|                               | Implementation Boundary
|                               |
|  +------------------------------------------------------------------+
|  |                    Transport Layer                               |
|  |                                                                  |
|  |  - Memory-mapped register access                                 |
|  |  - Interrupt assertion and handling                              |
|  |  - DMA buffer management                                         |
|  |  - Internal emulation mechanics                                  |
|  +------------------------------------------------------------------+
|                                                                    |
+------------------------------------------------------------------+
|                      Emulator Core                                |
+------------------------------------------------------------------+
```

### Layer Responsibilities

**Device Identity Layer:**

- Present consistent device identity to macOS.
- Implement Apple-compatible register interfaces.
- Generate appropriate device tree nodes.
- Report device properties macOS expects.

**Transport Layer:**

- Handle memory-mapped I/O operations.
- Route interrupts to appropriate handlers.
- Manage DMA operations if needed.
- Connect to host resources for actual functionality.

## Device Identity Requirements

### What macOS Recognizes

macOS identifies devices through:

**Device Tree Nodes:**

Each device appears as a node in the device tree with:

- Compatible string identifying device type.
- Register addresses for MMIO regions.
- Interrupt assignments.
- Device-specific properties.

**Register Interface:**

Devices provide registers at specific addresses:

- Control registers for device operation.
- Status registers for device state.
- Data registers for information transfer.
- Configuration registers for setup.

**Behavioral Characteristics:**

Devices behave according to documented or observed patterns:

- Specific register sequences for operations.
- Expected response to certain commands.
- Interrupt generation conditions.
- Error reporting mechanisms.

### Apple-Compatible Identity

For macOS to accept a device, it must appear Apple-compatible:

- Device tree compatible string matches Apple drivers.
- Register layout matches driver expectations.
- Interrupt behavior matches driver assumptions.
- Device properties provide required information.

## What Device Identity Is Not

### Not VirtIO

VirtIO is a standardized paravirtualization interface:

- VirtIO devices identify as VirtIO devices.
- macOS has no native VirtIO drivers.
- VirtIO identity is wrong for macOS.

The emulator may use virtio-like mechanisms internally, but devices must not present virtio identity to macOS.

### Not Linux-Style Discovery

Linux uses mechanisms like:

- PCI bus enumeration.
- USB device enumeration.
- Platform device matching.

Apple Silicon macOS uses:

- Device tree as primary hardware description.
- Apple-specific bus topologies.
- Platform-defined device addresses.

Devices must follow Apple's discovery model, not Linux conventions.

### Not Generic ARM Peripherals

Standard ARM platforms use:

- ARM GIC (Generic Interrupt Controller).
- ARM Generic Timer.
- SBSA-defined peripherals.

Apple Silicon uses:

- Apple Interrupt Controller (AIC).
- Apple Timer implementation.
- Apple-specific peripherals.

Devices must present Apple identity, not ARM generic identity.

## Device Categories

### Timer Devices

**Identity Requirements:**

- Device tree node with Apple timer compatible string.
- Registers at Apple-expected addresses.
- Interrupt connected to AIC.
- Timer semantics matching Apple implementation.

**What macOS Expects:**

- Monotonic counter readable from register.
- Compare value for interrupt generation.
- Timer frequency information.
- Per-CPU timer instances if applicable.

**Transport Independence:**

The emulator implements timer counting internally. macOS sees only the Apple-compatible timer interface.

### Interrupt Controller

**Identity Requirements:**

- Device tree node identifying AIC.
- Register interface matching AIC layout.
- Interrupt routing to CPU.
- Priority and masking support.

**What macOS Expects:**

- Interrupt acknowledge and completion registers.
- Per-interrupt enable/disable.
- Priority configuration.
- CPU targeting for multi-core.

**Transport Independence:**

The emulator routes interrupts from emulated devices through AIC interface. macOS sees AIC, not emulator internals.

### Storage Devices

**Identity Requirements:**

- Device tree node with Apple storage compatible.
- Register interface for block device access.
- Interrupt for completion notification.
- Device properties (capacity, block size, etc.).

**What macOS Expects:**

- Command submission interface.
- Completion notification mechanism.
- Data transfer capability.
- Error reporting.

**Transport Independence:**

The emulator may use host file or block device for actual storage. macOS sees Apple-compatible storage interface.

### Serial Console

**Identity Requirements:**

- Device tree node with Apple serial compatible.
- MMIO registers for UART operations.
- Interrupt for receive notification.
- Console configuration properties.

**What macOS Expects:**

- Transmit register for output.
- Receive register for input.
- Status register for device state.
- Baud rate and format configuration.

**Transport Independence:**

The emulator routes serial I/O to host console. macOS sees Apple serial interface.

## Device Tree Representation

### Node Structure

Each device appears in the device tree:

```
device-name@address {
    compatible = "apple,device-type";
    reg = <address size>;
    interrupts = <interrupt-spec>;
    device-specific-property = <value>;
};
```

### Required Properties

**compatible:**

String identifying device type for driver matching:

- Must match what Apple drivers expect.
- May include version or variant information.
- Determines which driver loads for device.

**reg:**

Register addresses and sizes:

- Physical addresses where device registers appear.
- Sizes of each register region.
- Multiple regions if device has several.

**interrupts:**

Interrupt specification:

- Interrupt number(s) for device events.
- Format depends on interrupt controller.
- May specify trigger type and priority.

### Device-Specific Properties

Devices may have additional properties:

- Capability descriptions.
- Configuration parameters.
- Relationship to other devices.
- Version information.

## Implementation Independence

### External View Stability

The device's external view must remain stable:

- Device tree representation is fixed.
- Register interface is fixed.
- Interrupt behavior is predictable.
- Properties are consistent.

### Internal Flexibility

Implementation can vary without affecting identity:

- Optimization techniques can change.
- Host interface can evolve.
- Internal data structures are not exposed.
- Emulation mechanics are hidden.

### Example: Storage Device

**Fixed (Identity):**

- Device tree: apple,storage-controller.
- Registers: at 0x500000000, size 0x10000.
- Interrupt: connected to AIC IRQ 42.
- Capacity: reported as device property.

**Flexible (Implementation):**

- Host backing: file or block device.
- Caching: various strategies.
- Threading: implementation detail.
- Format: internal concern.

## Device Initialization Flow

### Machine Setup Phase

1. Machine model determines device configuration.
2. Device instances created with identity parameters.
3. Devices registered with memory and interrupt systems.
4. Device tree nodes generated for each device.

### Device Tree Placement

1. Root node created with platform properties.
2. Device nodes added as children.
3. Properties set for each device.
4. Tree finalized and placed in memory.

### Runtime Operation

1. macOS parses device tree.
2. Drivers match to devices by compatible string.
3. Drivers access devices through MMIO.
4. Devices respond with Apple-compatible behavior.

## Validation Criteria

### Device Acceptance

A device is accepted by macOS when:

- Driver matches device tree compatible string.
- Driver successfully probes device.
- Device responds correctly to initial operations.
- No device-related panics occur.

### Identity Correctness

Device identity is correct when:

- macOS kernel log shows correct device identification.
- Driver behavior indicates successful communication.
- Device functionality operates as expected.
- No identity-related errors appear.

### Transport Transparency

Transport is transparent when:

- macOS cannot distinguish emulated from real device.
- No transport-layer artifacts visible to macOS.
- Device behaves identically to Apple device.
- Performance characteristics are reasonable.

## Summary

Devices in the emulator are defined by their identity, not their implementation:

- Device identity is what macOS sees: device tree nodes, register interfaces, and behavioral characteristics.
- Transport mechanism is internal: how the emulator implements the device.
- Identity must be Apple-compatible for drivers to function.
- Transport is an implementation detail hidden from macOS.

The emulator presents Apple-compatible device identities. How those devices are implemented is an internal concern that does not affect macOS operation.
