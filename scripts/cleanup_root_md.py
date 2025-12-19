#!/usr/bin/env python3
"""
Delete root markdown files that have duplicates in internal/.
"""

import os
import filecmp
from pathlib import Path

BASE = Path(__file__).parent.parent
DOCS = BASE / "docs"

def main():
    root_md = list(DOCS.glob("*.md"))
    deleted = []
    kept = []
    for f in root_md:
        if f.name == "index.md":
            kept.append(f)
            continue
        internal = DOCS / "internal" / f.name
        if internal.exists():
            # check if identical
            if filecmp.cmp(f, internal, shallow=False):
                print(f"  {f.name}: identical, deleting")
                f.unlink()
                deleted.append(f)
            else:
                # ask user? but we'll keep both with warning
                print(f"  {f.name}: differs, keeping root as backup")
                # rename root to .backup
                backup = f.with_suffix('.md.backup')
                f.rename(backup)
                deleted.append(f)
        else:
            print(f"  {f.name}: no internal counterpart, moving to internal")
            internal.parent.mkdir(exist_ok=True)
            f.rename(internal)
            deleted.append(f)
    print(f"Deleted/moved {len(deleted)} files, kept {len(kept)}.")

if __name__ == "__main__":
    main()