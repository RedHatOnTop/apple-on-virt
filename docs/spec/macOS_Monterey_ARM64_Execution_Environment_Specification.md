# macOS Monterey ARM64 Execution Environment Technical Specification

Last updated: 2025-12-16

This technical specification outlines the vision and concrete implementation plan for a professional and systematic research and development project aimed at running ARM64 architecture macOS Monterey on general-purpose ARM and x86 hardware. **Phase 1 (macOS ARM on QEMU) will be developed and executed exclusively within the Windows Subsystem for Linux (WSL) environment to ensure cross-platform compatibility and standardized development workflow.** The project is systematically divided into three key milestones, considering technical complexity and dependencies, with clear objectives for each phase to ensure sequential and successful execution. This document provides an in-depth analysis of the technical requirements, implementation strategies, potential challenges, and LLM (Large Language Model)-based automated development workflow design principles for each milestone.

## Milestone 1: ARM-based macOS Emulator Construction (WSL Implementation)

The first milestone, "ARM-based macOS Emulator Construction," is the foundational and decisive phase of the entire project. **This phase must be implemented and validated within the Windows Subsystem for Linux (WSL) environment as the primary development and execution platform.** The clear objective is to "enable GUI-based desktop environment and basic application execution," which requires the successful integration of three core technical elements: a QEMU-based emulator with UEFI bootloader, Paravirtualized devices (VirtIO), and essential kernel extension (Kext) injection. The success of this phase directly impacts progression to subsequent milestones and the feasibility assessment of execution on x86 hardware. Therefore, it is crucial to clearly recognize realistic technical limitations and prioritize an optimized approach that accounts for WSL's unique virtualization constraints and capabilities.

### 1.1 Core Technical Stack and Architecture Design

To execute macOS Monterey ARM64 on an ARM-based virtual machine, a modern UEFI (Ultra Extensible Firmware Interface) platform is essential. macOS now uses UEFI instead of traditional BIOS, and particularly in Apple Silicon environments, it requires Apple's proprietary boot mechanism [[64](https://github.com/utmapp/UTM/discussions/3930)]. Therefore, simply using QEMU's `virt` manifest is insufficient for booting; an UEFI firmware image generated from EDK2 (TianoCore) project's ArmVirtPkg must be explicitly specified using the `-bios` option [[7](https://wiki.osdev.org/EDK2), [8](https://ww2.coastal.edu/mmurphy2/oer/qemu/aarch64/)]. This Apple Silicon-compatible UEFI firmware is included in standard package paths such as `/usr/share/edk2/aarch64/QEMU_EFI.fd`, and without its use, QEMU fails to recognize ISO images and immediately enters the `(qemu)` monitor, resulting in boot failure [[54](https://unix.stackexchange.com/questions/682733/cannot-boot-aarch64-alpine-linux-on-mac-os-using-qemu-6-2-0), [55](https://superuser.com/questions/1684886/qemu-aarch64-on-arm-mac-never-boots-and-only-shows-qemu-prompt)].

As a hypervisor, QEMU is virtually the standard for virtualization technology, providing powerful emulation capabilities through TCG (Tiny Code Generator) that supports various architectures [[49](https://www.theregister.com/2023/09/29/utm_apple_hypervisor_foss_fest/)]. However, the approach to virtual device access has fundamentally changed with macOS Monterey's built-in VirtIO driver support [[9](https://talk.tidbits.com/t/how-to-run-older-macos-versions-on-a-newer-mac/31436)]. VirtIO provides a paravirtualized interface for efficient communication between the hypervisor and operating system, dramatically improving GPU acceleration, networking, and disk I/O performance. Therefore, to enable GUI desktop environment operation, the `virtio-gpu-pci` device must be added, and network (`virtio-net-pci`) and disk (`virtio-blk`) devices should also be connected through VirtIO drivers [[10](https://gist.github.com/Vogtinator/293c4f90c5e92838f7e72610725905fd), [56](https://brennan.io/2020/03/22/sos-block-device/)]. This enables efficient communication with the hypervisor rather than emulation, significantly enhancing GPU acceleration, networking, and disk I/O performance. One of the key performance bottlenecks for macOS Monterey ARM64 VM is the absence of Metal GPU acceleration [[40](https://the-sequence.com/mac-virtualization)]. Some tools like UTM provide OpenGL 3.3+ support using `virgl`, but actual performance is not guaranteed, and specific cases (UTM on Asahi Linux) may experience SPICE-related crash issues [[27](https://github.com/utmapp/UTM/issues/4285), [38](https://discussion.fedoraproject.org/t/enable-spice-virtio-gpu-opengl-for-qemu/99965)]. Therefore, initially, successfully driving the GUI with just `ramfb` or `virtio-gpu-pci` itself constitutes success.

### 1.2 Step-by-Step Implementation Plan for GUI Desktop Environment Construction

Booting to a GUI desktop environment requires a combination of several complex elements beyond simple kernel loading. Below is a systematic implementation plan.

**Step 1: Prepare macOS Monterey ARM64 Installation Media**
First, prepare the macOS Monterey ARM64 installation media. Tools like UTM directly download and process IPSW files, but when using QEMU directly, scripts like `fetch-macOS-v2.py` should be utilized to extract `BaseSystem.dmg` from the full installer obtained from the App Store [[2](https://github.com/kholia/OSX-KVM), [12](https://tinyapps.org/docs/arm-vms.html)]. This image must be formatted in APFS format, and QEMU recognizes this image as boot media through the `mtd` disk controller.

**Step 2: Create and Format Virtual Disk Image**
QEMU requires a virtual disk image with the APFS partition structure demanded by macOS. First, use the `qemu-img` command to create a virtual hard disk image in qcow2 format. For example, to create a 256GB image, use the command `qemu-img create -f qcow2 mac_hdd_ng.img 256G` [[2](https://github.com/kholia/OSX-KVM)]. After connecting the created image to QEMU, format it as APFS using Disk Utility during the macOS installation process.

**Step 3: Initial Boot Attempt and Troubleshooting (WSL Environment)**
Below is an example QEMU command for booting macOS Monterey ARM64 within the Windows Subsystem for Linux (WSL) environment. **Since WSL does not support Apple's HVF (Hypervisor.Framework) or native macOS virtualization, the command must use TCG (Tiny Code Generator) emulation with appropriate WSL-compatible display and acceleration options.** This configuration prioritizes compatibility and stability within WSL constraints [[8](https://ww2.coastal.edu/mmurphy2/oer/qemu/aarch64/), [37](https://github.com/knazarov/homebrew-qemu-virgl)].

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -accel tcg,thread=multi \
  -m 4G \
  -smp 4 \
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive file=BaseSystem.img,if=mtd \
  -drive file=mac_hdd_ng.img,if=virtio \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -display gtk,gl=off
```

This command includes the following key options (WSL-adapted):
*   `-M virt`: Specifies QEMU's virtual ARM64 platform.
*   `-cpu cortex-a72`: Uses a compatible ARM64 CPU model instead of `host` since WSL runs on x86_64 hardware and cannot pass through Apple Silicon CPU features [[42](https://github.com/utmapp/UTM/discussions/3458)].
*   `-accel tcg,thread=multi`: Uses TCG emulation with multi-threading for better performance in WSL, as HVF/KVM are not available [[8](https://ww2.coastal.edu/mmurphy2/oer/qemu/aarch64/)].
*   `-bios ...`: Specifies the Apple Silicon-compatible UEFI firmware required for macOS booting.
*   `-drive file=...,if=mtd`: Connects the macOS installation media through the mtd controller.
*   `-drive file=...,if=virtio`: Connects the APFS-formatted virtual disk image through the VirtIO disk controller.
*   `-device ramfb`: Provides a basic software GPU rendering framebuffer device. Serves as a fallback device if `virtio-gpu-pci` fails to operate [[10](https://gist.github.com/Vogtinator/293c4f90c5e92838f7e72610725905fd)].
*   `-device virtio-gpu-pci`: Paravirtualized GPU device for GUI desktop environment (limited functionality in WSL).
*   `-nic user,model=virtio-net-pci`: Connects a paravirtualized network card.
*   `-display gtk,gl=off`: Uses GTK display backend compatible with WSL GUI applications, with OpenGL disabled due to WSL graphics limitations [[37](https://github.com/knazarov/homebrew-qemu-virgl)].

**Step 4: Post-Install Kext Injection and SIP Disabling (Critical)**
After installation completion, System Integrity Protection (SIP) must be disabled and necessary kernel extensions (Kexts) injected. This should be performed by mimicking OpenCore's NVRAM settings to modify NVRAM variables in the EFI partition or directly modifying the installed system's NVRAM.

*   **SIP Disabling:** Since macOS Catalina and later, disabling SIP requires using the `csrutil disable` command in Recovery environment, which is difficult to perform directly in QEMU environments. Therefore, a method of directly modifying NVRAM variables is needed. Setting the `csr-active-config` value to `00000000` for GUID `7C436110-AB2A-4BBB-A880-FE41995C9F82` completely disables SIP [[66](https://www.insanelymac.com/forum/topic/352952-booting-monterey-into-single-user-mode-to-disable-sip/), [67](https://dortania.github.io/OpenCore-Install-Guide/troubleshooting/extended/post-issues.html)]. Direct access via UTM or similar tools is required for this.

*   **Essential Kext Injection:** The essential Kext stack for macOS booting includes:
    *   `Lilu.kext`: Core library that most other Kexts depend on [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)].
    *   `VirtualSMC.kext`: Provides virtual SMC (Sensor Management Controller) to allow macOS to properly detect hardware [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)].
    *   `WhateverGreen.kext`: Handles GPU patching, managing graphics card recognition, resolution settings, and multimedia support [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/), [57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)].
    *   `BlueToolFixup.kext`: Essential Kext for Bluetooth support [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)].
    *   Additional Kexts should be injected according to USB, Bluetooth, and Ethernet chipsets. For example, Realtek RTL8111 chipset requires `AppleIGB.kext` [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)], and Intel Bluetooth requires `BlueToolFixup.kext` [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)]. These Kexts must be accurately added to `config.plist` using tools like ProperTree, and Kext entries should be performed by mimicking OpenCore's NVRAM settings [[52](https://dortania.github.io/OpenCore-Install-Guide/config.plist/)].

| Kext Name | Role and Necessity |
| :--- | :--- |
| Lilu.kext | Provides essential dependencies [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |
| VirtualSMC.kext | Provides virtual SMC [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |
| WhateverGreen.kext | GPU patching and multimedia support [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/), [57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |
| BlueToolFixup.kext | Bluetooth support (Monterey+) [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)] |
| AppleIGB.kext | Realtek Ethernet chipset support [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)] |
| VoodooI2C / VoodooPS2 | Input device (I2C, PS/2) support (optional) [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |

### 1.3 Performance Optimization and Potential Issue Resolution (WSL Considerations)

After constructing the GUI desktop environment, performance optimization and potential issue resolution are necessary. **Special considerations must be made for the WSL environment, which has inherent limitations compared to native macOS or Linux systems.**

*   **WSL-Specific Constraints:** WSL operates as a compatibility layer on Windows, which introduces additional overhead for virtualization tasks. The lack of direct hardware access and limited GPU acceleration capabilities in WSL significantly impact macOS VM performance [[50](https://hackernoon.com/virtualization-and-emulation-on-macos)].

*   **GPU Acceleration:** While the `virtio-gpu-pci` device enables basic GUI rendering, high-performance graphics acceleration through the Metal API is not supported [[40](https://the-sequence.com/mac-virtualization)]. In WSL environments, even basic OpenGL acceleration may be unavailable or unstable, requiring fallback to software rendering (`-display gtk,gl=off`). The initial goal is to secure a stable 2D GUI rendering state through `virtio-gpu-pci` or `ramfb` rather than pursuing advanced graphics acceleration.

*   **Memory Management:** It should be recognized that Activity Monitor in macOS Monterey ARM64 VM may exaggerate memory usage, burdening the system [[45](https://discussions.apple.com/thread/253543188)]. This can be more severe in TCG Emulation than hardware virtualization and may cause performance degradation. Therefore, the RAM size allocated to the virtual machine should be appropriately set, and unnecessary applications minimized to efficiently manage system resources.

*   **Disk I/O:** Disk I/O performance heavily depends on the virtual disk controller and image format used. `virtio-blk` provides much faster performance than IDE in TCG Emulation environments, but NVMe may be unstable due to poor compatibility with APFS features like snapshotting [[65](https://github.com/adespoton/utmconfigs)]. Initially, using `virtio-blk` is the most stable choice.

*   **Networking:** The `user` network mode provides basic internet connectivity, but for better performance and functionality, consider switching to `bridged` mode. UTM provides networking enhancement features for Mac OS X hosts through the `vmnet-macos` backend, but has the drawback of not maintaining MAC addresses [[37](https://github.com/knazarov/homebrew-qemu-virgl)].

By carefully executing these steps, the goal of the first milestone—GUI desktop environment operation—can be successfully achieved, providing a foundation to progress to the second milestone.

## Milestone 2: Real Hardware Execution Conditions Research and Validation

After successfully constructing the ARM-based macOS Monterey emulator in the first milestone, the second milestone focuses on researching and validating how to optimize and operate this environment on various real hardware. The purpose of this phase goes beyond merely confirming 'compatibility'—it aims to reproduce specific hardware models (SMBIOS) and apply corresponding SSDT (Serially Shadowed Device Table) and boot arguments to make macOS operate as natively as possible. This milestone also includes research on advanced features like PCIe Passthrough to maximize emulator utility.

### 2.1 SMBIOS and Hardware Reproduction

macOS recognizes hardware and activates necessary drivers and features based on SMBIOS (System Management BIOS) data requiring specific hardware model information. macOS Monterey (12.x) has very strict hardware support policies. For example, iMac15,x and earlier models, Macmini6,x and earlier models, MacBookAir6,x and earlier models have discontinued support, with only modern models like iMac16,1+, Macmini7,1+, MacBookAir7,1+ being supported [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html), [68](https://dortania.github.io/OpenCore-Legacy-Patcher/MONTEREY-DROP.html)]. Therefore, to make macOS recognize the QEMU virtual machine as compatible, QEMU's SMBIOS settings should be appropriately modified referencing the `config.plist` file. This can be implemented using QEMU's `-smbios` option, with key parameters including `board-id`, `serial-number`, `rom`, `smc-version`, etc. For example, to set the model as `Macmini7,1`, specify a value like `board-id=Mac-7BA5B2D9E42DDD94`. This process guides macOS to recognize the hardware, ensuring subsequent drivers and patches load properly.

### 2.2 Hardware-Specific SSDT and Boot Argument Application

To ensure the XNU kernel properly recognizes and controls specific hardware configurations (e.g., CPU, GPU), appropriate SSDTs and boot arguments must be applied.

**SSDT Application:**
SSDTs are tables that describe hardware behavior according to the ACPI (Automated Configuration and Power Interface) specification. While QEMU provides virtual hardware, macOS may require specific SSDTs for certain drivers.

*   **CPU/GPU Management:** When using Haswell iGPU, macOS uses model drivers like `Macmini7,1` to control the iGPU [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)]. If using incompatible SMBIOS, patches like `algrey - Force cpuid_cores_per_package` may be needed for AMD CPUs [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)]. These patches properly inform the XNU kernel of the CPU's physical core count to ensure stable booting.

*   **NVRAM and Power Management:** For Coffee Lake and later CPUs, applying `SSDT-AWAC-DISABLE.aml` can disable Wake-on-WLAN (WoWLAN) to resolve booting issues [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)]. Additionally, `SSDT-PMC.aml` may be needed to resolve NVRAM issues with 300-series chipsets [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)]. These SSDTs can be obtained from OpenCore Legacy Patcher or public resources and included in the EFI partition using QEMU's `-smbios type=11,file=...` option.

**Boot Argument Utilization:**
Boot arguments are command-line options passed to the kernel and system services during macOS booting, very useful for debugging, performance optimization, and enabling specific features.

*   **Basic Debugging:** `-v` outputs the boot process in verbose mode to help identify problem locations [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `debug=0x100` prevents rebooting on kernel panic, extending debugging time [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)].

*   **Kext and SIP Control:** `kext-dev-mode=1` allows unsigned Kexts, useful during development and modification [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `rootless=0` disables SIP, but it's recommended to set this through the `csr-active-config` NVRAM variable rather than the `-s` boot argument [[66](https://www.insanelymac.com/forum/topic/352952-booting-monterey-into-single-user-mode-to-disable-sip/), [69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)].

*   **Hardware Control:** `dart=0` disables DART (DMA Address Translation) IOMMU to improve compatibility with Thunderbolt devices or certain network cards [[53](https://elitemacx86.com/threads/how-to-create-opencore-config-plist-file-for-booting-macos-on-desktops-and-laptops-intel-amd-opencore-config-plist-guide.1022/), [69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `framebuffer-stolenmem` is an incorrect parameter; the correct parameter should be `framebuffer-stolemem` [[66](https://www.insanelymac.com/forum/topic/352952-booting-monterey-into-single-user-mode-to-disable-sip/)].

*   **Debugging Purposes:** `keepsyms=1` maintains kernel symbols, useful for kext loading order issues or other debugging [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. Boot arguments like `liludbgall` and `wegdbg` exist to activate debug logs for specific Kexts [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)].

The core of the second milestone is to iteratively apply and analyze these SSDTs and boot arguments to find optimal settings for specific hardware configurations.

### 2.3 PCIe Passthrough and Advanced Device Control

PCIe Passthrough is a technology that directly connects physical PCIe devices (e.g., network cards, storage devices) from the host system to virtual machines, providing near-native performance. However, this is a highly complex and vulnerable technology, and its implementation in macOS environments can be even more difficult.

*   **Basic Principles and Limitations:** QEMU's PCIe Passthrough reads the PCIe descriptor of the device when the VM first starts, creates a static copy, and operates based on this copy. Therefore, if the device dynamically changes its descriptor (e.g., firmware updates), it may not function properly within the VM [[13](https://news.ycombinator.com/item?id=41116473)]. Additionally, hardware that works well on the host may fail to initialize within the VM, possibly due to bugs in the forwarding code [[13](https://news.ycombinator.com/item?id=41116473)].

*   **Compatibility Issues:** When attempting to connect physical iOS devices via USB Passthrough to macOS Monterey ARM64 VM, the `usbmuxd` process causes pairing failures with `file-write-mode` access denial errors [[43](https://developer.apple.com/forums/tags/virtualization?page=2)]. This is presumed to be due to macOS's Sandbox policy operating more strictly within virtual environments.

*   **Validation Plan:** PCIe Passthrough should be excluded initially and considered as a research topic in the latter part of the second milestone. Experiments should proceed in the following order:
    1. Identify available PCIe devices on the host system.
    2. Add options like `-device vfio-pci,host=XX:XX.X` to the QEMU command to connect the device to the VM.
    3. Verify that the device is recognized within macOS and that the appropriate device driver loads correctly.
    4. Test whether the device functions properly (e.g., network connection, storage device mounting).
    5. Observe whether device state changes (e.g., firmware updates) affect the VM.

The second milestone is a crucial phase that systematically analyzes and resolves these complex hardware issues, enabling the emulator to possess stability and functionality similar to real hardware beyond just a virtual environment.

## Milestone 3: ARM OpenCore Development and Custom Emulator Creation

After validating that the QEMU-based emulator constructed in the first milestone operates stably and accumulating optimization experience for various hardware environments in the second milestone, progression to the third milestone becomes possible. The ultimate goal of this phase is to develop a completely independent custom emulator without forking QEMU to execute ARM64 macOS Monterey. This will demonstrate the project's technical maturity and serve as a foundation for better performance, flexibility, and new feature implementation in the future. However, this is an ambitious goal requiring years of time and enormous development effort, making realistic approaches and systematic development plans essential.

### 3.1 QEMU Fork vs. Custom Emulator: Strategic Path Selection

The decision of whether to fork QEMU to create your own version or design a completely new emulator is a critical strategic choice that determines the project's direction.

*   **Advantages of QEMU Fork:** QEMU already implements almost all core foundational technologies required for macOS ARM64 execution. This includes UEFI boot logic, VirtIO drivers, various disk/network/USB controllers, and a powerful architecture emulation engine based on TCG [[49](https://www.theregister.com/2023/09/29/utm_apple_hypervisor_foss_fest/)]. Therefore, forking QEMU is a relatively realistic approach that leverages the existing massive codebase while modifying only specific parts (e.g., performance enhancement, new device addition) according to your needs. QEMU modifications, UEFI troubleshooting experience, and VirtIO driver implementation experience gained in the first milestone will greatly assist this fork work.

*   **Advantages and Difficulty of Custom Emulator:** Creating a completely new emulator means redesigning and implementing operating system, hardware virtualization, disk/network I/O, and especially UEFI boot logic from scratch. This is an extremely challenging task requiring overcoming numerous technical barriers. For example, UEFI boot logic requires understanding EDK2 project's complex structure and integrating it appropriately into QEMU's codebase [[7](https://wiki.osdev.org/EDK2)]. Additionally, implementing paravirtualized technologies like VirtIO requires deep understanding of interoperability with macOS kernel drivers [[9](https://talk.tidbits.com/t/how-to-run-older-macos-versions-on-a-newer-mac/31436)]. Such work requires years of time and enormous development effort.

In conclusion, without deep experience and knowledge accumulation from the first milestone, success in the third milestone is very difficult. Therefore, the most reasonable approach is to initially focus development on QEMU forks, and gradually transition to custom emulator development only when specific requirements (e.g., QEMU complexity issues, absence of specific features) become clear.

### 3.2 Custom Emulator Core Component Design

Several core components must be considered when designing a custom emulator. This should be designed by analyzing QEMU's code and reflecting macOS Monterey ARM64 requirements.

**UEFI Bootloader:**
Since macOS mandatorily uses UEFI, the custom emulator must include its own UEFI bootloader. EDK2 (TianoCore) is an open-source UEFI development environment compliant with UEFI standards, making its utilization the most standard approach [[7](https://wiki.osdev.org/EDK2)]. Hardware platforms should be defined based on ArmVirtPkg and optimized for macOS booting. Particularly, implementing Apple Silicon-compatible UEFI firmware should support macOS recognizing boot media, reading EFI partitions, and executing customized bootloaders like OpenCore [[55](https://superuser.com/questions/1684886/qemu-aarch64-on-arm-mac-never-boots-and-only-shows-qemu-prompt), [64](https://github.com/utmapp/UTM/discussions/3930)]. As evidenced by UTM using Apple-signed EDK2 variants, upstream EDK2 alone is insufficient, and compatibility with Apple's bootloader (OpenCore) must be ensured [[55](https://superuser.com/questions/1684886/qemu-aarch64-on-arm-mac-never-boots-and-only-shows-qemu-prompt)].

**Hardware Virtualization and Paravirtualized Drivers:**
The custom emulator should simulate physical hardware while ensuring the macOS kernel recognizes it as paravirtualized devices.

*   **VirtIO Implementation:** Since VirtIO is supported by built-in drivers from macOS Monterey onwards, the custom emulator must implement devices like disk (virtio-blk), network (virtio-net), and GPU (virtio-gpu) that operate according to the VirtIO protocol [[9](https://talk.tidbits.com/t/how-to-run-older-macos-versions-on-a-newer-mac/31436)]. VirtIO driver implementation can proceed by referencing QEMU's `virtio-blk.c` and `virtio-gpu.c` code [[56](https://brennan.io/2020/03/22/sos-block-device/)]. This enables efficient communication with the hypervisor rather than emulation, dramatically improving GPU acceleration, networking, and disk I/O performance.

*   **GPU Acceleration:** GPU acceleration through the Metal API is a key factor determining macOS GUI performance. The custom emulator should register specific device IDs through UEFI to expose the Metal API to the macOS kernel and ensure macOS internal Metal drivers recognize them. This is a very complex task requiring deep analysis of macOS GPU driver structure [[40](https://the-sequence.com/mac-virtualization)]. Similar to how UTM supports OpenGL using `virgl`, the custom emulator should explore direct Metal support or Metal-to-Vulkan/DirectX conversion for compatibility.

*   **DriverKit-based HID:** Considering the future, developing virtual HID devices using DriverKit may be important, though this requires considerable development effort [[39](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice)]. This is supported from macOS Ventura onwards but requires Apple developer credentials and entitlements for development.

**File System and Disk I/O:**
Since macOS uses APFS (Archived POSIX File System) as its default file system, the custom emulator must create and manage virtual disk images supporting APFS. Supporting cloneable image formats like QEMU's qcow2 would be advantageous for easily creating and testing multiple VM instances [[12](https://tinyapps.org/docs/arm-vms.html)]. Implementing VirtIO-blk drivers is essential for maximizing disk I/O performance [[56](https://brennan.io/2020/03/22/sos-block-device/)].

### 3.3 Development Phases and Goal Setting

Custom emulator development can be divided into the following phases.

**Phase 1: Minimal Bootable Image Creation**
The goal is to construct the emulator's minimal executable environment. In this phase, implement the UEFI bootloader and generate Apple Silicon-compatible firmware images using EDK2 to integrate with QEMU's `virt` manifest. This firmware should only aim to load and execute kernel images (.img). The quality gate for determining success in this phase is "the emulator successfully loads the kernel image and outputs a specific string ('Starting kernel') in the kernel log."

**Phase 2: VirtIO-based I/O Implementation**
After kernel booting, verify that core I/O devices like disk, network, and GPU are recognized by the macOS kernel. In this phase, implement the VirtIO protocol so that `virtio-blk`, `virtio-net`, and `virtio-gpu` devices are loaded by macOS kernel's built-in drivers, and basic I/O operations (file read/write, IP connection, graphics initialization) are successfully performed. The quality gate is "all VirtIO devices output 'loaded' messages in the macOS kernel log, and basic functionality of each device works."

**Phase 3: GUI and SIP Control**
After confirming stable kernel booting and I/O device operation, the goal is to drive the GUI desktop environment. In this phase, activate graphics output through the `virtio-gpu` device and disable SIP to enable Kext injection. The quality gate is "the emulator boots the macOS installation media and the installer's GUI displays normally."

**Phase 4: Full Feature Implementation**
The final goal is to complete a custom emulator with equivalent functionality to the QEMU-based emulator constructed in the first milestone. In this phase, implement advanced features like performance optimization, PCIe Passthrough, Metal GPU acceleration, and DriverKit-based HID. The quality gate for determining success in this phase is "the emulator installs macOS Monterey ARM64, disables SIP to inject custom Kexts, and executes basic applications (e.g., Finder, Safari) normally."

Through these phased goals and concrete quality gates, the complex and long-term custom emulator development project can be systematically managed and successfully completed.

## LLM-Based Automated Testing and Development Workflow Design

Introducing LLM (Large Language Model) agents as part of the development process has great potential for automation, productivity enhancement, and solving complex technical problems. However, given LLM's characteristics of output uncertainty and security risks, structured workflows and clear quality management systems are essential for effective utilization. This section designs an LLM-based automated testing and development workflow based on user requirements ("set quality gates in prompts to ensure agents complete tasks within a single session") and presents specific prompt engineering strategies for implementation.

### 4.1 Quality Gate Specification and Prompt Design Principles

The user requirement of "100% completion of targeted functionality in the task" as a quality gate is very abstract and does not provide clear work objectives for LLMs. Therefore, concrete and measurable quality gates must be defined for each test and explicitly included in prompts. Adopting structured methodologies like the Roo framework for prompt design is important [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)].

**Quality Gate Specification:**
Quality Gates should be defined as conditions that can be clearly judged as 'success' or 'failure'.

*   **Success Case:** "QEMU successfully boots Alpine Linux ARM64 ISO with the `-boot d` option and outputs the 'Welcome to Alpine Linux' message to the console." [[54](https://unix.stackexchange.com/questions/682733/cannot-boot-aarch64-alpine-linux-on-mac-os-using-qemu-6-2-0)]
*   **Failure Case:** "QEMU attempts Alpine Linux ARM64 ISO with the `-boot d` option but displays only the `(qemu)` prompt with no output."
*   **Function Completion Case:** "The QEMU command generated by LLM boots the macOS Monterey ARM64 installation media and displays the installer's GUI normally, returning `is_success: true`."

**Five Principles of Prompt Design:**
1.  **Context:** "We are developing an ARM64 macOS emulator based on QEMU for a project aiming to run macOS Monterey ARM64 on various hardware." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
2.  **Scope:** "Your task is to generate a single, executable shell command for `qemu-system-aarch64` that boots an Alpine Linux ARM64 ISO using the latest version of QEMU with native virtualization enabled." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
3.  **Expected Output:** "The output must be a single, executable `qemu-system-aarch64` command string with all necessary arguments clearly defined. The command should not include any comments or explanations outside of the code block." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
4.  **Additional Resources:** "You have access to the internet for research. However, you must use only official documentation and community forums for information." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
5.  **Project Rules Enforcement:** "Do not use any Unicode characters or emojis in your response. Use only relative paths in any scripts. The final document must be timestamped at the beginning with 'Last updated: YYYY-MM-DD'." [[20](https://www.linkedin.com/pulse/quality-gate-system-makes-llm-code-production-ready-devonte-emokpae-urpxf)]

Such structured prompts provide LLMs with clear work scope and expected results, preventing unnecessary questions or creative interpretations, and enhancing work accuracy and consistency.

### 4.2 Output Enforcement through JSON Schema

Considering that LLM outputs do not always follow consistent and predictable formats, enforcing output standardization through JSON Schema is very important. This ensures that LLM-generated results can be easily parsed and processed by subsequent automation scripts or other systems. Provider-native structured output APIs like OpenAI's `response_format: { type: 'json_schema' }` can be utilized, or libraries like Zod can be used to validate LLM outputs [[19](https://dev.to/dthompsondev/llm-structured-json-building-production-ready-ai-features-with-schema-enforced-outputs-4j2j)].

Below is an example JSON Schema for test tasks given to LLM agents:

```json
{
  "type": "object",
  "properties": {
    "task_id": {
      "type": "string",
      "description": "Unique identifier for the task being performed."
    },
    "shell_command": {
      "type": "string",
      "description": "The complete qemu-system-aarch64 command generated by the agent."
    },
    "rationale": {
      "type": "string",
      "description": "Brief explanation of why this specific command was chosen."
    },
    "expected_outcome": {
      "type": "string",
      "description": "Description of what the command is expected to achieve."
    },
    "is_success": {
      "type": "boolean",
      "description": "True if the command successfully achieves its outcome, false otherwise."
    }
  },
  "required": ["task_id", "shell_command", "rationale", "expected_outcome", "is_success"]
}
```

Including this schema in the prompt's system message gives LLMs a clear instruction that "generated content must be output only in the above JSON Schema format." This forces LLM outputs to always return as structured JSON objects, enabling reliable evaluation of quality gates (`is_success`) and easy handoff of agent work results to the next stage of automated workflows.

### 4.3 Security Design: Prompt Injection and Agent Action Control

Security is very important when LLM agents perform tasks that affect the system. Security design principles like 'Action-Selector', 'Plan-Then-Execute', and 'Dual LLM' patterns should be applied to isolate and control user input from directly connecting to agent actions [[29](https://news.ycombinator.com/item?id=44268335), [30](https://simonwillison.net/2025/Jun/13/prompt-injection-design-patterns/)]. Particularly, tasks where agents execute root-privileged scripts or modify system settings must be handled very carefully.

**Prompt Injection Attack Defense:**
Attacks injecting hidden malicious commands using techniques like Unicode tag characters are possible [[31](https://www.robustintelligence.com/blog-posts/understanding-and-mitigating-unicode-tag-prompt-injection), [32](https://blogs.cisco.com/ai/understanding-and-mitigating-unicode-tag-prompt-injection)]. To defend against this, frameworks processing LLM agent inputs should first normalize all inputs through Unicode normalization (NFKC), then filter disallowed invisible characters through grapheme cluster analysis [[33](https://repello.ai/blog/prompt-injection-using-emojis)]. Additionally, layer filtering should be applied to detect Token Expansion Attacks as specified in OWASP Top 10 LLM Vulnerabilities [[34](https://www.prompt.security/blog/unicode-exploits-are-compromising-application-security)].

**Agent Action Control:**
The 'Action-Selector' pattern for LLM agents pre-defines a list of actions the agent can perform and makes the agent select which action to perform. This prevents agents from executing arbitrary commands and ensures all work occurs only within pre-approved scopes. Additionally, the 'Plan-Then-Execute' pattern has agents first plan their work and only execute after the plan's validity is verified, enhancing work safety [[29](https://news.ycombinator.com/item?id=44268335)].

**Agents Rule of Two Application:**
Until robust prompt injection detection is resolved, LLM agents should not simultaneously satisfy all three properties: 'untrustworthy inputs', 'access sensitive systems/private data', and 'change state or communicate externally'. If all three properties are needed, Human-in-the-loop (HITL) supervision is mandatory [[28](https://simonw.substack.com/p/new-prompt-injection-papers-agents)]. Therefore, if LLM agents perform tasks receiving user input to modify system settings, the design should require final approval through HITL.

Integrating these security design principles into workflows enables safe and reliable utilization of LLM agents in production environments.

### 4.4 Example Test Prompt for LLM Agents

Below is an example English prompt for an LLM agent attempting to boot macOS Monterey ARM64 installation media, applying all previously discussed principles.

---
# Task Title: Generate QEMU Command to Boot macOS Monterey ARM64 Installer
## Context
We are developing an ARM64 macOS emulator as part of a larger project. Our goal is to run macOS Monterey (12.x) ARM64 on various hardware configurations. This task involves generating a QEMU command to boot the macOS Monterey ARM64 installer image.
## Scope
Your task is to generate a single, executable `qemu-system-aarch64` command that boots the provided macOS Monterey ARM64 BaseSystem.dmg image. The command must be designed for an Apple Silicon host (M1/M2) to leverage native virtualization for maximum performance.
## Expected Output
Return a JSON object strictly conforming to the following schema:
{
  "type": "object",
  "properties": {
    "task_id": {"type": "string"},
    "shell_command": {"type": "string"},
    "rationale": {"type": "string"},
    "expected_outcome": {"type": "string"},
    "is_success": {"type": "boolean"}
  },
  "required": ["task_id", "shell_command", "rationale", "expected_outcome", "is_success"]
}
## Additional Resources
Use the official QEMU documentation for `qemu-system-aarch64`. For UEFI firmware, use the standard EDK2 AArch64 firmware located at `/usr/share/edk2/aarch64/QEMU_EFI.fd`.
## Project Rules Enforcement
Ensure your response contains NO Unicode characters or emojis. Use only relative paths in any script examples. The final output must be a valid JSON object.
---

This prompt integrates structuring, quality management, security, and project rules to provide LLM agents with clear and safe instructions. Building development workflows in this manner enables LLMs to be utilized as powerful partners in development, innovatively enhancing project speed and quality.

## Strategic Conclusion and Future Direction

This technical specification presents a concrete implementation plan for the challenging project of "running arm64 macOS on general x86/arm devices." Analysis results indicate that project success depends on recognizing realistic technical limitations and achieving success through systematic milestone-based approaches. **The professional and systematic research and development methodology ensures that Phase 1 is thoroughly validated within the WSL environment before considering more complex deployment scenarios.** Particularly, the success of the first milestone is critical to the entire project, and the feasibility of execution on x86 hardware is deemed unrealistic at initial stages.

### 5.1 Core Strategic Recommendations for the Project

**Focus on First Milestone (WSL Implementation):** The foundation of the project lies in the stable construction of the ARM-based macOS Monterey emulator **within the WSL environment**. All resources and focus should be concentrated on successfully integrating the three core technologies: UEFI firmware, VirtIO drivers, and Kext injection, while accounting for WSL's virtualization constraints. Analyzing and adapting existing solutions like UTM for WSL compatibility may be the most practical approach [[12](https://tinyapps.org/docs/arm-vms.html), [42](https://github.com/utmapp/UTM/discussions/3458)]. Achieving basic GUI desktop environment operation through software rendering in WSL is the primary goal, rather than pursuing native virtualization features unavailable in this environment.

**Re-evaluation of x86 Host Execution Feasibility:** Among user objectives, "execution on x86 devices" is currently very unrealistic. macOS Monterey ARM64 does not support ARM64 TCG (instruction translation), and requires unique Apple Silicon features like Pointer Authentication, making emulation on x86 CPUs nearly impossible [[50](https://hackernoon.com/virtualization-and-emulation-on-macos)]. Therefore, this aspect should be explicitly stated as "future research" or "impossible goal" in initial specifications, and priority should be shifted to higher ARM-based execution. Setting realistic goals is important for increasing project success probability.

**Efficient Utilization of LLM Agents:** Introducing LLM agents as part of the development process is very promising, but their success depends on well-designed prompts and clear quality gates. Adopting structured methodologies like the Roo framework and enforcing output standardization through JSON Schema is important [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team), [19](https://dev.to/dthompsondev/llm-structured-json-building-production-ready-ai-features-with-schema-enforced-outputs-4j2j)]. Additionally, recognizing LLM 'Hallucination' and 'Consistency Drift' issues, mechanisms for repeatedly validating agent outputs should be established [[21](https://natesnewsletter.substack.com/p/the-prompt-doctor-is-in-fixes-for)]. Security design principles like 'Action-Selector' and 'Plan-Then-Execute' patterns must be applied [[29](https://news.ycombinator.com/item?id=44268335), [30](https://simonwillison.net/2025/Jun/13/prompt-injection-design-patterns/)].

### 5.2 Future Direction and Technical Expansion

Upon successful completion of the first milestone, the project can naturally expand to the second and third milestones.

*   **Second Milestone Expansion:** Based on the emulator constructed in the first milestone, deepen and optimize compatibility testing for various hardware configurations (SMBIOS). Research advanced features like PCIe Passthrough to enable the emulator to possess stability and functionality similar to real hardware beyond just a virtual environment.

*   **Third Milestone Expansion:** After enhancing performance through QEMU forks and adding new features, gradually progress to developing a completely independent custom emulator based on systematic development experience. This is the ultimate goal for maximizing the project's technical maturity.

*   **Future Version Support:** Once successful execution of macOS Monterey is confirmed, progressively expand support to subsequent versions like Ventura and Sonoma. Each version requires different UEFI features, Kexts, and Boot Args, so the emulator must be updated accordingly.

*   **Security and Stability Enhancement:** Expand the LLM agent-utilized development workflow to automated testing, bug tracking, and documentation. Additionally, continuously improve emulator security and enhance system resource management functionality to provide a more stable and efficient environment.

In conclusion, while the user's project has very challenging goals, it can possess feasibility through systematic division and strategic approaches recognizing realistic technical limitations. Securing the success of the first milestone and progressively advancing to the second and third milestones based on those achievements is the most reasonable path. This project has the potential to open new horizons in macOS virtualization technology, and successful results can be achieved through consistent effort and systematic execution.