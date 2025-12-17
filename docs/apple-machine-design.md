# apple-silicon-bringup Machine Implementation Design

## Machine Role Summary (One Sentence)

> **이 머신은 가상 하드웨어가 아니라 macOS가 기대하는 Apple Silicon '플랫폼 상태'를 만들어주는 역할만 한다.**

## What This Machine Does NOT Do

* ❌ 여러 보드 지원 (Multiple board support)
* ❌ 여러 CPU 선택 (Multiple CPU selection)  
* ❌ UEFI / BIOS 제공 (UEFI/BIOS provision)
* ❌ 표준 ARM 머신처럼 행동 (Behave like standard ARM machine)

## What This Machine MUST Do

* Apple-style 메모리 레이아웃 (Apple-style memory layout)
* Apple-style Device Tree
* Secure boot context 주입 (Secure boot context injection)
* iBoot에 "정상 플랫폼"이라고 납득시키기 (Convince iBoot this is a normal platform)

## QEMU Structure Location

```
hw/apple/apple_machine.c
```

* Inherits from `MachineClass`
* Name: **`apple-silicon-bringup`**
* User-facing options: Minimal (almost none)

## Machine Initialization Flow (Critically Important)

```c
static void apple_machine_init(MachineState *machine)
{
    ApplePlatformState *ps;

    ps = apple_platform_state_create(machine);

    apple_memory_init(ps);
    apple_cpu_init(ps);
    apple_platform_identity_init(ps);
    apple_secure_boot_init(ps);

    apple_dt_generate(ps);

    apple_load_iboot(ps);
}
```

> **This order MUST NOT be changed**  
> (DT must reflect CPU/platform state as result, not input)

## Core Component Design Specifications

### 1️⃣ Memory Map (`apple_memory_init`)

**SBSA/virt machine memory map is PROHIBITED**

Conceptual layout:

```
0x00000000_00000000  DRAM
0x00000001_00000000  MMIO (Apple-style)
0x00000002_00000000  Secure / Reserved
```

**Secure Region Requirements:**
* Must be regions that kernel "believes exist"
* Actual access can be stubbed/stubbed out
* Memory layout must be consistent across macOS versions

**Implementation Notes:**
```c
// Example memory region setup
MemoryRegion *sysmem = get_system_memory();
memory_region_add_subregion(sysmem, 0x0, dram_mr);
memory_region_add_subregion(sysmem, 0x100000000ULL, mmio_mr);
memory_region_add_subregion(sysmem, 0x200000000ULL, secure_mr);
```

### 2️⃣ CPU Connection (`apple_cpu_init`)

* **Exactly one CPU only**
* Model: `apple-arm64e`
* SMP: ❌ (disabled in initial phase)

```c
static void apple_cpu_init(ApplePlatformState *ps)
{
    Error *err = NULL;
    ARMCPU *cpu;

    cpu = ARM_CPU(cpu_create("apple-arm64e"));
    if (!cpu) {
        error_report("Failed to create apple-arm64e CPU");
        exit(1);
    }

    object_property_set_bool(OBJECT(cpu), true, "realized", &err);
    if (err) {
        error_report_err(err);
        exit(1);
    }

    ps->cpu = cpu;
}
```

### 3️⃣ Platform Identity

```c
typedef struct {
    uint32_t platform_id;    // e.g., 0x12345678
    uint32_t board_id;       // e.g., 0x87654321  
    uint64_t chip_id;        // e.g., 0xABCDEF1234567890ULL
} ApplePlatformIdentity;
```

**Critical Requirements:**
* Values don't need to be "real" - consistency is key
* Must remain consistent across macOS versions → enables version universality
* Identity must be injected into Device Tree and Secure Boot Context

**Implementation:**
```c
static void apple_platform_identity_init(ApplePlatformState *ps)
{
    // Use consistent fake values that work across macOS versions
    ps->identity.platform_id = 0x12345678;
    ps->identity.board_id = 0x87654321;
    ps->identity.chip_id = 0xABCDEF1234567890ULL;
}
```

### 4️⃣ Secure Boot Context

```c
typedef struct {
    bool secure_boot_enabled;   // true
    bool trusted_boot_path;     // true  
    bool production_fused;      // true
} AppleSecureBootState;
```

**Core Philosophy:**
* ❌ "Bypass verification"
* ✅ "Assume already verified state"

**Implementation Strategy:**
* Initialize all flags to indicate successful secure boot
* Inject context into Device Tree `/secure-boot` node
* Ensure iBoot sees trusted boot path as already established

```c
static void apple_secure_boot_init(ApplePlatformState *ps)
{
    ps->secure_boot.secure_boot_enabled = true;
    ps->secure_boot.trusted_boot_path = true;
    ps->secure_boot.production_fused = true;
}
```

### 5️⃣ Device Tree Generation (`apple_dt_generate`)

**STRICT PROHIBITION:** Linux DT generator reuse forbidden

**Required DT Nodes:**
* `/cpus` - CPU topology with apple-arm64e properties
* `/memory` - Apple-style memory layout
* `/chosen` - Boot arguments and platform info
* `/apple-platform` - Platform identity and capabilities
* `/secure-boot` - Secure boot context state

**Critical Importance:**
> DT is macOS's **primary evidence** that "this is Apple Silicon"

**Implementation Approach:**
```c
static void apple_dt_generate(ApplePlatformState *ps)
{
    void *fdt;
    
    fdt = create_device_tree();
    
    // Add required Apple-specific nodes
    add_apple_cpus_node(fdt, ps->cpu);
    add_apple_memory_node(fdt, ps->memory_map);
    add_apple_chosen_node(fdt, ps->boot_args);
    add_apple_platform_node(fdt, &ps->identity);
    add_secure_boot_node(fdt, &ps->secure_boot);
    
    ps->device_tree = fdt;
}
```

### 6️⃣ iBoot Loading

**Absolute Rule:** iBoot binary **MUST NOT** be modified

**Loading Process:**
1. Load unaltered iBoot binary into memory
2. Set CPU PC to iBoot entry point
3. Transfer control without modification

```c
static void apple_load_iboot(ApplePlatformState *ps)
{
    uint64_t iboot_entry;
    size_t iboot_size;
    
    // Load unmodified iBoot binary
    iboot_size = load_file("iboot.img", ps->iboot_buffer);
    iboot_entry = APPLE_IBOOT_LOAD_ADDR;
    
    // Copy to target memory location
    cpu_physical_memory_write(iboot_entry, ps->iboot_buffer, iboot_size);
    
    // Set PC and transfer control
    cpu_set_pc(CPU(ps->cpu), iboot_entry);
}
```

## Alignment with OpenCore Philosophy

### Version Universality Through Platform Accuracy
* **"Don't touch boot path"** - Preserve unaltered iBoot → boot.efi → kernelcache
* **"Match environment exactly"** - Recreate precise Apple Silicon platform state
* **"Minimize version-specific branching"** - Same machine works across Monterey/Ventura/Sonoma

### Strategic Benefits
* **Monterey / Ventura / Sonoma**: Same machine implementation possible
* **Future macOS versions**: Only platform enhancements needed, not structural changes
* **Research sustainability**: Stable foundation for long-term platform assumption analysis

## Implementation Priority Order

1. **Memory Map** - Foundation for all other components
2. **CPU Connection** - Single apple-arm64e CPU creation  
3. **Platform Identity** - Consistent fake values for version universality
4. **Secure Boot Context** - Trusted state injection (not bypass)
5. **Device Tree Generation** - Primary evidence of Apple Silicon authenticity
6. **iBoot Loading** - Unaltered binary execution

## Validation Criteria

### Success Metrics
* Machine initializes without errors
* Device Tree contains all required Apple-specific nodes
* iBoot loads and begins execution
* No kernel panics during early bring-up
* Same machine works across multiple macOS versions

### Failure Indicators
* Device Tree missing critical Apple nodes
* Inconsistent platform identity values
* Secure boot context indicating untrusted state
* Memory layout conflicts with Apple expectations
* iBoot fails to recognize platform as Apple Silicon

## Non-Goals Enforcement

This machine explicitly excludes:
* **Multi-board support**: Focus exclusively on apple-silicon-bringup
* **Generic ARM compatibility**: Target only Apple Silicon requirements
* **User configuration options**: Minimal user-facing complexity
* **Performance optimization**: Accuracy over speed during bring-up

## Future Evolution

### Enhanced Platform Reconstruction
* More accurate Apple Silicon memory layouts
* Additional Apple-specific device tree nodes
* Refined secure boot context states
* Improved platform identity consistency

### Independence from QEMU
* Custom machine implementation with same interface
* Enhanced accuracy for Apple Silicon specifics
* Optimized performance for research purposes
* Direct integration with custom emulator core

## Conclusion

The `apple-silicon-bringup` machine represents the strategic foundation of Apple-on-Virt's version universality approach. By focusing on precise platform state recreation rather than boot chain modification, the project enables sustainable research across multiple macOS versions with minimal structural changes.

> This machine doesn't emulate hardware - it recreates the platform state that makes macOS believe it never left home.