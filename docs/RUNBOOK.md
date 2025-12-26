# DietPi NanoPi Download Station - Runbook

Complete setup and operations guide for the DietPi NanoPi Download Station project.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [SSH Key Configuration](#ssh-key-configuration)
4. [Asset Preparation](#asset-preparation)
5. [Deployment](#deployment)
6. [Verification](#verification)
7. [Daily Operations](#daily-operations)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware
- **NanoPi NEO or NEO2** (ARMv7 or ARMv8)
- **TF card** (8GB minimum, 16GB+ recommended)
- **USB storage device** (formatted as ext4, exFAT, or NTFS)
- **Network connection** (Ethernet recommended)

### Software (PC Side)
- **Windows**: PowerShell with SSH client, or WSL/Git Bash
- **Mac/Linux**: Terminal with SSH client
- **SD Card Tool**: Etcher, Win32DiskImager, or dd

---

## Initial Setup

### Step 1: Download DietPi Image

1. Go to https://dietpi.com/downloads/images/
2. Find **NanoPi NEO** or **NanoPi NEO2** image
3. Download the Bookworm (Debian 12) version:
   - For NEO (ARMv7): `DietPi_NanoPiNEO-ARMv7-Bookworm.img.xz`
   - For NEO2 (ARMv8): `DietPi_NanoPiNEO2-ARMv8-Bookworm.img.xz`

**Important**: Do NOT commit this image to git. It's 200MB+ compressed.

### Step 2: Flash TF Card

#### Windows (using Etcher)
```powershell
# Download and install Etcher from balena.io
# Run Etcher, select image, select SD card, flash
```

#### Linux/Mac
```bash
# Extract image
xz -d DietPi_NanoPiNEO-ARMv7-Bookworm.img.xz

# Flash to SD card (replace /dev/sdX with your SD card)
sudo dd if=DietPi_NanoPiNEO-ARMv7-Bookworm.img of=/dev/sdX bs=4M status=progress
sync
```

### Step 3: Configure dietpi.txt

1. Mount the boot partition of the TF card
2. Copy `dietpi.txt` from project root to the boot partition
3. **Optional**: Edit settings (timezone, password, etc.)

### Step 4: First Boot

1. Insert TF card into NanoPi
2. Connect Ethernet cable and USB storage
3. Power on
4. Wait 5-10 minutes for auto-installation
5. Find Pi IP address in router's DHCP client list

---

## SSH Key Configuration

### Generate SSH Key Pair

```bash
cd /path/to/DietPi-NanoPi
ssh-keygen -t rsa -b 4096 -f dietpi.pem -C "dietpi-nanopi"
chmod 600 dietpi.pem  # Linux/Mac only
```

### Create Configuration File

```bash
cp pi.config.example pi.config
# Edit pi.config with your Pi's IP address
```

### Copy Public Key to Pi

```bash
# First time only - uses password "dietpi"
ssh-copy-id -i dietpi.pem.pub root@192.168.1.100
```

---

## Asset Preparation

Download required assets to the `assets/` folder:

### 1. Mihomo (Clash Meta)
- Visit: https://github.com/MetaCubeX/mihomo/releases
- Download: `mihomo-linux-armv7-*.gz` (for NEO) or `mihomo-linux-arm64-*.gz` (for NEO2)
- Extract and rename to: `assets/binaries/mihomo`

### 2. GeoIP Database
- Visit: https://github.com/Dreamacro/maxmind-geoip/releases
- Download: `Country.mmdb`
- Rename to: `assets/binaries/country.mmdb`

### 3. AriaNg Web UI
- Visit: https://github.com/mayswind/AriaNg/releases
- Download: `AriaNg-*-AllInOne.zip`
- Rename to: `assets/web/AriaNg.zip`

See [assets/README.md](../assets/README.md) for detailed download links.

---

## Deployment

### Initial Deployment

```bash
# 1. Install assets to Pi
./setup.sh

# 2. Deploy configurations
./deploy.sh

# 3. Check status
./status.sh
```

### USB Drive Setup

After first boot, the USB drive must be mounted to `/mnt`:

```bash
# SSH to Pi
ssh -i dietpi.pem root@<pi-ip>

# Find USB device
lsblk

# Mount USB drive (replace sda1 with your device)
mount /dev/sda1 /mnt

# Create required directories
mkdir -p /mnt/downloads /mnt/aria2
touch /mnt/aria2/aria2.session

# Make mount persistent across reboots
echo '/dev/sda1 /mnt exfat defaults 0 2' >> /etc/fstab

# Verify mount
df -h /mnt
```

**Note:** USB drive filesystem can be exfat, ext4, or NTFS. Adjust fstab accordingly.

### Development Workflow

```bash
# Edit configs locally
nano local_configs/aria2.conf

# Deploy changes
./deploy.sh

# Verify
./status.sh
```

---

## Verification

### Check Services

```bash
./status.sh
```

Expected output shows all services as `active (running)`.

### Test Web Access

- **Portal**: `http://<pi-ip>/`
- **AriaNg**: `http://<pi-ip>/ariang`
- **VPN Control**: `http://<pi-ip>/vpn.php`

### Test Samba Access

**Windows**: `Win+R → \\<pi-ip>\downloads`  
**Mac**: `Finder → Go → Connect to Server → smb://<pi-ip>/downloads`

---

## Daily Operations

### Edit Configurations

```bash
nano local_configs/aria2.conf
./deploy.sh
./status.sh
```

### Check Logs

```bash
./status.sh           # All services
./status.sh aria2     # Specific service
```

### Update Clash Subscription

Via Web UI: `http://<pi-ip>/vpn.php` → Paste URL → Update

Or edit `local_configs/clash_config.yaml` → `./deploy.sh`

---

## Troubleshooting

### GitHub Connectivity Blocked (China/GFW)

**Symptom:** DietPi first-run setup fails with "Failed to connect to raw.githubusercontent.com"

**Root Cause:** GitHub is blocked by the Great Firewall in China. DietPi's first-run setup always tries to check for updates from GitHub, regardless of CONFIG_CHECK_DIETPI_UPDATES setting (that only affects post-installation automated checks).

**Solution - Bypass DietPi Installation System:**

1. **Let first boot fail** (it will get stuck on update check dialog)

2. **SSH into the Pi** when the dialog appears:
   ```bash
   ssh -i dietpi.pem root@<pi-ip>
   ```

3. **Kill stuck processes and force direct APT installation:**
   ```bash
   # Kill the stuck dialog and dietpi-software loop
   pkill -9 whiptail
   pkill -9 dietpi-software
   pkill -9 dietpi-update
   
   # Set install stage to bypass first-run checks
   echo 1 > /boot/dietpi/.install_stage
   
   # Install packages directly with APT (bypasses DietPi's GitHub checks)
   apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
     openssh-server aria2 nginx-light samba php-fpm php-cli unzip > /tmp/install.log 2>&1 &
   ```

4. **Monitor installation progress:**
   ```bash
   # Check if apt is running (wait 10-15 minutes)
   ps aux | grep apt | grep -v grep
   
   # Check log
   tail -f /tmp/install.log
   ```

5. **Verify services after installation:**
   ```bash
   systemctl status nginx aria2 samba ssh
   # Nginx should show "active (running)"
   ```

6. **Create Aria2 service manually** (DietPi's automated setup was bypassed):
   ```bash
   # Will be covered in deployment section
   ```

**Why CONFIG_CHECK_DIETPI_UPDATES=0 doesn't help:**
- That setting only controls **automated daily checks** after installation
- **First-run setup** is hardcoded to check for updates regardless
- The only solution is to bypass dietpi-software and use direct APT installation

**After VPN is configured:** You can update DietPi through Mihomo VPN using the web portal's "Update System" button or manually: `dietpi-update`

---

### First-Run Installation Stuck or Hanging

If the Pi is stuck at a "First run setup failed" dialog or installation isn't progressing:

**Check if installation is still running:**
```bash
# Check for apt/dpkg processes
ssh -i dietpi.pem root@<pi-ip> "ps aux | grep -E 'apt|dpkg' | grep -v grep"

# If output shows apt-get running: WAIT 10-15 minutes, it's still installing
# If no output: Installation completed or stuck
```

**Check installation log:**
```bash
ssh -i dietpi.pem root@<pi-ip> "tail -20 /var/tmp/dietpi/logs/dietpi-firstrun-setup.log"

# Should show [OK] DietPi-Update | APT update or package installation messages
```

**If stuck on "DietPi-Update failed" dialog:**
```bash
# Kill the dialog and manually start software installation
ssh -i dietpi.pem root@<pi-ip> "pkill -f whiptail"
ssh -i dietpi.pem root@<pi-ip> "/boot/dietpi/dietpi-software install 105 132 85 96 89"

# Then monitor:
watch -n 5 'ssh -i dietpi.pem root@<pi-ip> "ps aux | grep -E apt"'
```

**Verify services after installation completes:**
```bash
# Check if services are running
ssh -i dietpi.pem root@<pi-ip> "systemctl status aria2 nginx samba ssh"

# If all show "active (running)", installation is complete
```

**Why this happens:**
- DietPi tries to check GitHub during first boot but network may not be ready
- The update check fails but APT (Debian repos) works fine
- Software still installs even if update check fails
- Solution: `dietpi.txt` now has `CONFIG_CHECK_DIETPI_UPDATES=2` to disable this check

---

### Cannot Connect via SSH

```bash
# Test connection
ping <pi-ip>

# Verify SSH key permissions
chmod 600 dietpi.pem
```

### Aria2 Not Starting

```bash
# Check logs
./status.sh aria2

# Verify USB mount
ssh -i dietpi.pem root@<pi-ip>
df -h /mnt
```

### Nginx Shows Default Page

```bash
# Deploy homepage
./deploy.sh

# Remove nginx default
ssh -i dietpi.pem root@<pi-ip>
rm -f /var/www/html/index.nginx-debian.html
```

### Services Not Responding

```bash
# Check status
./status.sh

# Restart services
./deploy.sh
```

---

## Security Best Practices

1. Never commit `dietpi.pem` or `pi.config` to git
2. Set SSH key permissions: `chmod 600 dietpi.pem`
3. Change default password: `ssh -i dietpi.pem root@<ip>` → `passwd`
4. Use Aria2 RPC secret in `local_configs/aria2.conf`

---

## Maintenance

### Update DietPi

```bash
ssh -i dietpi.pem root@<pi-ip>
dietpi-update
```

### Backup Configuration

```bash
./download.sh
git add local_configs/
git commit -m "Backup configs"
git push
```

---

**For more details:**
- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) - Architecture overview
- [../assets/README.md](../assets/README.md) - Asset download links
- [../local_configs/README.md](../local_configs/README.md) - Config management
