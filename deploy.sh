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
    
    # Initialize Aria2 directories and session file
    echo "Initializing Aria2 directories..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /mnt/usb_data/aria2 && touch /mnt/usb_data/aria2/aria2.session"
    
    # Since we are running as root, we just need to ensure the directory is accessible
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "chmod -R 777 /mnt/usb_data/aria2 /mnt/usb_data/downloads 2>/dev/null || true"
fi

# Deploy Samba config
if [ -f "local_configs/smb.conf" ]; then
    echo "Deploying smb.conf..."
    scp -i "$PEM_FILE" local_configs/smb.conf "${REMOTE_USER}@${REMOTE_HOST}:/etc/samba/"
    
    # Ensure downloads directory exists with proper permissions
    echo "Initializing Samba share directory..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /mnt/usb_data/downloads"
fi




# Remove all other index.html files except /var/www/html/index.html
echo "Cleaning up duplicate index.html files on the Pi..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "find / -type f -name 'index.html' ! -path '/var/www/html/index.html' -delete 2>/dev/null || true"

# Deploy portal web UI
echo "Deploying portal web UI..."
scp -i "$PEM_FILE" assets/web/index.html "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/index.html"
# Optionally deploy all assets (uncomment if needed):
# scp -i "$PEM_FILE" -r assets/web/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/"

# Deploy Nginx config
if [ -f "local_configs/nginx-default-site" ]; then
    echo "Deploying nginx site config..."
    scp -i "$PEM_FILE" local_configs/nginx-default-site "${REMOTE_USER}@${REMOTE_HOST}:/etc/nginx/sites-available/default"
    # Always reload nginx and restart PHP-FPM after config deployment
    echo "Reloading nginx and restarting PHP-FPM..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "systemctl reload nginx 2>/dev/null || systemctl restart nginx; systemctl restart php*-fpm 2>/dev/null || echo 'Warning: php-fpm not running'"
fi

if [ -f "local_configs/nginx.conf" ]; then
    echo "Deploying nginx.conf..."
    scp -i "$PEM_FILE" local_configs/nginx.conf "${REMOTE_USER}@${REMOTE_HOST}:/etc/nginx/nginx.conf"
    # Always reload nginx after main config deployment
    echo "Reloading nginx..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "systemctl reload nginx 2>/dev/null || systemctl restart nginx"
fi

# Deploy Clash config
if [ -f "local_configs/config.yaml" ]; then
    echo "Deploying config.yaml..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /etc/mihomo"
    scp -i "$PEM_FILE" local_configs/config.yaml "${REMOTE_USER}@${REMOTE_HOST}:/etc/mihomo/config.yaml"
fi


# Deploy VPN page

# Deploy MetaCubeX dashboard
if [ -d "assets/web/metacubexd" ]; then
    echo "Deploying MetaCubeX dashboard..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/metacubexd"
    scp -i "$PEM_FILE" -r assets/web/metacubexd/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/metacubexd/"
fi

# Deploy Web API scripts
if [ -d "assets/web/api" ]; then
    echo "Deploying Web API scripts..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/api"
    scp -i "$PEM_FILE" assets/web/api/*.php "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/api/"
fi

# Deploy php-proxy-app
if [ -d "assets/web/proxy" ]; then
    echo "Deploying php-proxy-app..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/proxy"
    scp -i "$PEM_FILE" -r assets/web/proxy/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/proxy/"
fi

# Deploy php-proxy-app (updated folder name)
if [ -d "assets/web/php-proxy-app" ]; then
    echo "Deploying php-proxy-app..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p /var/www/html/proxy"
    scp -i "$PEM_FILE" -r assets/web/php-proxy-app/* "${REMOTE_USER}@${REMOTE_HOST}:/var/www/html/proxy/"
fi

# Configure USB Auto-Mount (if /dev/sda1 exists and not configured)
echo "Checking USB storage configuration..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
    # Check if /dev/sda1 exists (First USB drive)
    if [ -b "/dev/sda1" ]; then
        # Check if already in fstab
        if ! grep -q "/mnt/usb_data" /etc/fstab; then
            echo "Found USB drive /dev/sda1. Configuring auto-mount..."
            # Add to fstab (exFAT, full access for all users)
            echo "/dev/sda1 /mnt/usb_data exfat defaults,uid=0,gid=0,umask=000,iocharset=utf8,noatime,nofail,x-systemd.automount 0 0" >> /etc/fstab
            # Reload systemd to pick up fstab changes
            systemctl daemon-reload
            mount -a
            echo "USB drive mounted to /mnt/usb_data"
        else
            echo "USB drive already configured in /etc/fstab."
        fi
    else
        echo "No USB drive found at /dev/sda1. Skipping mount."
    fi
EOF

# Deploy Helper Scripts
if [ -f "assets/scripts/update_mihomo.sh" ]; then
    echo "Deploying update_mihomo.sh..."
    scp -i "$PEM_FILE" assets/scripts/update_mihomo.sh "${REMOTE_USER}@${REMOTE_HOST}:/usr/local/bin/update_mihomo"
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" "chmod +x /usr/local/bin/update_mihomo"
fi

# Configure Sudoers for Web UI
echo "Configuring sudoers for Web UI..."
ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
    # Create sudoers file for www-data
    cat > /etc/sudoers.d/dietpi-www << SUDO
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop mihomo
www-data ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mihomo
www-data ALL=(ALL) NOPASSWD: /bin/systemctl start mihomo
www-data ALL=(ALL) NOPASSWD: /bin/systemctl stop mihomo
www-data ALL=(ALL) NOPASSWD: /bin/systemctl restart mihomo
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/update_mihomo
SUDO
    chmod 0440 /etc/sudoers.d/dietpi-www
EOF



# Restart services
if [ "$RESTART_SERVICES" = true ]; then
    echo ""
    echo "Reloading systemd and restarting services..."
    ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << 'EOF'
        systemctl daemon-reload
        
        # Enable and restart Aria2
        systemctl enable aria2 2>/dev/null || true
        systemctl restart aria2 2>/dev/null || echo "Warning: aria2 not running"
        
        # Enable and restart Mihomo (service always enabled now)
        systemctl enable mihomo 2>/dev/null || true
        systemctl restart mihomo 2>/dev/null || echo "Warning: mihomo not running"
        
        # Restart Nginx and PHP
        systemctl restart nginx 2>/dev/null || echo "Warning: nginx not running"
        systemctl restart php*-fpm 2>/dev/null || echo "Warning: php-fpm not running"
        
        # Restart Samba
        systemctl restart smbd 2>/dev/null || echo "Warning: smbd not running"
        systemctl restart nmbd 2>/dev/null || echo "Warning: nmbd not running"
        
        # Set Samba password for dietpi user (required for login)
        (echo "dietpi"; echo "dietpi") | smbpasswd -s -a dietpi
EOF
fi

echo ""
echo "=== Deployment Complete ==="
echo "Run ./status.sh to verify services are running"