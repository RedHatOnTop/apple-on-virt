#!/usr/bin/env python3
"""
Organize docs/internal/ into topic subdirectories.
"""

import os
import shutil
from pathlib import Path

BASE = Path(__file__).parent.parent
INTERNAL = BASE / "docs" / "internal"

# Define topic categories and their files
TOPICS = {
    "architecture": [
        "architecture.md",
        "responsibility-matrix.md"
    ],
    "boot-chain": [
        "boot-chain.md",
        "platform-boot-layer.md"
    ],
    "cpu-model": [
        "cpu-arm64e.md",
        "cpu-model-skeleton.md"
    ],
    "device-model": [
        "device-model.md",
        "machine-model-skeleton.md"
    ],
    "development": [
        "debugging-guide.md",
        "directory-structure.md",
        "terminology.md",
        "versioning.md"
    ],
    "policies": [
        "fork-policy.md",
        "kernel-policy.md",
        "security-model.md"
    ],
    "failure-analysis": [
        "failure-containment.md",
        "failure-modes.md"
    ],
    "qemu": [
        "qemu-as-substrate.md",
        "qemu-decomposition.md"
    ],
    "progress": [
        "milestone-1-completion.md",
        "phase0-completion.md",
        "phase1.5-completion.md",
        "phase2-readiness-report.md",
        "phase2-step1-iboot-loading.md",
        "phase2-step2-execution-handoff.md",
        "phase2-step3-platform-context.md",
        "phase2-step4-controlled-execution.md",
        "phase2-step5-failure-classification.md",
        "phase2-validation-report.md",
        "phaseA-completion.md",
        "phaseB-completion.md",
        "phaseC-completion.md",
        "phaseD-completion.md",
        "phaseE-completion.md"
    ]
}

def ensure_dir(path):
    path.mkdir(parents=True, exist_ok=True)

def main():
    print("Organizing internal documentation...")
    
    # Create all topic directories
    for topic in TOPICS.keys():
        ensure_dir(INTERNAL / topic)
        print(f"Created directory: {topic}/")
    
    # Move files to their respective directories
    moved_count = 0
    for topic, files in TOPICS.items():
        for filename in files:
            src = INTERNAL / filename
            dst = INTERNAL / topic / filename
            
            if src.exists():
                shutil.move(str(src), str(dst))
                print(f"  Moved {filename} -> {topic}/")
                moved_count += 1
            else:
                print(f"  WARNING: {filename} not found in internal/")
    
    print(f"Successfully moved {moved_count} files to topic directories.")
    
    # Check for any remaining files (should be none)
    remaining = list(INTERNAL.glob("*.md"))
    if remaining:
        print(f"WARNING: {len(remaining)} files remain in internal/ root:")
        for f in remaining:
            print(f"  - {f.name}")
    else:
        print("All files have been organized into topic directories.")

if __name__ == "__main__":
    main()