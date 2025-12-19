---
title: Apple Silicon Boot Stages
derived-from:
  - docs/external/Asahi Linux Docs/docs/fw/boot.md
  - docs/external/Asahi Linux Docs/docs/platform/pc-boot-differences.md
project-relevance:
  Defines the boot flow the emulator must support to launch guest kernels (macOS or Linux).
confidence: high
---

## Extracted Facts

### Stage 0 (SecureROM)
- Located in SoC-integrated ROM.
- First code to run.
- Verifies, loads, and executes Stage 1 from NOR Flash.
- Falls back to DFU mode if Stage 1 load fails.

### Stage 1 (LLB/iBoot1)
- Located in on-board NOR Flash.
- "System Firmware" equivalent; persistent generic bootloader.
- Understands APFS.
- Reads `boot-volume` variable from NVRAM (`<gpt-partition-type-uuid>:<gpt-partition-uuid>:<volume-group-uuid>`).
- Retrieves Local Policy Hash (try SEP cmd 11, then SEP cmd 14).
- Loads Local Boot Policy from iSCPreboot partition (`/<volume-group-uuid>/LocalPolicy/<policy-hash>.img4`).
- Policy metadata includes:
    - vuid (Volume Group UUID)
    - kuid (KEK Group UUID)
    - sip flags (SIP customized, signed system volume disabled, CTRR disabled, etc.)
    - boot args filtering status
- Loading Next Stage:
    - Boot dir: `/<volume-uuid>/boot/<local-policy.metadata.nsih>` (Preboot subvolume).
    - Decrypts/Verifies/Executes `iBoot.img4` (Stage 2) + Device Tree + firmware files.

### Stage 2 (iBoot2)
- OS-level bootloader, located in the OS partition (part of macOS).
- Acts as the OS loader (similar to `boot.efi`).
- Loads the kernel/rest of system.

### Boot Modes
- AP (Application Processor) boot mode confirmed by SEP:
    - 0: macOS
    - 1: 1TR ("one true" recoveryOS) - SEP allows policy editing here.
    - 2: recoveryOS
    - 3: kcOS
    - 4: restoreOS
    - 255: unknown

### Storage Layout
- **SSD**: Contains both boot config (partitions 1) and OS (partition 2, etc).
- **Partition 1**: Boot-related, config, similar to UEFI var store.
- **Partition 2**: OS Container (APFS).
- **NOR Flash**: Product info + Stage 1 iBoot.

## Explicit Non-Facts / Unknowns
- "No evidence towards other metadata descriptors yet" (in Stage 1 loading).
- Exact details of `update-volume` and `upgrade-boot-volume` variables selection logic.
- Full list of SEP commands beyond 11 and 14 is not detailed here.

## Notes for Future Phases
- Emulator must mock SEP responses to reporting Boot Mode 0 (macOS) or 1 (1TR) depending on desired behavior.
- NVRAM variable parsing for `boot-volume` is required for faithful Stage 1 emulation.
