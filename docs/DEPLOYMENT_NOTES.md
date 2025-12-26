# Deployment Notes - December 26, 2025

## Summary of Manual Steps (Now Automated)

This document tracks the manual steps taken during first deployment that are now automated in the scripts.

### 1. Package Installation (China/GFW Workaround)

**Manual command executed:**
```bash
pkill -9 whiptail; pkill -9 dietpi-software; pkill -9 dietpi-update
echo 1 > /boot/dietpi/.install_stage
apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  openssh-server aria2 nginx-light samba php-fpm php-cli unzip
```

**Why:** DietPi's first-run setup fails in China due to GitHub being blocked by GFW.

**Now automated in:** `docs/RUNBOOK.md` - GitHub Connectivity Blocked troubleshooting section

---

### 2. Web Assets Deployment

**Manual commands executed:**
```bash
# Upload homepage and VPN UI
scp index.html vpn.php root@pi:/var/www/html/

# Upload API files
mkdir -p /var/www/html/api
scp api/system.php root@pi:/var/www/html/api/

# Extract AriaNg
cd /var/www/html/ariang
unzip /tmp/AriaNg.zip
chmod -R 755 /var/www/html/ariang
```

**Now automated in:** `setup.sh` - Uploads and extracts all web assets with proper permissions

---

### 3. Nginx PHP Configuration

**Manual commands executed:**
```bash
# Updated /etc/nginx/sites-available/default to:
# - Add index.php to index directive
# - Enable PHP location block with fastcgi_pass unix:/run/php/php-fpm.sock
# - Enable .htaccess deny block

systemctl restart nginx
systemctl restart php*-fpm
```

**Now automated in:**
- `local_configs/nginx-default-site` - PHP-enabled site config
- `deploy.sh` - Uploads config and restarts services

---

### 4. Aria2 Service Setup

**Manual commands executed:**
```bash
# Create service file at /etc/systemd/system/aria2.service
# Upload config to /etc/aria2/aria2.conf

# Create required directories
mkdir -p /mnt/usb_drive/aria2
touch /mnt/usb_drive/aria2/aria2.session
mkdir -p /mnt/downloads

# Enable and start service
systemctl daemon-reload
systemctl enable aria2
systemctl start aria2
```

**Now automated in:**
- `local_configs/aria2.service` - Systemd service file
- `local_configs/aria2.conf` - Configuration
- `deploy.sh` - Creates directories, enables service, restarts

---

### 5. Samba Share Configuration

**Manual commands executed:**
```bash
# Added to /etc/samba/smb.conf:
[downloads]
   comment = Download Files
   path = /mnt/downloads
   browseable = yes
   read only = no
   guest ok = yes
   create mask = 0775
   directory mask = 0775

# Create share directory
mkdir -p /mnt/downloads
chmod 777 /mnt/downloads

# Restart Samba
systemctl restart smbd nmbd
```

**Now automated in:**
- `local_configs/smb.conf` - Full Samba config with downloads share
- `deploy.sh` - Creates directory with permissions, restarts services

---

## Files Created/Modified

### Configuration Files
- `local_configs/aria2.service` - Aria2 systemd service
- `local_configs/aria2.conf` - Aria2 download manager config
- `local_configs/nginx-default-site` - Nginx site config with PHP enabled
- `local_configs/nginx.conf` - Main Nginx config
- `local_configs/smb.conf` - Samba config with downloads share
- `assets/web/api/system.php` - System status API endpoint

### Scripts Updated
- `setup.sh` - Added chmod for AriaNg, API file upload
- `deploy.sh` - Added directory initialization, PHP-FPM restart, service enable commands

### Documentation
- `docs/RUNBOOK.md` - Added "GitHub Connectivity Blocked (China/GFW)" troubleshooting
- `dietpi.txt` - Changed CONFIG_CHECK_DIETPI_UPDATES and CONFIG_CHECK_APT_UPDATES to 0

---

## Deployment Workflow (After Today's Changes)

### Fresh Pi Setup:
1. Flash DietPi image
2. Copy updated `dietpi.txt` to boot partition
3. Boot Pi (wait 5-10 mins)
4. **In China:** Follow RUNBOOK.md GFW workaround to bypass stuck first-run
5. SSH in and verify IP
6. On PC: `./setup.sh` - Uploads all assets
7. On PC: `./deploy.sh` - Deploys configs and starts services
8. On PC: `./status.sh` - Verify all services running

### Service URLs:
- Portal: http://192.168.0.139/
- AriaNg: http://192.168.0.139/ariang/
- VPN UI: http://192.168.0.139/vpn.php
- Samba: \\\\192.168.0.139\\downloads

---

## Known Issues & Solutions

### Issue: Aria2 fails to start with "File not found" error
**Cause:** Session file doesn't exist  
**Solution:** `deploy.sh` now creates `/mnt/usb_drive/aria2/aria2.session`

### Issue: AriaNg shows 403 Forbidden
**Cause:** Missing permissions or unzip failed  
**Solution:** `setup.sh` now runs `chmod -R 755` after extraction

### Issue: PHP files download instead of executing
**Cause:** Nginx not configured for PHP  
**Solution:** `nginx-default-site` has PHP fastcgi block enabled

### Issue: Samba share not accessible
**Cause:** Directory doesn't exist or wrong permissions  
**Solution:** `deploy.sh` creates `/mnt/downloads` with 777 permissions

---

## Next Steps (Not Yet Automated)

1. **Mihomo VPN Setup** - Requires subscription URL (user-specific)
2. **USB Drive Auto-mount** - DietPi Drive Manager configuration
3. **SSL/HTTPS** - Let's Encrypt certificate (requires domain name)
4. **Firewall Configuration** - UFW or iptables rules
5. **Automated Backups** - Cron job for config backups

---

**Last Updated:** December 26, 2025  
**Tested On:** NanoPi NEO2 (ARMv8), DietPi v9.20.1, Debian Bookworm
