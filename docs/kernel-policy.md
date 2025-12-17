# Kernel Strategy and Policy

This document defines the strict kernel interaction policy for Apple-on-Virt, ensuring minimal intervention while enabling macOS arm64e execution.

## Basic Principles

### Unaltered Boot Chain Requirement
- **iBoot**: Absolutely no patches or modifications allowed
- **boot.efi**: Absolutely no patches or modifications allowed
- **kernelcache**: No binary patches permitted

### Minimal Intervention Policy
Kernel intervention is restricted to the absolute minimum required for bring-up success:
- **Timing**: Only immediately after kernel entry
- **Scope**: Only at documented bring-up failure points  
- **Duration**: Only during early initialization phase
- **Purpose**: Only to fulfill unmet platform assumptions

## Intervention Boundaries

### Allowed Interventions

#### Early Entry Point Modifications
- Platform assumption fulfillment immediately post-entry
- Hardware state correction for critical registers
- Memory layout adjustments for Apple expectations
- Device tree validation and correction

#### Bring-up Failure Point Handling
- Specific panic point interception and resolution
- Critical hardware capability reporting fixes
- Security context initialization assistance
- Essential driver loading support

### Prohibited Actions

#### Security Disabling
- ❌ Complete security mechanism disable
- ❌ SIP (System Integrity Protection) bypass
- ❌ AMFI (Apple Mobile File Integrity) disable  
- ❌ SSV (System Software Verification) bypass
- ❌ Secure boot chain modification

#### Userspace Modifications
- ❌ Any userspace binary patching
- ❌ Application-level modifications
- ❌ System service alterations
- ❌ User environment changes

#### ABI Alterations
- ❌ Calling convention modifications
- ❌ Register usage changes
- ❌ Memory layout alterations beyond bring-up
- ❌ System call interface modifications

#### Persistent Modifications
- ❌ Runtime kernel patching beyond bring-up
- ❌ Dynamic binary modification
- ❌ Persistent memory alterations
- ❌ Long-term kernel state changes

## Kernel Bring-up Phases

### Phase 1: Entry and Early Initialization
**Intervention Window**: First few milliseconds of kernel execution
- Platform assumption validation
- Critical register state correction  
- Memory management setup assistance
- Early hardware detection support

### Phase 2: Platform Assumptions Resolution
**Intervention Window**: During platform-specific initialization
- Apple Silicon hardware identity confirmation
- Device tree parsing assistance
- Security context establishment support
- Essential driver loading facilitation

### Phase 3: Device Model Exposure
**Intervention Window**: During hardware enumeration
- Emulated device presentation as Apple hardware
- Driver compatibility assurance
- Hardware capability reporting accuracy
- Device tree node validation

### Phase 4: System Stabilization
**Intervention Window**: Final bring-up completion
- Basic system service initialization support
- Essential I/O subsystem activation
- Memory management finalization
- Security model integration completion

## Validation Criteria

### Success Metrics
- Kernel executes "Starting kernel" message without panics
- Early initialization completes successfully
- Essential drivers load without modification
- Basic system services start correctly
- Security mechanisms remain intact

### Failure Indicators
- Kernel panics during early bring-up
- Security validation failures
- Device driver loading errors
- Platform assumption violations
- Userspace execution failures

## Implementation Guidelines

### Code Injection Strategy
Any necessary code injection must follow strict guidelines:
- **Location**: Only in designated bring-up failure points
- **Size**: Minimal code footprint (bytes, not kilobytes)
- **Persistence**: Temporary during bring-up only
- **Reversibility**: Clean removal after bring-up completion

### Platform Assumption Fulfillment
Focus on fulfilling platform assumptions rather than bypassing them:
- Recreate missing hardware state
- Provide expected device tree entries  
- Initialize required system registers
- Establish proper security context

### Hardware Abstraction
Present emulated hardware as genuine Apple devices:
- Use Apple-compatible device identifiers
- Maintain consistent hardware topology
- Provide accurate capability reporting
- Ensure proper driver compatibility

## Research Methodology

### Failure Point Analysis
Systematic identification of kernel bring-up failure points:
- Analyze kernel panic messages and stack traces
- Document specific platform assumptions violated
- Map failure points to required interventions
- Validate interventions against genuine Apple Silicon

### Minimal Intervention Testing
Rigorous testing of intervention minimality:
- Remove each intervention to verify necessity
- Measure intervention scope and duration
- Validate no persistent side effects
- Ensure security model integrity preservation

### Platform Assumption Documentation
Comprehensive documentation of fulfilled platform assumptions:
- Catalog all Apple Silicon platform assumptions
- Document intervention rationale for each assumption
- Track assumption fulfillment across kernel versions
- Maintain assumption database for future research

## Non-Goals Enforcement

The kernel policy explicitly excludes:
- **Hackintosh-style patching**: No binary modification approach
- **Security bypass**: No disabling of security mechanisms  
- **Userspace modification**: No application or service changes
- **Performance optimization**: No kernel optimization patches
- **Feature enhancement**: No additional functionality injection

## Future Evolution

### Reduced Intervention Goals
As platform reconstruction accuracy improves:
- Gradually eliminate all kernel interventions
- Achieve completely unaltered kernel execution
- Remove all runtime modification requirements
- Establish pure platform assumption fulfillment

### Enhanced Platform Reconstruction
Improve Platform Boot Layer to eliminate intervention needs:
- More accurate Apple Silicon platform simulation
- Better device tree recreation
- Enhanced security context establishment
- Improved hardware state injection

### Research Expansion
Enable broader kernel research capabilities:
- Platform assumption analysis tools
- Security model investigation framework
- Hardware compatibility testing suite
- Boot chain validation utilities

## Compliance Verification

### Automated Testing
Implement automated compliance verification:
- Kernel binary integrity checking
- Intervention scope validation
- Security mechanism integrity testing
- Platform assumption fulfillment verification

### Code Review Process
Establish strict code review for any kernel-related changes:
- Verify minimal intervention compliance
- Validate security model preservation
- Confirm no prohibited actions included
- Ensure research integrity maintenance

### Community Guidelines
Provide clear community guidelines for kernel-related contributions:
- Document intervention approval process
- Specify validation requirements
- Establish compliance verification procedures
- Maintain research integrity standards

## Conclusion

The kernel strategy represents the ethical and technical foundation of Apple-on-Virt. By maintaining strict boundaries on kernel intervention while enabling legitimate research, the project creates a sustainable platform for Apple Silicon platform assumption analysis.

> This project does not try to make macOS run anywhere. It tries to make macOS believe it never left home.