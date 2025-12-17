# LLM Prompts for Apple Silicon–like Platform Emulation

Last updated: 2025-12-17

This document contains structured English prompts designed for LLM agents to process individual tasks in the **Apple-on-Virt** research project. Each prompt follows the structured design principles outlined in the technical specification and includes quality gates, expected outputs, and clear scope definitions.

## Core Project Principles

All LLM agents must understand and adhere to these fundamental principles:

- **Platform Recreation**: Focus on fulfilling Apple Silicon platform assumptions, not generic ARM64 workarounds
- **Security Model Preservation**: Security mechanisms are adapted, not disabled
- **Minimal Intervention**: Kernel modifications restricted to early bring-up phase only  
- **Authentic Device Presentation**: Hardware appears as Apple devices, not generic virtio

> This project emulates an Apple Silicon–like platform, not a generic ARM64 machine.

## Prompt Structure Guidelines

All prompts must include:

1. **Context**: Clear project background and current phase
2. **Scope**: Specific, bounded task definition  
3. **Expected Output**: Precise format and content requirements
4. **Additional Resources**: Approved reference materials only
5. **Project Rules Enforcement**: Quality gates and validation criteria

## Example Prompts

### Prompt 1: Platform Boot Layer Implementation

# Task Title: Implement Platform Boot Layer Fake Apple SoC State
## Context
Apple-on-Virt requires a Platform Boot Layer that replaces traditional UEFI/BIOS concepts. The core component is fake Apple SoC state recreation that convinces macOS arm64e it's running on genuine hardware.
## Scope
Your task is to generate C code for the fake Apple SoC state initialization function that sets up convincing hardware identifiers, memory layout, and CPU topology matching Apple Silicon expectations.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "c_code": {"type": "string"},
    "rationale": {"type": "string"},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "c_code", "rationale", "expected_outcome", "is_success"]
}
## Additional Resources
Reference Apple Silicon technical documentation and existing Platform Boot Layer implementations. Focus on behavioral equivalence rather than exact hardware replication.
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Code must follow Apple Silicon platform assumptions, not generic ARM64 approaches. The final output must be a valid JSON object.

### Prompt 2: arm64e Semantics Validation

# Task Title: Validate arm64e Semantics Implementation
## Context
The project specifically targets arm64e semantics, not generic ARMv8-A. This includes Pointer Authentication (PAC), specific ABI differences, and the kernel/userspace pointer trust model.
## Scope
Your task is to create a test suite that validates whether the emulation environment properly implements arm64e semantics required by macOS.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object", 
  "properties": {
    "task_id": {"type": "string"},
    "test_suite": {"type": "string"},
    "validation_criteria": {"type": "array", "items": {"type": "string"}},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "test_suite", "validation_criteria", "expected_outcome", "is_success"]
}
## Additional Resources
Reference Apple's arm64e documentation and macOS kernel source where available. Focus on behavioral validation rather than instruction-level emulation.
## Project Rules Enforcement
Tests must validate Apple Silicon-specific behaviors, not generic ARM64 functionality. Ensure response contains NO Unicode characters or emojis. Final output must be valid JSON.

### Prompt 3: Security Model Adaptation

# Task Title: Design Security Model Adaptation Strategy  
## Context
Security mechanisms must be selectively adapted where physical hardware assumptions cannot be met in emulation, rather than simply disabled. This preserves research integrity while enabling practical execution.
## Scope
Your task is to design a strategy for adapting AMFI (Apple Mobile File Integrity) and SSV (System Software Verification) for the emulation environment while maintaining security model integrity.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "adaptation_strategy": {"type": "string"},
    "security_preservation_measures": {"type": "array", "items": {"type": "string"}},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "adaptation_strategy", "security_preservation_measures", "expected_outcome", "is_success"]
}
## Additional Resources
Reference Apple security documentation and existing secure boot implementations. Focus on cryptographic context recreation rather than bypass techniques.
## Project Rules Enforcement
Strategy must preserve security intent while adapting to emulation constraints. NO security disabling approaches allowed. Ensure response contains NO Unicode characters or emojis. Final output must be valid JSON.

## Quality Gate Specification

All prompts must define concrete, measurable quality gates:

- **Success Case**: "Platform Boot Layer successfully initializes fake Apple SoC state and outputs verification message"
- **Failure Case**: "Platform Boot Layer fails to load or presents generic ARM64 hardware identifiers"  
- **Function Completion**: "Generated code compiles successfully and passes arm64e semantics validation tests"

## Security Design Requirements

LLM agent outputs must be validated against:

1. **No Security Bypass**: Solutions must adapt, not disable security mechanisms
2. **Platform Authenticity**: Approaches must recreate Apple Silicon conditions, not generic workarounds
3. **Minimal Intervention**: Kernel modifications limited to early bring-up phase only
4. **Research Integrity**: Solutions must support legitimate research objectives

## JSON Schema Enforcement

All LLM outputs must conform to strict JSON schemas to enable automated processing and validation. This ensures reliable evaluation of quality gates and seamless integration into development workflows.

## Conclusion

These prompts establish a framework for LLM-assisted development that aligns with Apple-on-Virt's core principles. By focusing on **platform assumption fulfillment** rather than **workaround implementation**, we create a sustainable foundation for legitimate macOS arm64e research.

> Security mechanisms are not disabled, but selectively adapted where physical hardware assumptions cannot be met in emulation.