# CPU Model Skeleton (apple-arm64e)

This document specifies the C skeleton structure for the apple-arm64e CPU model. This will be implemented in `target/apple-arm64e/cpu.c` once QEMU is forked.

## File Structure

### cpu.h

```c
#ifndef TARGET_APPLE_ARM64E_CPU_H
#define TARGET_APPLE_ARM64E_CPU_H

#include "qemu/osdep.h"
#include "cpu.h"
#include "hw/core/cpu.h"

/*
 * apple-arm64e CPU Model
 * Purpose-built arm64e implementation for macOS
 * This is NOT a generic ARM64 CPU
 */

#define TYPE_APPLE_ARM64E_CPU "apple-arm64e-cpu"
#define APPLE_ARM64E_CPU(obj) OBJECT_CHECK(AppleARM64ECPU, (obj), TYPE_APPLE_ARM64E_CPU)

/* CPU feature flags specific to apple-arm64e */
#define APPLE_ARM64E_FEATURE_PAC        (1ULL << 0)
#define APPLE_ARM64E_FEATURE_BTI        (1ULL << 1)
#define APPLE_ARM64E_FEATURE_SVE        (1ULL << 2)

/* apple-arm64e CPU state */
typedef struct {
    ARMCPU parent_obj;
    
    /* apple-arm64e specific features */
    uint64_t features;
    
    /* PAC key registers */
    uint64_t pac_key_ia_lo;
    uint64_t pac_key_ia_hi;
    uint64_t pac_key_ib_lo;
    uint64_t pac_key_ib_hi;
    uint64_t pac_key_da_lo;
    uint64_t pac_key_da_hi;
    uint64_t pac_key_db_lo;
    uint64_t pac_key_db_hi;
    uint64_t pac_key_ga_lo;
    uint64_t pac_key_ga_hi;
    
    /* Platform identity (from machine) */
    uint64_t platform_id;
    uint64_t board_id;
    uint64_t chip_id;
    
} AppleARM64ECPU;

/* CPU initialization */
void apple_arm64e_cpu_realize(DeviceState *dev, Error **errp);
void apple_arm64e_cpu_reset(CPUState *cs);

/* Feature register access */
uint64_t apple_arm64e_read_feature_register(AppleARM64ECPU *cpu, uint32_t reg);

/* PAC operations */
uint64_t apple_arm64e_pac_sign(AppleARM64ECPU *cpu, uint64_t ptr, uint64_t modifier, int key_type);
uint64_t apple_arm64e_pac_auth(AppleARM64ECPU *cpu, uint64_t ptr, uint64_t modifier, int key_type);
uint64_t apple_arm64e_pac_strip(uint64_t ptr);

#endif /* TARGET_APPLE_ARM64E_CPU_H */
```

### cpu.c

```c
#include "qemu/osdep.h"
#include "target/apple-arm64e/cpu.h"
#include "cpu.h"

/*
 * apple-arm64e CPU Model
 * 
 * This is the ONLY CPU model for Apple-on-Virt.
 * It implements arm64e semantics for macOS, not generic ARM64.
 * 
 * Architecture Philosophy:
 * - Semantic correctness over performance
 * - arm64e specific, not ARMv8-A generic
 * - PAC implementation for boot chain
 * - No multi-core initially
 */

/* Feature register values for apple-arm64e */
#define APPLE_ID_AA64PFR0_EL1   0x0000000100111111ULL  /* EL0-EL2, FP, AdvSIMD */
#define APPLE_ID_AA64PFR1_EL1   0x0000000000000020ULL  /* PAC present */
#define APPLE_ID_AA64MMFR0_EL1  0x0000000000101125ULL  /* 48-bit PA, 4KB granule */
#define APPLE_ID_AA64MMFR1_EL1  0x0000000000000000ULL  
#define APPLE_ID_AA64ISAR1_EL1  0x0000000000000001ULL  /* PAC algorithm */

/*
 * CPU instance initialization
 * Called when CPU object is created
 */
static void apple_arm64e_cpu_initfn(Object *obj)
{
    AppleARM64ECPU *cpu = APPLE_ARM64E_CPU(obj);
    
    /* Initialize apple-arm64e features */
    cpu->features = APPLE_ARM64E_FEATURE_PAC |
                    APPLE_ARM64E_FEATURE_BTI;
    
    /* Initialize PAC keys (will be set properly at reset) */
    /* Using zero for now, proper init happens at realize */
    cpu->pac_key_ia_lo = 0;
    cpu->pac_key_ia_hi = 0;
    cpu->pac_key_ib_lo = 0;
    cpu->pac_key_ib_hi = 0;
    cpu->pac_key_da_lo = 0;
    cpu->pac_key_da_hi = 0;
    cpu->pac_key_db_lo = 0;
    cpu->pac_key_db_hi = 0;
    cpu->pac_key_ga_lo = 0;
    cpu->pac_key_ga_hi = 0;
}

/*
 * CPU realization
 * Called when CPU is being realized into the system
 */
static void apple_arm64e_cpu_realize(DeviceState *dev, Error **errp)
{
    AppleARM64ECPU *cpu = APPLE_ARM64E_CPU(dev);
    CPUState *cs = CPU(dev);
    
    /* Set CPU to arm64e mode (not generic ARM64) */
    /* TODO: Configure ARM CPU base with arm64e specifics */
    
    /* Initialize feature registers */
    apple_arm64e_init_feature_registers(cpu);
    
    /* Initialize PAC keys with consistent values */
    apple_arm64e_init_pac_keys(cpu);
    
    /* Configure exception levels */
    /* apple-arm64e supports EL0, EL1, EL2 */
    apple_arm64e_init_exception_levels(cpu);
    
    /* Call parent realize */
    /* TODO: Integrate with QEMU ARM CPU parent class */
}

/*
 * CPU reset
 * Called when CPU is reset
 */
static void apple_arm64e_cpu_reset(CPUState *cs)
{
    AppleARM64ECPU *cpu = APPLE_ARM64E_CPU(cs);
    
    /* Reset to initial state */
    /* Set to EL2 or EL1 depending on boot mode */
    /* PC will be set by machine model to iBoot entry */
    
    /* Reinitialize PAC keys */
    apple_arm64e_init_pac_keys(cpu);
    
    /* TODO: Call parent reset */
}

/*
 * Feature register initialization
 * Sets up CPU feature registers with apple-arm64e values
 */
static void apple_arm64e_init_feature_registers(AppleARM64ECPU *cpu)
{
    /* Set feature registers to apple-arm64e values */
    /* These are NOT generic ARMv8 values */
    /* They indicate arm64e capabilities to macOS */
    
    /* TODO: Set ID_AA64PFR0_EL1 */
    /* TODO: Set ID_AA64PFR1_EL1 */
    /* TODO: Set ID_AA64MMFR0_EL1 */
    /* TODO: Set ID_AA64MMFR1_EL1 */
    /* TODO: Set ID_AA64ISAR1_EL1 */
}

/*
 * PAC key initialization
 * Initializes PAC key registers with consistent values
 */
static void apple_arm64e_init_pac_keys(AppleARM64ECPU *cpu)
{
    /* Initialize PAC keys */
    /* For semantic PAC, these can be simple consistent values */
    /* Full cryptographic keys are future work */
    
    cpu->pac_key_ia_lo = 0x0123456789ABCDEFULL;
    cpu->pac_key_ia_hi = 0xFEDCBA9876543210ULL;
    cpu->pac_key_ib_lo = 0x1111111111111111ULL;
    cpu->pac_key_ib_hi = 0x2222222222222222ULL;
    cpu->pac_key_da_lo = 0x3333333333333333ULL;
    cpu->pac_key_da_hi = 0x4444444444444444ULL;
    cpu->pac_key_db_lo = 0x5555555555555555ULL;
    cpu->pac_key_db_hi = 0x6666666666666666ULL;
    cpu->pac_key_ga_lo = 0x7777777777777777ULL;
    cpu->pac_key_ga_hi = 0x8888888888888888ULL;
}

/*
 * Exception level initialization
 * Configures EL0, EL1, EL2 support
 */
static void apple_arm64e_init_exception_levels(AppleARM64ECPU *cpu)
{
    /* Configure exception level support */
    /* apple-arm64e supports EL0-EL2 */
    /* EL3 is not used by macOS */
    
    /* TODO: Set up EL-specific state */
}

/*
 * Feature register read
 * Returns feature register values
 */
uint64_t apple_arm64e_read_feature_register(AppleARM64ECPU *cpu, uint32_t reg)
{
    /* Return feature register values */
    /* These tell macOS what CPU capabilities exist */
    
    switch (reg) {
        case /* ID_AA64PFR0_EL1 */:
            return APPLE_ID_AA64PFR0_EL1;
        case /* ID_AA64PFR1_EL1 */:
            return APPLE_ID_AA64PFR1_EL1;
        case /* ID_AA64MMFR0_EL1 */:
            return APPLE_ID_AA64MMFR0_EL1;
        case /* ID_AA64MMFR1_EL1 */:
            return APPLE_ID_AA64MMFR1_EL1;
        case /* ID_AA64ISAR1_EL1 */:
            return APPLE_ID_AA64ISAR1_EL1;
        default:
            return 0;
    }
}

/*
 * PAC signing operation
 * Implements semantic PAC signing
 */
uint64_t apple_arm64e_pac_sign(AppleARM64ECPU *cpu, uint64_t ptr, 
                                 uint64_t modifier, int key_type)
{
    /* Semantic PAC signing */
    /* For boot chain, this marks pointer as "signed" */
    /* Full cryptographic implementation is future work */
    
    /* Simple semantic implementation: */
    /* Set high bits to indicate signed status */
    uint64_t pac = (ptr & 0x0000FFFFFFFFFFFFULL) | 0xPAC000000000000ULL;
    
    /* TODO: Implement proper semantic PAC */
    
    return pac;
}

/*
 * PAC authentication operation
 * Implements semantic PAC verification
 */
uint64_t apple_arm64e_pac_auth(AppleARM64ECPU *cpu, uint64_t ptr,
                                 uint64_t modifier, int key_type)
{
    /* Semantic PAC authentication */
    /* For boot chain, this verifies semantic consistency */
    /* Full cryptographic verification is future work */
    
    /* Simple semantic implementation: */
    /* Strip PAC bits and return original pointer */
    uint64_t original = ptr & 0x0000FFFFFFFFFFFFULL;
    
    /* TODO: Implement proper semantic verification */
    
    return original;
}

/*
 * PAC stripping operation
 * Removes PAC without verification
 */
uint64_t apple_arm64e_pac_strip(uint64_t ptr)
{
    /* Strip PAC bits */
    return ptr & 0x0000FFFFFFFFFFFFULL;
}

/*
 * CPU class initialization
 * Defines CPU class properties
 */
static void apple_arm64e_cpu_class_init(ObjectClass *oc, void *data)
{
    DeviceClass *dc = DEVICE_CLASS(oc);
    CPUClass *cc = CPU_CLASS(oc);
    
    /* Set CPU class callbacks */
    dc->realize = apple_arm64e_cpu_realize;
    cc->reset = apple_arm64e_cpu_reset;
    
    /* CPU description */
    dc->desc = "Apple arm64e CPU";
    
    /* This CPU is not generic ARM64 */
    /* It is specifically apple-arm64e */
}

/*
 * CPU type definition
 */
static const TypeInfo apple_arm64e_cpu_info = {
    .name = TYPE_APPLE_ARM64E_CPU,
    .parent = TYPE_ARM_CPU,
    .instance_size = sizeof(AppleARM64ECPU),
    .instance_init = apple_arm64e_cpu_initfn,
    .class_init = apple_arm64e_cpu_class_init,
};

/*
 * CPU registration
 */
static void apple_arm64e_cpu_register_types(void)
{
    type_register_static(&apple_arm64e_cpu_info);
}

type_init(apple_arm64e_cpu_register_types)
```

## Key Architectural Points

### 1. Not Generic ARM64

This CPU is:
- apple-arm64e specific
- Not ARMv8-A generic
- Not Cortex-A based
- Not configurable to other ARM CPUs

### 2. arm64e Features

Implements:
- Pointer Authentication (PAC)
- Branch Target Identification (BTI)
- arm64e ABI semantics
- Apple-specific system registers

Does NOT implement:
- Generic ARMv8 extensions irrelevant to macOS
- Performance monitoring beyond basics
- Debug features beyond essentials
- Multi-core initially

### 3. Semantic PAC

PAC implementation is semantic:
- Sign operation marks pointers
- Auth operation verifies semantic consistency
- Strip operation removes PAC bits
- No cryptographic computation initially

Full cryptographic PAC is future work after boot succeeds.

### 4. Feature Register Values

Feature registers report apple-arm64e:
- Not reporting generic ARM capabilities
- Reporting what macOS expects from Apple Silicon
- Values are Apple-specific, not standard ARMv8

### 5. Exception Level Support

Supports:
- EL0: User mode
- EL1: Kernel mode
- EL2: Hypervisor mode (for iBoot)

Does NOT support:
- EL3: Secure monitor (not used by macOS)
- Multiple exception level 2 implementations

## Explicit Non-Implementations

At skeleton stage, these are NOT implemented:

- Instruction execution (TCG integration needed)
- Exception handling (handlers needed)
- System register full set (only feature regs)
- Memory management (MMU logic needed)
- Interrupt handling (integrated with machine)

## Feature Register Semantics

### ID_AA64PFR0_EL1 (Processor Feature Register 0)

```
Bits    | Field      | Value | Meaning
--------|------------|-------|---------------------------
63:60   | SVE        | 0000  | SVE not present initially
59:56   | RAS        | 0000  | RAS not implemented
55:52   | GIC        | 0000  | No GIC (have AIC)
51:48   | AdvSIMD    | 0001  | AdvSIMD present
47:44   | FP         | 0001  | FP present
43:40   | EL3        | 0000  | EL3 not implemented
39:36   | EL2        | 0001  | EL2 implemented
35:32   | EL1        | 0001  | EL1 implemented
31:28   | EL0        | 0001  | EL0 implemented
```

### ID_AA64PFR1_EL1 (Processor Feature Register 1)

```
Bits    | Field      | Value | Meaning
--------|------------|-------|---------------------------
7:4     | BT         | 0010  | BTI present
3:0     | (reserved) | 0000  | Reserved
```

### ID_AA64ISAR1_EL1 (Instruction Set Attribute Register 1)

```
Bits    | Field      | Value | Meaning
--------|------------|-------|---------------------------
7:4     | APA        | 0001  | PAC algorithm present
3:0     | API        | 0000  | PAC implementation defined
```

## Validation Criteria

The skeleton is correct when:

1. **Not Generic ARM**: No generic ARM64 CPU references.
2. **arm64e Identity**: Clearly identified as apple-arm64e.
3. **PAC Structure**: PAC key registers and operations defined.
4. **Feature Flags**: apple-arm64e specific features defined.
5. **No Multi-Core**: Single CPU focus initially.
6. **Documentation Match**: Structure matches documented CPU responsibilities.

## Integration with Machine Model

```c
/* Machine creates CPU */
cpuobj = object_new(TYPE_APPLE_ARM64E_CPU);

/* Machine sets platform identity */
AppleARM64ECPU *cpu = APPLE_ARM64E_CPU(cpuobj);
cpu->platform_id = ams->platform_id;
cpu->board_id = ams->board_id;
cpu->chip_id = ams->chip_id;

/* Machine realizes CPU */
qdev_realize(DEVICE(cpuobj), NULL, &error_fatal);

/* CPU is now ready for iBoot execution */
```

## Next Steps

After skeleton creation:

1. Integrate with QEMU ARM CPU base class.
2. Implement feature register access.
3. Implement PAC instruction handling.
4. Implement exception level management.
5. Integrate with TCG for instruction execution.
6. Test feature register reads.
7. Test PAC operations.
8. Verify macOS recognizes CPU as arm64e.

This skeleton establishes CPU structure. Implementation adds functionality.