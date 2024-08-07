#!/usr/bin/env bash

# Check if the script is run with an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <device>"
    exit 1
fi

# Store the input argument in a variable
DEVICE=$1
OUTPUT_DIR=$(dirname "$0")/..
UNCOMPRESSED_NAME="nixos.img"
COMPRESSED_NAME="disk1.raw.zst"

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "No such directory: $OUTPUT_DIR"
    exit 1
fi

wipe_filesystem () {
    echo "Wiping filesystem..."
    # Unmount possible mounted filesystems
    sync; sudo umount -q "$DEVICE"* || true;
    # Wipe first 100MB of disk
    sudo dd if=/dev/zero of="$DEVICE" bs=100M count=1 conv=fsync
    SECTORS=$(sudo fdisk -l "$DEVICE" | head -n 1 |  awk '{print $7}')
    # Wipe last ~100MB of disk. The sector size does not matter much
    sudo dd if=/dev/zero of="$DEVICE" seek="$((SECTORS - 204800))" conv=fsync
    echo "Flashing..."
}

# Ask for sudo
sudo -v

# Check if the device exists
if [ -e "$DEVICE" ]; then
    # Check for uncompressed image file
    if [ -f "$OUTPUT_DIR/$UNCOMPRESSED_NAME" ]; then
        echo "Found $UNCOMPRESSED_NAME..."
        wipe_filesystem
        sudo dd if="$OUTPUT_DIR/$UNCOMPRESSED_NAME" of="$DEVICE" bs=32M status=progress conv=fsync oflag=direct iflag=fullblock
    # Check for compressed image file
    elif [ -f "$OUTPUT_DIR/$COMPRESSED_NAME" ]; then
        echo "Found $COMPRESSED_NAME..."
        wipe_filesystem
        zstdcat "$OUTPUT_DIR/$COMPRESSED_NAME" | sudo dd of="$DEVICE" bs=32M status=progress conv=fsync oflag=direct iflag=fullblock
    else
        echo "No image files found in the $OUTPUT_DIR/ directory."
    fi
else
    echo "No such device: $DEVICE"
    exit 1
fi
