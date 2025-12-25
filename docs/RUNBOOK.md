## Changing USB Disk

## Customizing the Home Page

## IP Changes and Access Stability

- The portal builds links and the Samba path using the live browser `hostname` (what you used to access the page), so it adapts automatically if the IP changes.
- To avoid broken bookmarks, prefer accessing via a hostname rather than an IP:
    - Reserve a static IP for the device in your router (DHCP reservation by MAC).
    - Or set a static IP in DietPi (`dietpi-config` → Network → Static IP) or by editing `/etc/dhcpcd.conf`.
    - Optionally enable mDNS for `dietpi.local` by installing `avahi-daemon`.
- UNC path: with Samba `netbios name` set to the device hostname, you can use `\\<hostname>\\downloads` in Windows even if the IP changes.

- Edit the repo page: [web/index.html](web/index.html)
- Redeploy to Lighttpd root:
    ```bash
    sudo bash scripts/install_home_page.sh
    sudo systemctl restart lighttpd
    sudo rm -f /var/www/html/index.lighttpd.html
    ```
- Open http://<pi-ip>/ to see changes.

- Stop services: `aria2`, `smbd`, `nmbd`.
- Unmount current mount: `/mnt/usb_drive`.
- Prepare the new disk (choose one):
    - Windows-friendly (exFAT): Use [scripts/windows/format_usb_exfat.ps1](scripts/windows/format_usb_exfat.ps1) on a PC.
    - Linux-native (ext4): Use [scripts/prepare_usb_ext4.sh](scripts/prepare_usb_ext4.sh) on the NanoPi (formats an existing partition only).
- Plug the disk into NanoPi and run provisioning: `sudo bash scripts/provision.sh`.
- Verify mount and services.

Notes:
- [scripts/provision.sh](scripts/provision.sh) auto-detects the filesystem (ext4/exfat/ntfs) and writes the appropriate `/etc/fstab` entry.
- For exFAT/NTFS, ownership and permissions are controlled via mount options (`uid`,`gid`,`umask`).
- The watchdog [scripts/monitor_mount.sh](scripts/monitor_mount.sh) ensures the mount stays healthy and restarts `aria2` if needed.

## End-to-End Quick Start (Fresh Device)

## Verification Checklist (Brand-New TF Card)

- Network:
    - Find the device IP in your router; SSH works: `ssh root@<IP>`.
- Provisioning:
    - Run `./scripts/provision.sh` without errors; it mounts `/mnt/usb_drive`.
    - `/etc/fstab` contains a UUID entry pointing to `/mnt/usb_drive` with correct filesystem type.
- Web UI:
    - http://<IP>/ loads the portal. Header shows the device address.
    - http://<IP>/ariang loads AriaNg.
    - http://<IP>/vpn.php loads VPN UI.
- Aria2:
    - `systemctl status aria2` is active.
    - AriaNg connects to RPC and can start a small test download.
- Samba:
    - Windows can open `\\<IP>\\downloads` or `\\<hostname>\\downloads`.
    - Files appear under `/mnt/usb_drive/downloads` on the device.
    - Reboot device; portal and services still work; USB drive remounts automatically.
    - Unplug/replug USB drive: watchdog remounts and restarts Aria2 if needed.

Follow these steps from zero to a working AriaNg UI and Windows share.

1) Prepare on PC (Windows)

**IMPORTANT**: All third-party downloads (AriaNg, Mihomo, GeoIP data) must be done on your PC first. The NanoPi will NOT download from the internet during provisioning.

```bash
# Clone the repo
git clone https://github.com/lishuren/DietPi-NanoPi.git
cd DietPi-NanoPi

# Download required assets (AriaNg, Mihomo, GeoIP data)
bash scripts/download_ariang.sh
bash scripts/download_mihomo.sh

# Alternatively, manually download and place in downloads/:
# - AriaNg-1.3.12.zip (from GitHub releases)
# - mihomo (binary for linux-armv7)
# - Country.mmdb
# - GeoSite.dat
```

2) Flash DietPi image to microSD
- Download the DietPi image for your NanoPi model from dietpi.com.
- Use Balena Etcher (or Rufus) to flash the image to the microSD card.
- After flashing, mount the boot partition and copy `config/dietpi.txt` from this repo to the card’s root to preseed settings.

3) Boot and find IP
- Insert the microSD into the NanoPi, connect Ethernet and power.
- Wait ~2–3 minutes for first boot; find the device IP via your router DHCP list.

4) Upload repo to NanoPi (PC → Pi)

This syncs all scripts, configs, AND the downloaded assets to the device.

```bash
scp -r ./scripts ./config ./downloads root@<NANOPI_IP>:/root/DietPi-NanoPi
```

---

5) Configure on the NanoPi (Pi-side only)

```bash
ssh root@<NANOPI_IP>
cd /root/DietPi-NanoPi

# Base provisioning (mounts USB, installs web stack/services)
./scripts/provision.sh

# One-shot AriaNg install
./scripts/setup_ariang.sh

# One-shot Samba setup
./scripts/setup_samba.sh --guest
# Or with user credentials:
# ./scripts/setup_samba.sh --user dietpi --password "yourpass"

# VPN setup (UI + subscription + enable)
./scripts/install_vpn_web_ui.sh
# Replace with your actual subscription URL
./scripts/update_subscription.sh "https://example.com/path/to/subscription.yaml"
./scripts/toggle_vpn.sh on
```

## Samba Access

Setup (one command on NanoPi):

```bash
cd /root/DietPi-NanoPi
# Guest access (no credentials):
./scripts/setup_samba.sh --guest

# Or user mode:
Windows:

6) Verify & access
- AriaNg UI: http://<NANOPI_IP>/ariang/
- Windows share: \\<NANOPI_IP>\downloads
- VPN Control: http://<NANOPI_IP>/vpn.php

- Open `\\<NANOPI_IP>\downloads` in Explorer (e.g., `\\192.168.0.139\downloads`).
- Map a drive via “This PC” → “Map network drive…”.
- `sudo apt-get install -y cifs-utils`
- `sudo mkdir -p /mnt/nanopi_downloads`
- `sudo mount -t cifs //<NANOPI_IP>/downloads /mnt/nanopi_downloads -o username=dietpi`
- Verify services: `systemctl status smbd nmbd`
- Validate config: `testparm -s`
- Ensure share path exists: `/mnt/usb_drive/downloads` with `dietpi:dietpi` ownership.
- Windows: clear saved creds (Credential Manager) and retry; confirm you’re using `SMB2` (SMB1 not required).
## AriaNg Dist Normalization & Verification

The installer now automatically normalizes AriaNg assets:

- Flattens common nested folders: `ariang`, `AriaNg`, and `dist`.
- Searches recursively for `index.html` and lifts that directory’s contents to the top level so `/var/www/html/ariang/index.html` exists.

### Deploy (recommended)

Use the deploy helper to sync the repo and run the installer on the NanoPi:

```bash
bash scripts/deploy.sh <NANOPI_IP> scripts/install_ariang.sh
```

Alternatively, SSH into the NanoPi and run:

```bash
cd /root/DietPi-NanoPi
./scripts/install_ariang.sh
```

### Verify

Check that `index.html` exists at the top level and the server responds correctly:

```bash
ls -l /var/www/html/ariang
curl -I http://localhost/ariang
curl -I http://localhost/ariang/
```

Expected:

- `index.html` is present in `/var/www/html/ariang` (not only inside a subfolder).
- HTTP `200 OK` for `/ariang/`, or a `301` redirect to `/ariang/` from `/ariang`.
- Not `403`/`404`.

If permissions are off, apply:

```bash
sudo chown -R www-data:www-data /var/www/html/ariang
sudo find /var/www/html/ariang -type d -exec chmod 755 {} \;
sudo find /var/www/html/ariang -type f -exec chmod 644 {} \;
sudo systemctl restart lighttpd
```

### Downloader Fallback (PC-side)

If `scripts/download_ariang.sh` or `scripts/download_mihomo.sh` fail due to network restrictions, manually download the assets:

#### AriaNg Manual Download

1. Visit: https://github.com/mayswind/AriaNg/releases
2. Download `AriaNg-1.3.12.zip` (or latest version)
3. Extract the `dist/` folder contents into `downloads/ariang/` in your repo
4. Or place the ZIP file directly in `downloads/` folder

#### Mihomo (Clash) Manual Download

1. Visit: https://github.com/MetaCubeX/mihomo/releases
2. Download `mihomo-linux-armv7-v1.18.1.gz`
3. Extract and rename to `mihomo`, place in `downloads/mihomo`
4. Make executable: `chmod +x downloads/mihomo` (Git Bash)

5. Visit: https://github.com/MetaCubeX/meta-rules-dat/releases
6. Download `country.mmdb` → save as `downloads/Country.mmdb`
7. Download `geosite.dat` → save as `downloads/GeoSite.dat`

After manual download, sync to NanoPi:
```bash
scp -r ./downloads ./scripts ./config root@<NANOPI_IP>:/root/DietPi-NanoPi
```

This ensures `/var/www/html/ariang/index.html` is present and served.

### One-Shot: Install AriaNg

Simplest option — auto-detect and install (staged → ZIP → URL):

```bash
cd /root/DietPi-NanoPi
./scripts/setup_ariang.sh
```

Direct installer options:

- From staged assets:
```bash
./scripts/install_ariang.sh
```

- From a ZIP path:
```bash
./scripts/install_ariang.sh --zip /root/AriaNg-1.3.12.zip
```

- From a URL:
```bash
./scripts/install_ariang.sh --url https://github.com/mayswind/AriaNg/releases/download/1.3.12/AriaNg-1.3.12.zip
```

### PC-side staging + deploy (optional)

On your PC (Windows Git Bash):

```bash
bash scripts/download_ariang.sh
# If you manually downloaded the ZIP, you can pass its path directly:
bash scripts/download_ariang.sh 'd:/dev/DietPi-NanoPi/downloads/AriaNg-1.3.12.zip'
# This will extract and stage assets into downloads/ariang/
```

Deploy and install on NanoPi:

```bash
scp -r ./downloads ./scripts ./config root@<NANOPI_IP>:/root/DietPi-NanoPi
ssh root@<NANOPI_IP> 'cd /root/DietPi-NanoPi && ./scripts/install_ariang.sh'
```

### Verify on NanoPi

```bash
ls -la /var/www/html/ariang | grep index.html
curl -I http://localhost/ariang
curl -I http://localhost/ariang/
```

Expected:

- `index.html` at `/var/www/html/ariang`. If missing, the installer places a placeholder page to avoid `403`.
- `/ariang/` returns `200 OK` (or `301` then `200`).

Fix permissions if needed:

```bash
sudo chown -R www-data:www-data /var/www/html/ariang
sudo find /var/www/html/ariang -type d -exec chmod 755 {} \;
sudo find /var/www/html/ariang -type f -exec chmod 644 {} \;
sudo systemctl restart lighttpd
```

Troubleshooting:

- Still `403/404`: confirm `index.html` exists at the top level; re-run the installer.
- Nested folders (e.g., `ariang/AriaNg/dist`): the installer flattens `ariang`, `AriaNg`, and `dist` automatically.
- Network blocks: use browser download, then stage `dist` into `downloads/ariang` and redeploy.

# NanoPi NEO Download Station Runbook

## 1. Overview
This project transforms a NanoPi NEO into a robust, "always-on" download station using DietPi and Aria2. 
The design philosophy is **Infrastructure as Code**: all configurations are stored locally in this repository. If the TF card fails, we can rebuild the system in minutes without data loss (assuming the USB drive is intact).

Provisioning is code-driven: versioned scripts and configs in this repo define and reproduce the device state end-to-end.

## 2. Hardware Requirements
- **Device:** NanoPi NEO (512MB RAM recommended)
- **Storage:** MicroSD Card (8GB+ Class 10)
- **External Storage:** USB Hard Drive or USB Stick (Formatted as ext4 recommended for performance)
- **Power:** 5V 2A Power Supply (Critical for USB stability)

## 3. Architecture & Recovery Strategy

### Challenge 1: TF Card Failure
**Solution:** We do not store any persistent data on the TF card.
- **OS/Configs:** Re-generated from this repository using `scripts/provision.sh`.
- **Downloads:** Stored on the external USB drive.
- **Aria2 Session:** Stored on the external USB drive.

### Challenge 2: Backup & Restore
**Solution:** The `aria2.session` file tracks all active, paused, and completed downloads.
- We configure Aria2 to read/write this file directly to the USB mount.
- If the TF card breaks:
    1. Flash a new card.
    2. Run `scripts/provision.sh`.
    3. The script remounts the USB drive.
    4. Aria2 starts and reads the existing `aria2.session` from the USB drive.
    5. All downloads resume exactly where they left off.

### Challenge 3: USB Drive Instability
**Solution:**
- **UUID Mounting:** We use the disk's unique UUID in `/etc/fstab` so it never mounts to the wrong location.
- **Watchdog Script:** A cron job (`scripts/monitor_mount.sh`) runs every minute to check if the drive is accessible. If not, it attempts to remount it and restart Aria2.

## 4. Setup Instructions

### Step 1: Prepare the Image
Run the download script on your Mac:
```bash
./scripts/download_image.sh
```
Flash the downloaded `.img` file to your SD card (using BalenaEtcher or similar).

### Step 2: Pre-Configuration
Before ejecting the card from your Mac:
1. Copy `config/dietpi.txt` to the root of the SD card (overwrite the existing one).
2. Configure your Wi-Fi credentials in `dietpi.txt` (if not using Ethernet).

### Step 3: First Boot
1. Insert SD card into NanoPi NEO.
2. Connect Ethernet (preferred) and Power.
3. Wait ~5-10 minutes for DietPi to initialize and update.

### Step 4: Provisioning
You can run the provisioning directly from your Mac using the deploy script.

**Option 1: From your Mac (Recommended)**
```bash
./scripts/deploy.sh <ip-address> provision.sh
```
*Note: You will be prompted for the root password (default: `dietpi`) twice.*

**Option 2: Manual (via SSH)**
1. SSH into the NanoPi: `ssh root@<ip-address>` (Default pass: `dietpi`).
2. Copy only what’s needed (lighter than the whole repo):
    ```bash
    # From your PC, in the repo root
    scp -r ./scripts ./config root@<ip-address>:/root/DietPi-NanoPi
    # If using the key from the optional section above:
    scp -i ~/.ssh/dietpi_key -r ./scripts ./config root@<ip-address>:/root/DietPi-NanoPi
    ```
    Example for your device (IP 192.168.0.139):
    ```bash
    scp -r ./scripts ./config root@192.168.0.139:/root/DietPi-NanoPi
    scp -i ~/.ssh/dietpi_key -r ./scripts ./config root@192.168.0.139:/root/DietPi-NanoPi
    ```
    If you prefer to sync everything (larger transfer):
    ```bash
    scp -r ./ root@<ip-address>:/root/DietPi-NanoPi
    ```
3. Run the provision script:
```bash
cd /root/DietPi-NanoPi
./scripts/provision.sh
```
Provisioning installs and configures:
- Lighttpd + PHP (FastCGI) and deploys AriaNg UI
- Aria2 daemon + systemd service
- Samba share for `downloads`
- Mihomo (Clash) and VPN Web UI (if present)

If you pull updates to the repo later, re-run the `scp` step to sync the latest `scripts/` and `config/` before re-provisioning.

### Optional: Set Up SSH Key Access
This lets you log in without typing the password each time.

1. Generate a key on your Mac/PC (bash/Git Bash):
    ```bash
    ssh-keygen -t ed25519 -f ~/.ssh/dietpi_key -N ""
    ```
2. Copy the public key to the NanoPi (prompts for your current password once):
    ```bash
    ssh-copy-id -i ~/.ssh/dietpi_key.pub root@<ip-address>
    ```
    If `ssh-copy-id` is unavailable:
    ```bash
    cat ~/.ssh/dietpi_key.pub | ssh root@<ip-address> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
    ```
3. Reconnect using the key (no password prompt):
    ```bash
    ssh -i ~/.ssh/dietpi_key root@<ip-address>
    ```
    Example for your device (IP 192.168.0.139):
    ```bash
    ssh -i ~/.ssh/dietpi_key root@192.168.0.139
    ```


## 5. Accessing the WebUI
Once the setup is complete, you can manage your downloads via the web interface.
- **URL:** `http://<ip-address>/ariang`
- **Connection Settings:**
    - **RPC Host:** `<ip-address>`
    - **RPC Port:** `6800`
    - **RPC Secret:** (Leave blank unless you uncommented it in `aria2.conf`)

Examples for your device (IP 192.168.0.139):

```text
AriaNg: http://192.168.0.139/ariang
```

### Offline AriaNg Setup (if GitHub is blocked)
On your PC (Git Bash):
```bash
cd D:/dev/DietPi-NanoPi
chmod +x ./scripts/download_ariang.sh
./scripts/download_ariang.sh
# Upload staged assets to the device
scp -r ./downloads/ariang root@<ip-address>:/root/DietPi-NanoPi/downloads/ariang
```
On the NanoPi:
```bash
cd /root/DietPi-NanoPi
./scripts/install_web_stack.sh
./scripts/install_ariang.sh
```
Then open: `http://<ip-address>/ariang`.

## 6. Accessing Files (Samba)
You can access your downloaded files directly from your Mac or PC.
- **Mac:** Finder -> Go -> Connect to Server -> `smb://<ip-address>/downloads`
- **Windows:** File Explorer -> `\\<ip-address>\downloads`
- **Username:** `dietpi`
- **Password:** `dietpi` (or whatever you changed it to)

## 7. VPN (Clash/Mihomo)
This setup includes Mihomo (Clash Meta) to proxy your downloads.

### Setup
You can set up the VPN configuration in two ways:

**Option A: Manual Upload**
1.  Get your Clash config YAML (e.g., from Clash Verge or your provider).
2.  Rename it to `config.yaml`.
3.  Upload it to the NanoPi: `/etc/mihomo/config.yaml`.

**Option B: Import from URL (Subscription)**
If you have a subscription link (http/https), run this command on the NanoPi:
```bash
./scripts/update_subscription.sh "YOUR_SUBSCRIPTION_URL_HERE"
```
*Note: Wrap the URL in quotes to avoid issues with special characters.*

**Option C: Pre-download Locally and Upload (Offline-friendly)**
If the NanoPi cannot reach GitHub, download on your PC and upload:

1. On your PC (bash/Git Bash):
    ```bash
    cd D:/dev/DietPi-NanoPi
    chmod +x ./scripts/download_mihomo.sh
    ./scripts/download_mihomo.sh
    ```
    If downloads are blocked, manually place these files in `downloads/`:
    - `mihomo` (from `mihomo-linux-armv7-v1.18.1.gz`, extracted and renamed)
    - `Country.mmdb`
    - `GeoSite.dat`

2. Upload to NanoPi:
    ```bash
    scp -r ./downloads ./scripts ./config root@192.168.0.139:/root/DietPi-NanoPi
    ```

3. On the NanoPi:
    ```bash
    ssh -i ~/.ssh/dietpi_key root@192.168.0.139
    cd /root/DietPi-NanoPi
    ./scripts/provision.sh
    ```

Troubleshooting: Filenames are case-sensitive. If needed on the NanoPi:
```bash
cd /root/DietPi-NanoPi/downloads
mv country.mmdb Country.mmdb 2>/dev/null || true
mv geosite.dat GeoSite.dat 2>/dev/null || true
```

### Usage
**Method 1: Web Interface (Recommended)**
Go to `http://<ip-address>/vpn.php` in your browser.
- **Toggle VPN:** Click **Turn ON** or **Turn OFF** to control the service.
- **Update Subscription:** Paste your subscription URL into the text box and click **Update Config**. This will download the latest config and restart the service automatically.
- The page shows the current status.

Example for your device (IP 192.168.0.139):

```text
VPN Control: http://192.168.0.139/vpn.php
```

**Method 2: Command Line**
```bash
# Turn VPN ON (Starts Clash, configures Aria2 to use proxy)
./scripts/toggle_vpn.sh on

# Turn VPN OFF (Stops Clash, removes proxy from Aria2)
./scripts/toggle_vpn.sh off
```

## 8. Remote Deployment (PC Side)
To update the system without manually SSH-ing into the device, you can use the `deploy.sh` script from your Mac/PC. This script syncs your local code to the NanoPi and executes the installation script.

The script will remember your NanoPi's IP address after the first use (saved in `config/deploy.env`).

```bash
# Usage: ./scripts/deploy.sh [ip-address] [script_name]

# First time (saves the IP):
./scripts/deploy.sh 192.168.1.100 install_vpn_web_ui.sh

# Subsequent runs (uses saved IP):
./scripts/deploy.sh install_vpn_web_ui.sh

# Or just run the default script (install_vpn_web_ui.sh):
./scripts/deploy.sh
```

Note: If `rsync` is not available on your PC, `deploy.sh` automatically falls back to `scp` to sync `scripts/`, `config/`, and `downloads/`.

### Example: Full Provisioning (Re-run everything)
```bash
./scripts/deploy.sh 192.168.1.100 provision.sh
```

## PC-Side Provisioning (No Pi-side shell)

Run everything from your PC via SSH, including provisioning and verification. Replace `<NANOPI_IP>` with your device IP.

### Sync and Provision

```bash
# Sync repo folders to the device
scp -r ./scripts ./config ./downloads root@<NANOPI_IP>:/root/DietPi-NanoPi

# Run provisioning remotely under bash
ssh root@<NANOPI_IP> 'bash -lc "cd /root/DietPi-NanoPi && chmod +x scripts/*.sh && bash scripts/provision.sh"'
```

### Quick Status Checks

```bash
ssh root@<NANOPI_IP> 'systemctl status aria2 --no-pager'
ssh root@<NANOPI_IP> 'findmnt /mnt/usb_drive'
ssh root@<NANOPI_IP> 'journalctl -u aria2 -n 200 --no-pager'
ssh root@<NANOPI_IP> 'systemctl status smbd nmbd --no-pager'
```

### (Optional) Format USB as ext4 remotely

If mounting fails with messages like "wrong fs type, bad superblock" and the drive is new or you plan to use ext4, format the partition from your PC. This ERASES all data on that partition.

```bash
# Inspect disks
ssh root@<NANOPI_IP> 'lsblk -f'

# Format target partition (replace /dev/sda1 accordingly)
ssh root@<NANOPI_IP> 'bash -lc "cd /root/DietPi-NanoPi && echo YES | bash scripts/prepare_usb_ext4.sh /dev/sda1 usbdata"'

# Re-run provisioning
ssh root@<NANOPI_IP> 'bash -lc "cd /root/DietPi-NanoPi && bash scripts/provision.sh"'
```

### (Optional) Format USB as exFAT remotely

If you prefer cross‑platform plug‑and‑play (Windows/macOS/Linux), you can use exFAT. Ownership/permissions are controlled by mount options, not stored in the filesystem.

**IMPORTANT**: You must sync the latest scripts to the NanoPi before formatting, otherwise `prepare_usb_exfat.sh` will not be found.

```bash
# 1) Sync repo folders to the device (required before formatting)
scp -r ./scripts ./config ./downloads root@<NANOPI_IP>:/root/DietPi-NanoPi

# 2) Inspect disks
ssh root@<NANOPI_IP> 'lsblk -f'

# 3) Format target partition as exFAT (DESTROYS data; replace /dev/sda1)
ssh root@<NANOPI_IP> 'bash -lc "cd /root/DietPi-NanoPi && echo YES | bash scripts/prepare_usb_exfat.sh /dev/sda1 usbdrive"'

# 4) Re-run provisioning; exFAT is auto-detected and fstab entry will use uid/gid/umask
ssh root@<NANOPI_IP> 'bash -lc "cd /root/DietPi-NanoPi && bash scripts/provision.sh"'
```

Or format from Windows using the helper:

```powershell
powershell -File scripts/windows/format_usb_exfat.ps1
```

### exFAT vs ext4: risks and trade‑offs
- Reliability: exFAT has no journal; unexpected power loss can cause metadata corruption more easily than ext4. Mitigation: watchdog remount, safe removal, periodic `fsck.exfat` (from exfatprogs).
- Permissions: no real POSIX ownership/permissions; Linux uses mount options (`uid`,`gid`,`umask`). For a single‑user server, this is acceptable.
- Features: no symlinks/hardlinks; some Unix workflows may not work if placed on the exFAT drive (keep configs/binaries on TF card).
- Performance: good enough for downloads on NanoPi; NTFS via `ntfs-3g` is heavier, ext4 is fastest on Linux.
- Portability: best cross‑platform choice; Windows and macOS read/write exFAT natively.

### Diagnostics for mount failures (no reformat)

If ext4 still fails to mount and `dmesg` shows messages like `EXT4-fs (sda1): Could not load journal inode`, try non-destructive repair and journal recreation:

```bash
# Inspect fstab entry
ssh root@<NANOPI_IP> 'bash -lc "grep UUID= /etc/fstab; cat /etc/fstab"'

# Kernel messages around ext4
ssh root@<NANOPI_IP> 'dmesg | tail -n 200 | grep -i -E "sda|ext4|mount" -n || dmesg | tail -n 100'

# Stop services, unmount, and repair
ssh root@<NANOPI_IP> 'bash -lc "systemctl stop aria2 || true; umount /dev/sda1 || true; e2fsck -fy /dev/sda1"'

# Attempt journal recreation if needed, then re-check
ssh root@<NANOPI_IP> 'bash -lc "tune2fs -j /dev/sda1 || true; e2fsck -fy /dev/sda1; mount -a; findmnt /mnt/usb_drive"'

# As last resort for diagnostics (read-only, ignores journal; not for normal use)
ssh root@<NANOPI_IP> 'bash -lc "mount -o ro,noload -t ext4 /dev/sda1 /mnt/usb_drive && findmnt /mnt/usb_drive"'
```

## 9. Maintenance
- **Check Status:** `systemctl status aria2`
- **Logs:** `/var/log/aria2.log`

## 10. Troubleshooting
- **AriaNg 404/403:**
    - Verify `/var/www/html/ariang/index.html` exists.
    - Run the installer to normalize structure and fix permissions:
        ```bash
        cd /root/DietPi-NanoPi
        ./scripts/install_ariang.sh
        ```
    - If you uploaded into a nested folder (e.g., `/var/www/html/ariang/ariang`), the installer will flatten it. If needed manually:
        ```bash
        mv /var/www/html/ariang/ariang/* /var/www/html/ariang/ 2>/dev/null || mv /var/www/html/ariang/AriaNg/* /var/www/html/ariang/ 2>/dev/null
        rm -rf /var/www/html/ariang/ariang /var/www/html/ariang/AriaNg 2>/dev/null
        chown -R www-data:www-data /var/www/html/ariang
        find /var/www/html/ariang -type d -exec chmod 755 {} \;
        find /var/www/html/ariang -type f -exec chmod 644 {} \;
        systemctl restart lighttpd
        ```
- **USB ext4 directory checksum errors (Bad message during chown):**
    - Unmount and repair the filesystem:
        ```bash
        systemctl stop aria2 || true
        umount /mnt/usb_drive
        e2fsck -fD /dev/sda1   # add -y for non-interactive
        mount -a
        ```
    - Re-run provisioning:
        ```bash
        cd /root/DietPi-NanoPi
        ./scripts/provision.sh
        ```
