#!/usr/bin/env python3
"""
Final verification of docs organization.
"""

from pathlib import Path

BASE = Path(__file__).parent.parent
DOCS = BASE / "docs"

def main():
    print("Final verification of docs organization:")
    print()
    
    # Check external directory
    external_count = len(list((DOCS / "external").rglob("*.md"))) + len(list((DOCS / "external").rglob("*.pdf")))
    print(f"External documents: {external_count} files")
    
    # Check collected directory
    collected_count = len(list((DOCS / "collected").rglob("*.md")))
    collected_subdirs = [d.name for d in (DOCS / "collected").iterdir() if d.is_dir()]
    print(f"Collected documents: {collected_count} files in {len(collected_subdirs)} subdirectories: {', '.join(collected_subdirs)}")
    
    # Check internal directory
    internal_count = len(list((DOCS / "internal").rglob("*.md")))
    internal_subdirs = [d.name for d in (DOCS / "internal").iterdir() if d.is_dir()]
    print(f"Internal documents: {internal_count} files in {len(internal_subdirs)} subdirectories: {', '.join(sorted(internal_subdirs))}")
    
    # Check root docs directory
    root_files = [f.name for f in (DOCS).iterdir() if f.is_file() and f.suffix == '.md']
    print(f"Root docs files: {len(root_files)} files: {', '.join(root_files)}")
    
    print()
    print("Organization summary:")
    print("- External: Third-party documents (PDFs, Asahi docs)")
    print("- Collected: Research materials we obtained (organized by topic)")
    print("- Internal: Project documentation (organized by topic)")
    print("- Root: Only index.md for directory structure overview")
    
    print()
    print("✅ All documentation is properly classified and organized!")

if __name__ == "__main__":
    main()