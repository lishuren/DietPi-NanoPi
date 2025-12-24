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

# 1. Install Binary (from local or download)
if [ -f "$LOCAL_BINARY" ]; then
    echo "Using pre-downloaded Mihomo binary from $LOCAL_BINARY..."
    cp "$LOCAL_BINARY" "$INSTALL_DIR/mihomo"
    chmod +x "$INSTALL_DIR/mihomo"
else
    echo "Local binary not found. Downloading Mihomo (Clash Meta)..."
    DOWNLOAD_URL="https://github.com/MetaCubeX/mihomo/releases/download/v1.18.1/mihomo-linux-armv7-v1.18.1.gz"
    
    curl -L -o mihomo.gz "$DOWNLOAD_URL"
    
    if [ $? -ne 0 ]; then
        echo "Download failed!"
        exit 1
    fi
    
    echo "Installing binary..."
    gzip -d mihomo.gz
    chmod +x mihomo
    mv mihomo "$INSTALL_DIR/mihomo"
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

# 4. Download or copy Country MMDB (GeoIP)
echo "Setting up GeoIP data..."
LOCAL_MMDB="$REPO_ROOT/downloads/Country.mmdb"
LOCAL_GEOSITE="$REPO_ROOT/downloads/GeoSite.dat"

if [ -f "$LOCAL_MMDB" ]; then
    echo "Using pre-downloaded Country.mmdb..."
    cp "$LOCAL_MMDB" "$CONFIG_DIR/Country.mmdb"
else
    echo "Downloading Country.mmdb..."
    curl -L -o "$CONFIG_DIR/Country.mmdb" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
fi

if [ -f "$LOCAL_GEOSITE" ]; then
    echo "Using pre-downloaded GeoSite.dat..."
    cp "$LOCAL_GEOSITE" "$CONFIG_DIR/GeoSite.dat"
else
    echo "Downloading GeoSite.dat..."
    curl -L -o "$CONFIG_DIR/GeoSite.dat" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"
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
