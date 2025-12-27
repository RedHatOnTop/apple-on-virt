import struct
import sys

BIN = sys.argv[1]
MIN_VA = int(sys.argv[2], 16)
MAX_VA = int(sys.argv[3], 16)

b = open(BIN, "rb").read()

count_total = 0
count_in_range = 0

# scan 8-byte aligned qwords only
for (q,) in struct.iter_unpack("<Q", b[: len(b) - (len(b) % 8)]):
    count_total += 1
    if MIN_VA <= q < MAX_VA:
        count_in_range += 1

print(f"total_qwords={count_total}")
print(f"qwords_in_kernel_va_span={count_in_range}")
if count_total:
    print(f"fraction={count_in_range / count_total:.6f}")
