#!/bin/bash

###############################################################################
# deploy.sh - Deploy local_configs to Pi and restart services
# Usage: ./deploy.sh [--no-restart]
#
# This script uploads configuration files from local_configs/ to the Pi
# and restarts affected services.
###############################################################################

set -e

# Load configuration
if [ ! -f "pi.config" ]; then
    echo "Error: pi.config not found!"
    echo "Copy pi.config.example to pi.config and update with your values."
    exit 1
fi

source pi.config

RESTART_SERVICES=true
if [ "$1" == "--no-restart" ]; then
    RESTART_SERVICES=false
fi

echo "=== Deploying Configs to $REMOTE_HOST ==="

# Check SSH connection
if ! ssh -i "$PEM_FILE" -o ConnectTimeout=5 "${REMOTE_USER}@${REMOTE_HOST}" "echo 'Connected'" > /dev/null 2>&1; then
    echo "Error: Cannot connect to ${REMOTE_HOST}"
    exit 1
fi

# Deploy systemd services
if [ -f "local_configs/mihomo.service" ]; then
    echo "Deploying mihomo.service..."
    scp -i "$PEM_FILE" local_configs/mihomo.service "${REMOTE_USER}@${REMOTE_HOST}:/etc/systemd/system/"
fi

if [ -f "local_configs/aria2.service" ]; then
    echo "Deploying aria2.service..."
    scp -i "$PEM_FILE" local_configs/aria2.service "${REMOTE_USER}@${REMOTE_HOST}:/etc/systemd/system/"
fi

# Deploy Aria2 config
if [ -f "local_configs/aria2.conf" ]; then
    echo "Deploying aria2.conf..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /etc/aria2"
    scp -i "$PEM_FILE" local_configs/aria2.conf "${REMOTE_USER}@${REMOTE_HOST}:/etc/aria2/"
fi

# Deploy Samba config
if [ -f "local_configs/smb.conf" ]; then
    echo "Deploying smb.conf..."
    scp -i "$PEM_FILE" local_configs/smb.conf "${REMOTE_USER}@${REMOTE_HOST}:/etc/samba/"
fi

# Deploy Nginx config
if [ -f "local_configs/nginx.conf" ]; then
    echo "Deploying nginx.conf..."
    scp -i "$PEM_FILE" local_configs/nginx.conf "${REMOTE_USER}@${REMOTE_HOST}:/etc/nginx/sites-available/default"
fi

# Deploy Clash config
if [ -f "local_configs/clash_config.yaml" ]; then
    echo "Deploying clash_config.yaml..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /etc/mihomo"
    scp -i "$PEM_FILE" local_configs/clash_config.yaml "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/config.yaml"
fi

# Deploy homepage
if [ -f "local_configs/index.html" ]; then
    echo "Deploying index.html..."
    scp -i "$PEM_FILE" local_configs/index.html "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/"
fi

# Restart services
if [ "$RESTART_SERVICES" = true ]; then
    echo ""
    echo "Reloading systemd and restarting services..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
        systemctl daemon-reload
        systemctl restart aria2 2>/dev/null || echo "Warning: aria2 not running"
        systemctl restart mihomo 2>/dev/null || echo "Warning: mihomo not running"
        systemctl restart nginx 2>/dev/null || echo "Warning: nginx not running"
        systemctl restart smbd 2>/dev/null || echo "Warning: smbd not running"
        systemctl restart nmbd 2>/dev/null || echo "Warning: nmbd not running"
EOF
fi

echo ""
echo "=== Deployment Complete ==="
echo "Run ./status.sh to verify services are running"
