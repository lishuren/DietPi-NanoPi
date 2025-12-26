# 🍓 DietPi NanoPi Download Station

**Automated NAS setup for NanoPi NEO/NEO2 with Aria2, VPN, and Samba**

Turn a $15 NanoPi board into a powerful headless download station with web-based management, VPN support, and network file sharing.

## ✨ Features

- ⬇️ **Aria2 Downloader** - High-performance download manager with web UI (AriaNg)
- 🔒 **VPN/Proxy Support** - Mihomo (Clash Meta) for secure routing
- 📁 **Samba File Sharing** - Access downloads from any device on your network
- 🌐 **Web Management Portal** - Real-time system status and service control
- 💾 **USB Storage** - Auto-mount with persistent downloads
- 🚀 **Infrastructure as Code** - Complete PC-to-Pi deployment workflow

## 🎯 Quick Start

### 1. Prepare TF Card
```bash
# Download DietPi image
# See: https://dietpi.com/downloads/images/

# Flash to TF card using Etcher or Win32DiskImager
# Copy dietpi.txt to boot partition
```

### 2. Setup SSH Keys
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f dietpi.pem -C "dietpi-nanopi"

# Create configuration file
cp pi.config.example pi.config
# Edit pi.config with your Pi's IP address

# Copy public key to Pi (first time only, uses password)
ssh-copy-id -i dietpi.pem.pub root@192.168.1.100
```

### 3. Deploy
```bash
# Install assets to Pi
./setup.sh

# Deploy configurations
./deploy.sh

# Check status
./status.sh
```

### 4. Access Services
- **Portal**: http://&lt;pi-ip&gt;/
- **AriaNg**: http://&lt;pi-ip&gt;/ariang
- **VPN UI**: http://&lt;pi-ip&gt;/vpn.php
- **Samba**: `\\<pi-ip>\downloads`

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
