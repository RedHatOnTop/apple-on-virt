# Apple Silicon arm64e target configuration
# This target produces: qemu-system-apple64e
#
# This is NOT a generic ARM64 target.
# This is specifically for Apple Silicon platform reconstruction.

TARGET_ARCH=aarch64
TARGET_BASE_ARCH=arm
TARGET_SUPPORTS_MTTCG=y
TARGET_XML_FILES= gdb-xml/aarch64-core.xml gdb-xml/aarch64-fpu.xml
# Apple Silicon does not use FDT in the standard ARM way
# but we keep this for now as it's needed by some QEMU infrastructure
TARGET_NEED_FDT=y
