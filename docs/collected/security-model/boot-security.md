---
title: Apple Platform Security Model
derived-from:
  - docs/external/Asahi Linux Docs/docs/platform/security.md
project-relevance:
  Context for the environment the emulator mimics (Permissive Security Mode).
confidence: high
---

## Extracted Facts

### Security Modes
- **Full Security**: Default macOS. Signed/hashed kernelcache/System Volume (SSV).
- **Permissive Security**:
    - Used for third-party OS (Asahi Linux).
    - Allows enrollment of non-Apple-signed kernelcaches (signed by user/Machine Owner).
    - SSV disabled.
    - Still requires decent boot object (e.g. m1n1 encapsulated in Mach-O).
- **1TR (One True Recovery)**:
    - Special recovery mode entered via Power Button held + Auth.
    - The *only* place to change security policy (Permissive <-> Full).

### SEP (Secure Enclave Processor)
- Hardware trust root.
- Manages Boot Policy per APFS container.
- Verifies boot objects (Stage 1, Stage 2, Kernel).
- Handles Disk Encryption keys (VEK, xART) - keys bypassed to storage controller, not seen by CPU.

### Boot Process Security
- **Stage 0 (SecureROM)** -> **Stage 1 (iBoot1/NOR)** -> **Stage 2 (iBoot2/OS)**.
- Chain of trust rooted in Hardware + User (Machine Owner).
- "Permissive" mode allows replacing the Kernel (after Stage 2), but Stage 2 itself is immutable/signed by Apple.
- Asahi approach: Enroll `m1n1` as the "kernel" in Permissive mode.

### Encryption
- **Data Protection**: Transparent encryption.
- Keys wrapped by KEK (User Creds).
- **Emulator Note**: Since we emulate the CPU, we likely emulate "unwrapped" state or ignore encryption if working with raw images, but real hardware enforces this.

## Explicit Non-Facts / Unknowns
- Internal workings of SEP firmware (sepOS) are black-box.

## Notes for Future Phases
- Emulator should behave as a machine in "Permissive Security" mode to boot custom kernels/m1n1.
- No need to emulate full SEP crypto/attestation unless testing macOS Secure Boot logic deeply.