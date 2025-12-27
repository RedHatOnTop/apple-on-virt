import sys
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

path = sys.argv[1]
out = sys.argv[2]
base = int(sys.argv[3], 0)  # pseudo-base for display (file-offset-based)

code = open(path, "rb").read()

md = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
md.detail = False

# Linear sweep, 4-byte aligned. If an instruction can't be decoded, emit a .word.
with open(out, "w", encoding="utf-8") as f:
    for off in range(0, len(code) - (len(code) % 4), 4):
        chunk = code[off : off + 4]
        addr = base + off
        insns = list(md.disasm(chunk, addr))
        if insns:
            insn = insns[0]
            f.write(f"0x{insn.address:08x}: {insn.bytes.hex():<8}\t{insn.mnemonic}\t{insn.op_str}\n")
        else:
            w = int.from_bytes(chunk, "little")
            f.write(f"0x{addr:08x}: {chunk.hex():<8}\t.word\t0x{w:08x}\n")
