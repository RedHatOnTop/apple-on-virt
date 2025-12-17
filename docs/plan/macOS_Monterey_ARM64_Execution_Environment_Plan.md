# Apple Silicon–like Platform Emulation Project Plan

Last updated: 2025-12-17

This project plan outlines the strategic roadmap for **Apple-on-Virt**, a research initiative focused on emulating an Apple Silicon–like platform for macOS arm64e execution. The plan reflects our core philosophy: **reconstructing enough of the Apple Silicon platform for macOS arm64e to believe it is home**.

## Strategic Vision

### Core Identity Shift

**From**: Generic ARM64 macOS emulator using QEMU/UEFI  
**To**: Apple Silicon–like platform emulation with arm64e Secure Boot–aware execution environment

### Key Principles

1. **Platform Assumption Fulfillment**: Rather than patching, we recreate the conditions macOS expects
2. **Security Model Preservation**: Security mechanisms are adapted, not disabled
3. **Minimal Intervention**: Kernel modifications restricted to early bring-up phase only
4. **Authentic Device Presentation**: Hardware appears as Apple devices, not generic virtio

## Development Phases

### Phase 0: Apple Silicon Platform Assumptions Research

**Objective**: Comprehensive understanding of Apple Silicon platform requirements

**Key Activities**:
- Analyze Apple Silicon boot process and secure boot chain
- Document platform assumptions made by macOS arm64e kernel
- Identify critical security model components (AMFI, SSV, SEP dependencies)
- Map device tree requirements for proper hardware recognition
- Research arm64e semantics vs. generic ARMv8-A differences

**Success Criteria**:
- Complete documentation of Apple Silicon platform assumptions
- Clear understanding of secure boot context requirements
- Identification of minimal intervention points for emulation

**Timeline**: Foundation phase - ongoing throughout project

### Phase 1: Headless Kernel Bring-up

**Objective**: Achieve unaltered kernel execution without GUI

**Key Activities**:
- Implement Platform Boot Layer replacing UEFI/BIOS concepts
- Recreate fake Apple SoC state and device tree
- Establish secure boot context for iBoot validation
- Develop minimal kext bridges for essential devices
- Validate kernel entry and early initialization

**Technical Requirements**:
- Platform Boot Layer providing Apple-compatible boot environment
- Fake Apple SoC identification and topology
- Secure boot certificate chain recreation
- Basic device tree with essential hardware entries
- Minimal kext framework for platform bridging

**Success Criteria**:
- Unaltered kernel successfully loads and executes
- Kernel logs "Starting kernel" message without panics
- Basic system services initialize properly
- No kernel patches required beyond early bring-up phase

**Dependencies**: Completion of Phase 0 research

### Phase 2: Minimal Userspace Viability

**Objective**: Enable basic system functionality with stable userspace

**Key Activities**:
- Expand device model exposure to include storage and network
- Implement proper Apple device presentation (not virtio exposure)
- Validate security model adaptation effectiveness
- Ensure AMFI and SSV function in emulation context
- Test basic system daemons and services

**Technical Requirements**:
- Storage presented as Apple NVMe controller
- Network exposed as Apple network interface
- Proper device enumeration and driver loading
- Security model adaptation for userspace execution
- Stable system service startup and operation

**Success Criteria**:
- Basic system services start without kernel panics
- Storage and network devices function properly
- Userspace applications execute without modification
- Security mechanisms operate as expected in emulation

**Dependencies**: Successful completion of Phase 1

### Phase 3: Display + I/O Stabilization

**Objective**: Full GUI support and stable device interaction

**Key Activities**:
- Implement platform-provided display device presentation
- Develop graphics driver compatibility layer
- Stabilize input device handling (keyboard, mouse, trackpad)
- Optimize performance and eliminate stability issues
- Validate complete user experience

**Technical Requirements**:
- Graphics hardware presented as Apple display device
- Proper GPU driver loading and initialization
- Input devices exposed as Apple HID controllers
- Stable GUI desktop environment operation
- Performance optimization for practical usability

**Success Criteria**:
- GUI desktop environment displays normally
- Graphics acceleration functions appropriately
- Input devices respond correctly to user interaction
- System remains stable during extended operation
- Standard applications execute without issues

**Dependencies**: Successful completion of Phase 2

### Phase 4: Optional OpenCore-like Abstractions

**Objective**: Enhanced user experience and advanced features

**Key Activities**:
- Develop higher-level convenience layers if needed
- Implement advanced device support (audio, specialized peripherals)
- Create user-friendly configuration and management tools
- Achieve production-ready stability improvements
- Document best practices and usage guidelines

**Technical Requirements**:
- Optional abstraction layers for ease of use
- Extended device support beyond basic requirements
- Robust configuration management system
- Comprehensive documentation and examples
- Production-quality stability and reliability

**Success Criteria**:
- Enhanced user experience with simplified setup
- Extended device support for comprehensive functionality
- Production-ready stability for research purposes
- Complete documentation enabling community adoption

**Dependencies**: Successful completion of Phase 3

## Non-Goals and Boundaries

This project explicitly **does not aim** to provide:

- **Production macOS VM**: Not intended for daily use or commercial deployment
- **Hackintosh Replacement**: Fundamentally different approach from x86 Hackintosh projects
- **App Store/DRM Support**: Not designed for executing DRM-protected content
- **Generic ARM64 Emulation**: Specifically targets Apple Silicon arm64e semantics only
- **Performance Optimization Focus**: Research integrity prioritized over raw performance

## Technical Constraints

### Hardware Support Matrix

| Platform | Support Level | Notes |
|----------|---------------|-------|
| Apple Silicon (M1/M2/M3) | Primary Target | Native virtualization (HVF) for optimal performance |
| Linux ARM64 | Secondary Target | KVM support required for reasonable performance |
| Windows WSL2 | Experimental | TCG emulation only - very slow, research purposes only |
| x86 Hosts | Unsupported | Technically infeasible due to arm64e semantics requirements |

### Software Dependencies

**Current Dependencies** (temporary):
- QEMU 7.0+ with aarch64 support
- Python 3.8+ for development scripts
- Custom Platform Boot Layer implementation

**Future Goal**:
- Eliminate QEMU dependency entirely
- Self-contained custom hypervisor implementation

## Risk Management

### Technical Risks

1. **Secure Boot Complexity**: Recreating secure boot context may prove more complex than anticipated
   - **Mitigation**: Start with minimal secure boot requirements, expand gradually

2. **arm64e Semantics Gap**: Behavioral differences between emulated and real arm64e may cause issues
   - **Mitigation**: Focus on Apple Silicon-specific behaviors, not generic ARM64

3. **Device Driver Compatibility**: Apple drivers may have undocumented hardware dependencies
   - **Mitigation**: Comprehensive device tree recreation and hardware state simulation

### Timeline Risks

- **Phase 1 complexity**: May require more time than initially estimated
- **Security model adaptation**: Could reveal unexpected constraints
- **Hardware availability**: Limited access to Apple Silicon for testing

## Success Metrics

### Phase Completion Metrics

- **Phase 1**: Kernel boots to command line without patches
- **Phase 2**: Basic system services operate stably  
- **Phase 3**: GUI desktop environment functions normally
- **Phase 4**: Enhanced features work reliably for research purposes

### Quality Metrics

- **Security Integrity**: No security mechanisms disabled, only adapted
- **Kernel Purity**: Minimal intervention limited to early bring-up
- **Device Authenticity**: Hardware appears as genuine Apple devices
- **Documentation Quality**: Clear, comprehensive technical documentation

## Resource Requirements

### Development Resources

- **Primary Development**: Apple Silicon Mac for native testing
- **Secondary Testing**: Linux ARM64 systems for cross-platform validation
- **Documentation**: Comprehensive technical specifications and user guides
- **Community Engagement**: Clear communication of project goals and boundaries

### Timeline Estimates

- **Phase 0**: Ongoing (foundation for all phases)
- **Phase 1**: 3-6 months (depending on complexity discovered)
- **Phase 2**: 2-4 months (after Phase 1 completion)
- **Phase 3**: 3-6 months (after Phase 2 completion)  
- **Phase 4**: 2-4 months (after Phase 3 completion)

## Conclusion

This project plan establishes a realistic, principled approach to Apple Silicon platform emulation. By focusing on **platform assumption fulfillment** rather than **workaround implementation**, we create a sustainable foundation for legitimate macOS arm64e research. The phased approach ensures steady progress while maintaining our core principles of security model preservation and minimal intervention.

> This project is not about booting macOS on ARM hardware, but about reconstructing enough of the Apple Silicon platform for macOS arm64e to believe it is home.