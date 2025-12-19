# hw/apple meson.build
# Apple Silicon Platform Reconstruction
#
# Note: The actual source files are added from hw/arm/meson.build
# because QEMU's build system looks up hw_arch by TARGET_BASE_ARCH.
# For apple64e target, TARGET_BASE_ARCH=arm, so files must be in arm_ss.

apple_ss = ss.source_set()

# Files are added from hw/arm/meson.build instead

# Future: Apple devices (Phase 1+)
# Will also be added from hw/arm/meson.build

hw_arch += {'apple': apple_ss}
