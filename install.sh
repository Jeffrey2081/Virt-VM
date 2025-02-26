#!/bin/bash

# Function to install virtualization tools for Arch Linux
setup_arch() {
    echo "Setting up virtualization for Arch Linux..."
    yay -S qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables libguestfs
    sudo sed -i 's/^#\(unix_sock_group = "libvirt"\)/\1/; s/^#\(unix_sock_rw_perms = "0770"\)/\1/' /etc/libvirt/libvirtd.conf
    sudo systemctl enable --now libvirtd
    sudo usermod -a -G libvirt $(whoami)
    sudo virsh net-autostart default
    sudo virsh net-startdefault
    newgrp libvirt
    echo "Virtualization setup complete for Arch Linux!"
}

# Function to install virtualization tools for Debian-based distros
setup_debian() {
    echo "Setting up virtualization for Debian-based system..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    sudo sed -i 's/^#\(unix_sock_group = "libvirt"\)/\1/; s/^#\(unix_sock_rw_perms = "0770"\)/\1/' /etc/libvirt/libvirtd.conf
    sudo virsh net-autostart default
    sudo virsh net-startdefault
    sudo systemctl enable --now libvirtd
    sudo usermod -aG libvirt $(whoami)
    newgrp libvirt
    echo "Virtualization setup complete for Debian-based system!"
}

# Function to install virtualization tools for Fedora
setup_fedora() {
    echo "Setting up virtualization for Fedora..."
    sudo dnf install -y @virtualization
    sudo sed -i 's/^#\(unix_sock_group = "libvirt"\)/\1/; s/^#\(unix_sock_rw_perms = "0770"\)/\1/' /etc/libvirt/libvirtd.conf
    sudo systemctl enable --now libvirtd
    sudo virsh net-autostart default
    sudo virsh net-startdefault
    sudo usermod -aG libvirt $(whoami)
    newgrp libvirt
    echo "Virtualization setup complete for Fedora!"
}

# Detect and ask the user for their OS
echo "Select your OS:"
echo "1) Arch Linux"
echo "2) Debian/Ubuntu"
echo "3) Fedora"
read -p "Enter your choice (1/2/3): " OS_CHOICE

case $OS_CHOICE in
    1)
        setup_arch
        ;;
    2)
        setup_debian
        ;;
    3)
        setup_fedora
        ;;
    *)
        echo "Invalid choice! Exiting."
        exit 1
        ;;
esac

echo "Please reboot for changes to take effect."
