#!/bin/bash

###############################################################################
# download.sh - Download current configs from Pi to local_configs/
# Usage: ./download.sh
#
# This script downloads configuration files from the Pi to your local
# local_configs/ directory for editing and version control.
###############################################################################

set -e

# Load configuration
if [ ! -f "pi.config" ]; then
    echo "Error: pi.config not found!"
    echo "Copy pi.config.example to pi.config and update with your values."
    exit 1
fi

source pi.config

echo "=== Downloading Configs from $REMOTE_HOST ==="

# Create local_configs directory
mkdir -p local_configs

# Download systemd services
echo "Downloading systemd services..."
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/etc/systemd/system/mihomo.service" local_configs/ 2>/dev/null || echo "Warning: mihomo.service not found"
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/etc/systemd/system/aria2.service" local_configs/ 2>/dev/null || echo "Warning: aria2.service not found"

# Download Aria2 config
echo "Downloading Aria2 config..."
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/etc/aria2/aria2.conf" local_configs/ 2>/dev/null || echo "Warning: aria2.conf not found"

# Download Samba config
echo "Downloading Samba config..."
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/etc/samba/smb.conf" local_configs/ 2>/dev/null || echo "Warning: smb.conf not found"

# Download Nginx config
echo "Downloading Nginx config..."
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/etc/nginx/sites-available/default" local_configs/nginx.conf 2>/dev/null || echo "Warning: nginx config not found"

# Download Clash config
echo "Downloading Clash config..."
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/config.yaml" local_configs/clash_config.yaml 2>/dev/null || echo "Warning: clash config not found"

# Download homepage
echo "Downloading homepage..."
scp -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/index.html" local_configs/ 2>/dev/null || echo "Warning: index.html not found"

echo ""
echo "=== Download Complete ==="
echo "Files saved to local_configs/"
echo "You can now edit these files and run ./deploy.sh to push changes"
