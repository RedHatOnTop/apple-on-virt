# Phase 2 Step 3: Platform Context Exposure

## Objective

Expose Platform Boot Layer outputs to iBoot.

## Implementation

### Device Tree Content

The FDT placed at `APPLE_DT_BASE` (0x40000000) contains:

#### Root Node (`/`)

```
/ {
    compatible = "apple,apple-silicon-bringup";
    model = "Apple Silicon Bringup Platform";
    #address-cells = <2>;
    #size-cells = <2>;
    platform-id = <0xa0a0a0a0>;
    board-id = <0xb0b0b0b0>;
    chip-id = <0xc0c0c0c0>;
}
```

#### Chosen Node (`/chosen`)

```
/chosen {
    bootargs = "debug=0x8 serial=3";
    secure-boot = <1>;
    boot-mode = <0>;  /* APPLE_BOOT_MODE_NORMAL */
}
```

#### Memory Node (`/memory`)

```
/memory {
    device_type = "memory";
    reg = <0x00000000 0x40000000 0x00000000 0x40000000>;
    /* Base: 0x40000000, Size: 1GB (0x40000000) */
}
```

#### CPU Node (`/cpus/cpu@0`)

```
/cpus {
    #address-cells = <1>;
    #size-cells = <0>;
    
    cpu@0 {
        compatible = "apple,arm64e";
        device_type = "cpu";
        reg = <0>;
    }
}
```

### Platform Identity

| Property | Value | Purpose |
|----------|-------|---------|
| platform-id | 0xA0A0A0A0 | Synthetic platform identifier |
| board-id | 0xB0B0B0B0 | Synthetic board identifier |
| chip-id | 0xC0C0C0C0 | Synthetic chip identifier |

These values are:
- Stable (same across runs)
- Obviously synthetic (not real hardware)
- Accessible to iBoot via Device Tree

### Memory Map Consistency

The Device Tree memory node matches the actual DRAM region:
- **Base**: 0x40000000 (APPLE_DRAM_BASE)
- **Size**: 0x40000000 (1GB, APPLE_DRAM_SIZE)

### Secure Boot State

The `/chosen` node indicates:
- `secure-boot = <1>` - Secure boot is "enabled" (synthesized)
- `boot-mode = <0>` - Normal boot mode

This is the "trusted boot path" assumption - we synthesize the state that would exist after successful secure boot verification.

### Access from iBoot

iBoot can access the Device Tree via:
1. **Register X0**: Contains FDT address (0x40000000)
2. **Memory**: FDT blob is at 0x40000000

## Quality Gate

**iBoot does not immediately abort due to missing platform context.**

Verification:
- Device Tree is accessible at X0
- Platform identity is stable
- Memory map is consistent with actual DRAM

## Constraints Met

- ✅ Device Tree is accessible (placed at 0x40000000, address in X0)
- ✅ Platform identity is stable (synthetic values)
- ✅ Memory map is consistent
- ✅ No Secure Boot logic (assumed "trusted boot path")