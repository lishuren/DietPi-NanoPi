# Project Context: NanoPi NEO Download Station

## 1. Project Overview
This project is a fully automated "Infrastructure as Code" setup for a NanoPi NEO/NEO2 running DietPi. It functions as a headless download station with VPN support, managed entirely from a PC.

## 2. Core Components
- **OS:** DietPi (Debian Bookworm based)
- **Downloader:** Aria2 (systemd service)
- **Web Server:** Nginx
- **Storage:** External USB Drive (auto-mounted via UUID)
- **File Sharing:** Samba (SMB) share for network access
- **VPN/Proxy:** Mihomo (Clash Meta) for routing traffic securely
- **Management:** PHP Web UI for VPN control and subscription updates

## 3. Key Design Principles
- **PC-Driven Workflow:** All operations run from PC using SSH keys - no manual SSH needed
- **Stateless TF Card:** No persistent data on SD card
- **Persistent USB:** Downloads and session state on USB drive
- **Version-Controlled Configs:** `local_configs/` folder as single source of truth
- **Idempotent Deployment:** Scripts can run multiple times safely
- **Security First:** SSH key authentication, no passwords committed to git

## 4. New Architecture (Post-Restructure)

### Root-Level Scripts (PC Side)
- **`setup.sh`**: Upload assets (binaries, web files) to Pi
- **`download.sh`**: Download current configs from Pi to `local_configs/`
- **`update_configs.sh`**: Regenerate/update local configs programmatically
- **`deploy.sh`**: Deploy `local_configs/` to Pi and restart services
- **`status.sh`**: Check Pi system status and view logs

### Configuration Management
- **`pi.config`**: Connection parameters (PEM_FILE, REMOTE_USER, REMOTE_HOST)
- **`dietpi.txt`**: DietPi auto-install configuration (at project root)
- **`local_configs/`**: Editable configs committed to git
  - `aria2.conf`, `aria2.service`
  - `mihomo.service`, `clash_config.yaml`
  - `smb.conf`, `nginx.conf`
  - `index.html` (portal)

### Assets Folder
- **`assets/binaries/`**: mihomo, country.mmdb, geosite.dat
  - **`assets/web/`**: vpn.php, index.html
- **`assets/templates/`**: config.yaml (Clash template)

## 5. Workflows

### Initial Setup
1. Flash DietPi with `dietpi.txt` on boot partition
2. Boot Pi, wait for auto-install
3. Generate SSH keys: `ssh-keygen -f dietpi.pem`
4. Copy public key to Pi: `ssh-copy-id -i dietpi.pem.pub root@<ip>`
5. Create `pi.config` from `pi.config.example`
6. Download assets (mihomo, etc.) to `assets/`
7. Run `./setup.sh` to install assets
8. Run `./deploy.sh` to deploy configurations

### Development Cycle
1. Edit files in `local_configs/` on PC
2. Run `./deploy.sh` to push changes to Pi
3. Run `./status.sh` to verify
4. Commit changes to git

### Adding New Configs
1. SSH to Pi manually (if needed) and configure
2. Run `./download.sh` to pull configs to `local_configs/`
3. Edit as needed
4. Run `./deploy.sh` to push back
5. Commit to git

## 6. Configuration Files

### DietPi Auto-Install (`dietpi.txt`)
Software IDs:
- **105**: OpenSSH Server
- **132**: Aria2
- **85**: Nginx
- **96**: Samba
- **89**: PHP

### SSH Configuration (`pi.config`)
```bash
PEM_FILE="dietpi.pem"
REMOTE_USER="root"
REMOTE_HOST="192.168.1.100"
```

### Local Configs (`local_configs/`)
All committed to git as "golden configuration":
- Systemd services
- Application configs
- Web files
- **`dietpi.txt`**: Automation config for DietPi (Auto-install software IDs: 105, 68, 69, 84, 96, 89).
- **`aria2.conf`**: Optimized Aria2 settings (RPC enabled, session saving enabled).
