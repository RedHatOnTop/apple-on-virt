# macOS Version Compatibility Strategy

This document defines how Apple-on-Virt achieves compatibility across multiple macOS versions without version-specific logic.

## Core Principle: Platform Fidelity Over Conditional Branching

### The Problem with Version-Specific Code

Traditional emulators often accumulate version-specific workarounds:

```c
// ANTI-PATTERN: Version-specific logic
if (macos_version == MONTEREY) {
    apply_monterey_workaround();
} else if (macos_version == VENTURA) {
    apply_ventura_workaround();
} else if (macos_version == SONOMA) {
    apply_sonoma_workaround();
}
```

This approach creates:
- Growing complexity with each macOS release.
- Maintenance burden for old version support.
- Risk of regression when supporting new versions.
- Fragmented codebase with parallel logic paths.

### The Platform Fidelity Approach

Apple-on-Virt achieves version independence through accurate platform reconstruction:

```c
// CORRECT PATTERN: Version-agnostic platform state
void initialize_platform() {
    synthesize_apple_silicon_state();
    // Same code for all macOS versions
}
```

This approach provides:
- Single code path for all versions.
- New versions work without code changes.
- Maintenance focused on platform accuracy.
- Clear understanding of platform contracts.

## Platform Stability Assumptions

### Why Platform Fidelity Works

macOS version compatibility through platform fidelity relies on these observations:

**Observation 1: Apple Controls Hardware and Software**

Apple designs both Apple Silicon and macOS. This creates stable platform contracts:
- Hardware interfaces remain consistent across product generations.
- macOS relies on well-defined hardware behaviors.
- Platform assumptions evolve incrementally, not radically.

**Observation 2: Backward Compatibility Requirements**

Apple maintains backward compatibility:
- Older macOS versions run on newer hardware.
- Newer macOS versions support older hardware (within limits).
- Core platform interfaces remain stable for multiple years.

**Observation 3: Boot Chain Consistency**

The boot chain structure is remarkably stable:
- iBoot, boot.efi, kernelcache sequence is consistent.
- Device Tree format and required nodes are stable.
- Security boot context expectations are consistent.
- Memory map conventions follow established patterns.

**Observation 4: ABI Stability**

arm64e ABI is stable across macOS versions:
- Instruction semantics do not change.
- Exception level behavior is architecturally defined.
- System register layout is standardized.
- PAC instruction behavior is consistent.

## Version-Agnostic Design Principles

### Principle 1: Implement Platform Contracts, Not Version Behaviors

**Wrong Approach:**
Implement what specific macOS version requires.

**Right Approach:**
Implement what Apple Silicon platform provides.

**Example:**

```c
// WRONG: Version-specific timer implementation
if (version == MONTEREY) {
    timer_frequency = 24000000;  // Monterey expects this
} else if (version == VENTURA) {
    timer_frequency = 24000000;  // Ventura also expects this
}

// RIGHT: Platform-accurate timer implementation
timer_frequency = APPLE_SILICON_TIMER_FREQ;  // Apple Silicon defines this
```

### Principle 2: Use Stable Interfaces

Rely on interfaces that are stable across versions:

**Stable:**
- Device Tree node structure and required properties.
- System register addresses and basic semantics.
- Exception vector layouts.
- Memory attribute encoding.
- Standard instruction behaviors.

**Unstable:**
- Kernel internal data structures.
- Undocumented kernel behaviors.
- Kernel symbol addresses.
- Internal kernel APIs.

**Example:**

```c
// WRONG: Rely on kernel internals
#define KERNEL_BOOT_ARGS_MONTEREY  0xfffffff007004000
#define KERNEL_BOOT_ARGS_VENTURA   0xfffffff007008000

// RIGHT: Use device tree to pass boot arguments
void set_boot_args_in_device_tree(const char *args) {
    device_tree_set_property("/chosen", "boot-args", args);
}
```

### Principle 3: Complete Implementation Over Partial Workarounds

**Wrong Approach:**
Implement minimum to make specific version work.

**Right Approach:**
Implement complete platform behavior once.

**Example:**

```c
// WRONG: Partial implementation per version
void handle_device_tree_monterey() {
    add_cpu_node();
    add_memory_node();
    // Monterey only needs these
}

void handle_device_tree_ventura() {
    add_cpu_node();
    add_memory_node();
    add_secure_boot_node();
    // Ventura needs security info too
}

// RIGHT: Complete implementation for all versions
void generate_device_tree() {
    add_cpu_node();
    add_memory_node();
    add_chosen_node();
    add_secure_boot_node();
    add_platform_identity_node();
    // Complete Apple Silicon device tree
}
```

### Principle 4: Synthesize Ground Truth, Not Version-Specific Expectations

**Wrong Approach:**
Set platform state based on what specific macOS version checks.

**Right Approach:**
Set platform state based on what genuine Apple Silicon provides.

**Example:**

```c
// WRONG: Match version-specific checks
if (version == MONTEREY) {
    set_secure_boot_state(MONTEREY_EXPECTED_STATE);
} else if (version == VENTURA) {
    set_secure_boot_state(VENTURA_EXPECTED_STATE);
}

// RIGHT: Match Apple Silicon ground truth
set_secure_boot_state(APPLE_SILICON_PRODUCTION_STATE);
```

## Compatibility Mechanism

### How Version-Agnostic Design Enables Compatibility

**Step 1: Platform Boot Layer Synthesis**

Platform Boot Layer creates Apple Silicon platform state:
- Memory Map follows Apple Silicon conventions.
- Device Tree uses Apple format with standard nodes.
- Secure Boot Context reflects production hardware state.
- Platform Identity uses consistent synthetic values.

This state is version-independent because it represents the platform, not version requirements.

**Step 2: macOS Queries Platform**

When macOS boots, it queries the platform:
- Reads Device Tree to discover hardware.
- Checks system registers for CPU capabilities.
- Queries secure boot state for security policy.
- Uses platform identity for driver selection.

These queries return platform state, which is the same for all versions.

**Step 3: macOS Adapts to Platform**

macOS adapts its behavior based on platform responses:
- Loads appropriate drivers for detected devices.
- Configures memory management for reported capabilities.
- Sets security policy based on boot state.
- Enables features based on CPU capabilities.

Because platform state is accurate, macOS makes correct decisions for any version.

## Handling Platform Evolution

### When Platform Changes

Occasionally, Apple Silicon platform evolves:
- New hardware features added.
- New device tree properties defined.
- New security mechanisms introduced.
- New system registers added.

### Adaptation Strategy

When platform evolution occurs:

**Step 1: Detect the Change**

Monitor for boot failures on new macOS versions:
- New version fails to boot.
- Error indicates missing platform feature.
- Investigation reveals new platform requirement.

**Step 2: Identify the Platform Feature**

Determine what Apple Silicon added:
- New device tree node or property.
- New system register.
- New boot context requirement.
- New device capability.

**Step 3: Implement the Platform Feature**

Add the feature to platform synthesis:
- Extend Device Tree generation.
- Add system register support.
- Update secure boot context.
- Implement new device capability.

**Step 4: Verify Backward Compatibility**

Ensure old versions still work:
- Test on Monterey.
- Test on Ventura.
- Test on Sonoma.
- Verify no regression.

### Example: Hypothetical New Feature

Suppose a future macOS version requires a new "hardware-version" property:

**Wrong Response:**
```c
if (version >= FUTURE_VERSION) {
    add_hardware_version_property();
}
```

**Right Response:**
```c
// Add hardware-version to device tree unconditionally
// All versions will see it, future version requires it
add_hardware_version_property();
```

## Testing Strategy

### Multi-Version Testing

Verify version-agnostic design through testing:

**Test Matrix:**
- Monterey 12.0, 12.1, 12.2, ... (sample releases)
- Ventura 13.0, 13.1, 13.2, ... (sample releases)
- Sonoma 14.0, 14.1, 14.2, ... (sample releases)
- Future versions as they become available

**Test Method:**
- Same emulator build for all versions.
- No version detection in emulator code.
- No version-specific configuration files.
- Identical platform state for all versions.

**Success Criteria:**
- All versions boot through kernelcache entry.
- No version-specific failures.
- No version-specific workarounds needed.
- New versions work without emulator changes.

### Regression Prevention

Prevent version-specific code from creeping in:

**Code Review Checklist:**
- [ ] No macOS version detection code.
- [ ] No version numbers in conditional logic.
- [ ] No version-specific constants or structures.
- [ ] Platform state based on Apple Silicon, not macOS version.

**Automated Checks:**
- Grep for version detection patterns.
- Flag conditional branches on version variables.
- Verify device tree generation is version-independent.
- Check platform synthesis uses only platform constants.

## Anti-Patterns

### Anti-Pattern 1: Version Detection

```c
// FORBIDDEN
uint32_t detect_macos_version() {
    // Any version detection is wrong
}

if (macos_version >= MINIMUM_VERSION) {
    enable_feature();
}
```

**Why it's wrong:** Creates version-specific code paths that must be maintained.

**Right approach:** Implement complete platform, let macOS discover capabilities.

### Anti-Pattern 2: Conditional Platform State

```c
// FORBIDDEN
if (version == MONTEREY) {
    device_tree.security_level = "base";
} else if (version == VENTURA) {
    device_tree.security_level = "enhanced";
}
```

**Why it's wrong:** Platform state should reflect hardware, not software version.

**Right approach:** Set security level based on Apple Silicon production state, constant across versions.

### Anti-Pattern 3: Progressive Feature Addition

```c
// FORBIDDEN
void generate_device_tree() {
    add_core_nodes();
    
    if (version >= VENTURA) {
        add_ventura_nodes();
    }
    
    if (version >= SONOMA) {
        add_sonoma_nodes();
    }
}
```

**Why it's wrong:** Fragments device tree generation, creates version branches.

**Right approach:** Generate complete device tree based on platform specification, not version requirements.

### Anti-Pattern 4: Version-Specific Workarounds

```c
// FORBIDDEN
void handle_boot_failure() {
    if (version == MONTEREY) {
        apply_monterey_fix();
    } else if (version == VENTURA) {
        apply_ventura_fix();
    }
}
```

**Why it's wrong:** Accumulates fixes that should be replaced with proper platform fidelity.

**Right approach:** Improve platform fidelity to eliminate failure, working for all versions.

## Documentation Principles

### Document Platform, Not Versions

**Wrong:**
"Monterey requires device tree node /cpus with property #address-cells = 2."

**Right:**
"Apple Silicon provides device tree node /cpus with property #address-cells = 2."

### Avoid Version-Specific Examples

**Wrong:**
"In Monterey, set secure boot flag. In Ventura, add additional context."

**Right:**
"Set secure boot flag according to Apple Silicon production state."

### Reference Apple Silicon, Not macOS

**Wrong:**
"macOS 13 expects PAC keys initialized."

**Right:**
"Apple Silicon boot chain requires PAC keys initialized before iBoot entry."

## Long-Term Compatibility Goals

### Five-Year Forward Compatibility

Goal: Emulator built today works with macOS released five years from now.

**How to achieve:**
- Accurate Apple Silicon platform reconstruction.
- Complete implementation of platform features.
- No version-specific code paths.
- Regular platform fidelity improvements.

### Backward Compatibility Maintenance

Goal: Support for older macOS versions remains as new versions are supported.

**How to achieve:**
- Additive platform features only.
- No breaking changes to platform state.
- Test on old versions when adding new features.
- Maintain old version test cases.

## Summary

Version-agnostic compatibility is achieved through:

1. **Platform Fidelity**: Accurate Apple Silicon reconstruction.
2. **No Version Detection**: Zero version-specific code paths.
3. **Stable Interfaces**: Rely on stable platform contracts.
4. **Complete Implementation**: Full platform features, not partial workarounds.
5. **Ground Truth Synthesis**: Platform state from hardware, not version expectations.

This approach enables:
- Current macOS versions work without version-specific code.
- Future macOS versions work with minimal or no changes.
- Old macOS versions continue working as platform improves.
- Single codebase for all versions.
- Clear platform architecture without version complexity.
