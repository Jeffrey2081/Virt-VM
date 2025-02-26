#!/bin/bash

# Get user input
read -p "Enter VM name: " VM_NAME
read -p "Enter number of cores: " CORES
read -p "Enter RAM size (e.g., 8G): " RAM
read -p "Enter size of drive (e.g., 60G): " DRIVE_SIZE
read -p "Enter path to Windows ISO: " ISO_PATH
read -p "Enter path to VirtIO drivers ISO: " VIRTIO_PATH

# Convert RAM to megabytes (if entered in gigabytes)
if [[ $RAM =~ G$ ]]; then
    RAM_MB=$(( ${RAM%G} * 1024 ))
else
    RAM_MB=${RAM%M}
fi

# Path to the VM disk image
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

# Create a disk image for the VM
qemu-img create -f qcow2 $DISK_PATH $DRIVE_SIZE

# Create the virtual machine
virt-install \
    --name "$VM_NAME" \
    --vcpus "$CORES" \
    --memory "$RAM_MB" \
    --disk path="$DISK_PATH",format=qcow2,size=${DRIVE_SIZE%G},bus=virtio \
    --cdrom "$ISO_PATH" \
    --disk path="$VIRTIO_PATH",device=cdrom \
    --os-type windows \
    --os-variant win11 \
    --network network=default,model=virtio \
    --graphics spice,gl=on,listen=none \
    --video virtio,3d=on \
    --noautoconsole

echo "Windows VM $VM_NAME created successfully with VirtIO drivers and 3D acceleration!"
