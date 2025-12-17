# apple-arm64e CPU Model Implementation Checklist

This is an **implementation order guide**. Deviating from this sequence will cause significant debugging difficulties.

## 0️⃣ CPU Identity Declaration

### Critical Requirements
* **Name**: `apple-arm64e`
* **Never mix** with generic ARM CPU implementations
* Dedicated feature flag for arm64e semantics

```c
// In target/arm/cpu.h
#define ARM_CPU_FEATURE_ARM64E  (1ULL << 60)

// In target/arm/cpu.c
static const ARMCPUInfo arm_cpus[] = {
    { "apple-arm64e", ARM_CPU_FEATURE_ARM64E },
    // ... other CPUs
};
```

### Implementation Priority: HIGHEST
- Must be established before any other CPU work
- Ensures clean separation from generic ARM implementations

## 1️⃣ Essential Feature Flags

### MUST Enable Features
* **AArch64**: Full 64-bit execution support
* **EL0 / EL1 / EL2**: All exception levels required by macOS
* **Virtual memory**: MMU and page table support  
* **Exception levels**: Proper exception handling across ELs

### MUST Declare as arm64e
* **ABI = arm64e**: Not generic ARM64
* **Pointer authentication present**: PAC feature flag enabled

```c
static void apple_arm64e_initfn(Object *obj)
{
    ARMCPU *cpu = ARM_CPU(obj);
    
    // Enable essential features
    cpu->has_el0 = true;
    cpu->has_el1 = true; 
    cpu->has_el2 = true;
    cpu->has_aarch64 = true;
    cpu->has_virt = true;
    
    // Declare as arm64e
    cpu->abi = ARM_ABI_AARCH64_APPLE;
    cpu->has_pauth = true;  // Pointer authentication
    
    // Set arm64e feature flag
    cpu->features |= ARM_CPU_FEATURE_ARM64E;
}
```

### Implementation Priority: HIGH
- Required before PAC or system register work
- Establishes CPU identity for Device Tree exposure

## 2️⃣ PAC Implementation Strategy (Critical)

### Initial Phase Goals
* ❌ Actual cryptographic PAC implementation
* ❌ Key security mechanisms  
* ✅ **Semantic PAC only**

### Semantic PAC Definition
* **PAC instruction decode**: Must correctly decode all PAC instructions
* **Failure conditions**: Almost never occur during bring-up
* **Primary objective**: Kernel bring-up success

### Implementation Approach
```c
// In target/arm/pac.c
static bool apple_pac_authenticate(CPUARMState *env, uint64_t ptr, int key_type)
{
    // Semantic PAC: Always succeed during bring-up
    // Real implementation would perform cryptographic verification
    return true;
}

static uint64_t apple_pac_sign(CPUARMState *env, uint64_t ptr, int key_type)
{
    // Semantic PAC: Return pointer with simple modification
    // Real implementation would use cryptographic keys
    return ptr | (1ULL << 63);  // Simple high-bit marking
}
```

### Implementation Priority: MEDIUM-HIGH
- Can be simplified initially but must decode instructions correctly
- Focus on bring-up success, not cryptographic accuracy

## 3️⃣ Exception Level Transition Accuracy

### Critical Transition Points
* **EL2 → EL1 entry**: Most sensitive transition for macOS kernel
* **Exception return**: Proper context restoration
* **Stack pointer switching**: Correct SP_ELx register handling

### Failure Consequences
* ❌ Kernel panic (debuggable)
* ❌ **Silent hang** (extremely difficult to debug)

### Implementation Requirements
```c
// In target/arm/helper.c
void apple_el2_to_el1_transition(CPUARMState *env)
{
    // Ensure proper register state for EL1 entry
    env->cp15.sctlr_el[1] = APPLE_SCTLR_EL1_VALUE;
    env->cp15.tcr_el[1] = APPLE_TCR_EL1_VALUE;
    env->sp_el[1] = env->sp_el[2];  // Proper stack pointer transfer
    
    // Set correct exception level
    env->pstate = PSTATE_MODE_EL1h | PSTATE_SP_EL1;
}
```

### Implementation Priority: CRITICAL
- Must be implemented correctly from the start
- Silent failures make debugging nearly impossible

## 4️⃣ System Register Minimum Set

### Mandatory Consistent Values
These registers **MUST** provide consistent, macOS-acceptable values:

* **`ID_AA64PFR0_EL1`**: Processor feature register 0
* **`ID_AA64PFR1_EL1`**: Processor feature register 1  
* **`ID_AA64MMFR0_EL1`**: Memory model feature register 0
* **`ID_AA64MMFR1_EL1`**: Memory model feature register 1
* **`SCTLR_EL1`**: System control register
* **`TTBR0_EL1`**: Translation table base register 0
* **`TTBR1_EL1`**: Translation table base register 1
* **`TCR_EL1`**: Translation control register

### Value Philosophy
* ❌ "Identical to real M1 values"
* ✅ "Values that macOS accepts as valid"

### Implementation Example
```c
// In target/arm/cpu.c
static void apple_arm64e_set_sysregs(ARMCPU *cpu)
{
    // Set values that macOS will accept
    cpu->isar.id_aa64pfr0 = 
        FIELD_DP64(0, ID_AA64PFR0, GIC, 1) |
        FIELD_DP64(0, ID_AA64PFR0, ADVSIMD, 1) |
        FIELD_DP64(0, ID_AA64PFR0, FP, 1);
        
    cpu->isar.id_aa64mmfr0 = 
        FIELD_DP64(0, ID_AA64MMFR0, PARANGE, 5) |  // 48-bit PA
        FIELD_DP64(0, ID_AA64MMFR0, ASIDBITS, 1);  // 16-bit ASID
        
    // Apple-specific SCTLR value
    cpu->reset_sctlr = APPLE_SCTLR_EL1_RESET_VALUE;
}
```

### Implementation Priority: HIGH
- Required for proper kernel initialization
- Inconsistent values cause early boot failures

## 5️⃣ Exception Vector Layout

### Requirements
* **Apple-style vector layout**: Not Linux-standard vectors
* **Proper base address**: VBAR_EL1 must point to correct location
* **Complete handler set**: All exception types must have handlers

### Critical Validation Point
> Kernel performs sanity-check on vector addresses

### Implementation Approach
```c
// In target/arm/excp_helper.c
void apple_setup_exception_vectors(ARMCPU *cpu)
{
    // Set Apple-style vector base address
    cpu->env.cp15.vbar_el[1] = APPLE_VECTOR_BASE_ADDR;
    
    // Ensure all vector slots are properly initialized
    // Apple expects specific layout different from Linux
    memset((void*)APPLE_VECTOR_BASE_ADDR, 0, 0x800);
    
    // Install minimal handlers for bring-up
    install_vector_handler(APPLE_VECTOR_SYNC_CURRENT, sync_handler);
    install_vector_handler(APPLE_VECTOR_IRQ_CURRENT, irq_handler);
    // ... other handlers
}
```

### Implementation Priority: MEDIUM-HIGH
- Required before kernel exception handling
- Wrong layout causes immediate kernel panics

## 6️⃣ Timer / Interrupt (Initial Simplification)

### Initial Phase Strategy
* ❌ Precise timing emulation
* ❌ Complex interrupt controller modeling
* ✅ **Monotonic timer increment**
* ✅ **Prevent interrupt storms**

### Minimal Implementation
```c
// In hw/apple/apple_timer.c
static void apple_timer_tick(void *opaque)
{
    AppleTimerState *s = opaque;
    
    // Simple monotonic increment
    s->counter++;
    
    // Prevent interrupt storms during bring-up
    if (s->counter % 1000 == 0) {
        qemu_set_irq(s->irq, 1);
        qemu_set_irq(s->irq, 0);
    }
    
    // Schedule next tick
    timer_mod(s->timer, qemu_clock_get_ns(QEMU_CLOCK_VIRTUAL) + 1000000);
}
```

### Implementation Priority: MEDIUM
- Can be simplified initially
- Focus on preventing hangs rather than accuracy

## 7️⃣ What This CPU Model Does NOT Do

### Explicitly Excluded Features
* **Multi-core scheduling**: Single CPU only in initial phase
* **Performance optimization**: Accuracy over speed
* **Speculative execution modeling**: Not required for bring-up
* **Advanced power management**: Basic functionality only

### Implementation Philosophy
Focus exclusively on features required for macOS arm64e kernel bring-up success.

## CPU Model Goal Summary (One Line)

> **이 CPU는 "빠른 ARM CPU"가 아니라 macOS arm64e 커널을 안 놀라게 만드는 CPU다.**

## OpenCore Philosophy Alignment

### Version Universality Through CPU Accuracy
* **No version-specific branching** in CPU/ machine implementation
* **macOS updates**: New requirements → platform enhancements, not structural changes
* **"Minimum modification for all versions"** becomes practically achievable

### Strategic Benefits
* Same CPU model works across Monterey/Ventura/Sonoma
* Future macOS versions require only incremental platform improvements  
* Stable foundation for long-term arm64e research

## Implementation Order Checklist

### Phase 1: Foundation (Must Complete First)
- [ ] CPU identity declaration (`apple-arm64e` name, feature flag)
- [ ] Essential feature flags (AArch64, EL0-2, virtual memory)
- [ ] System register minimum set (consistent macOS-acceptable values)

### Phase 2: Critical Path (Required for Bring-up)
- [ ] Exception level transition accuracy (EL2→EL1, stack pointers)
- [ ] Exception vector layout (Apple-style, proper base address)
- [ ] PAC semantic implementation (instruction decode, always succeed)

### Phase 3: Stabilization (Prevents Hangs/Panics)  
- [ ] Timer/interrupt simplification (monotonic, no storms)
- [ ] Device Tree CPU node exposure (consistent with machine identity)
- [ ] Integration with apple-silicon-bringup machine

### Phase 4: Enhancement (Future Work)
- [ ] Full cryptographic PAC implementation
- [ ] Multi-core support (if needed)
- [ ] Advanced power management states
- [ ] Performance monitoring extensions

## Validation Criteria

### Success Metrics
* CPU creates and realizes without errors
* Device Tree shows apple-arm64e CPU with correct properties
* Kernel recognizes CPU as genuine arm64e
* No panics during early CPU initialization
* Exception handling works correctly
* PAC usage doesn't cause failures during bring-up

### Failure Indicators
* CPU creation fails or hangs
* Device Tree missing critical CPU properties
* Kernel panic during CPU feature detection
* Silent hang during EL2→EL1 transition
* PAC instruction decode errors
* Vector address sanity check failures

## Non-Goals Enforcement

This CPU model explicitly excludes:
* **Generic ARM64 support**: Focus exclusively on arm64e semantics
* **Multi-platform compatibility**: Target only Apple Silicon requirements
* **Performance priority**: Accuracy over speed during bring-up
* **Full cryptographic implementation**: Semantic PAC sufficient for research

## Conclusion

The `apple-arm64e` CPU model represents the technical foundation of Apple-on-Virt's version universality strategy. By implementing precise arm64e semantics rather than generic ARM64 functionality, the project enables legitimate research into macOS arm64e platform requirements across multiple macOS versions with minimal structural changes.

> This CPU doesn't emulate speed - it recreates the semantics that make macOS believe it never left home.