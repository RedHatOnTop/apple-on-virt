# Minimal device configuration for apple64e-softmmu
# Apple Silicon Platform Reconstruction
#
# This is NOT a generic ARM64 target.
# ONLY apple-silicon-bringup machine is allowed.
# All other machines are disabled.

# =============================================================================
# ENABLE APPLE SILICON MACHINE
# =============================================================================

CONFIG_APPLE_SILICON_BRINGUP=y

# =============================================================================
# DISABLE ALL GENERIC ARM MACHINES
# =============================================================================

# 64-bit ARM machines
CONFIG_ARM_VIRT=n
CONFIG_SBSA_REF=n
CONFIG_XLNX_ZYNQMP_ARM=n
CONFIG_XLNX_VERSAL=n

# 32-bit ARM machines
CONFIG_CUBIEBOARD=n
CONFIG_DIGIC=n
CONFIG_EXYNOS4=n
CONFIG_HIGHBANK=n
CONFIG_INTEGRATOR=n
CONFIG_MPS3R=n
CONFIG_MUSCA=n
CONFIG_MUSICPAL=n
CONFIG_NETDUINO2=n
CONFIG_NETDUINOPLUS2=n
CONFIG_OLIMEX_STM32_H405=n
CONFIG_REALVIEW=n
CONFIG_SABRELITE=n
CONFIG_STELLARIS=n
CONFIG_STM32VLDISCOVERY=n
CONFIG_COLLIE=n
CONFIG_SX1=n
CONFIG_VERSATILE=n
CONFIG_VEXPRESS=n
CONFIG_ZYNQ=n
CONFIG_ALLWINNER_H3=n
CONFIG_ALLWINNER_R40=n
CONFIG_RASPI=n
CONFIG_B_L475E_IOT01A=n
CONFIG_NPCM7XX=n
CONFIG_FSL_IMX25=n
CONFIG_FSL_IMX31=n
CONFIG_ASPEED_SOC=n
CONFIG_MPS2=n
CONFIG_FSL_IMX7=n
CONFIG_FSL_IMX6UL=n
CONFIG_MICROBIT=n
CONFIG_EMCRAFT_SF2=n

# =============================================================================
# BASIC INFRASTRUCTURE (minimal for skeleton)
# =============================================================================

# We need GIC for interrupt handling skeleton
CONFIG_ARM_GIC=y

# We need PL011 for basic serial output
CONFIG_PL011=y

# Device tree support (needed by ARM infrastructure)
CONFIG_DEVICE_TREE=y
