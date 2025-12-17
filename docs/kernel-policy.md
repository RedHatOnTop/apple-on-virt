# Kernel Accommodation Policy

This document defines the strict rules for when and how kernel interventions are permitted during macOS bring-up on the emulator.

## Fundamental Principles

### Boot Chain Integrity

The boot chain must remain unmodified:

- iBoot binary: Never modified.
- boot.efi binary: Never modified.
- kernelcache binary: Never modified.

All boot components execute their original code. This principle is non-negotiable.

### Kernel Intervention as Last Resort

Kernel accommodation is permitted only when:

- Platform Boot Layer cannot satisfy the assumption.
- No device model change can satisfy the assumption.
- No machine configuration change can satisfy the assumption.
- The kernel encounters an unresolvable runtime condition.

Kernel intervention is the last resort, not the first solution.

### Version-Agnostic Design

All interventions must be version-agnostic:

- No version-specific patches or workarounds.
- No checks for macOS version numbers.
- No branching based on kernel build identifiers.
- Interventions must work across Monterey, Ventura, Sonoma, and future releases.

### Temporary Nature

All interventions are temporary:

- Each intervention should have a documented removal plan.
- Improved platform fidelity should eliminate interventions.
- Interventions are technical debt to be resolved.
- The long-term goal is zero kernel interventions.

## Allowed Intervention Stages

### Stage 1: Pre-Entry Configuration

**When:** Before kernel entry point is reached.

**What is allowed:**

- Adjusting CPU register values.
- Modifying device tree content.
- Setting memory map parameters.
- Configuring platform state registers.

**What is not allowed:**

- Modifying kernel binary.
- Patching kernel code in memory.
- Changing kernel entry point.

**Rationale:**

Pre-entry configuration is part of platform synthesis. Adjusting the environment before kernel execution does not modify the kernel; it modifies what the kernel observes.

### Stage 2: Early Boot Accommodation

**When:** From kernel entry to early initialization completion (first few hundred milliseconds).

**What is allowed:**

- Intercepting specific panic points to provide missing platform state.
- Returning synthesized values from stubbed hardware interfaces.
- Providing platform information through emulated device responses.

**What is not allowed:**

- Modifying kernel code.
- Skipping kernel security checks.
- Disabling kernel integrity features.
- Permanent runtime modifications.

**Rationale:**

Early boot may encounter hardware assumptions that cannot be pre-satisfied. Limited runtime accommodation allows progress while maintaining kernel integrity.

### Stage 3: Runtime Stubs

**When:** During kernel runtime for specific hardware interactions.

**What is allowed:**

- Device stubs that return success for unsupported operations.
- Timer stubs that provide monotonic time.
- Interrupt controller stubs that manage delivery.

**What is not allowed:**

- Kernel code modification.
- Security feature bypass.
- Arbitrary memory modification.
- Userspace intervention.

**Rationale:**

Some hardware interactions cannot be fully emulated. Stubs allow the kernel to proceed without modifying kernel code.

## Forbidden Modifications

### Never Modify Kernel Code

Kernel code modification is absolutely forbidden:

- No binary patches to kernelcache.
- No runtime code modifications.
- No instruction replacement.
- No function hooking via code modification.

### Never Disable Security Features

Security features must not be disabled:

- No disabling SIP (System Integrity Protection).
- No disabling AMFI (Apple Mobile File Integrity).
- No disabling SSV (Signed System Volume).
- No disabling PAC enforcement.
- No disabling kernel integrity checks.

### Never Modify Userspace

Userspace must remain untouched:

- No userspace binary modifications.
- No application patching.
- No system service intervention.
- No user environment changes.

### Never Create Permanent Forks

No permanent kernel forks:

- No maintaining modified kernel images.
- No creating "emulator-compatible" kernel versions.
- No distributing patched kernels.
- No building custom kernels for emulation.

## Version-Agnostic Principles

### Stable Interfaces Only

Interventions must use stable interfaces:

- Device tree properties that are stable across versions.
- System register behaviors defined by architecture.
- Memory map conventions consistent across releases.
- Hardware interfaces with documented behavior.

### No Version Detection

Interventions must not detect kernel version:

```
FORBIDDEN:
    if (kernel_version == "12.0") {
        apply_monterey_workaround();
    } else if (kernel_version == "13.0") {
        apply_ventura_workaround();
    }

REQUIRED:
    // Same code path for all versions
    provide_platform_state();
```

### Platform Fidelity Over Workarounds

When an intervention is needed:

1. First, investigate whether platform fidelity can be improved.
2. If not, implement version-agnostic accommodation.
3. Document the accommodation with removal plan.
4. Continuously attempt to eliminate through platform improvement.

### New Version Compatibility

When a new macOS version releases:

- Verify existing platform state works.
- If issues arise, improve platform fidelity.
- Do not add version-specific code.
- All changes must work for all supported versions.

## Intervention Documentation Requirements

### Documentation Template

Each intervention must document:

```
INTERVENTION: [Descriptive name]

STAGE: [Pre-entry / Early Boot / Runtime]

PROBLEM: [What kernel assumption cannot be satisfied]

OBSERVATION: [How the problem manifests]

INTERVENTION: [What the emulator does]

PLATFORM IMPROVEMENT: [What platform change would eliminate this]

REMOVAL PLAN: [How to eliminate this intervention]

VERSION SCOPE: [Verified working on which versions]
```

### Example Documentation

```
INTERVENTION: Platform Timer Base Address

STAGE: Pre-entry Configuration

PROBLEM: Kernel expects Apple-format timer at specific address.

OBSERVATION: Kernel panics reading timer during early init.

INTERVENTION: Device tree provides Apple-format timer node at 
expected address. Emulator provides timer stub at that address.

PLATFORM IMPROVEMENT: Full timer emulation would eliminate stub.

REMOVAL PLAN: Implement complete Apple timer semantics.

VERSION SCOPE: Monterey, Ventura, Sonoma (all use same timer interface)
```

## Escalation Process

### When New Issues Arise

1. **Document the failure:**
   - Panic message or failure symptom.
   - Stack trace if available.
   - Boot stage where failure occurs.

2. **Investigate platform fidelity:**
   - What does the kernel expect?
   - What is the emulator providing?
   - Can the gap be closed without intervention?

3. **If platform change is possible:**
   - Implement platform improvement.
   - No intervention needed.
   - Document the platform change.

4. **If intervention is needed:**
   - Determine minimum intervention.
   - Ensure version-agnostic.
   - Document fully per template.
   - Create removal plan.

### Review Criteria

Before accepting an intervention:

- [ ] Platform improvement was attempted and rejected.
- [ ] Intervention does not modify kernel code.
- [ ] Intervention does not disable security.
- [ ] Intervention is version-agnostic.
- [ ] Intervention is fully documented.
- [ ] Removal plan exists.

## Categories of Acceptable Intervention

### Hardware Interface Stubs

**Acceptable:**

Providing stub responses for hardware the emulator cannot fully implement:

- Timer reads returning monotonic values.
- Power management queries returning "always on."
- Hardware capability queries returning conservative values.

**Not acceptable:**

Stubs that bypass kernel logic:

- Security queries returning "disabled."
- Verification checks returning "passed" without context.
- Error conditions returning success inappropriately.

### Device Tree Adjustments

**Acceptable:**

Modifying device tree to match emulator capabilities:

- Removing nodes for unsupported hardware.
- Adjusting properties for emulator specifics.
- Adding nodes for emulator-provided devices.

**Not acceptable:**

Device tree changes that alter security:

- Changing security configuration nodes to bypass checks.
- Removing security-related properties.
- Adding properties that disable enforcement.

### Platform State Synthesis

**Acceptable:**

Synthesizing platform state the kernel expects:

- Secure boot context indicating trusted state.
- Platform identity values for consistency.
- Hardware version information.

**Not acceptable:**

Platform state that disables functionality:

- Security state indicating "development mode" to reduce enforcement.
- Debug flags that alter kernel behavior.
- Boot arguments that disable protections.

## Intervention Lifecycle

### Creation

1. Identify unavoidable gap between kernel expectations and platform capability.
2. Design minimum intervention.
3. Verify version-agnostic operation.
4. Document fully.
5. Create removal plan.
6. Implement intervention.

### Maintenance

1. Verify continued necessity with platform improvements.
2. Test across all supported macOS versions.
3. Update documentation if understanding changes.
4. Refine removal plan as platform evolves.

### Removal

1. Implement platform improvement that satisfies kernel assumption.
2. Verify intervention is no longer needed.
3. Remove intervention code.
4. Update documentation.
5. Verify no regression across versions.

## Quality Assurance

### Testing Requirements

Each intervention must be tested:

- On all supported macOS versions.
- In combination with other interventions.
- With platform improvements enabled.
- Under various boot conditions.

### Regression Prevention

When platform changes are made:

- Verify no intervention becomes necessary that wasn't before.
- Verify existing interventions still function correctly.
- Verify no security properties are weakened.

### Audit Trail

Maintain history of:

- All interventions introduced.
- Rationale for each intervention.
- Removal of interventions over time.
- Platform improvements that enabled removal.

## Summary

Kernel accommodations are:

- Last resort after platform solutions fail.
- Limited to specific allowed stages.
- Absolutely forbidden from modifying kernel code.
- Absolutely forbidden from disabling security.
- Required to be version-agnostic.
- Temporary with documented removal plans.

The goal is zero kernel interventions through platform fidelity improvement.
