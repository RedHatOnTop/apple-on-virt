import csv
import struct
import sys

BIN = sys.argv[1]
OUT_SEGMENTS = sys.argv[2]
OUT_SUMMARY = sys.argv[3]

HIGH_BASE = 0xFFFF000000000000
LC_SEGMENT_64 = 0x19
LC_UNIXTHREAD = 0x5


def prot_str(p: int) -> str:
    return ("R" if p & 1 else "-") + ("W" if p & 2 else "-") + ("X" if p & 4 else "-")


b = open(BIN, "rb").read()
magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack_from(
    "<IiiIIIII", b, 0
)
if magic != 0xFEEDFACF:
    raise SystemExit(f"unexpected Mach-O magic 0x{magic:08x}")

off = 32
segs = []
entry_pc = entry_sp = entry_cpsr = None

for _ in range(ncmds):
    cmd, cmdsize = struct.unpack_from("<II", b, off)
    payload_off = off + 8

    if cmd == LC_SEGMENT_64:
        segname = b[payload_off : payload_off + 16].split(b"\0", 1)[0].decode(
            "ascii", "ignore"
        )
        vmaddr, vmsize, fileoff, filesize, maxprot, initprot, nsects, segflags = struct.unpack_from(
            "<QQQQiiII", b, payload_off + 16
        )
        segs.append((segname, vmaddr, vmsize, initprot, maxprot, fileoff, filesize))

    if cmd == LC_UNIXTHREAD and entry_pc is None:
        flavor, count = struct.unpack_from("<II", b, payload_off)
        if flavor == 6 and (cmdsize - 8) >= (8 + 34 * 8):
            regs = struct.unpack_from("<34Q", b, payload_off + 8)
            entry_sp = regs[31]
            entry_pc = regs[32]
            entry_cpsr = regs[33]

    off += cmdsize

segs.sort(key=lambda t: t[1])
min_va = min(s[1] for s in segs)
max_va = max(s[1] + s[2] for s in segs)
span = max_va - min_va

hit = None
for segname, vmaddr, vmsize, initprot, maxprot, fileoff, filesize in segs:
    if entry_pc is not None and vmaddr <= entry_pc < vmaddr + vmsize:
        hit = (segname, entry_pc - vmaddr)
        break

with open(OUT_SEGMENTS, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(
        [
            "segname",
            "vmaddr",
            "vmsize",
            "vmend",
            "initprot",
            "maxprot",
            "vmaddr_minus_high_base",
            "fileoff",
            "filesize",
        ]
    )
    for segname, vmaddr, vmsize, initprot, maxprot, fileoff, filesize in segs:
        w.writerow(
            [
                segname,
                f"0x{vmaddr:x}",
                f"0x{vmsize:x}",
                f"0x{(vmaddr + vmsize):x}",
                prot_str(initprot),
                prot_str(maxprot),
                f"0x{(vmaddr - HIGH_BASE):x}" if vmaddr >= HIGH_BASE else "NEG",
                f"0x{fileoff:x}",
                f"0x{filesize:x}",
            ]
        )

with open(OUT_SUMMARY, "w", encoding="utf-8") as f:
    f.write(f"mach_o_filetype={filetype}\n")
    f.write(f"cputype={cputype} cpusubtype={cpusubtype}\n")
    f.write(f"entry_pc=0x{entry_pc:x}\n")
    f.write(f"entry_sp=0x{entry_sp:x}\n")
    f.write(f"entry_cpsr=0x{entry_cpsr:x}\n")
    f.write(f"entry_minus_high_base=0x{(entry_pc - HIGH_BASE):x}\n")
    f.write(f"min_va=0x{min_va:x}\n")
    f.write(f"max_va=0x{max_va:x}\n")
    f.write(f"va_span=0x{span:x} ({span} dec)\n")
    f.write(f"entry_in={hit}\n")
