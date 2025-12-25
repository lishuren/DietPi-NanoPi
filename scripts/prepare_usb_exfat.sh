#!/usr/bin/env bash

set -euo pipefail

# Safe helper to format an existing USB partition as exFAT.
# This script DOES NOT create partitions; it only formats a chosen partition.
# Use this for cross-platform portability (Windows/macOS/Linux). Permissions are controlled via mount options.

usage() {
  echo "Usage: sudo ./prepare_usb_exfat.sh /dev/sdX1 [LABEL]"
  echo "  - Provide a partition device (e.g., /dev/sda1)"
  echo "  - Optional LABEL (default: usbdrive)"
}

if [ "${EUID}" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

DEV=${1:-}
LABEL=${2:-usbdrive}

if [ -z "$DEV" ]; then
  usage
  exit 1
fi

if [ ! -b "$DEV" ]; then
  echo "Error: $DEV is not a block device."
  exit 1
fi

# Ensure tools exist
if ! command -v mkfs.exfat >/dev/null 2>&1; then
  echo "Installing exfatprogs..."
  apt-get update && apt-get install -y exfatprogs || {
    echo "Warning: exfatprogs install failed; trying exfat-fuse"
    apt-get install -y exfat-fuse || true
  }
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
  umount "$DEV" || true
fi

echo "Formatting $DEV as exFAT with label '$LABEL'..."
mkfs.exfat -n "$LABEL" "$DEV"

echo "Format complete. You can now run provisioning to add fstab and mount:"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "  sudo bash $SCRIPT_DIR/provision.sh"
