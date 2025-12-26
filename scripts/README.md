# Scripts Folder (Legacy)

**⚠️ This folder contains legacy helper scripts.**

Most functionality has been moved to root-level operational scripts:
- `../setup.sh` - Replaces install scripts
- `../deploy.sh` - Replaces deployment scripts
- `../status.sh` - Replaces monitoring scripts

## Legacy Scripts (Still Useful)

Some scripts in this folder may still be useful for advanced operations:

- `provision.sh` - On-Pi provisioning script (can be run directly on Pi)
- `toggle_vpn.sh` - VPN control backend (called by vpn.php)
- `update_subscription.sh` - Clash subscription updater (called by vpn.php)
- `monitor_mount.sh` - USB mount watchdog (for cron jobs)
- `setup_samba.sh` - Samba configuration helper
- `prepare_usb_*.sh` - USB disk formatting helpers

## New Workflow

Instead of using these scripts directly, use the root-level workflow:

```bash
# Old way (deprecated)
./scripts/deploy.sh 192.168.1.100 provision.sh

# New way (recommended)
./setup.sh      # Install assets
./deploy.sh     # Deploy configs
./status.sh     # Check status
```

## Migration Status

- ✅ Deploy functionality → `../deploy.sh`
- ✅ Asset installation → `../setup.sh`
- ✅ Status checking → `../status.sh`
- ✅ Config management → `../local_configs/` + `../deploy.sh`
- ⏸️ Helper scripts → Keep for advanced use

## Windows Helper Scripts

The `windows/` subfolder contains Windows-specific scripts:
- `format_usb_exfat.ps1` - Format USB drive on Windows PC
- `provision_from_pc.ps1` - Old deployment script (replaced by root-level scripts)
