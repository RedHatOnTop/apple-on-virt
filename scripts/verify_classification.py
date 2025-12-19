#!/usr/bin/env python3
"""
Verify that all docs are correctly classified.
"""

from pathlib import Path
import sys

BASE = Path(__file__).parent.parent
DOCS = BASE / "docs"

def is_external(p: Path) -> bool:
    return p.is_relative_to(DOCS / "external")

def is_collected(p: Path) -> bool:
    return p.is_relative_to(DOCS / "collected")

def is_internal(p: Path) -> bool:
    return p.is_relative_to(DOCS / "internal")

def is_index(p: Path) -> bool:
    return p.name == "index.md" and p.parent == DOCS

def main():
    errors = []
    for md in DOCS.rglob("*.md"):
        if md.is_relative_to(DOCS / "external"):
            # external should only contain third-party docs, but markdown is okay
            pass
        elif md.is_relative_to(DOCS / "collected"):
            pass
        elif md.is_relative_to(DOCS / "internal"):
            pass
        elif is_index(md):
            pass
        else:
            errors.append(f"Unclassified markdown: {md.relative_to(DOCS)}")

    # Also check for misplaced collected files (should be .md with derived-from frontmatter?)
    # We'll just print counts.
    print("Classification verification:")
    print(f"  external: {len(list((DOCS / 'external').rglob('*.md')))} markdown files")
    print(f"  collected: {len(list((DOCS / 'collected').rglob('*.md')))} markdown files")
    print(f"  internal: {len(list((DOCS / 'internal').rglob('*.md')))} markdown files")
    if errors:
        print("ERRORS:")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print("All markdown files are classified.")

if __name__ == "__main__":
    main()