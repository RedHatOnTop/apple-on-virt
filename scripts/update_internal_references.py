#!/usr/bin/env python3
"""
Update internal document references to reflect new subdirectory structure.
"""

import re
from pathlib import Path

BASE = Path(__file__).parent.parent
INTERNAL = BASE / "docs" / "internal"

# Define the mapping of old filenames to new paths
REFERENCE_UPDATES = {
    # architecture/ subdirectory
    "architecture.md": "architecture/architecture.md",
    "responsibility-matrix.md": "architecture/responsibility-matrix.md",
    
    # boot-chain/ subdirectory
    "boot-chain.md": "boot-chain/boot-chain.md",
    "platform-boot-layer.md": "boot-chain/platform-boot-layer.md",
    
    # cpu-model/ subdirectory
    "cpu-arm64e.md": "cpu-model/cpu-arm64e.md",
    "cpu-model-skeleton.md": "cpu-model/cpu-model-skeleton.md",
    
    # device-model/ subdirectory
    "device-model.md": "device-model/device-model.md",
    "machine-model-skeleton.md": "device-model/machine-model-skeleton.md",
    
    # development/ subdirectory
    "debugging-guide.md": "development/debugging-guide.md",
    "directory-structure.md": "development/directory-structure.md",
    "terminology.md": "development/terminology.md",
    "versioning.md": "development/versioning.md",
    
    # failure-analysis/ subdirectory
    "failure-containment.md": "failure-analysis/failure-containment.md",
    "failure-modes.md": "failure-analysis/failure-modes.md",
    
    # policies/ subdirectory
    "fork-policy.md": "policies/fork-policy.md",
    "kernel-policy.md": "policies/kernel-policy.md",
    "security-model.md": "policies/security-model.md",
    
    # qemu/ subdirectory
    "qemu-as-substrate.md": "qemu/qemu-as-substrate.md",
    "qemu-decomposition.md": "qemu/qemu-decomposition.md",
    
    # progress/ subdirectory
    "milestone-1-completion.md": "progress/milestone-1-completion.md",
    "phase0-completion.md": "progress/phase0-completion.md",
    "phase1.5-completion.md": "progress/phase1.5-completion.md",
    "phase2-readiness-report.md": "progress/phase2-readiness-report.md",
    "phase2-step1-iboot-loading.md": "progress/phase2-step1-iboot-loading.md",
    "phase2-step2-execution-handoff.md": "progress/phase2-step2-execution-handoff.md",
    "phase2-step3-platform-context.md": "progress/phase2-step3-platform-context.md",
    "phase2-step4-controlled-execution.md": "progress/phase2-step4-controlled-execution.md",
    "phase2-step5-failure-classification.md": "progress/phase2-step5-failure-classification.md",
    "phase2-validation-report.md": "progress/phase2-validation-report.md",
    "phaseA-completion.md": "progress/phaseA-completion.md",
    "phaseB-completion.md": "progress/phaseB-completion.md",
    "phaseC-completion.md": "progress/phaseC-completion.md",
    "phaseD-completion.md": "progress/phaseD-completion.md",
    "phaseE-completion.md": "progress/phaseE-completion.md",
}

def update_file_references(file_path):
    """Update references in a single file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Update markdown links [text](filename.md)
    for old_name, new_path in REFERENCE_UPDATES.items():
        # Match markdown links: [text](filename.md)
        pattern = r'\[([^\]]*)\]\(' + re.escape(old_name) + r'\)'
        replacement = f'[{r"\1"}]({new_path})'
        content = re.sub(pattern, replacement, content)
    
    # Also update any references without brackets but with parentheses
    for old_name, new_path in REFERENCE_UPDATES.items():
        # Match direct references that might appear in text
        pattern = r'(?<!\])\b' + re.escape(old_name) + r'\b(?!])'
        # Only replace if it's likely a reference (appears in context that suggests it)
        # For now, we'll be conservative and only update markdown links
        pass
    
    # Write back if changed
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    print("Updating internal document references...")
    
    updated_count = 0
    for md_file in INTERNAL.rglob("*.md"):
        # Skip the top-level directory files (they're now subdirectories)
        if md_file.parent == INTERNAL:
            continue
            
        if update_file_references(md_file):
            print(f"  Updated references in: {md_file.relative_to(INTERNAL.parent)}")
            updated_count += 1
    
    print(f"Updated references in {updated_count} files.")

if __name__ == "__main__":
    main()