#!/bin/bash

# Install Mihomo (Clash Meta) for ARMv7 (NanoPi NEO)
# We use Mihomo because it is the active fork of Clash and supports more protocols.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/mihomo"
SERVICE_FILE="/etc/systemd/system/mihomo.service"
LOCAL_BINARY="$REPO_ROOT/downloads/mihomo"

# 1. Install Binary (from local only)
if [ -f "$LOCAL_BINARY" ]; then
    echo "Using pre-downloaded Mihomo binary from $LOCAL_BINARY..."
    cp "$LOCAL_BINARY" "$INSTALL_DIR/mihomo"
    chmod +x "$INSTALL_DIR/mihomo"
else
    echo "Error: Local Mihomo binary not found at $LOCAL_BINARY"
    echo "Please download Mihomo on your PC using scripts/download_mihomo.sh and sync to the device."
    exit 1
fi

# 3. Create Config Directory
mkdir -p "$CONFIG_DIR"

# Copy clash config if available
CLASH_CONFIG_SRC="$REPO_ROOT/config/clash_config.yaml"
if [ -f "$CLASH_CONFIG_SRC" ]; then
    cp "$CLASH_CONFIG_SRC" "$CONFIG_DIR/config.yaml"
else
    touch "$CONFIG_DIR/config.yaml"
fi

# 4. Setup GeoIP data (from local only)
echo "Setting up GeoIP data..."
LOCAL_MMDB="$REPO_ROOT/downloads/country.mmdb"
LOCAL_GEOSITE="$REPO_ROOT/downloads/geosite.dat"

if [ -f "$LOCAL_MMDB" ]; then
    echo "Using pre-downloaded Country.mmdb..."
    cp "$LOCAL_MMDB" "$CONFIG_DIR/Country.mmdb"
else
    echo "Warning: Country.mmdb not found at $LOCAL_MMDB"
    echo "Please download on your PC using scripts/download_mihomo.sh and sync to the device."
fi

if [ -f "$LOCAL_GEOSITE" ]; then
    echo "Using pre-downloaded GeoSite.dat..."
    cp "$LOCAL_GEOSITE" "$CONFIG_DIR/GeoSite.dat"
else
    echo "Warning: GeoSite.dat not found at $LOCAL_GEOSITE"
    echo "Please download on your PC using scripts/download_mihomo.sh and sync to the device."
fi

# 5. Create Systemd Service
echo "Creating Systemd service..."
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Mihomo (Clash Meta) Daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_DIR/mihomo -d $CONFIG_DIR
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
# We do NOT enable it by default. The user should enable it via the toggle script or manually.
# systemctl enable mihomo

echo "Mihomo installed. Use 'scripts/toggle_vpn.sh on' to start it."
