#!/bin/bash

set -euo pipefail

# Safe helper to format an existing USB partition as ext4.
# This script DOES NOT create partitions; it only formats a chosen partition.
# Use this if you want a Linux-native filesystem for best performance/permissions.

usage() {
  echo "Usage: sudo ./prepare_usb_ext4.sh /dev/sdX1 [LABEL]"
  echo "  - Provide a partition device (e.g., /dev/sda1)"
  echo "  - Optional LABEL (default: usbdata)"
}

if [ "${EUID}" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

DEV=${1:-}
LABEL=${2:-usbdata}

if [ -z "$DEV" ]; then
  usage
  exit 1
fi

if [ ! -b "$DEV" ]; then
  echo "Error: $DEV is not a block device."
  exit 1
fi

echo "Target partition: $DEV"
echo "WARNING: This will ERASE all data on $DEV."
read -r -p "Type 'YES' to continue: " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

# Ensure not mounted
if mount | grep -q "^$DEV "; then
  echo "Partition is mounted; attempting to unmount..."
  umount "$DEV"
fi

echo "Formatting $DEV as ext4 (compat mode) with label '$LABEL'..."
# Use ext4 features compatible with older kernels (disable 64bit/metadata_csum)
mkfs.ext4 -F -L "$LABEL" -O ^64bit,^metadata_csum "$DEV"

echo "Format complete. You can now mount it or run provision:"
echo "  sudo bash $(dirname "$0")/provision.sh"
