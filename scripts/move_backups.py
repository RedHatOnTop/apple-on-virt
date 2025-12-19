#!/usr/bin/env python3
"""
Move .backup files to _backup directory.
"""

from pathlib import Path
import shutil

BASE = Path(__file__).parent.parent
DOCS = BASE / "docs"

def main():
    backup_dir = DOCS / "_backup"
    backup_dir.mkdir(exist_ok=True)
    moved = []
    for f in DOCS.glob("*.md.backup"):
        dest = backup_dir / f.name
        if dest.exists():
            # Append number
            i = 1
            while True:
                new_name = f.stem + f".{i}.backup"
                dest = backup_dir / new_name
                if not dest.exists():
                    break
                i += 1
        shutil.move(str(f), str(dest))
        moved.append(f)
    print(f"Moved {len(moved)} backup files to {backup_dir}")

if __name__ == "__main__":
    main()