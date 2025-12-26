#!/bin/bash

###############################################################################
# setup.sh - Install assets to NanoPi
# Usage: ./setup.sh
#
# This script:
# 1. Uploads binaries (mihomo, country.mmdb, geosite.dat) to Pi
# 2. Uploads web assets (AriaNg.zip, vpn.php) to Pi
# 3. Extracts AriaNg to web directory
###############################################################################

set -e

# Load configuration
if [ ! -f "pi.config" ]; then
    echo "Error: pi.config not found!"
    echo "Copy pi.config.example to pi.config and update with your values."
    exit 1
fi

source pi.config

echo "=== Installing Assets to $REMOTE_HOST ==="

# Check SSH connection
echo "Testing SSH connection..."
if ! ssh -i "$PEM_FILE" -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" "echo 'Connection successful'" > /dev/null 2>&1; then
    echo "Error: Cannot connect to ${REMOTE_HOST}"
    echo "Check your pi.config and SSH key permissions (chmod 600 ${PEM_FILE})"
    exit 1
fi

# Upload binaries
echo "Uploading binaries..."
if [ -d "assets/binaries" ] && [ "$(ls -A assets/binaries 2>/dev/null)" ]; then
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /usr/local/bin"
    scp -i "$PEM_FILE" assets/binaries/* "${REMOTE_USER}@${REMOTE_HOST}:/usr/local/bin/" || echo "Warning: No binaries found or upload failed"
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "chmod +x /usr/local/bin/mihomo 2>/dev/null || true"
else
    echo "Warning: No binaries found in assets/binaries/"
fi

# Upload web assets
echo "Uploading web assets..."
if [ -f "assets/web/vpn.php" ]; then
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html"
    scp -i "$PEM_FILE" assets/web/vpn.php "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/"
else
    echo "Warning: vpn.php not found in assets/web/"
fi

# Upload and extract AriaNg
if [ -f "assets/web/AriaNg.zip" ]; then
    echo "Uploading and extracting AriaNg..."
    scp -i "$PEM_FILE" assets/web/AriaNg.zip "${REMOTE_USER}@${REMOTE_HOST}:/tmp/"
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
        mkdir -p /var/www/html/ariang
        cd /var/www/html/ariang
        unzip -o /tmp/AriaNg.zip
        rm /tmp/AriaNg.zip
        echo "AriaNg extracted to /var/www/html/ariang"
EOF
else
    echo "Warning: AriaNg.zip not found in assets/web/"
    echo "Download from: https://github.com/mayswind/AriaNg/releases"
fi

# Upload Clash config template
if [ -f "assets/templates/config.yaml" ]; then
    echo "Uploading Clash config template..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /etc/mihomo"
    scp -i "$PEM_FILE" assets/templates/config.yaml "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
fi

echo ""
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Edit local_configs/ files as needed"
echo "2. Run: ./deploy.sh to deploy configurations"
echo "3. Run: ./status.sh to check Pi status"
