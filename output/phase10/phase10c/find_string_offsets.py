import sys

path = sys.argv[1]

b = open(path, "rb").read()
need = [
    b"load-kernel-start",
    b"Kernelcache too large",
    b"Kernelcache image not valid",
    b"/System/Library/Caches/com.apple.kernelcaches/kernelcache",
    b"/System/Library/Caches/com.apple.kernelcaches/kernelcache.auxkc",
    b"/boot/kernelcache",
    b"Trustcache",
    b"Kernel-mach_header",
    b"AuxKC-mach_header",
]

for s in need:
    i = b.find(s)
    label = s.decode("utf-8", "ignore")
    if i == -1:
        print(f"{label}: NOTFOUND")
    else:
        print(f"{label}: offset=0x{i:x} ({i} dec)")
