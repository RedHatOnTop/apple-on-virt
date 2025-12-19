# hw/apple/platform meson.build
# Phase E: Platform Boot Layer Skeleton
#
# Platform Boot Layer components for Apple Silicon reconstruction.

platform_ss = ss.source_set()

# Platform state and boot layer
platform_ss.add(when: 'CONFIG_APPLE_SILICON_BRINGUP', if_true: files(
    'platform_state.c',
    'device_tree_skeleton.c',
    'platform_boot_layer.c',
))

# Export for parent meson.build
hw_apple_platform_ss = platform_ss
