import struct
import sys

BIN = sys.argv[1]

# Load command constants
LC_DYLD_INFO = 0x22
LC_DYLD_INFO_ONLY = 0x80000022
LC_SEGMENT_SPLIT_INFO = 0x1E
LC_REEXPORT_DYLIB = 0x1F
LC_NOTE = 0x31
LC_UUID = 0x1B
LC_BUILD_VERSION = 0x32
LC_DYLD_CHAINED_FIXUPS = 0x80000034

b = open(BIN, "rb").read()
magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack_from(
    "<IiiIIIII", b, 0
)
if magic != 0xFEEDFACF:
    raise SystemExit(f"unexpected magic 0x{magic:08x}")

seen = set()
chained_fixups = None

off = 32
for _ in range(ncmds):
    cmd, cmdsize = struct.unpack_from("<II", b, off)
    seen.add(cmd)
    if cmd == LC_DYLD_CHAINED_FIXUPS:
        # linkedit_data_command: cmd, cmdsize, dataoff, datasize
        dataoff, datasize = struct.unpack_from("<II", b, off + 8)
        chained_fixups = (dataoff, datasize)
    off += cmdsize

want = [
    ("LC_DYLD_INFO", LC_DYLD_INFO),
    ("LC_DYLD_INFO_ONLY", LC_DYLD_INFO_ONLY),
    ("LC_SEGMENT_SPLIT_INFO", LC_SEGMENT_SPLIT_INFO),
    ("LC_REEXPORT_DYLIB", LC_REEXPORT_DYLIB),
    ("LC_NOTE", LC_NOTE),
    ("LC_UUID", LC_UUID),
    ("LC_BUILD_VERSION", LC_BUILD_VERSION),
    ("LC_DYLD_CHAINED_FIXUPS", LC_DYLD_CHAINED_FIXUPS),
]

for n, v in want:
    print(f"{n} (0x{v:08x}) present={v in seen}")

print(f"chained_fixups_linkedit={chained_fixups}")

# If present, decode the dyld_chained_fixups_header (first 7 uint32 fields)
if chained_fixups:
    dataoff, datasize = chained_fixups
    if dataoff + 28 <= len(b):
        hdr = struct.unpack_from("<7I", b, dataoff)
        version, starts_offset, imports_offset, symbols_offset, imports_count, imports_format, symbols_format = hdr
        print("dyld_chained_fixups_header:")
        print(f"  version={version}")
        print(f"  starts_offset=0x{starts_offset:x}")
        print(f"  imports_offset=0x{imports_offset:x}")
        print(f"  symbols_offset=0x{symbols_offset:x}")
        print(f"  imports_count={imports_count}")
        print(f"  imports_format={imports_format}")
        print(f"  symbols_format={symbols_format}")
        # sanity: starts_offset should point within datasize
        print(f"  starts_offset_within_datasize={starts_offset < datasize}")
        print(f"  imports_offset_within_datasize={imports_offset < datasize}")
        print(f"  symbols_offset_within_datasize={symbols_offset < datasize}")
