#!/bin/bash
set -euo pipefail

# Virt-VM: Windows Virtual Machine Creator
echo "=================================================="
echo "         Virt-VM Windows VM Installation          "
echo "=================================================="

# Prompt for VM Name
while true; do
    read -r -p "Enter VM name [win-vm]: " VM_NAME
    VM_NAME="${VM_NAME:-win-vm}"
    # Sanitize VM name
    VM_NAME=$(echo "$VM_NAME" | tr -cd '[:alnum:]_-')
    if [ -n "$VM_NAME" ]; then break; fi
    echo "Invalid VM name. Please try again."
done

# CPU Cores
HOST_CORES=$(nproc 2>/dev/null || echo 4)
DEFAULT_CORES=$(( HOST_CORES > 2 ? HOST_CORES / 2 : 2 ))
while true; do
    read -r -p "Enter number of CPU cores [default: $DEFAULT_CORES, host max: $HOST_CORES]: " CORES
    CORES="${CORES:-$DEFAULT_CORES}"
    if [[ "$CORES" =~ ^[0-9]+$ ]] && [ "$CORES" -ge 1 ] && [ "$CORES" -le "$HOST_CORES" ]; then
        break
    fi
    echo "Please enter a valid core count between 1 and $HOST_CORES."
done

# RAM Size
while true; do
    read -r -p "Enter RAM size (e.g. 8G or 8192M) [8G]: " RAM
    RAM="${RAM:-8G}"
    if [[ "$RAM" =~ ^[0-9]+[Gg]$ ]]; then
        RAM_MB=$(( ${RAM%[Gg]} * 1024 ))
        break
    elif [[ "$RAM" =~ ^[0-9]+[Mm]$ ]]; then
        RAM_MB=${RAM%[Mm]}
        break
    elif [[ "$RAM" =~ ^[0-9]+$ ]]; then
        RAM_MB="$RAM"
        break
    fi
    echo "Invalid RAM format. Use e.g. 4G, 8G, or 8192M."
done

# Drive Size
while true; do
    read -r -p "Enter virtual disk size (e.g. 60G) [60G]: " DRIVE_SIZE
    DRIVE_SIZE="${DRIVE_SIZE:-60G}"
    if [[ "$DRIVE_SIZE" =~ ^[0-9]+[Gg]$ ]]; then
        break
    fi
    echo "Invalid disk size format. Use e.g. 60G or 100G."
done

# Windows ISO
while true; do
    read -r -p "Enter path to Windows ISO: " ISO_PATH
    ISO_PATH=$(eval echo "$ISO_PATH")
    if [ -f "$ISO_PATH" ]; then
        break
    fi
    echo "Error: File '$ISO_PATH' not found. Please provide a valid file path."
done

# VirtIO ISO
read -r -p "Enter path to VirtIO drivers ISO (press Enter to skip): " VIRTIO_PATH
VIRTIO_PATH=$(eval echo "$VIRTIO_PATH")

# OS Variant selection
echo ""
echo "Select Windows Variant:"
echo "1) Windows 11 (TPM 2.0 & SecureBoot)"
echo "2) Windows 10"
read -r -p "Selection (1/2) [1]: " OS_VAR
OS_VAR="${OS_VAR:-1}"
if [ "$OS_VAR" = "2" ]; then
    OS_VARIANT="win10"
else
    OS_VARIANT="win11"
fi

# Disk directory selection
STORAGE_DIR="/var/lib/libvirt/images"
if [ ! -w "$STORAGE_DIR" ]; then
    # Fallback to user pool if /var/lib/libvirt/images is not writable
    USER_POOL="$HOME/.local/share/libvirt/images"
    mkdir -p "$USER_POOL"
    STORAGE_DIR="$USER_POOL"
    echo "Using user storage directory: $STORAGE_DIR"
fi

DISK_PATH="${STORAGE_DIR}/${VM_NAME}.qcow2"

if [ -f "$DISK_PATH" ]; then
    read -r -p "Warning: Disk '$DISK_PATH' already exists. Overwrite? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Aborted by user."
        exit 1
    fi
    rm -f "$DISK_PATH"
fi

echo "Creating QCOW2 disk image of size $DRIVE_SIZE at $DISK_PATH..."
qemu-img create -f qcow2 "$DISK_PATH" "$DRIVE_SIZE"

# Build virt-install command
CMD=(virt-install
    --name "$VM_NAME"
    --vcpus "$CORES"
    --memory "$RAM_MB"
    --disk "path=${DISK_PATH},format=qcow2,bus=virtio"
    --cdrom "$ISO_PATH"
    --os-variant "$OS_VARIANT"
    --network network=default,model=virtio
    --graphics spice
    --video qxl
    --noautoconsole
)

# Attach VirtIO driver ISO if supplied
if [ -n "$VIRTIO_PATH" ] && [ -f "$VIRTIO_PATH" ]; then
    CMD+=(--disk "path=${VIRTIO_PATH},device=cdrom")
fi

echo "Launching VM installation for '$VM_NAME'..."
"${CMD[@]}"

echo "=================================================="
echo "✓ VM '$VM_NAME' created and started!"
echo "Open 'virt-manager' to view the console."
echo "=================================================="
