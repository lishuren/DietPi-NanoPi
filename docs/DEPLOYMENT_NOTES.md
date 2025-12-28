
# Deployment Notes (as of December 28, 2025)

## Summary

This document tracks all deployment steps, automation, and troubleshooting for the DietPi-NanoPi project. All major setup and configuration steps are now automated via the provided scripts. Use this as a reference for what is handled by automation and what may require manual intervention.


### 1. Package Installation (China/GFW Workaround)

**Manual command (now automated):**
See `docs/RUNBOOK.md` for the GitHub Connectivity Blocked troubleshooting section. All required packages (OpenSSH, Aria2, Nginx, Samba, PHP, unzip) are installed automatically by DietPi using the provided `dietpi.txt`.

---


### 2. Web Assets Deployment

**Now automated in:** `setup.sh` – Uploads and extracts all web assets (homepage, VPN UI, API files) with correct permissions to the Pi.

---


### 3. Nginx PHP Configuration

**Now automated in:**
- `local_configs/nginx-default-site` – PHP-enabled site config
- `deploy.sh` – Uploads config and restarts Nginx and PHP-FPM services

---


### 4. Aria2 Service Setup

**Now automated in:**
- `local_configs/aria2.service` – Systemd service file
- `local_configs/aria2.conf` – Aria2 configuration
- `deploy.sh` – Creates directories, enables service, and restarts Aria2

---


### 5. Samba Share Configuration

**Now automated in:**
- `local_configs/smb.conf` – Full Samba config with downloads share
- `deploy.sh` – Creates directory with correct permissions and restarts Samba services

---


## Files Created/Modified

### Configuration Files
- `local_configs/aria2.service` – Aria2 systemd service
- `local_configs/aria2.conf` – Aria2 download manager config
- `local_configs/nginx-default-site` – Nginx site config with PHP enabled
- `local_configs/nginx.conf` – Main Nginx config
- `local_configs/smb.conf` – Samba config with downloads share
- `assets/web/api/system.php` – System status API endpoint

### Scripts Updated
- `setup.sh` – Uploads all web assets and API files
- `deploy.sh` – Directory initialization, config deployment, service restarts

### Documentation
- `docs/RUNBOOK.md` – Added "GitHub Connectivity Blocked (China/GFW)" troubleshooting
- `dietpi.txt` – Updated to skip update checks on first boot

---


## Deployment Workflow

### Fresh Pi Setup
1. Flash DietPi image
2. Copy updated `dietpi.txt` to boot partition
3. Boot Pi (wait 5-10 mins)
4. **In China:** Follow RUNBOOK.md GFW workaround to bypass stuck first-run
5. SSH in and verify IP
6. On PC: `./setup.sh` – Uploads all assets
7. On PC: `./deploy.sh` – Deploys configs and starts services
8. On PC: `./status.sh` – Verify all services running

### Service URLs
- Portal: http://192.168.0.139/
- VPN UI: http://192.168.0.139/vpn.php
- Samba: \\192.168.0.139\downloads

---


## Known Issues & Solutions

### Aria2 fails to start with "File not found" error
**Cause:** Session file doesn't exist  
**Solution:** `deploy.sh` now creates `/mnt/aria2/aria2.session` on USB drive

### PHP files download instead of executing
**Cause:** Nginx not configured for PHP  
**Solution:** `nginx-default-site` has PHP fastcgi block enabled

### Samba share not accessible
**Cause:** Directory doesn't exist or wrong permissions  
**Solution:** `deploy.sh` creates `/mnt/downloads` with 777 permissions

---


## Next Steps (Not Yet Automated)

1. **Mihomo VPN Setup** – Requires user subscription URL
2. **USB Drive Auto-mount** – DietPi Drive Manager configuration
3. **SSL/HTTPS** – Let's Encrypt certificate (requires domain name)
4. **Firewall Configuration** – UFW or iptables rules
5. **Automated Backups** – Cron job for config backups

---

**Last Updated:** December 28, 2025  
**Tested On:** NanoPi NEO2 (ARMv8), DietPi v9.20.1, Debian Bookworm
