# macOS Monterey ARM64 실행 환경 구축 프로젝트 기획서

본 기획서는 ARM64 아키텍처의 macOS Monterey를 일반적인 ARM 및 x86 하드웨어에서 구동하는 것을 최종 목표로 하는 프로젝트의 기술적 비전과 구체적인 실행 계획을 제시합니다. 프로젝트는 기술적 복잡도와 의존성을 고려하여 세 가지 핵심 마일스톤으로 체계적으로 분리하고, 각 단계의 목표를 명확히 하여 순차적으로 성공적으로 수행함으로써 궁극적인 목표 달성을 추구합니다. 본 보고서는 각 마일스톤의 기술적 요구사항, 구현 전략, 잠재적 도전 과제 및 LLM(Large Language Model) 기반 자동화 개발 워크플로우의 설계 원칙을 심층적으로 분석합니다.

## 첫 번째 마일스톤: ARM 기반 맥OS 에뮬레이터 구축

첫 번째 마일스톤인 "ARM 기반 맥OS 에뮬레이터 구축"은 전체 프로젝트의 초석을 다지는 결정적인 단계입니다. 사용자의 명확한 목표는 "GUI 기반 데스크톱 환경 및 기본 앱 구동까지 가능하게 하는 것"이며, 이를 위해 QEMU를 활용한 에뮬레이터를 기반으로 UEFI 부팅 로더, Paravirtualized 장치(VirtIO), 그리고 필수적인 커널 확장 모듈(Kext) 삽입이라는 세 가지 핵심 기술 요소를 성공적으로 통합하는 것입니다. 이 단계의 성공 여부는 후속 마일스톤으로의 진입과 x86 하드웨어에서의 실행 가능성 검토에 직접적인 영향을 미칩니다. 따라서 이 단계에서는 현실적인 기술적 한계를 명확히 인식하고, Apple Silicon 환경에서의 최적화된 접근법을 우선적으로 채택하는 것이 중요합니다.

### 1.1. 핵심 기술 스택 및 아키텍처 설계

macOS Monterey ARM64 버전을 ARM 기반 가상 머신에서 실행하기 위해서는 현대적인 UEFI(Ultra Extensible Firmware Interface) 플랫폼이 필수적입니다. macOS는 이제 전통적인 BIOS 대신 UEFI를 사용하며, 특히 Apple Silicon 환경에서는 더 나아가 Apple의 고유한 부팅 메커니즘을 요구합니다 [[64](https://github.com/utmapp/UTM/discussions/3930)]. 따라서 단순히 QEMU의 `virt` 매니페스트만으로는 부팅이 불가능하며, EDK2(TianoCore) 프로젝트에서 제공하는 ArmVirtPkg를 기반으로 생성된 UEFI 펌웨어 이미지를 `-bios` 옵션으로 명시적으로 지정해야 합니다 [[7](https://wiki.osdev.org/EDK2), [8](https://ww2.coastal.edu/mmurphy2/oer/qemu/aarch64/)]. 이러한 Apple Silicon 호환 UEFI 펌웨어는 `/usr/share/edk2/aarch64/QEMU_EFI.fd`와 같이 표준 패키지 경로에 포함되어 있으며, 이를 사용하지 않으면 QEMU가 ISO 이미지를 인식하지 못하고 바로 `(qemu)` 모니터로 진입하여 부팅 실패로 이어집니다 [[54](https://unix.stackexchange.com/questions/682733/cannot-boot-aarch64-alpine-linux-on-mac-os-using-qemu-6-2-0), [55](https://superuser.com/questions/1684886/qemu-aarch64-on-arm-mac-never-boots-and-only-shows-qemu-prompt)].

Hypervisor로서 QEMU는 사실상 가상화 기술의 표준이며, 다양한 아키텍처를 지원하는 TCG(Tiny Code Generator)를 통해 강력한 에뮬레이션 능력을 제공합니다 [[49](https://www.theregister.com/2023/09/29/utm_apple_hypervisor_foss_fest/)]. 하지만 macOS Monterey부터 내장된 VirtIO 드라이버 지원을 통해 가상 장치 접근 방식이 근본적으로 변화했습니다 [[9](https://talk.tidbits.com/t/how-to-run-older-macos-versions-on-a-newer-mac/31436)]. VirtIO는 에뮬레이션 대신 하이퍼바이저와 운영체제 간의 효율적인 통신을 위한 파라볼티알라이즈드(Paravirtualized) 인터페이스를 제공하여 GPU 가속, 네트워킹, 디스크 I/O 성능을 획기적으로 향상시킵니다. 따라서 GUI 데스크톱 환경 구동을 위해서는 `virtio-gpu-pci` 장치를 필수적으로 추가해야 하며, 네트워크(`virtio-net-pci`) 및 디스크(`virtio-blk`) 장치 역시 VirtIO 드라이버를 통해 연결해야 합니다 [[10](https://gist.github.com/Vogtinator/293c4f90c5e92838f7e72610725905fd), [56](https://brennan.io/2020/03/22/sos-block-device/)]. 이는 에뮬레이션 대신 하이퍼바이저와의 효율적인 통신을 가능하게 하여 GPU 가속, 네트워킹, 디스크 I/O 등 성능을 획기적으로 향상시킵니다. macOS Monterey ARM64 VM의 핵심 성능 저해 요소 중 하나는 Metal GPU 가속의 부재입니다 [[40](https://the-sequence.com/mac-virtualization)]. UTM과 같은 일부 도구들은 `virgl`을 사용해 OpenGL 3.3+ 지원을 제공하지만, 실질적인 성능은 보증되지 않으며, 특정 경우(UTM on Asahi Linux)에서는 SPICE 관련 크래시 문제가 발생할 수 있습니다 [[27](https://github.com/utmapp/UTM/issues/4285), [38](https://discussion.fedoraproject.org/t/enable-spice-virtio-gpu-opengl-for-qemu/99965)]. 따라서 초기에는 `ramfb` 또는 `virtio-gpu-pci`만으로도 GUI를 구동하는 것 자체가 성공입니다.

### 1.2. GUI 데스크톱 환경 구축을 위한 단계별 실행 계획

GUI 데스크톱 환경까지 부팅하는 것은 단순한 커널 로딩을 넘어 여러 복잡한 요소의 조합이 필요합니다. 아래는 체계적인 실행 계획입니다.

**단계 1: macOS Monterey ARM64 설치 미디어 준비**
먼저, macOS Monterey ARM64 설치 미디어를 준비해야 합니다. UTM과 같은 도구들은 IPSW 파일을 직접 다운로드하고 처리하지만, 직접 QEMU를 사용한다면 `fetch-macOS-v2.py`와 같은 스크립트를 활용하여 App Store에서 받은 전체 설치 파일에서 `BaseSystem.dmg`를 추출해야 합니다 [[2](https://github.com/kholia/OSX-KVM), [12](https://tinyapps.org/docs/arm-vms.html)]. 이 이미지는 APFS 형식으로 포맷되어야 하며, QEMU는 `mtd` 디스크 tl러를 통해 이 이미지를 부팅 미디어로 인식합니다.

**단계 2: 가상 디스크 이미지 생성 및 포맷팅**
QEMU는 macOS가 요구하는 APFS 파티션 구조를 갖춘 가상 디스크 이미지를 필요로 합니다. 먼저 `qemu-img` 명령어를 사용하여 qcow2 포맷의 가상 하드디스크 이미지를 생성합니다. 예를 들어, 256GB 크기의 이미지를 생성하려면 `qemu-img create -f qcow2 mac_hdd_ng.img 256G` 명령을 사용합니다 [[2](https://github.com/kholia/OSX-KVM)]. 생성된 이미지를 QEMU에 연결한 후, macOS 설치 과정에서 Disk Utility를 이용하여 APFS로 포맷해야 합니다.

**단계 3: 초기 부팅 시도 및 문제 해결**
아래는 Apple Silicon(M1/M2) 호스트에서 macOS Monterey ARM64를 부팅하기 위한 QEMU 명령어 예시입니다. 이 명령어는 Native Virtualization(Framework)인 HVF(Hypervisor.Framework)를 사용하여 최대한 높은 성능을 발휘하도록 구성되었습니다 [[8](https://ww2.coastal.edu/mmurphy2/oer/qemu/aarch64/), [37](https://github.com/knazarov/homebrew-qemu-virgl)].

```bash
qemu-system-aarch64 \
  -M virt \
  -cpu host \
  -accel hvf \
  -m 4G \
  -smp 4 \
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive file=BaseSystem.img,if=mtd \
  -drive file=mac_hdd_ng.img,if=virtio \
  -device ramfb \
  -device virtio-gpu-pci \
  -nic user,model=virtio-net-pci \
  -display cocoa,gl=on
```

이 명령어는 다음과 같은 주요 옵션을 포함합니다.
*   `-M virt`: QEMU의 가상 ARM64 플랫폼을 지정합니다.
*   `-cpu host`: 호스트 CPU 모델을 사용하여 최적의 성능을 확보합니다 [[42](https://github.com/utmapp/UTM/discussions/3458)].
*   `-accel hvf`: Apple Silicon 호스트에서 native virtualization을 활성화합니다. KVM은 Linux ARM 호스트에서 사용됩니다 [[8](https://ww2.coastal.edu/mmurphy2/oer/qemu/aarch64/)].
*   `-bios ...`: macOS 부팅에 필요한 Apple Silicon 호환 UEFI 펌웨어를 지정합니다.
*   `-drive file=...,if=mtd`: macOS 설치 미디어를 mtd 컨트롤러를 통해 연결합니다.
*   `-drive file=...,if=virtio`: APFS 포맷된 가상 디스크 이미지를 VirtIO 디스크 컨트롤러를 통해 연결합니다.
*   `-device ramfb`: 기본 소프트웨어 GPU 렌더링을 위한 플레인(fb) 장치입니다. `virtio-gpu-pci`가 작동하지 않을 경우를 대비하여 기본 장치를 제공합니다 [[10](https://gist.github.com/Vogtinator/293c4f90c5e92838f7e72610725905fd)].
*   `-device virtio-gpu-pci`: GUI 데스크톱 환경을 위한 파라볼티알라이즈드 GPU 장치입니다.
*   `-nic user,model=virtio-net-pci`: 파라볼티알라이즈드 네트워크 카드를 연결합니다.
*   `-display cocoa,gl=on`: Cocoa 디스플레이 백엔드를 사용하고, Metal/GPU 가속을 활성화합니다 [[37](https://github.com/knazarov/homebrew-qemu-virgl)].

**단계 4: Post-Install Kext 삽입 및 SIP 비활성화 (핵심)** 설치가 완료된 후에는 System Integrity Protection(SIP)을 비활성화하고 필요한 커널 확장 모듈(Kext)들을 삽입해야 합니다. 이는 OpenCore의 NVRAM 설정을 모방하여 EFI 파티션의 NVRAM 변수를 수정하거나, 설치된 시스템의 NVRAM을 직접 수정하는 방식으로 수행해야 합니다.
*   **SIP 비활성화:** macOS Catalina 이상부터는 SIP를 비활성화하려면 `csrutil disable` 명령어를 Recovery 환경에서 사용해야 하지만, 이는 QEMU 환경에서 직접 수행하기 어렵습니다. 따라서 NVRAM 변수를 직접 수정하는 방법이 필요합니다. GUID `7C436110-AB2A-4BBB-A880-FE41995C9F82`의 `csr-active-config` 값을 `00000000`으로 설정하면 SIP가 완전히 비활성화됩니다 [[66](https://www.insanelymac.com/forum/topic/352952-booting-monterey-into-single-user-mode-to-disable-sip/), [67](https://dortania.github.io/OpenCore-Install-Guide/troubleshooting/extended/post-issues.html)]. 이를 위해 UTM이나 직접적인 접근이 가능해야 합니다.
*   **필수 Kext 삽입:** macOS 부팅에 필수적인 Kext 스택은 다음과 같습니다.
    *   `Lilu.kext`: 대부분의 다른 Kext들이 의존하는 핵심 라이브러리입니다 [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)].
    *   `VirtualSMC.kext`: 가상 SMC(Sensor Management Controller)를 제공하여 macOS가 하드웨어를 올바르게 감지할 수 있도록 합니다 [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)].
    *   `WhateverGreen.kext`: GPU 관련 패칭을 담당하며, 그래픽 카드 인식, 해상도 설정, 멀티미디어 지원 등을 처리합니다 [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/), [57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)].
    *   `BlueToolFixup.kext`: Bluetooth 지원을 위한 필수 Kext입니다 [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)].
    *   추가적으로 USB, Bluetooth, Ethernet 칩셋에 맞는 Kext들을 삽입해야 합니다. 예를 들어, Realtek RTL8111 칩셋은 `AppleIGB.kext`가 필요하며 [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)], Intel Bluetooth는 `BlueToolFixup.kext`를 사용해야 합니다 [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)]. 이러한 Kext들은 ProperTree와 같은 도구를 사용하여 `config.plist`에 정확하게 추가해야 하며, 오른쪽 Kext 항목은 OpenCore의 NVRAM 설정을 모방하여 수행해야 합니다 [[52](https://dortania.github.io/OpenCore-Install-Guide/config.plist/)].

| Kext 이름 | 역할 및 필요성 |
| :--- | :--- |
| Lilu.kext | 필수적인 종속성 제공 [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |
| VirtualSMC.kext | 가상 SMC 제공 [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |
| WhateverGreen.kext | GPU 패칭 및 멀티미디어 지원 [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/), [57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |
| BlueToolFixup.kext | Bluetooth 지원 (Monterey+) [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)] |
| AppleIGB.kext | Realtek Ethernet 칩셋 지원 [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)] |
| VoodooI2C / VoodooPS2 | 입력 장치(I2C, PS/2) 지원 (선택 사항) [[57](https://gist.github.com/Nihhaar/a85d4cd4507f131144dd3706161e17fd)] |

### 1.3. 성능 최적화 및 잠재적 문제 해결

GUI 데스크톱 환경 구축 후에는 성능을 최적화하고 잠재적인 문제를 해결하는 작업이 필요합니다.
*   **GPU 가속:** `virtio-gpu-pci` 장치를 사용하면 기본적인 GUI 렌더링은 가능하지만, Metal API를 통한 고성능 그래픽 가속은 지원되지 않습니다 [[40](https://the-sequence.com/mac-virtualization)]. UTM v3.0.1 beta 이상에서는 `cocoa,gl=es` 옵션과 함께 `virtio-gpu-gl-pci` 장치를 사용하여 OpenGL ES 3.0을 노출시키는 실험이 이루어졌으나, 실제 성능은 장치에 따라 다르며, 특정 환경에서는 SPICE 관련 크래시 문제가 발생할 수 있습니다 [[37](https://github.com/knazarov/homebrew-qemu-virgl), [38](https://discussion.fedoraproject.org/t/enable-spice-virtio-gpu-opengl-for-qemu/99965)]. 초기 목표는 Metal 가속보다는 `virtio-gpu-pci`를 통해 안정적인 2D GUI 렌더링이 가능한 상태를 확보하는 것입니다.
*   **메모리 관리:** macOS Monterey ARM64 VM에서 Activity Monitor가 메모리 사용량을 과장하여 시스템에 부담을 줄 수 있다는 점을 인지해야 합니다 [[45](https://discussions.apple.com/thread/253543188)]. 이는 하드웨어 가상화보다 TCG Emulation에서 더 심각할 수 있으며, 성능 저하의 원인이 될 수 있습니다. 따라서 가상 머신에 할당된 RAM 크기를 적절히 설정하고, 불필요한 애플리케이션을 최소화하여 시스템 리소스를 효율적으로 관리해야 합니다.
*   **디스크 I/O:** 디스크 I/O 성능은 사용되는 가상 디스크 컨트롤러와 이미지 형식에 크게 좌우됩니다. `virtio-blk`은 TCG Emulation 환경에서 IDE보다 훨씬 빠른 성능을 제공하지만, NVMe는 snapshotting과 같은 APFS 기능과 호환이 잘 되지 않아 불안정할 수 있습니다 [[65](https://github.com/adespoton/utmconfigs)]. 초기에는 `virtio-blk`을 사용하는 것이 가장 안정적인 선택입니다.
*   **네트워킹:** `user` 네트워크 모드는 기본적인 인터넷 연결을 제공하지만, 더 나은 성능과 기능을 위해서는 `bridged` 모드로 전환하는 것을 고려할 수 있습니다. UTM은 `vmnet-macos` 백엔드를 통해 Mac OS X 호스트에서의 네트워킹을 향상시키는 기능을 제공하지만, MAC 주소가 유지되지 않는다는 단점이 있습니다 [[37](https://github.com/knazarov/homebrew-qemu-virgl)].

이러한 단계들을 차근차근 수행하면서 첫 번째 마일스톤의 목표인 GUI 데스크톱 환경 구동을 성공적으로 달성하고, 이를 기반으로 두 번째 마일스톤으로 넘어가는 것이 현재로서는 가장 현실적이고 효율적인 접근법입니다.

## 두 번째 마일스톤: 실 기기 구동 조건 연구 및 실증

첫 번째 마일스톤에서 성공적으로 ARM 기반 macOS Monterey 에뮬레이터를 구축한 후, 두 번째 마일스톤은 이 환경을 다양한 실제 하드웨어에서 어떻게 최적화하고 구동시키는지를 연구하고 실증하는 데 집중합니다. 이 단계의 목적은 단순히 '호환성'을 확인하는 것을 넘어, 특정 하드웨어 모델(SMBIOS)을 재현하고, 해당 하드웨어에 맞는 SSDT(Serially Shadowed Device Table) 및 부트 인자(Boot Arguments)를 적용하여 macOS가 최대한 네이티브처럼 작동하도록 만드는 것입니다. 또한 PCIe Passthrough와 같은 고급 기능에 대한 연구를 포함하여, 에뮬레이터의 활용성을 극대화하는 방향으로 나아갑니다.

### 2.1. SMBIOS 및 하드웨어 재현

macOS는 특정 하드웨어 모델의 정보를 요구하는 SMBIOS(System Management BIOS) 데이터를 바탕으로 하드웨어를 인식하고, 필요한 드라이버와 기능을 활성화합니다. macOS Monterey(12.x)는 매우 엄격한 하드웨어 지원 정책을 가지고 있습니다. 예를 들어, iMac15,x 및 이전 모델, Macmini6,x 및 이전 모델, MacBookAir6,x 및 이전 모델 등은 지원이 중단되었으며, 지원되는 모델은 iMac16,1+, Macmini7,1+, MacBookAir7,1+ 등 현대적인 모델들만 해당합니다 [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html), [68](https://dortania.github.io/OpenCore-Legacy-Patcher/MONTEREY-DROP.html)]. 따라서 QEMU 가상 머신에서도 macOS가 호환되는 것으로 인식되도록 하려면, `config.plist` 파일을 참조하여 QEMU의 SMBIOS 설정을 적절히 변경해야 합니다. 이는 QEMU의 `-smbios` 옵션을 통해 구현할 수 있으며, 주요 파라미터로는 `board-id`, `serial-number`, `rom`, `smc-version` 등이 있습니다. 예를 들어, `Macmini7,1`을 모델로 설정하려면 `board-id=Mac-7BA5B2D9E42DDD94`와 같은 값을 지정해야 합니다. 이 과정은 macOS가 하드웨어를 인식하도록 유도하여, 이후에 필요한 드라이버와 패치가 정상적으로 로드되도록 하는 기초 작업입니다.

### 2.2. 하드웨어별 SSDT 및 부트 인자 적용

특정 하드웨어 구성(예: CPU, GPU)을 사용할 때 XNU 커널이 이를 올바르게 인식하고 제어할 수 있도록 하려면 SSDT 및 부트 인자를 적절히 적용해야 합니다.

**SSDT 적용:**
SSDT는 ACPI(Automated Configuration and Power Interface) 스펙에 따라 하드웨어의 동작을 설명하는 테이블입니다. QEMU는 가상 하드웨어를 제공하지만, macOS는 특정 드라이버를 위해 특정 SSDT를 요구할 수 있습니다.
*   **CPU/GPU 관리:** Haswell iGPU를 사용할 경우, macOS는 `Macmini7,1`과 같은 모델 드라이버를 사용하여 iGPU를 제어합니다 [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)]. 만약 호환되지 않는 SMBIOS를 사용할 경우, AMD CPU를 사용할 때 `algrey - Force cpuid_cores_per_package`와 같은 패치가 필요할 수 있습니다 [[1](https://dortania.github.io/OpenCore-Install-Guide/extras/monterey.html)]. 이러한 패치는 CPU의 물리적 코어 수를 XNU 커널에 올바르게 알려주어 안정적인 부팅을 보장합니다.
*   **NVRAM 및 전원 관리:** Coffee Lake 이상 CPU를 사용할 경우 `SSDT-AWAC-DISABLE.aml`을 적용하여 Wake-on-WLAN(WoWLAN)을 비활성화하여 부팅 문제를 해결할 수 있습니다 [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)]. 또한, 300-series 칩셋의 NVRAM 문제를 해결하기 위해 `SSDT-PMC.aml`이 필요할 수 있습니다 [[4](https://elitemacx86.com/threads/how-to-boot-macos-installer-on-desktops-and-laptops-using-opencore-uefi-legacy-opencore-install-guide.950/)]. 이러한 SSDT들은 OpenCore Legacy Patcher나 공개 자료를 통해 얻을 수 있으며, QEMU의 `-smbios type=11,file=...` 옵션을 통해 EFI 파티션에 포함시킬 수 있습니다.

**부트 인자(Boot Arguments) 활용:**
부트 인자는 macOS 부팅 시 커널과 시스템 서비스에 전달되는 명령줄 옵션으로, 디버깅, 성능 최적화, 특정 기능 활성화 등에 매우 유용합니다.
*   **기본 디버깅:** `-v`는 부팅 과정을 verbose(세부) 모드로 출력하여 문제 발생 지점을 파악하는 데 도움을 줍니다 [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `debug=0x100`은 커널 패닉 시 재부팅을 방지하여 디버깅 시간을 연장합니다 [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)].
*   **Kext 및 SIP 제어:** `kext-dev-mode=1`은 서명되지 않은 Kext를 허용하여 개발 및 수정 과정에서 유용합니다 [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `rootless=0`은 SIP를 비활성화하지만, 이는 `-s` 부트 인자가 아닌 `csr-active-config` NVRAM 변수를 통해 설정하는 것이 권장됩니다 [[66](https://www.insanelymac.com/forum/topic/352952-booting-monterey-into-single-user-mode-to-disable-sip/), [69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)].
*   **하드웨어 제어:** `dart=0`은 DART(DMA Address Translation) IOMMU를 비활성화하여 Thunderbolt 장치나 특정 네트워크 카드의 호환성을 높이는 데 사용될 수 있습니다 [[53](https://elitemacx86.com/threads/how-to-create-opencore-config-plist-file-for-booting-macos-on-desktops-and-laptops-intel-amd-opencore-config-plist-guide.1022/), [69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `framebuffer-stolenmem`은 잘못된 파라미터로, 정확한 파라미터는 `framebuffer-stolemem`이어야 합니다 [[66](https://www.insanelymac.com/forum/topic/352952-booting-monterey-into-single-user-mode-to-disable-sip/)].
*   **디버깅 용도:** `keepsyms=1`은 커널 심볼을 유지하여 kext 로딩 순서 문제나 기타 디버깅에 유용합니다 [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)]. `liludbgall`, `wegdbg`와 같은 특정 Kext의 디버그 로그를 활성화하는 부트 인자들도 존재합니다 [[69](https://elitemacx86.com/threads/common-boot-args-for-macos-clover-opencore.937/)].

이러한 SSDT와 부트 인자를 실험적으로 적용하고 결과를 분석하는 과정을 반복하여, 특정 하드웨어 구성에 맞는 최적의 설정을 찾아내는 것이 두 번째 마일스톤의 핵심입니다.

### 2.3. PCIe Passthrough 및 고급 기기 제어

PCIe Passthrough는 호스트 시스템의 물리적인 PCIe 장치(예: 네트워크 카드, 저장 장치)를 가상 머신으로 직접 연결하여 거의 네이티브 수준의 성능을 제공하는 기술입니다. 그러나 이는 매우 복잡하고 취약성이 많은 기술로, macOS 환경에서의 구현은 더욱 어려울 수 있습니다.
*   **기본 원리 및 제약:** QEMU의 PCIe Passthrough는 VM이 처음 시작될 때 장치의 PCIe 설명자(descriptor)를 읽어 static한 복사본을 생성한 후, 이 복사본을 기반으로 동작합니다. 따라서 장치 자체가 동적으로 설명자를 변경하는 경우(예: 펌웨어 업데이트) VM 내부에서 제대로 작동하지 않을 수 있습니다 [[13](https://news.ycombinator.com/item?id=41116473)]. 또한, 호스트에서 잘 작동하는 하드웨어가 VM 내부에서는 초기화에 실패하는 경우도 있으며, 이는 forwarding 코드의 버그 때문일 수 있습니다 [[13](https://news.ycombinator.com/item?id=41116473)].
*   **호환성 문제:** macOS Monterey ARM64 VM에서 물리적인 iOS 장치를 USB Passthrough로 연결하려 할 때, `usbmuxd` 프로세스가 `file-write-mode` 접근 거부 오류를 일으키면서 pairing이 실패하는 문제가 보고되었습니다 [[43](https://developer.apple.com/forums/tags/virtualization?page=2)]. 이는 macOS의 Sandbox 정책이 가상 환경 내에서 더 엄격하게 작동하기 때문으로 추정됩니다.
*   **실증 계획:** PCIe Passthrough는 초기 단계에서는 배제하고, 두 번째 마일스톤의 후반부에 고려할 수 있는 연구 주제로 삼습니다. 실험은 다음과 같은 순서로 진행됩니다.
    1.  호스트 시스템에서 사용 가능한 PCIe 장치를 식별합니다.
    2.  QEMU 명령어에 `-device vfio-pci,host=XX:XX.X`와 같은 옵션을 추가하여 장치를 VM에 연결합니다.
    3.  macOS 내부에서 장치가 인식되고, 해당 장치의 드라이버가 올바르게 로드되는지 확인합니다.
    4.  장치의 기능이 정상적으로 작동하는지(예: 네트워크 연결, 저장 장치 마운트) 테스트합니다.
    5.  장치의 상태 변화(예: 펌웨어 업데이트)가 VM에 영향을 미치는지 관찰합니다.

두 번째 마일스톤은 이러한 복잡한 하드웨어 문제들을 체계적으로 분석하고 해결책을 찾는 과정을 통해, 에뮬레이터가 단순한 가상 환경을 넘어 실제 하드웨어와 유사한 안정성과 기능성을 갖추도록 하는 중요한 단계입니다.

## 세 번째 마일스톤: ARM용 오픈코어 제작 및 커스텀 에뮬레이터 개발

첫 번째 마일스톤에서 구축한 QEMU 기반 에뮬레이터가 안정적으로 작동함을 입증하고, 두 번째 마일스톤에서 다양한 하드웨어 환경에 대한 최적화 경험을 축적한 후, 세 번째 마일스톤으로 나아갈 수 있습니다. 이 단계의 궁극적인 목표는 QEMU 포크(fork) 없이 완전히 독립적인 커스텀 에뮬레이터를 개발하여 ARM64용 macOS Monterey를 실행하는 것입니다. 이는 프로젝트의 기술적 성숙도를 증명하고, 향후 더 나은 성능, 유연성, 그리고 새로운 기능 구현을 위한 기반이 될 것입니다. 하지만 이는 수년간의 시간과 엄청난 개발 노력이 필요한 거창한 목표이므로, 현실적인 접근법과 체계적인 개발 계획이 필수적입니다.

### 3.1. QEMU 포크 vs. 커스텀 에뮬레이터: 전략적 경로 선택

QEMU를 포크하여 자신만의 버전을 만들지, 아니면 완전히 새로운 에뮬레이터를 설계해야 할지에 대한 결정은 프로젝트의 방향성을 결정하는 핵심적인 전략적 선택입니다.
*   **QEMU 포크의 장점:** QEMU는 이미 macOS ARM64 실행을 위한 거의 모든 핵심 기반 기술을 구현하고 있습니다. UEFI 부팅 로직, VirtIO 드라이버, 다양한 디스크/네트워크/USB 컨트롤러, 그리고 TCG 기반의 강력한 아키텍처 에뮬레이션 엔진이 모두 포함되어 있습니다 [[49](https://www.theregister.com/2023/09/29/utm_apple_hypervisor_foss_fest/)]. 따라서 QEMU를 포크하는 것은 기존의 거대한 코드베이스를 그대로 활용하면서 자신의 필요에 맞게 특정 부분(예: 성능 향상, 새로운 기기 추가)만 수정하는 상대적으로 현실적인 접근법입니다. 첫 번째 마일스톤에서 얻은 QEMU 수정 사항, UEFI 문제 해결 경험, VirtIO 드라이버 구현 경험 등은 바로 이 포크 작업에 큰 도움이 됩니다.
*   **커스텀 에뮬레이터의 장점 및 난이도:** 완전히 새로운 에뮬레이터를 만든다는 것은 운영체제, 하드웨어 가상화, 디스크/네트워크 I/O, 그리고 무엇보다 UEFI 부팅 로직을 모두 다시 설계하고 구현해야 한다는 뜻입니다. 이는 수많은 기술적 장벽을 넘어야 하는 매우 도전적인 작업입니다. 예를 들어, UEFI 부팅 로직은 EDK2 프로젝트의 복잡한 구조를 이해하고, 이를 QEMU의 코드베이스에 맞게 통합해야 합니다 [[7](https://wiki.osdev.org/EDK2)]. 또한, VirtIO와 같은 파라볼티알라이즈드 기술을 구현하기 위해서는 macOS 커널의 드라이버와의 상호 운용성을 깊이 있게 이해해야 합니다 [[9](https://talk.tidbits.com/t/how-to-run-older-macos-versions-on-a-newer-mac/31436)]. 이러한 작업은 수년간의 시간과 엄청난 개발 노력이 필요합니다.

결론적으로, 첫 번째 마일스톤의 깊이 있는 경험과 지식 축적 없이는 세 번째 마일스톤의 성공은 매우 어렵다고 판단됩니다. 따라서 프로젝트의 초기 단계에서는 QEMU 포크를 중심으로 개발을 진행하고, 특정 요구사항(예: QEMU의 복잡성 문제, 특정 기능의 부재 등)이 명확해지면 그때서야 커스텀 에뮬레이터 개발로 점진적으로 전환하는 순차적인 발전 계획이 가장 합리적입니다.

### 3.2. 커스텀 에뮬레이터 핵심 컴포넌트 설계

커스텀 에뮬레이터를 설계하기 위해선 몇 가지 핵심 컴포넌트를 고려해야 합니다. 이는 QEMU의 코드를 분석하고, macOS Monterey ARM64의 요구사항을 반영하여 설계해야 합니다.

**UEFI 부팅 로더:**
macOS는 UEFI를 필수적으로 사용하므로, 커스텀 에뮬레이터는 자체적인 UEFI 부팅 로더를 내장해야 합니다. EDK2(TianoCore)는 UEFI 표준을 준수하는 공개 소스 UEFI 개발 환경으로, 이를 활용하는 것이 가장 표준적인 방법입니다 [[7](https://wiki.osdev.org/EDK2)]. ArmVirtPkg를 기반으로 하드웨어 플랫폼을 정의하고, 이를 macOS 부팅에 맞게 최적화해야 합니다. 특히, Apple Silicon 호환 UEFI 펌웨어의 구현은 macOS가 부팅 미디어를 인식하고, EFI 파티션을 읽고, OpenCore와 같은 커스터마이징된 부팅 로더를 실행하는 과정을 지원해야 합니다 [[55](https://superuser.com/questions/1684886/qemu-aarch64-on-arm-mac-never-boots-and-only-shows-qemu-prompt), [64](https://github.com/utmapp/UTM/discussions/3930)]. 이는 UTM이 Apple-signed EDK2 variants를 사용한다는 사실에서 알 수 있듯, 단순히 업스트림 EDK2만으로는 부족하며, Apple의 부트 로더(OpenCore)와의 호환성을 보장하는 것이 중요합니다 [[55](https://superuser.com/questions/1684886/qemu-aarch64-on-arm-mac-never-boots-and-only-shows-qemu-prompt)].

**하드웨어 가상화 및 파라볼티알라이즈드 드라이버:**
커스텀 에뮬레이터는 물리적인 하드웨어를 시뮬레이션하는 동시에, macOS 커널이 이를 파라볼티알라이즈드 장치로 인식하도록 해야 합니다.
*   **VirtIO 구현:** VirtIO는 macOS Monterey부터 내장된 드라이버를 통해 지원되므로, 커스텀 에뮬레이터는 VirtIO 프로토콜에 따라 동작하는 디스크(virtio-blk), 네트워크(virtio-net), GPU(virtio-gpu) 등의 장치를 구현해야 합니다 [[9](https://talk.tidbits.com/t/how-to-run-older-macos-versions-on-a-newer-mac/31436)]. VirtIO 드라이버의 구현은 QEMU의 `virtio-blk.c` 및 `virtio-gpu.c` 코드를 참조하여 진행할 수 있습니다 [[56](https://brennan.io/2020/03/22/sos-block-device/)]. 이는 에뮬레이션 대신 하이퍼바이저와의 효율적인 통신을 가능하게 하여 GPU 가속, 네트워킹, 디스크 I/O 성능을 획기적으로 향상시킵니다.
*   **GPU 가속:** Metal API를 통한 GPU 가속은 macOS GUI의 성능을 좌우하는 핵심 요소입니다. 커스텀 에뮬레이터는 Metal API를 macOS 커널에 노출시키기 위해 UEFI를 통해 특정 기기 ID를 등록하고, macOS 내부의 Metal 드라이버가 이를 인식하도록 해야 합니다. 이는 매우 복잡한 작업으로, macOS의 GPU 드라이버 구조를 깊이 있게 분석해야 합니다 [[40](https://the-sequence.com/mac-virtualization)]. UTM이 `virgl`을 사용하여 OpenGL을 지원하는 것처럼, 커스텀 에뮬레이터는 Metal을 직접 지원하거나, Metal-to-Vulkan/DirectX 변환을 통해 호환성을 확보하는 방안을 모색해야 합니다.
*   **DriverKit 기반 HID:** 미래를 고려하면 DriverKit을 활용한 가상 HID 장치를 개발하는 것이 중요할 수 있으나, 이는 상당한 개발 노력이 필요합니다 [[39](https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice)]. 이는 macOS Ventura부터 지원되지만, 개발에는 Apple의 개발자 자격과 엔티itlement이 필요합니다.

**파일 시스템 및 디스크 I/O:**
macOS는 APFS(Archived POSIX File System)를 기본 파일 시스템으로 사용하므로, 커스텀 에뮬레이터는 APFS를 지원하는 가상 디스크 이미지를 생성하고 관리해야 합니다. QEMU의 qcow2 형식과 같은 클론 가능한 이미지 형식을 지원하면, 여러 VM 인스턴스를 쉽게 생성하고 테스트하는 데 유리합니다 [[12](https://tinyapps.org/docs/arm-vms.html)]. 디스크 I/O 성능을 극대화하기 위해 VirtIO-blk 드라이버를 구현하는 것이 필수적입니다 [[56](https://brennan.io/2020/03/22/sos-block-device/)].

### 3.3. 개발 단계 및 목표 설정

커스텀 에뮬레이터 개발은 다음 단계로 나눌 수 있습니다.

**단계 1: Minimal Bootable Image 생성**
에뮬레이터의 최소 실행 가능 환경을 구축하는 것을 목표로 합니다. 이 단계에서는 UEFI 부팅 로더를 구현하고, EDK2를 사용하여 Apple Silicon 호환 펌웨어 이미지를 생성하여 QEMU의 `virt` 매니페스트에 통합합니다. 이 펌웨어는 단순히 커널 이미지(.img)를 로드하고 실행하는 기능만을 목표로 합니다. 이 단계의 성공 여부를 판단하는 퀄리티 게이트는 "에뮬레이터가 커널 이미지를 성공적으로 로드하고, 커널 로그에 특정 문자열('Starting kernel')이 출력되는 것"입니다.

**단계 2: VirtIO 기반 I/O 구현**
커널 부팅 이후, 디스크, 네트워크, GPU 등 핵심 I/O 장치가 macOS 커널에 의해 인식되는지 확인합니다. 이 단계에서는 VirtIO 프로토콜을 구현하여 `virtio-blk`, `virtio-net`, `virtio-gpu` 장치가 macOS 커널의 내장 드라이버에 의해 로드되고, 기본적인 I/O 작업(파일 읽기/쓰기, IP 연결, 그래픽 초기화)이 성공적으로 이루어지는지를 테스트합니다. 퀄리티 게이트는 "모든 VirtIO 장치가 macOS 커널의 로그에 'loaded'라는 메시지를 출력하고, 각 장치의 기본 기능이 작동하는 것"입니다.

**단계 3: GUI 및 SIP 제어**
커널 부팅 및 I/O 장치가 안정적으로 작동함을 확인한 후, GUI 데스크톱 환경을 구동하는 것을 목표로 합니다. 이 단계에서는 `virtio-gpu` 장치를 통해 그래픽 출력을 활성화하고, SIP를 비활성화하여 Kext 삽입이 가능하도록 만듭니다. 퀄리티 게이트는 "에뮬레이터가 macOS 설치 미디어를 부팅하고, 설치 프로그램의 GUI가 정상적으로 표시되는 것"입니다.

**단계 4: Full Feature Implementation**
최종 목표는 첫 번째 마일스톤에서 구축한 QEMU 기반 에뮬레이터와 동등한 기능을 갖춘 커스텀 에뮬레이터를 완성하는 것입니다. 이 단계에서는 성능 최적화, PCIe Passthrough, Metal GPU 가속, DriverKit 기반 HID 등 고급 기능을 구현합니다. 이 단계의 성공 여부를 판단하는 퀄리티 게이트는 "에뮬레이터가 macOS Monterey ARM64를 설치하고, SIP를 비활성화하여 사용자 지정 Kext를 삽입한 후, 기본 애플리케이션(예: Finder, Safari)이 정상적으로 실행되는 것"입니다.

이러한 단계별 목표 설정과 구체적인 퀄리티 게이트를 통해, 복잡하고 장기적인 커스텀 에뮬레이터 개발 프로젝트를 체계적으로 관리하고 성공적으로 마무리할 수 있을 것입니다.

## LLM 기반 자동화 테스트 및 개발 워크플로우 설계

LLM(Large Language Model) 에이전트를 개발 프로세스의 일부로 도입하는 것은 자동화, 생산성 향상, 그리고 복잡한 기술 문제 해결에 큰 잠재력을 가지고 있습니다. 하지만 LLM의 특성상 출력의 불확실성과 보안 위험이 존재하기 때문에, 이를 효과적으로 활용하기 위해서는 구조화된 워크플로우와 명확한 품질 관리 체계가 필수적입니다. 본 섹션에서는 사용자가 제시한 요구사항("프롬프트에는 퀄리티 게이트 등을 설정하여 에이전트가 반드시 한 세션 안에 작업을 완료하도록 해 줘")을 바탕으로, LLM 기반의 자동화 테스트 및 개발 워크플로우를 설계하고, 이를 구현하기 위한 구체적인 프롬프트 엔지니어링 전략을 제시합니다.

### 4.1. Quality Gate의 구체화 및 프롬프트 설계 원칙

사용자의 요구사항인 "해당 태스크에서 목표한 기능 100% 완료"라는 퀄리티 게이트는 매우 추상적이며, LLM에게는 명확한 작업 목표를 제공하지 못합니다. 따라서 각 테스트마다 구체적이고 측정 가능한 퀄리티 게이트를 정의하고, 이를 프롬프트에 명시적으로 포함해야 합니다. Roo 프레임워크와 같은 구조화된 방법론을 채택하여 프롬프트를 설계하는 것이 중요합니다 [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)].

**Quality Gate의 구체화:**
Qualitative Gate는 '성공' 또는 '실패'로 명확하게 판단할 수 있는 조건으로 정의되어야 합니다.
*   **성공 사례:** "QEMU가 `-boot d` 옵션으로 Alpine Linux ARM64 ISO를 성공적으로 부팅하고, 콘솔에 'Welcome to Alpine Linux' 메시지를 출력한다." [[54](https://unix.stackexchange.com/questions/682733/cannot-boot-aarch64-alpine-linux-on-mac-os-using-qemu-6-2-0)]
*   **실패 사례:** "QEMU가 `-boot d` 옵션으로 Alpine Linux ARM64 ISO를 시도했으나, 아무런 출력 없이 `(qemu)` 프롬프트만 표시된다."
*   **기능 완료 사례:** "LLM이 생성한 QEMU 명령어가 macOS Monterey ARM64 설치 미디어를 부팅하고, 설치 프로그램의 GUI가 정상적으로 표시되면 `is_success: true`를 반환한다."

**프롬프트 설계의 5대 원칙:**
1.  **Context (맥락):** "We are developing an ARM64 macOS emulator based on QEMU for a project aiming to run macOS Monterey ARM64 on various hardware." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
2.  **Scope (범위):** "Your task is to generate a single, executable shell command for `qemu-system-aarch64` that boots an Alpine Linux ARM64 ISO using the latest version of QEMU with native virtualization enabled." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
3.  **Expected Output (예상 출력):** "The output must be a single, executable `qemu-system-aarch64` command string with all necessary arguments clearly defined. The command should not include any comments or explanations outside of the code block." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
4.  **Additional Resources (추가 자원):** "You have access to the internet for research. However, you must use only official documentation and community forums for information." [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team)]
5.  **Project Rules Enforcement:** "Do not use any Unicode characters or emojis in your response. Use only relative paths in any scripts. The final document must be timestamped at the beginning with 'Last updated: YYYY-MM-DD'." [[20](https://www.linkedin.com/pulse/quality-gate-system-makes-llm-code-production-ready-devonte-emokpae-urpxf)]

이러한 구조화된 프롬프트는 LLM에게 명확한 작업 범위와 기대 결과를 제공하여 불필요한 질문이나 창의적인 해석을 방지하고, 작업의 정확성과 일관성을 높입니다.

### 4.2. JSON Schema를 통한 출력 강제 규격화

LLM의 출력이 항상 일관되고 예측 가능한 형식을 따르지 않는다는 점을 고려할 때, 출력을 JSON Schema를 통해 강제 규격화하는 것이 매우 중요합니다. 이는 LLM이 생성한 결과물을 후속 자동화 스크립트나 다른 시스템이 쉽게 파싱하고 처리할 수 있도록 보장합니다. OpenAI의 `response_format: { type: 'json_schema' }`와 같은 provider-native structured output APIs를 활용하거나, Zod와 같은 라이브러리를 사용하여 LLM의 출력을 검증할 수 있습니다 [[19](https://dev.to/dthompsondev/llm-structured-json-building-production-ready-ai-features-with-schema-enforced-outputs-4j2j)].

다음은 LLM 에이전트에게 주어질 테스트 태스크를 위한 JSON Schema 예시입니다:

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

이러한 스키마를 프롬프트의 시스템 메시지에 포함시켜 LLM에게 "생성된 내용은 위의 JSON Schema 형식으로만 출력해야 한다"는 명확한 지시를 줍니다. 이는 LLM의 출력이 항상 구조화된 JSON 객체 형태로 반환되도록 강제하여, 퀄리티 게이트(`is_success`)를 신뢰성 있게 평가하고, 에이전트의 작업 결과를 자동화된 워크플로우의 다음 단계로 손쉽게 전달할 수 있습니다.

### 4.3. 보안 설계: Prompt Injection 및 Agent Action 제어

LLM 에이전트가 시스템에 영향을 미치는 작업을 수행할 때는 보안이 매우 중요합니다. 'Action-Selector', 'Plan-Then-Execute', 'Dual LLM' 패턴과 같은 보안 설계 원칙을 적용하여, 사용자의 입력이 에이전트의 행동으로 바로 연결되지 않도록 격리하고 제어해야 합니다 [[29](https://news.ycombinator.com/item?id=44268335), [30](https://simonwillison.net/2025/Jun/13/prompt-injection-design-patterns/)]. 특히, 에이전트가 root 권한을 가진 스크립트를 실행하거나 시스템 설정을 변경하는 작업은 매우 신중하게 다뤄야 합니다.

**Prompt Injection 공격 방어:**
Unicode tag character와 같은 기법을 사용하여 숨겨진 악의적인 명령을 주입하는 공격이 가능합니다 [[31](https://www.robustintelligence.com/blog-posts/understanding-and-mitigating-unicode-tag-prompt-injection), [32](https://blogs.cisco.com/ai/understanding-and-mitigating-unicode-tag-prompt-injection)]. 이를 방어하기 위해, LLM 에이전트의 입력을 처리하는 프레임워크는 먼저 모든 입력을 Unicode normalization(NFKC)을 거쳐 정규화하고, grapheme cluster analysis를 통해 disallowed invisible characters를 필터링해야 합니다 [[33](https://repello.ai/blog/prompt-injection-using-emojis)]. 또한, OWASP Top 10 LLM Vulnerabilities에 명시된 Token Expansion Attack을 탐지하기 위한 layer filtering을 적용해야 합니다 [[34](https://www.prompt.security/blog/unicode-exploits-are-compromising-application-security)].

**Agent Action 제어:**
LLM 에이전트의 'Action-Selector' 패턴은 에이전트가 수행할 수 있는 작업(Action)의 목록을 미리 정의하고, 에이전트가 어떤 작업을 수행할지 선택하도록 만듭니다. 이는 에이전트가 임의의 명령을 실행하는 것을 방지하고, 모든 작업이 사전에 승인된 범위 내에서만 이루어지도록 보장합니다. 또한, 'Plan-Then-Execute' 패턴은 에이전트가 먼저 작업을 계획(plan)하고, 그 계획이 유효성을 검사된 후에야 실제로 실행(execute)하는 방식으로 작업의 안전성을 높입니다 [[29](https://news.ycombinator.com/item?id=44268335)].

**Agents Rule of Two 적용:**
Robust prompt injection detection이 해결되지 않는 한, LLM 에이전트는 'untrustworthy inputs', 'access sensitive systems/private data', 'change state or communicate externally'라는 세 가지 속성을 동시에 만족해서는 안 됩니다. 만약 모든 세 가지 속성이 필요하다면, Human-in-the-loop(HITL) supervision이 반드시 필요합니다 [[28](https://simonw.substack.com/p/new-prompt-injection-papers-agents)]. 따라서 LLM 에이전트가 사용자로부터 입력을 받아 시스템 설정을 변경하는 작업을 수행한다면, HITL를 통해 최종 승인을 받도록 설계해야 합니다.

이러한 보안 설계 원칙들을 워크플로우에 통합함으로써, LLM 에이전트를 프로덕션 환경에서 안전하고 신뢰성 있게 활용할 수 있습니다.

### 4.4. LLM 에이전트를 위한 테스트 프롬프트 예시

아래는 앞서 논의한 모든 원칙을 적용한, macOS Monterey ARM64 설치 미디어 부팅을 시도하는 LLM 에이전트에게 주어질 영문 프롬프트 예시입니다.

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

이 프롬프트는 구조화, 품질 관리, 보안, 그리고 프로젝트 규칙을 모두 통합하여 LLM 에이전트에게 명확하고 안전한 지시를 내릴 수 있게 합니다. 이와 같은 방식으로 개발 워크플로우를 구축하면, LLM을 개발의 강력한 파트너로 활용하여 프로젝트의 속도와 품질을 혁신적으로 향상시킬 수 있습니다.

## 전략적 결론 및 미래 방향성

본 기획서는 'arm64용 맥OS를 일반 x86/arm 기기에서 구동'하는 것을 목표로 하는 도전적인 프로젝트의 구체적인 실행 계획을 제시했다. 분석 결과, 프로젝트의 성패는 현실적인 기술적 한계를 인지하고, 체계적인 마일스톤별 접근법을 통해 단계적으로 성공을 거두는 데 달려있다. 특히, 첫 번째 마일스톤의 성공이 전체 프로젝트의 핵심이며, x86 하드웨어에서의 실행 가능성은 초기 단계에서 비현실적이라는 결론에 도달했다.

### 5.1. 프로젝트의 핵심 전략적 제언

**첫 번째 마일스톤의 집중:** 프로젝트의 초석은 ARM 기반 macOS Monterey 에뮬레이터의 안정적인 구축에 있다. 이 단계에서 UEFI 펌웨어, VirtIO 드라이버, 그리고 Kext injection이라는 세 가지 핵심 기술을 성공적으로 통합하는 데 모든 자원과 집중을 기울여야 한다. UTM과 같은 기존 솔루션을 분석하고 모방하는 것이 가장 빠른 길일 수 있다 [[12](https://tinyapps.org/docs/arm-vms.html), [42](https://github.com/utmapp/UTM/discussions/3458)]. Apple Silicon 호스트에서의 Native Virtualization(Framework)인 HVF를 최우선으로 활용하여 GUI 데스크톱 환경 구동을 성공적으로 달성하는 것이 첫 번째 목표이다.

**x86 호스트 실행 가능성의 재평가:** 사용자의 목표 중 'x86 기기에서의 구동'은 현재로서는 매우 비현실적이다. macOS Monterey ARM64는 ARM64 TCG(명령어 변환)를 지원하지 않으며, Apple Silicon의 Pointer Authentication 등 고유한 기능을 요구하기 때문에, x86 CPU에서 이를 에뮬레이션하는 것은 거의 불가능에 가깝다 [[50](https://hackernoon.com/virtualization-and-emulation-on-macos)]. 따라서 초기 기획서에서는 이 부분을 '미래 연구' 또는 '불가능한 목표'로 명시하고, 우선순위를 높은 ARM 기반 실행으로 전환하는 것이 현명하다. 프로젝트의 성공 확률을 높이기 위해서는 현실적인 목표를 설정하는 것이 중요하다.

**LLM Agent의 효율적인 활용:** LLM 에이전트를 개발 프로세스의 일부로 도입하는 것은 매우 유망하지만, 그 성공은 잘 설계된 프롬프트와 명확한 퀄리티 게이트에 의존한다. Roo 프레임워크와 같은 구조화된 방법론을 채택하고, JSON Schema를 통해 출력을 강제로 규격화하는 것이 중요하다 [[18](https://github.com/Mnehmos/Building-a-Structured-Transparent-and-Well-Documented-AI-Team), [19](https://dev.to/dthompsondev/llm-structured-json-building-production-ready-ai-features-with-schema-enforced-outputs-4j2j)]. 또한, LLM의 'Hallucination' 및 'Consistency Drift' 문제를 인지하고, 에이전트의 출력을 반복적으로 검증하는 메커니즘을 마련해야 한다 [[21](https://natesnewsletter.substack.com/p/the-prompt-doctor-is-in-fixes-for)]. 보안을 위해 'Action-Selector' 및 'Plan-Then-Execute' 패턴과 같은 보안 설계 원칙을 반드시 적용해야 한다 [[29](https://news.ycombinator.com/item?id=44268335), [30](https://simonwillison.net/2025/Jun/13/prompt-injection-design-patterns/)].

### 5.2. 미래 방향성 및 기술적 확장

첫 번째 마일스톤이 성공적으로 완료되면, 프로젝트는 두 번째 및 세 번째 마일스톤으로 자연스럽게 확장될 수 있다.
*   **두 번째 마일스톤 확장:** 첫 번째 마일스톤에서 구축한 에뮬레이터를 기반으로, 다양한 하드웨어 구성(SMBIOS)에 대한 호환성 테스트를 심화하고 최적화한다. PCIe Passthrough와 같은 고급 기능을 연구하여, 에뮬레이터가 단순한 가상 환경을 넘어 실제 하드웨어와 유사한 안정성과 기능성을 갖추도록 한다.
*   **세 번째 마일스톤 확장:** QEMU 포크를 통해 성능을 극대화하고, 새로운 기능을 추가하는 과정을 거친 후, 체계적인 개발 경험을 바탕으로 완전히 독립적인 커스텀 에뮬레이터 개발로 나아간다. 이는 프로젝트의 기술적 성숙도를 극대화하는 궁극적인 목표이다.
*   **미래 버전 지원:** macOS Monterey의 성공적인 실행이 확인되면, 후속 버전인 Ventura, Sonoma 등으로의 지원 범위를 점진적으로 확장하는 연구를 진행한다. 각 버전별로 요구되는 UEFI 기능, Kext, Boot Args가 달라지므로, 이에 맞춰 에뮬레이터를 업데이트해야 한다.
*   **보안 및 안정성 강화:** LLM 에이전트를 활용한 개발 워크플로우를 확장하여, 자동화된 테스트, 버그 추적, 문서화 등으로 활용 범위를 넓힌다. 또한, 에뮬레이터의 보안을 강화하고, 시스템 리소스 관리 기능을 향상시켜 더 안정적이고 효율적인 환경을 제공하는 것을 지속적으로 개선해야 한다.

결론적으로, 사용자의 프로젝트는 매우 도전적인 목표지만, 체계적인 분할과 현실적인 기술적 한계를 인지하는 전략적 접근을 통해 가능성을 가질 수 있다. 첫 번째 마일스톤의 성공을 확보하고, 그 성과를 바탕으로 두 번째, 세 번째 마일스톤으로 점진적으로 발전시키는 것이 가장 합리적인 길이다. 이 프로젝트는 macOS 가상화 기술의 새로운 지평을 열어줄 잠재력을 가지고 있으며, 꾸준한 노력과 체계적인 실행을 통해 성공적인 결과를 얻을 수 있을 것이다.