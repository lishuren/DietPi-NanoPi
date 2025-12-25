# DietPi-NanoPi

Scripts and configuration to provision DietPi on NanoPi devices.

Design philosophy: **Infrastructure as Code**. Provisioning is code-driven — versioned scripts and configs in this repo define and reproduce the device state end-to-end. See [docs/RUNBOOK.md](docs/RUNBOOK.md) for setup and operations.

Repository layout

Quick Start (Fresh TF Card):
- Follow the end-to-end guide in [docs/RUNBOOK.md](docs/RUNBOOK.md#end-to-end-quick-start-fresh-device).
- Then validate with the [Verification Checklist](docs/RUNBOOK.md#verification-checklist-brand-new-tf-card).

Fast Commands (on NanoPi):
```bash
cd /root/DietPi-NanoPi
./scripts/provision.sh            # mounts USB, installs web stack, Aria2, portal
./scripts/setup_ariang.sh         # installs AriaNg UI
./scripts/setup_samba.sh --guest  # guest share (or use --user dietpi --password "yourpass")
./scripts/install_vpn_web_ui.sh   # installs VPN UI
```

Portal & Services:
- Portal: http://<ip>/
- AriaNg: http://<ip>/ariang
- VPN UI: http://<ip>/vpn.php
- Samba: `\\<ip>\\downloads` (or `\\<hostname>\\downloads`)

- `config/` — configuration files
- `docs/` — project documentation
- `scripts/` — helper and install scripts

Quick push instructions

1. Install Git (and `gh` for easier creation):

```powershell
# with winget
winget install --id Git.Git -e --source winget
# optional: GitHub CLI
winget install --id GitHub.cli -e --source winget
```

2. Initialize, commit and push (replace `<your-username>` and `DietPi-NanoPi` if different):

```powershell
cd "D:\dev\DietPi-NanoPi"
git init
git add .
git commit -m "Initial commit"
# Option A: create remote with gh (recommended)
gh repo create lishuren/DietPi-NanoPi --public --source=. --remote=origin --push
# Option B: manual remote + push
git remote add origin https://github.com/lishuren/DietPi-NanoPi.git
git branch -M main
git push -u origin main
```

If you want me to call `gh repo create` and push, ensure `git` and `gh` are installed and tell me to proceed.
