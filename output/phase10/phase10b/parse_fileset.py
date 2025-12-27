import struct
import sys

BIN = sys.argv[1]

LC_FILESET_ENTRY = 0x35
LC_REQ_DYLD = 0x80000000
LC_FILESET_ENTRY_REQ = LC_REQ_DYLD | LC_FILESET_ENTRY

b = open(BIN, "rb").read()
magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack_from(
    "<IiiIIIII", b, 0
)

if magic != 0xFEEDFACF:
    raise SystemExit(f"unexpected magic 0x{magic:08x}")

entries = []
off = 32
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack_from("<II", b, off)
    if cmd in (LC_FILESET_ENTRY, LC_FILESET_ENTRY_REQ):
        vmaddr, fileoff, entry_id, resv = struct.unpack_from("<QQII", b, off + 8)
        s_off = off + entry_id
        s_end = b.find(b"\0", s_off)
        name = b[s_off:s_end].decode("utf-8", "ignore") if s_end != -1 else ""
        inner_magic = struct.unpack_from("<I", b, fileoff)[0]
        entries.append((name, vmaddr, fileoff, inner_magic, cmd))
    off += cmdsize

entries.sort(key=lambda t: (t[1], t[0]))

print(f"entries={len(entries)}")
if entries:
    min_vm = min(e[1] for e in entries)
    max_vm = max(e[1] for e in entries)
    print(f"vmaddr_min=0x{min_vm:016x}")
    print(f"vmaddr_max=0x{max_vm:016x}")

# show first/last few entries as evidence
print("-- first 15 --")
for e in entries[:15]:
    name, vmaddr, fileoff, inner_magic, cmd = e
    print(f"{name}\tvmaddr=0x{vmaddr:016x}\tfileoff=0x{fileoff:x}\tinner_magic=0x{inner_magic:08x}\tcmd=0x{cmd:08x}")

print("-- last 15 --")
for e in entries[-15:]:
    name, vmaddr, fileoff, inner_magic, cmd = e
    print(f"{name}\tvmaddr=0x{vmaddr:016x}\tfileoff=0x{fileoff:x}\tinner_magic=0x{inner_magic:08x}\tcmd=0x{cmd:08x}")

# count inner magics
from collections import Counter
c = Counter(e[3] for e in entries)
print("-- inner_magic counts --")
for k,v in sorted(c.items()):
    print(f"0x{k:08x} count={v}")
