# CPU arm64e Model

This document specifies the `apple-arm64e` CPU model implementation requirements for Apple-on-Virt, designed to provide the precise arm64e semantics required by macOS arm64e.

## CPU Model Definition

### Core Identity
- **Name**: `apple-arm64e`
- **Base Class**: Derived from QEMU `ARMCPU`
- **Feature Flag**: Dedicated `ARM_CPU_FEATURE_ARM64E`
- **Exclusivity**: Never shared with generic ARMv8 CPU implementations

### Design Philosophy
The `apple-arm64e` CPU model implements **accuracy over compatibility**, focusing exclusively on the arm64e semantics required by macOS rather than general ARM64 functionality.

## Essential ISA/ABI Requirements

### arm64e Calling Convention
The CPU model must implement Apple's specific arm64e calling convention:
- **Register Usage**: Precise register allocation for function calls
- **Stack Alignment**: Apple-specific stack alignment requirements  
- **Parameter Passing**: Correct handling of complex parameter types
- **Return Value Handling**: Proper return value register usage

### PAC Instruction Decode
Full support for Pointer Authentication Code (PAC) instructions:
- **PACIA/PACIB**: Pointer authentication with address diversity
- **AUTIA/AUTIB**: Pointer verification with address diversity  
- **PACDA/PACDB**: Data pointer authentication
- **AUTDA/AUTDB**: Data pointer verification
- **XPACD/XPACL**: Pointer de-authentication instructions

### Pointer Authentication Semantics
The CPU must provide meaningful PAC semantics that satisfy macOS kernel expectations:
- **Key Management**: Proper PAC key register initialization and management
- **Context Sensitivity**: Authentication behavior varies by execution context
- **Failure Handling**: Appropriate exception generation on authentication failure
- **Performance Characteristics**: Reasonable performance for bring-up purposes

## Essential CPU State Requirements

### PAC Key Registers
Critical registers that must be properly initialized:
- **APIAKeyLo/APIAKeyHi**: Instruction pointer authentication keys
- **APIBKeyLo/APIBKeyHi**: Branch target authentication keys  
- **APDAKeyLo/APDAKeyHi**: Data pointer authentication keys
- **APDBKeyLo/APDBKeyHi**: Generic data pointer authentication keys
- **APGAKeyLo/APGAKeyHi**: Generic authentication keys

### Exception Level Behavior
Precise EL3/EL2/EL1 transition behavior expected by Apple Silicon:
- **EL3 Context**: Secure monitor mode with proper register state
- **EL2 Context**: Hypervisor mode with virtualization extensions
- **EL1 Context**: Kernel mode with appropriate privilege levels
- **Transition Semantics**: Correct behavior during exception level changes

### Exception Vector Layout
Apple-specific exception vector table structure:
- **Vector Base Address**: Proper VBAR_ELx register values
- **Vector Table Layout**: Correct exception handler entry points
- **Interrupt Handling**: Proper IRQ/FIQ exception routing
- **Synchronous Exceptions**: Correct synchronous exception handling

### System Register Values
Critical system registers with Apple-expected values:
- **Memory Management**: TTBR0_EL1, TTBR1_EL1, TCR_EL1
- **Cache Control**: SCTLR_EL1, CLIDR_EL1, CCSIDR_EL1  
- **Debug Registers**: MDSCR_EL1, DBGBCR/DBGWCR registers
- **Performance Monitors**: PMCR_EL0, PMCNTENSET_EL0

## CPU Initialization Flow

### Realization Sequence
```
cpu_realize()
 ├─ init_arm64e_features()      # Enable arm64e-specific CPU features
 ├─ init_pac_keys()             # Initialize all PAC key registers with valid values
 ├─ init_exception_levels()     # Set up EL3/EL2/EL1 contexts with Apple expectations
 ├─ init_system_registers()     # Configure system registers with Apple-expected values
 └─ expose_cpu_to_machine()     # Integrate CPU with apple-silicon-bringup machine
```

### Feature Initialization Details
**init_arm64e_features()**:
- Enable `ARM_CPU_FEATURE_ARM64E` flag
- Configure PAC instruction support
- Set up arm64e-specific memory management features
- Initialize Apple-specific CPU capabilities

**init_pac_keys()**:
- Generate consistent but fake PAC keys
- Initialize all key register pairs (Lo/Hi)
- Ensure keys are valid for semantic PAC implementation
- Maintain key consistency across CPU instances

**init_exception_levels()**:
- Configure EL3 secure monitor context
- Set up EL2 hypervisor environment  
- Initialize EL1 kernel execution context
- Establish proper exception level transitions

**init_system_registers()**:
- Configure memory management registers for Apple layout
- Set cache control registers for optimal performance
- Initialize debug registers for kernel debugging support
- Configure performance monitor registers

## PAC Implementation Strategy

### Semantic PAC Approach
For initial development phases, implement **semantic PAC** rather than full cryptographic PAC:

#### Validity Semantics
- "이 포인터는 유효하다" ("This pointer is valid")
- All authenticated pointers are considered valid during bring-up
- No actual cryptographic verification performed
- Focus on correct instruction decode and register usage

#### Context-Based Passing  
- "이 컨텍스트에서는 항상 통과" ("Always passes in this context")
- Authentication always succeeds in kernel bring-up context
- Gradually introduce failure cases as bring-up stabilizes
- Maintain semantic correctness while simplifying implementation

### Implementation Phases

#### Phase 1: Instruction Decode Only
- Correct PAC instruction decoding
- Proper register usage and side effects
- All authentications succeed (semantic only)
- Focus on kernel bring-up success

#### Phase 2: Basic Context Awareness  
- Different behavior in different execution contexts
- Simple validity tracking for critical pointers
- Introduction of controlled failure scenarios
- Validation against genuine Apple Silicon behavior

#### Phase 3: Full Semantic Implementation
- Complete pointer validity tracking
- Context-sensitive authentication behavior
- Proper exception generation on failures
- Performance optimization for research purposes

## Integration with Machine Model

### CPU-Machine Interface
The `apple-arm64e` CPU integrates tightly with the `apple-silicon-bringup` machine:

- **Memory Map Coordination**: CPU uses machine-provided memory layout
- **Device Tree Integration**: CPU properties exposed in device tree
- **Platform State Sharing**: CPU state synchronized with platform assumptions
- **Boot Context Alignment**: CPU initialization aligned with Platform Boot Layer

### Hardware Identity Exposure
CPU exposes Apple-consistent hardware identity:
- **CPU Topology**: Correct core/thread topology for Apple SoC
- **Feature Flags**: Accurate feature reporting matching Apple Silicon
- **Performance Characteristics**: Reasonable performance modeling
- **Power Management**: Basic power state support

## Validation Criteria

### Functional Validation
- PAC instructions decode and execute correctly
- Exception levels transition properly
- System registers contain expected values
- Memory management functions correctly
- Calling conventions work as expected

### Compatibility Validation  
- macOS kernel recognizes CPU as genuine arm64e
- PAC usage in kernel doesn't cause panics
- Exception handling works correctly
- Device drivers load without CPU-related errors
- Performance is sufficient for bring-up purposes

### Accuracy Validation
- CPU behavior matches Apple Silicon expectations
- Platform assumptions are fulfilled accurately
- Security model integration works correctly
- Boot chain executes without CPU-related failures

## Non-Goals Enforcement

The CPU model explicitly excludes:
- **Generic ARM64 support**: Focus exclusively on arm64e semantics
- **Multi-platform compatibility**: Target only Apple Silicon requirements  
- **Performance optimization priority**: Accuracy over speed during bring-up
- **Full cryptographic PAC**: Semantic PAC sufficient for research purposes
- **Advanced power management**: Basic functionality only for bring-up

## Future Evolution

### Enhanced PAC Implementation
As bring-up stabilizes, gradually enhance PAC implementation:
- Introduce actual cryptographic verification
- Add pointer validity tracking across contexts
- Implement more sophisticated failure scenarios
- Optimize performance for research workloads

### Additional Apple Features
Implement additional Apple-specific CPU features:
- Advanced power management states
- Enhanced security features
- Performance monitoring extensions
- Debug and profiling capabilities

### Independence from QEMU
Ultimate goal is CPU model independence from QEMU:
- Custom CPU implementation with same interface
- Enhanced accuracy for Apple Silicon specifics
- Optimized performance for research purposes
- Direct integration with custom emulator core

## Conclusion

The `apple-arm64e` CPU model represents the foundation of Apple-on-Virt's platform reconstruction approach. By implementing precise arm64e semantics rather than generic ARM64 functionality, the project enables legitimate research into macOS arm64e platform requirements.

> This project does not try to make macOS run anywhere. It tries to make macOS believe it never left home.