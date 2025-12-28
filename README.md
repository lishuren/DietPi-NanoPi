# 🍓 DietPi Download Station

**Automated NAS setup for NanoPi, Raspberry Pi, and other SBCs with Aria2, VPN, and Samba**

Turn a low-cost Single Board Computer (like NanoPi NEO, Raspberry Pi, Orange Pi) into a powerful headless download station with web-based management, VPN support, and network file sharing.

## ✨ Features

- ⬇️ **Aria2 Downloader** - High-performance download manager with web UI
- 🔒 **VPN/Proxy Support** - Mihomo (Clash Meta) for secure routing
- 📁 **Samba File Sharing** - Access downloads from any device on your network
- 🌐 **Web Management Portal** - Real-time system status and service control
- 💾 **USB Storage** - Auto-mount with persistent downloads
- 🚀 **Infrastructure as Code** - Complete PC-to-Pi deployment workflow

## 🚀 Quick Start

### 1. Download & Flash DietPi Image
```bash
# Download from: https://dietpi.com/downloads/images/
# Get the correct image for your device (e.g., NanoPi NEO, Raspberry Pi 4, etc.)
# For NanoPi NEO: DietPi_NanoPiNEO-ARMv7-Bookworm.img.xz
# For NanoPi NEO2: DietPi_NanoPiNEO2-ARMv8-Trixie.img.xz

# Flash to TF card using Etcher or Win32DiskImager
```

### 2. Copy dietpi.txt to Boot Partition
```powershell
# After flashing, copy dietpi.txt to the boot partition
Copy-Item dietpi.txt <boot-drive-letter>:\
```

### 3. Boot the Pi
- Insert TF card into NanoPi
- Connect USB drive
- Connect Ethernet cable
- Power on
- **Wait 5-10 minutes** for DietPi auto-install

### 4. Find Pi IP Address
Check your router's DHCP client list for device named "DietPi"

### 5. Setup SSH Keys
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f dietpi.pem -C "dietpi-nanopi"

# Create configuration file
cp pi.config.example pi.config
# Edit pi.config with your Pi's IP address

# Copy public key to Pi (first time only, password: "dietpi")
ssh-copy-id -i dietpi.pem.pub root@192.168.1.100
```

### 6. Verify SSH Connection
```bash
# If you get "REMOTE HOST IDENTIFICATION HAS CHANGED" warning:
# (This happens when reflashing the Pi or reusing an IP address)
ssh-keygen -R 192.168.1.100

# First SSH connection to DietPi
ssh -i dietpi.pem root@192.168.1.100

# On first login, DietPi will run its first-run setup wizard:
# 1. Accept/update global password (default: "dietpi")
# 2. Wait for software installation to complete (5-10 minutes)
# 3. Setup completes automatically (services start)
# 4. You'll see the DietPi banner and command prompt

# Note: dietpi.txt has CONFIG_CHECK_DIETPI_UPDATES=2 to skip GitHub update checks
# during first boot (avoiding connectivity issues). You can update manually later
# using the Update System button on the web portal or run: dietpi-update

# After first login succeeds, type 'exit' to disconnect
# Subsequent connections will be immediate (no wizard)
```

### 7. Deploy to Pi
```bash
# Install assets to Pi
./setup.sh

# Deploy configurations
./deploy.sh

# Check status
./status.sh
```

### 8. Access Services
- **Portal**: http://192.168.1.100/
- **AriaNg**: http://192.168.1.100/ariang
- **VPN UI**: http://192.168.1.100/vpn.php
- **Samba**: `\\192.168.1.100\downloads`

### 9. Update VPN Subscription (MetaCubeX/Mihomo)

To fetch the latest Clash/Mihomo subscription config for MetaCubeX:

```bash
# Download your provider's config (replace URL with your actual subscription link)
./SubscriptionVPN.sh "https://your-provider-subscription-url.com"
# This saves to ./local_configs/subscription.yaml by default
```

- The script sets the correct User-Agent for full config downloads.
- You can also download manually:

```bash
curl -sSL -H "User-Agent: clash" "https://your-provider-subscription-url.com" -o ./local_configs/subscription.yaml
```

**Deployment:**
- `deploy.sh` will automatically deploy `local_configs/subscription.yaml` to `/etc/mihomo/providers/subscription.yaml` on your Pi.
- You can edit or update the file anytime and re-run `deploy.sh`.

> ⚠️ Some providers require the `User-Agent: clash` header to return a full config, not just a node list.

## 📁 Project Structure

```
DietPi-NanoPi/
├── dietpi.txt              # DietPi auto-install config
├── pi.config.example       # SSH connection template
│
├── setup.sh                # Install assets to Pi
├── deploy.sh               # Deploy configs to Pi
├── download.sh             # Download configs from Pi
├── update_configs.sh       # Regenerate local configs
├── status.sh               # Check Pi status
│
├── assets/                 # Binaries & web files
│   ├── binaries/           # mihomo, country.mmdb, etc.
│   ├── web/                # AriaNg.zip, vpn.php, index.html
│   └── templates/          # config.yaml
│
├── local_configs/          # Deployed configurations
│   ├── aria2.conf
│   ├── nginx.conf
│   ├── smb.conf
│   └── index.html
│
└── docs/                   # Documentation
    ├── RUNBOOK.md          # Detailed setup guide
    └── PROJECT_CONTEXT.md  # Architecture overview
```

## 🔄 Development Workflow

```bash
# Edit configs locally
nano local_configs/aria2.conf

# Deploy changes
./deploy.sh

# Check status
./status.sh

# Repeat as needed
```

All operations run from your PC - no manual SSH needed!

## 📖 Documentation

- **[RUNBOOK.md](docs/RUNBOOK.md)** - Complete setup guide with troubleshooting
- **[PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md)** - Architecture and design principles
- **[assets/README.md](assets/README.md)** - Download links for binaries
- **[local_configs/README.md](local_configs/README.md)** - Configuration management

## 🛠️ Requirements

**Hardware:**
- NanoPi NEO or NEO2 (ARMv7/ARMv8)
- TF card (8GB+)
- USB storage device

**Software:**
- DietPi OS (Debian Bookworm based)
- PC with SSH client (Windows/Mac/Linux)

## 📦 Installed Services

The `dietpi.txt` auto-installs:
- **OpenSSH** (105) - SSH server
- **Aria2** (132) - Download manager
- **Nginx** (85) - Web server
- **Samba** (96) - File sharing
- **PHP** (89) - Web scripting

## 🔐 Security

- SSH key-based authentication (no passwords)
- `dietpi.pem` and `pi.config` are **never committed** to git
- See [docs/RUNBOOK.md](docs/RUNBOOK.md) for security best practices

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test on actual hardware
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- [DietPi](https://dietpi.com/) - Lightweight Debian OS
- [Aria2](https://aria2.github.io/) - Download utility
- [AriaNg](https://github.com/mayswind/AriaNg) - Web UI for Aria2
- [Mihomo](https://github.com/MetaCubeX/mihomo) - Clash Meta core

---

**Star ⭐ this repo if you find it useful!**
gh repo create lishuren/DietPi-NanoPi --public --source=. --remote=origin --push
# Option B: manual remote + push
git remote add origin https://github.com/lishuren/DietPi-NanoPi.git
git branch -M main
git push -u origin main
```

If you want me to call `gh repo create` and push, ensure `git` and `gh` are installed and tell me to proceed.
