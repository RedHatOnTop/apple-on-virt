# iBoot Extraction

**Date**: 2025-12-18

## Extracted File

- **Source IPSW**: UniversalMac_11.0.1_20B29_Restore.ipsw (macOS 11.0.1 Big Sur)
- **File**: Firmware/all_flash/iBoot.j274.RELEASE.im4p
- **Size**: 444,887 bytes
- **Model**: j274 (Mac mini M1, 2020)
- **Location**: local_storage/ipsw/extracted/iBoot.j274.RELEASE.im4p

## File Format

`.im4p` is Apple IMG4 Payload format:
- Contains actual firmware binary
- Wrapped with Apple signature/metadata
- Requires extraction tool to get raw binary

## Next Steps

1. Examine im4p file structure
2. Extract raw iBoot binary from im4p container
3. Determine iBoot load address from binary header
4. Test with emulator

## Tools Needed

- img4tool (for im4p extraction) OR
- Manual parsing of im4p structure
