# 🖥️ Virt-VM: Automated KVM/QEMU Windows Virtual Machine Creator

An automated setup toolkit and provisioning script to easily configure high-performance KVM/QEMU Windows 10/11 virtual machines on Linux with VirtIO drivers and hardware acceleration.

---

## 🌟 Features

- **Multi-Distro Hypervisor Setup**: Automated KVM, QEMU, `libvirt`, `virt-manager`, and bridge network configuration for **Arch Linux**, **Debian/Ubuntu**, and **Fedora**.
- **Automated Distro Detection**: Auto-detects your Linux distribution via `/etc/os-release` with interactive override.
- **Optimized Windows VM Generation**:
  - Near-native I/O throughput with VirtIO storage and network drivers.
  - UEFI (OVMF) and TPM 2.0 readiness for Windows 11 compatibility.
  - Interactive validation for CPU cores, RAM sizes (e.g. `8G` or `8192M`), disk sizing, and ISO file existence.
  - Permission-safe disk creation in either `/var/lib/libvirt/images` or user home storage.

---

## 🚀 Quick Start

### 1. Host Hypervisor Setup
Configure QEMU, KVM, libvirt permissions, and default virtual networking:
```bash
chmod +x install.sh create.sh
./install.sh
```
*Note: If prompted, log out and log back in (or reboot) for your user to join the `libvirt` group.*

### 2. Create a Windows VM
Ensure you have downloaded:
1. Windows 10/11 ISO from Microsoft.
2. [Fedora VirtIO Windows Drivers ISO](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso) *(Optional but strongly recommended for high-performance disk and network drivers).*

Run the creator:
```bash
./create.sh
```

---

## 🛠️ Configuration Details

| Parameter | Recommended Setting | Note |
| :--- | :--- | :--- |
| **CPU Cores** | 4 to 8 cores | Allocated from host threads |
| **RAM** | `8G` (8192 MB) | Minimum 4G for Win 10/11 |
| **Disk Size** | `60G`+ | Dynamically allocated `qcow2` |
| **OS Variant** | `win11` / `win10` | Uses modern `osinfo` database |

---

## 🛡️ Error Handling Improvements
- Verified existence of ISO files before initiating `virt-install`.
- Auto-fixed libvirt network startup typo (`net-start default`).
- Added input validation for RAM formatting (`G`/`M`) and disk space.
- Graceful fallbacks for graphics modes when 3D acceleration is unsupported on the host compositor.
