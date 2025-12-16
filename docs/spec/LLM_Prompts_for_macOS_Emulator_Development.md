# LLM Prompts for macOS Emulator Development

Last updated: 2025-12-16

This document contains structured English prompts designed for LLM agents to process individual tasks in the **professional and systematic research and development** project for macOS Monterey ARM64 emulator. **All Phase 1 development and execution must occur within the Windows Subsystem for Linux (WSL) environment.** Each prompt follows the structured design principles outlined in the technical specification and includes quality gates, expected outputs, and clear scope definitions with WSL compatibility requirements.

## Prompt 1: Generate QEMU Command to Boot macOS Monterey ARM64 Installer

# Task Title: Generate QEMU Command to Boot macOS Monterey ARM64 Installer in WSL
## Context
We are conducting professional and systematic research and development for an ARM64 macOS emulator as part of a larger project. Our goal is to run macOS Monterey (12.x) ARM64 on various hardware configurations. **This task specifically focuses on WSL (Windows Subsystem for Linux) environment implementation, which has unique constraints compared to native macOS or Linux systems.**
## Scope
Your task is to generate a single, executable `qemu-system-aarch64` command that boots the provided macOS Monterey ARM64 BaseSystem.dmg image **within the WSL environment**. The command must account for WSL limitations: no Apple HVF support, x86_64 host architecture, limited GPU acceleration, and GTK-based display requirements instead of Cocoa.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "shell_command": {"type": "string"},
    "rationale": {"type": "string"},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "shell_command", "rationale", "expected_outcome", "is_success"]
}
## Additional Resources
Use the official QEMU documentation for `qemu-system-aarch64`. For UEFI firmware, use the standard EDK2 AArch64 firmware located at `/usr/share/edk2/aarch64/QEMU_EFI.fd`. Reference WSL-specific QEMU configuration guides for ARM64 emulation on x86_64 hosts.
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Use only relative paths in any script examples. The final output must be a valid JSON object. **The generated command must be explicitly compatible with WSL environment constraints and should not assume Apple Silicon or native macOS features.**

---

## Prompt 2: Configure Essential Kext Injection for macOS Monterey ARM64

# Task Title: Configure Essential Kext Injection for macOS Monterey ARM64 in WSL Environment
## Context
We have successfully booted macOS Monterey ARM64 in a QEMU virtual machine **within the WSL environment** but need to inject essential kernel extensions (Kexts) to enable basic functionality. **WSL's virtualized environment has specific hardware abstraction limitations that affect Kext selection and configuration.**
## Scope
Your task is to generate a complete list of essential Kexts required for macOS Monterey ARM64 operation in a **WSL-based virtualized environment**, along with their specific purposes and WSL-compatible configuration requirements. Include Lilu.kext, VirtualSMC.kext, WhateverGreen.kext, BlueToolFixup.kext, and any chipset-specific Kexts that are compatible with emulated hardware rather than physical devices.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "essential_kexts": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {"type": "string"},
          "purpose": {"type": "string"},
          "dependencies": {"type": "array", "items": {"type": "string"}},
          "configuration_notes": {"type": "string"}
        },
        "required": ["name", "purpose"]
      }
    },
    "injection_method": {"type": "string"},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "essential_kexts", "injection_method", "expected_outcome", "is_success"]
}
## Additional Resources
Reference Dortania's OpenCore Install Guide and kholia's OSX-KVM repository for Kext compatibility information. **Pay special attention to Kexts that work in emulated/virtualized environments rather than requiring specific physical hardware.**
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Use only relative paths in any script examples. The final output must be a valid JSON object. **All Kext recommendations must be validated for compatibility with WSL's virtualized environment and emulated hardware.**

---

## Prompt 3: Configure SMBIOS Settings for macOS Monterey Compatibility

# Task Title: Configure SMBIOS Settings for macOS Monterey Compatibility in WSL
## Context
macOS Monterey has strict hardware support policies and requires specific SMBIOS settings to recognize the virtual machine as compatible hardware. **In the WSL environment, we must configure SMBIOS parameters that represent virtualized/emulated hardware rather than attempting to mimic specific physical Mac models that may not be fully compatible with WSL's constraints.**
## Scope
Your task is to generate the correct SMBIOS configuration parameters for macOS Monterey ARM64 virtual machine **optimized for WSL environment**, including board-id, serial-number, rom, and smc-version values for supported models that work well in virtualized environments. Focus on models like Macmini7,1, iMac16,1+, or MacBookAir7,1+ that have proven compatibility with QEMU-based virtualization.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "supported_models": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "model": {"type": "string"},
          "board_id": {"type": "string"},
          "serial_number_pattern": {"type": "string"},
          "rom_pattern": {"type": "string"},
          "smc_version": {"type": "string"}
        },
        "required": ["model", "board_id"]
      }
    },
    "qemu_smbios_command": {"type": "string"},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "supported_models", "qemu_smbios_command", "expected_outcome", "is_success"]
}
## Additional Resources
Reference Dortania's OpenCore Install Guide for macOS Monterey hardware compatibility and SMBIOS requirements. **Prioritize SMBIOS configurations that have been tested in QEMU virtualization environments rather than physical hardware setups.**
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Use only relative paths in any script examples. The final output must be a valid JSON object. **SMBIOS configurations must be suitable for WSL's virtualized environment and should avoid settings that require native macOS hardware features unavailable in WSL.**

---

## Prompt 4: Implement VirtIO Device Configuration for macOS Monterey

# Task Title: Implement VirtIO Device Configuration for macOS Monterey in WSL
## Context
macOS Monterey includes built-in VirtIO driver support, which provides paravirtualized interfaces for efficient communication between hypervisor and operating system, dramatically improving GPU acceleration, networking, and disk I/O performance. **However, WSL environment has specific limitations regarding GPU acceleration and device passthrough that must be considered when configuring VirtIO devices.**
## Scope
Your task is to generate the complete QEMU command configuration for VirtIO devices including virtio-gpu-pci, virtio-net-pci, and virtio-blk controllers optimized for macOS Monterey ARM64 virtual machines **in the WSL environment**. Account for WSL's limited GPU capabilities and focus on stable, functional configurations rather than high-performance acceleration.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "virtio_devices": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "device_type": {"type": "string"},
          "qemu_option": {"type": "string"},
          "performance_notes": {"type": "string"},
          "limitations": {"type": "string"}
        },
        "required": ["device_type", "qemu_option"]
      }
    },
    "complete_virtio_config": {"type": "string"},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "virtio_devices", "complete_virtio_config", "expected_outcome", "is_success"]
}
## Additional Resources
Reference QEMU documentation for virtio-gpu-pci, virtio-net-pci, and virtio-blk device configuration options. **Consider WSL-specific limitations and prioritize stability over performance for GPU-related VirtIO configurations.**
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Use only relative paths in any script examples. The final output must be a valid JSON object. **All VirtIO configurations must be explicitly compatible with WSL environment constraints and should provide fallback options for limited GPU acceleration scenarios.**

---

## Prompt 5: Configure Boot Arguments for macOS Monterey Debugging and Optimization

# Task Title: Configure Boot Arguments for macOS Monterey Debugging and Optimization in WSL
## Context
Boot arguments are command-line options passed to the kernel and system services during macOS booting, very useful for debugging, performance optimization, and enabling specific features in virtualized environments. **In the WSL environment, specific boot arguments may be required to address virtualization overhead, limited hardware access, and compatibility issues unique to WSL's architecture.**
## Scope
Your task is to generate a comprehensive list of essential boot arguments for macOS Monterey ARM64 virtual machines **specifically optimized for WSL environment**, categorized by purpose (debugging, Kext/SIP control, hardware control, WSL compatibility, etc.) with detailed explanations of each argument's function and WSL-specific usage scenarios.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "boot_arguments": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "argument": {"type": "string"},
          "category": {"type": "string"},
          "description": {"type": "string"},
          "usage_scenario": {"type": "string"},
          "cautions": {"type": "string"}
        },
        "required": ["argument", "category", "description"]
      }
    },
    "recommended_combinations": {"type": "array", "items": {"type": "string"}},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "boot_arguments", "expected_outcome", "is_success"]
}
## Additional Resources
Reference eliteMacx86 forums and Dortania's OpenCore Install Guide for boot argument documentation. **Include WSL-specific boot arguments that address virtualization performance, memory management, and compatibility issues commonly encountered in WSL environments.**
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Use only relative paths in any script examples. The final output must be a valid JSON object. **All boot argument recommendations must be validated for effectiveness in WSL environment and should include WSL-specific optimization parameters where applicable.**

---

## Usage Instructions

1. Process each prompt individually in sequence
2. Ensure all outputs conform to the specified JSON schema
3. Validate quality gates (`is_success` field) before proceeding to next task
4. Use the structured output for automated integration into the **WSL-based** development workflow
5. Follow all project rules enforcement guidelines strictly, **with particular attention to WSL compatibility requirements**

Each prompt is designed to be self-contained and executable by an LLM agent within a single session, with clear quality gates and expected outcomes as specified in the technical specification document. **All generated solutions must be explicitly compatible with the Windows Subsystem for Linux (WSL) environment and should not assume access to native macOS or Apple Silicon features.**