# Project Context: NanoPi NEO Download Station

## 1. Project Overview
This project is a fully automated "Infrastructure as Code" setup for a NanoPi NEO (ARMv7) running DietPi. It functions as a headless download station with VPN support, managed remotely.

## 2. Core Components
- **OS:** DietPi (Debian Bookworm based).
- **Downloader:** Aria2 (running as a systemd service).
- **Frontend:** AriaNg (Web UI for Aria2).
- **Storage:** External USB Drive (Auto-mounted via UUID, sleep disabled).
- **File Sharing:** Samba (SMB) share for accessing downloads.
- **VPN/Proxy:** Mihomo (Clash Meta) for routing Aria2 traffic securely.
- **Management:** Custom PHP WebUI for VPN control and subscription updates.

## 3. Key Design Principles
- **Stateless TF Card:** No persistent data is stored on the SD card.
- **Persistent USB:** Downloads and Aria2 Session state (`aria2.session`) live on the USB drive.
- **Idempotent Provisioning:** The `provision.sh` script can be run multiple times to set up or repair the system.
- **Code-driven Provisioning:** Versioned scripts and configs in this repo define and reproduce the device state end-to-end.
- **Remote Deployment:** All changes are pushed from the PC (Mac) to the device via `deploy.sh`.

## 4. Script Inventory (`scripts/`)
- **`deploy.sh`**: The main entry point for the user. Syncs code from PC to NanoPi and executes scripts remotely.
    - Usage: `./scripts/deploy.sh [ip] [script_name]`
- **`provision.sh`**: The master installation script. Handles USB mounting, software installation, and service configuration.
- **`install_vpn_web_ui.sh`**: Generates the `vpn.php` control panel and configures `sudoers` for web-based control.
- **`toggle_vpn.sh`**: Backend script used by the WebUI to start/stop Clash and update Aria2 proxy settings.
- **`update_subscription.sh`**: Backend script to download and reload Clash config from a URL.
- **`monitor_mount.sh`**: Watchdog script (cron job) to ensure USB remains mounted and Aria2 is running.
- **`install_clash.sh`**: Downloads and installs the Mihomo binary.

## 5. Workflows

### Initial Setup / Recovery
1. Flash DietPi image to SD card.
2. Boot NanoPi.
3. Run from PC: `./scripts/deploy.sh <ip-address> provision.sh`

### Updating Code/Config
1. Edit files locally on PC.
2. Push changes: `./scripts/deploy.sh <ip-address> <script-to-run>`
   - Example: `./scripts/deploy.sh install_vpn_web_ui.sh`

### Using the System
- **Aria2 UI:** `http://<ip>/ariang`
- **VPN Control:** `http://<ip>/vpn.php` (Toggle VPN, Update Subscription)
- **Files:** `smb://<ip>/downloads`

## 6. Configuration Files (`config/`)
- **`dietpi.txt`**: Automation config for DietPi (Auto-install software IDs: 105, 68, 69, 84, 96, 89).
- **`aria2.conf`**: Optimized Aria2 settings (RPC enabled, session saving enabled).
