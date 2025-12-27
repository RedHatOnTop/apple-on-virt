import struct
import sys

path = sys.argv[1]
needle = int(sys.argv[2], 0)

b = open(path, 'rb').read()
pat = struct.pack('<I', needle)

hits = []
start = 0
while True:
    i = b.find(pat, start)
    if i == -1:
        break
    hits.append(i)
    start = i + 1

print(f"needle=0x{needle:08x} hits={len(hits)}")
for off in hits[:50]:
    print(f"  off=0x{off:x}")
