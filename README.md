# Apple-on-Virt: Apple Silicon Platform Reconstruction

> **This project is a purpose-built emulator that reconstructs the minimal Apple Silicon platform required for macOS arm64e to execute its unmodified boot chain.**

## Project Identity

### What This Is
- ✅ **Apple Silicon platform reconstruction**
- ✅ **arm64e-aware bring-up emulator**

### What This Is Not
- ❌ ARM64 VM
- ❌ macOS 가상머신  
- ❌ Hackintosh

## Project Goals

### Primary Goal
Enable macOS Monterey arm64e to execute the complete boot chain **iBoot → boot.efi → kernelcache** without any binary patches.

### Secondary Goals
Make Apple Silicon platform assumptions researchable in non-Apple environments:
- Kernel structure analysis
- Security model examination  
- Platform assumption validation

## Non-Goals

This project explicitly **does not aim** to provide:

- ❌ 범용 ARM64 에뮬레이터 (Generic ARM64 emulator)
- ❌ 여러 OS 지원 (Multi-OS support)
- ❌ App Store / DRM / iCloud functionality
- ❌ 성능 최적화 우선 (Performance optimization priority)
- ❌ “편하게 쓰는 macOS VM” (Convenient macOS VM)

## Design Philosophy

1. **패치보다 환경** (Environment over patching)
2. **우회보다 재현** (Reproduction over bypass)
3. **범용성보다 정확성** (Accuracy over generality)
4. **부트 체인을 존중** (Respect the boot chain)
5. **하나의 머신, 하나의 CPU** (One machine, one CPU)

## Architecture Overview

```
[ Host ]
 └─ Emulator Core (QEMU-derived)
     ├─ apple-arm64e CPU model
     ├─ apple-silicon-bringup machine
     ├─ Platform Boot Layer
     │    ├─ Apple-style Device Tree
     │    ├─ Secure Boot Context
     │    └─ Hardware State Injection
     ├─ iBoot (unaltered)
     ├─ boot.efi (unaltered)
     └─ macOS kernelcache (arm64e)
```

> **UEFI / BIOS / SBSA 개념 없음** (No UEFI/BIOS/SBSA concepts)

## Machine Model: `apple-silicon-bringup`

### Machine Identity
- Inherits from QEMU `MachineClass`
- Only one machine exists
- **"가짜 Apple SoC 플랫폼"** (Fake Apple SoC platform), not "virtual board"

### Machine Responsibilities

#### 1. Platform Boot Layer Provision
- Apple-style memory map
- Apple-style Device Tree generation
- Secure boot state composition

#### 2. CPU/Device Initial State Definition
- EL3/EL2/EL1 initial context
- PAC-related register initial values
- System register values expected by kernel

### Machine Initialization Flow

```
machine_init()
 ├─ init_memory_map()
 ├─ init_apple_cpu()
 ├─ init_platform_state()
 ├─ generate_apple_device_tree()
 ├─ load_iboot()
 └─ handoff_to_iboot()
```

### Device Tree Strategy
- ❌ Linux DT
- ❌ SBSA DT  
- ✅ **Apple-style minimal DT (역공학 기반)** (Apple-style minimal DT based on reverse engineering)

**Included Elements:**
- `/cpus`
- `/memory`
- `/chosen`
- Apple-specific nodes (secure-state, platform-id, etc.)

## CPU Model: `apple-arm64e`

### CPU Model Definition
- Derived from QEMU `ARMCPU`
- Dedicated `ARM_CPU_FEATURE_ARM64E`
- **Never shared with generic ARMv8 CPUs**

### CPU Requirements

#### Essential ISA/ABI
- arm64e calling convention
- PAC instruction decode
- pointer authentication semantics (partial abstraction allowed)

#### Essential State
- PAC key registers
- EL transition behavior
- exception vector layout

### CPU Initialization Flow

```
cpu_realize()
 ├─ init_arm64e_features()
 ├─ init_pac_keys()
 ├─ init_exception_levels()
 ├─ init_system_registers()
 └─ expose_cpu_to_machine()
```

### PAC Implementation Strategy (Initial Phase)
- ❌ 완전한 cryptographic PAC (Full cryptographic PAC)
- ✅ 의미론적 PAC (Semantic PAC)
  - "이 포인터는 유효하다" ("This pointer is valid")
  - "이 컨텍스트에서는 항상 통과" ("Always passes in this context")

> **커널 bring-up 통과가 목적** (Goal is kernel bring-up success)

## Platform Boot Layer

> Platform Boot Layer is a synthetic environment that satisfies Apple Silicon boot and security assumptions before macOS execution begins.

### Components

#### Secure Boot Context
- Boot stage state flags
- "Trusted boot path" assumption injection

#### Hardware Identity
- Platform ID
- Board ID  
- Chip ID (fake but consistent)

#### Boot Arguments
- Parameters passed to iBoot / boot.efi

## Kernel Strategy

### Basic Principles
- **iBoot / boot.efi 무패치** (No patches to iBoot / boot.efi)
- **Kernel**: Minimal intervention only allowed
  - Immediately after entry
  - At bring-up failure points only

### Prohibited Actions
- Complete security disable
- Userspace patching
- ABI modification

## Current Limitations

- Early development phase (Phase 0: Research)
- Headless kernel bring-up not yet achieved
- Platform Boot Layer implementation in progress
- arm64e CPU model under development

## Research Value

This project enables legitimate research into:
- Apple Silicon platform assumptions
- macOS arm64e boot chain requirements
- Secure boot implementation details
- arm64e semantics and security model
- Platform-specific kernel behavior

## Code Structure

```
emulator/
├── hw/apple/
│   ├── apple_machine.c
│   ├── apple_platform.c
│   └── apple_dt.c
├── target/apple-arm64e/
│   ├── cpu.c
│   ├── pac.c
│   └── sysregs.c
├── boot/
│   ├── platform_state.c
│   └── secure_context.c
├── docs/
│   ├── architecture.md
│   ├── boot-chain.md
│   ├── cpu-arm64e.md
│   └── kernel-policy.md
```

## Final Statement

> This project does not try to make macOS run anywhere.
> It tries to make macOS believe it never left home.

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Boot Chain Analysis](docs/boot-chain.md)  
- [CPU arm64e Model](docs/cpu-arm64e.md)
- [Kernel Policy](docs/kernel-policy.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This project is for educational and research purposes only. Running macOS on non-Apple hardware may violate Apple's End User License Agreement. Users are responsible for ensuring compliance with all applicable laws and license agreements.