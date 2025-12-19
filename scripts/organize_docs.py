#!/usr/bin/env python3
"""
Organize docs directory according to external/collected/internal categories.
"""

import os
import shutil
import filecmp
from pathlib import Path

BASE = Path(__file__).parent.parent
DOCS = BASE / "docs"

def ensure_dir(path):
    path.mkdir(parents=True, exist_ok=True)

def move_file(src, dst, overwrite=False):
    """Move file from src to dst, handling duplicates."""
    src = Path(src)
    dst = Path(dst)
    if not src.exists():
        print(f"  WARNING: source {src} does not exist")
        return
    if dst.exists():
        if filecmp.cmp(src, dst, shallow=False):
            print(f"  duplicate identical, removing source {src}")
            src.unlink()
            return
        else:
            if overwrite:
                print(f"  overwriting {dst} with {src}")
                dst.unlink()
            else:
                print(f"  WARNING: destination {dst} exists and differs, skipping")
                return
    ensure_dir(dst.parent)
    shutil.move(str(src), str(dst))
    print(f"  moved {src} -> {dst}")

def main():
    print("Organizing docs...")

    # 1. Move root markdown files (except index.md) to internal/
    root_md = list(DOCS.glob("*.md"))
    for f in root_md:
        if f.name == "index.md":
            continue
        dest = DOCS / "internal" / f.name
        move_file(f, dest)

    # 2. Move collected/extracted files from internal/extracted/ to collected/
    extracted_dir = DOCS / "internal" / "extracted"
    if extracted_dir.exists():
        for sub in extracted_dir.rglob("*.md"):
            # Determine destination under collected/ keeping subdirectory structure
            rel = sub.relative_to(extracted_dir)
            dest = DOCS / "collected" / rel
            move_file(sub, dest)
        # Try to remove empty directories
        try:
            shutil.rmtree(extracted_dir)
            print(f"  removed empty directory {extracted_dir}")
        except OSError:
            pass

    # 3. Move any remaining root files that are not .md? (none)

    # 4. Create missing subdirectories in collected/ based on existing structure
    collected_subdirs = [
        "boot-chain",
        "constraints",
        "cpu-arm64e",
        "device-tree",
        "memory-model",
        "platform-architecture",
        "security-model",
    ]
    for sub in collected_subdirs:
        ensure_dir(DOCS / "collected" / sub)

    # 5. Ensure internal/ has no extracted subdirectory left
    if (DOCS / "internal" / "extracted").exists():
        print("  WARNING: internal/extracted still exists (non-empty)")

    print("Done.")

if __name__ == "__main__":
    main()