###############################################################################
# setup.sh - Install assets to NanoPi
# Usage: ./setup.sh
#
# This script:
# 1. Uploads binaries (mihomo) to /usr/local/bin
# 2. Uploads config files (country.mmdb, geosite.dat, config.yaml) to /etc/mihomo
# 3. Uploads web assets (vpn.php, index.html) to /var/www/html
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

# 1. Upload binaries (upload to /tmp, then move with sudo)
echo "Uploading binaries..."
if [ -f "assets/binaries/mihomo" ]; then
    scp -i "$PEM_FILE" assets/binaries/mihomo "${REMOTE_USER}@${REMOTE_HOST}:/tmp/mihomo"
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "sudo mkdir -p /usr/local/bin && sudo mv /tmp/mihomo /usr/local/bin/mihomo && sudo chmod +x /usr/local/bin/mihomo"
else
    echo "Warning: assets/binaries/mihomo not found"
fi

# 2. Upload Mihomo Configs
echo "Uploading Mihomo configs..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /etc/mihomo"

if [ -f "assets/binaries/country.mmdb" ]; then
    scp -i "$PEM_FILE" assets/binaries/country.mmdb "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
else
    echo "Warning: assets/binaries/country.mmdb not found"
fi

if [ -f "assets/binaries/geosite.dat" ]; then
    scp -i "$PEM_FILE" assets/binaries/geosite.dat "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
else
    echo "Warning: assets/binaries/geosite.dat not found"
fi

if [ -f "assets/templates/config.yaml" ]; then
    scp -i "$PEM_FILE" assets/templates/config.yaml "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/"
else
    echo "Warning: assets/templates/config.yaml not found"
fi

# 3. Upload Web Assets
echo "Uploading web assets..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/api"

if [ -f "assets/web/index.html" ]; then
    scp -i "$PEM_FILE" assets/web/index.html "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/"
fi

# 4. Upload Aria2 Web UI (if exists)
if [ -d "assets/web/aria2webui" ]; then
    echo "Uploading Aria2 Web UI..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/aria2/docs"
    scp -i "$PEM_FILE" -r assets/web/aria2webui/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/aria2/docs/"
fi

# 5. Upload MetaCubeX Dashboard (if exists)
if [ -d "assets/web/metacubexd" ]; then
    echo "Uploading MetaCubeX Dashboard..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/metacubexd"
    scp -i "$PEM_FILE" -r assets/web/metacubexd/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/metacubexd/"
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "chown -R www-data:www-data /var/www/html/metacubexd"
fi
#!/bin/bash

# Upload API files if they exist
if [ -d "assets/web/api" ]; then
    scp -i "$PEM_FILE" assets/web/api/*.php "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/api/" 2>/dev/null || true
fi

# Upload php-proxy-app if it exists
if [ -d "assets/web/php-proxy-app" ]; then
    echo "Uploading php-proxy-app..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/proxy"
    scp -i "$PEM_FILE" -r assets/web/php-proxy-app/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/proxy/"
    # Ensure encode_url.php is present
    if [ -f "assets/web/php-proxy-app/encode_url.php" ]; then
        scp -i "$PEM_FILE" assets/web/php-proxy-app/encode_url.php "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/proxy/"
    fi
fi

# 4. Install System Dependencies (Filesystem support)
echo "Installing filesystem drivers (exFAT, NTFS)..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
    # Update package list and install drivers
    # exfatprogs: for exFAT support
    # ntfs-3g: for NTFS support
    apt-get update -q
    DEBIAN_FRONTEND=noninteractive apt-get install -y exfatprogs ntfs-3g
EOF

echo "=== Setup Complete ==="
echo "Next steps:"
echo "1. Edit local_configs/ files as needed"
echo "2. Run: ./deploy.sh to deploy configurations"
echo "3. Run: ./status.sh to check Pi status"
