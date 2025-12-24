#!/bin/bash

# Provision Script for NanoPi NEO Download Station
# Run this script on the NanoPi as root.

set -euo pipefail

# Resolve paths relative to this script to avoid CWD issues
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MOUNT_POINT="/mnt/usb_drive"
CONFIG_DIR="/etc/aria2"
USER="dietpi"
GROUP="dietpi"
ARIA_CONF_SRC="$REPO_ROOT/config/aria2.conf"

# 1. Detect USB Drive
echo "Detecting USB drive..."
# We look for the first partition of the first USB disk (usually sda1)
USB_DEV=$(lsblk -rno NAME,TRAN | grep usb | head -n1 | cut -d' ' -f1)
if [ -z "$USB_DEV" ]; then
    echo "Error: No USB drive detected. Please plug in your drive."
    exit 1
fi
# Append partition number 1 if not present (simple assumption for single partition drives)
USB_PART="/dev/${USB_DEV}1"
if [ ! -b "$USB_PART" ]; then
    USB_PART="/dev/${USB_DEV}"
fi

echo "Found USB device: $USB_PART"

# 2. Get UUID
UUID=$(blkid -s UUID -o value "$USB_PART")
if [ -z "$UUID" ]; then
    echo "Error: Could not get UUID for $USB_PART"
    exit 1
fi
echo "UUID: $UUID"

# 3. Setup Mount Point
mkdir -p "$MOUNT_POINT"
chown -R $USER:$GROUP "$MOUNT_POINT"

# 4. Update fstab for Persistent Mount
if grep -q "$UUID" /etc/fstab; then
    echo "Entry for UUID $UUID already exists in fstab."
else
    echo "Adding entry to /etc/fstab..."
    # nofail: Boot continues even if drive is missing
    # x-systemd.device-timeout=5: Don't wait long for it
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
fi

# 5. Mount Now
mount -a
if mountpoint -q "$MOUNT_POINT"; then
    echo "Drive mounted successfully."
else
    echo "Error: Failed to mount drive."
    exit 1
fi

# 5.1 Verify filesystem type and readability
FSTYPE=$(findmnt -n -o FSTYPE "$MOUNT_POINT" || echo "")
echo "Filesystem type: ${FSTYPE:-unknown}"
if [ -z "$FSTYPE" ]; then
    echo "Error: Could not determine filesystem type for $MOUNT_POINT"
    exit 1
fi
if [ "$FSTYPE" != "ext4" ]; then
    echo "Warning: Expected ext4, but mounted filesystem is '$FSTYPE'."
    echo "- Non-Linux filesystems (exfat/ntfs/vfat) may not support Unix permissions."
    echo "- Consider backing up data and reformatting the USB partition to ext4."
fi

# Quick sanity check: ensure the mount directory is readable
if ! ls "$MOUNT_POINT" > /dev/null 2>&1; then
    echo "Error: Cannot read $MOUNT_POINT; filesystem may be corrupted or incompatible."
    echo "Check kernel logs (dmesg) for details and run fsck after umount."
    exit 1
fi

# 6. Setup Directory Structure on USB Drive
echo "Setting up USB drive directories..."
mkdir -p "$MOUNT_POINT/downloads"
mkdir -p "$MOUNT_POINT/aria2"
touch "$MOUNT_POINT/aria2/aria2.session"
# Only attempt chown on filesystems that support Unix ownership
if [ "$FSTYPE" = "ext4" ]; then
    chown -R $USER:$GROUP "$MOUNT_POINT"
else
    echo "Skipping chown on $MOUNT_POINT (fstype=$FSTYPE)."
fi

# 7. Install Configuration
echo "Installing Aria2 configuration..."
if ! command -v aria2c >/dev/null 2>&1; then
    echo "aria2 not found; installing..."
    apt-get update && apt-get install -y aria2
fi
if [ ! -f "$ARIA_CONF_SRC" ]; then
    echo "Error: aria2.conf not found at $ARIA_CONF_SRC" >&2
    exit 1
fi
mkdir -p "$CONFIG_DIR"
cp "$ARIA_CONF_SRC" "$CONFIG_DIR/aria2.conf"
sed -i "s|^dir=.*|dir=$MOUNT_POINT/downloads|" "$CONFIG_DIR/aria2.conf"
sed -i "s|^input-file=.*|input-file=$MOUNT_POINT/aria2/aria2.session|" "$CONFIG_DIR/aria2.conf"
sed -i "s|^save-session=.*|save-session=$MOUNT_POINT/aria2/aria2.session|" "$CONFIG_DIR/aria2.conf"

# 7.1 Install Web Stack (Lighttpd + PHP) and AriaNg
echo "Installing web stack and AriaNg..."
if [ -f "$SCRIPT_DIR/install_web_stack.sh" ]; then
    chmod +x "$SCRIPT_DIR/install_web_stack.sh"
    "$SCRIPT_DIR/install_web_stack.sh"
else
    echo "Warning: install_web_stack.sh not found at $SCRIPT_DIR"
fi
if [ -f "$SCRIPT_DIR/install_ariang.sh" ]; then
    chmod +x "$SCRIPT_DIR/install_ariang.sh"
    "$SCRIPT_DIR/install_ariang.sh"
else
    echo "Warning: install_ariang.sh not found at $SCRIPT_DIR"
fi

# 8. Setup Systemd Service
echo "Configuring Systemd service..."
cat <<EOF > /etc/systemd/system/aria2.service
[Unit]
Description=Aria2 Download Manager
After=network.target mnt-usb_drive.mount
Requires=mnt-usb_drive.mount

[Service]
Type=simple
User=$USER
Group=$GROUP
ExecStart=/usr/bin/aria2c --conf-path=$CONFIG_DIR/aria2.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable aria2
systemctl start aria2

# 9. Disable USB Power Saving (Prevent Drive Sleep)
echo "Disabling USB power saving features..."

# Install hdparm if missing
if ! command -v hdparm &> /dev/null; then
    apt-get update && apt-get install -y hdparm
fi

# Disable APM (Advanced Power Management) and Spindown
# -B 255: Disable APM
# -S 0: Disable spindown timer
hdparm -B 255 -S 0 "$USB_PART" || { echo "Warning: Could not set hdparm for $USB_PART (Drive might not support it)"; true; }

# Disable USB Autosuspend via Kernel Parameter (Persistent)
# Only if cmdline exists
if [ -f /boot/cmdline.txt ]; then
    if ! grep -q "usbcore.autosuspend=-1" /boot/cmdline.txt; then
        sed -i 's/$/ usbcore.autosuspend=-1/' /boot/cmdline.txt
        echo "Added usbcore.autosuspend=-1 to /boot/cmdline.txt"
    fi
else
    echo "Warning: /boot/cmdline.txt not found; skipping autosuspend tweak"
fi

# 10. Configure Samba Share
echo "Configuring Samba share..."
SMB_CONF="/etc/samba/smb.conf"

if ! command -v smbd >/dev/null 2>&1; then
    echo "samba not found; installing..."
    apt-get update && apt-get install -y samba
fi

# Backup original config if present
if [ -f "$SMB_CONF" ] && [ ! -f "$SMB_CONF.bak" ]; then
    cp "$SMB_CONF" "$SMB_CONF.bak"
fi

# Ensure a baseline smb.conf exists
if [ ! -f "$SMB_CONF" ]; then
    cat <<'EOF' > "$SMB_CONF"
[global]
   workgroup = WORKGROUP
   server string = DietPi Samba Server
   security = user
   map to guest = Bad User
   dns proxy = no
EOF
fi

# Add 'downloads' share definition if not present
if ! grep -q "\[downloads\]" "$SMB_CONF"; then
    cat <<EOF >> "$SMB_CONF"

[downloads]
   comment = Aria2 Downloads
   path = $MOUNT_POINT/downloads
   browseable = yes
   create mask = 0664
   directory mask = 0775
   valid users = dietpi
   writeable = yes
EOF
    echo "Added [downloads] share to $SMB_CONF"
    systemctl restart smbd nmbd || echo "Warning: could not restart smbd/nmbd"
else
    echo "Samba share [downloads] already exists."
fi

# 11. Install Clash (Mihomo)
echo "Installing Clash (Mihomo)..."
if [ -f "$SCRIPT_DIR/install_clash.sh" ]; then
    chmod +x "$SCRIPT_DIR/install_clash.sh"
    "$SCRIPT_DIR/install_clash.sh"
else
    echo "Warning: install_clash.sh not found at $SCRIPT_DIR"
fi

# 12. Install VPN Web Control
echo "Installing VPN Web Control..."
if [ -f "$SCRIPT_DIR/install_vpn_web_ui.sh" ]; then
    chmod +x "$SCRIPT_DIR/install_vpn_web_ui.sh"
    "$SCRIPT_DIR/install_vpn_web_ui.sh"
else
    echo "Warning: install_vpn_web_ui.sh not found at $SCRIPT_DIR"
fi

# 13. Install Watchdog (Monitor Mount)
echo "Installing Watchdog script..."
if [ -f "$SCRIPT_DIR/monitor_mount.sh" ]; then
    cp "$SCRIPT_DIR/monitor_mount.sh" /usr/local/bin/monitor_mount.sh
    chmod +x /usr/local/bin/monitor_mount.sh
else
    echo "Warning: monitor_mount.sh not found at $SCRIPT_DIR"
fi

# Add to crontab if not exists (Run every minute)
CRON_JOB="* * * * * /usr/local/bin/monitor_mount.sh >> /var/log/monitor_mount.log 2>&1"
(crontab -l 2>/dev/null | grep -F "/usr/local/bin/monitor_mount.sh") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Provisioning Complete! Aria2 is running."
