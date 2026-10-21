#!/bin/bash
set -euo pipefail

# Virt-VM Hypervisor Setup Script
# Configures KVM, QEMU, libvirt, and bridge networking

log_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
log_ok() { echo -e "\e[32m[OK]\e[0m $1"; }
log_warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
log_err() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# Check virtualization support in CPU
check_cpu_virt() {
    if grep -E -q '(vmx|svm)' /proc/cpuinfo; then
        log_ok "Hardware virtualization (VT-x/AMD-V) is enabled in CPU."
    else
        log_warn "Hardware virtualization flag not found in /proc/cpuinfo. Enable VT-x/AMD-V in BIOS/UEFI."
    fi
}

setup_arch() {
    log_info "Configuring virtualization stack for Arch Linux..."
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm qemu-full virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat iptables-nft libguestfs edk2-ovmf swtpm
    else
        sudo pacman -S --needed --noconfirm qemu-desktop virt-manager virt-viewer dnsmasq vde2 bridge-utils iptables libguestfs edk2-ovmf swtpm
    fi

    # Enable socket permissions
    if [ -f /etc/libvirt/libvirtd.conf ]; then
        sudo sed -i 's/^#\(unix_sock_group = "libvirt"\)/\1/; s/^#\(unix_sock_rw_perms = "0770"\)/\1/' /etc/libvirt/libvirtd.conf
    fi

    sudo systemctl enable --now libvirtd.service || sudo systemctl enable --now virtqemud.service
    sudo usermod -aG libvirt "$USER"

    # Start and autostart default NAT network
    sudo virsh net-autostart default 2>/dev/null || true
    sudo virsh net-start default 2>/dev/null || true
    log_ok "Virtualization setup complete for Arch Linux!"
}

setup_debian() {
    log_info "Configuring virtualization stack for Debian/Ubuntu..."
    sudo apt update
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf swtpm
    if [ -f /etc/libvirt/libvirtd.conf ]; then
        sudo sed -i 's/^#\(unix_sock_group = "libvirt"\)/\1/; s/^#\(unix_sock_rw_perms = "0770"\)/\1/' /etc/libvirt/libvirtd.conf
    fi
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt "$USER"
    sudo virsh net-autostart default 2>/dev/null || true
    sudo virsh net-start default 2>/dev/null || true
    log_ok "Virtualization setup complete for Debian-based system!"
}

setup_fedora() {
    log_info "Configuring virtualization stack for Fedora..."
    sudo dnf install -y @virtualization edk2-ovmf swtpm
    if [ -f /etc/libvirt/libvirtd.conf ]; then
        sudo sed -i 's/^#\(unix_sock_group = "libvirt"\)/\1/; s/^#\(unix_sock_rw_perms = "0770"\)/\1/' /etc/libvirt/libvirtd.conf
    fi
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt "$USER"
    sudo virsh net-autostart default 2>/dev/null || true
    sudo virsh net-start default 2>/dev/null || true
    log_ok "Virtualization setup complete for Fedora!"
}

check_cpu_virt

# Auto-detect OS
AUTO_CHOICE=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        arch|manjaro|endeavouros|garuda|omarchy) AUTO_CHOICE=1 ;;
        debian|ubuntu|pop|linuxmint) AUTO_CHOICE=2 ;;
        fedora|rhel|centos) AUTO_CHOICE=3 ;;
    esac
fi

echo "=================================================="
echo "          Virt-VM Host Hypervisor Setup           "
echo "=================================================="
echo "1) Arch Linux / Manjaro / Omarchy"
echo "2) Debian / Ubuntu / Mint / Pop!_OS"
echo "3) Fedora / RHEL"

if [ -n "$AUTO_CHOICE" ]; then
    read -r -p "Detected distro [$ID]. Press Enter for option $AUTO_CHOICE, or choose (1/2/3): " OS_CHOICE
    OS_CHOICE="${OS_CHOICE:-$AUTO_CHOICE}"
else
    read -r -p "Enter your choice (1/2/3): " OS_CHOICE
fi

case "$OS_CHOICE" in
    1) setup_arch ;;
    2) setup_debian ;;
    3) setup_fedora ;;
    *) log_err "Invalid selection! Exiting."; exit 1 ;;
esac

echo ""
log_ok "Setup finished! Please log out and back in (or reboot) for user group changes to take effect."
