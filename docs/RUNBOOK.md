# NanoPi NEO Download Station Runbook

## 1. Overview
This project transforms a NanoPi NEO into a robust, "always-on" download station using DietPi and Aria2. 
The design philosophy is **Infrastructure as Code**: all configurations are stored locally in this repository. If the TF card fails, we can rebuild the system in minutes without data loss (assuming the USB drive is intact).

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

# Example: Full Provisioning (Re-run everything)
./scripts/deploy.sh 192.168.1.100 provision.sh
```

## 9. Maintenance
- **Check Status:** `systemctl status aria2`
- **Logs:** `/var/log/aria2.log`
