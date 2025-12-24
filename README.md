# DietPi-NanoPi

Scripts and configuration to provision DietPi on NanoPi devices.

Design philosophy: **Infrastructure as Code**. Provisioning is code-driven — versioned scripts and configs in this repo define and reproduce the device state end-to-end. See [docs/RUNBOOK.md](docs/RUNBOOK.md) for setup and operations.

Repository layout

Quick start: AriaNg step-by-step install is documented in [docs/RUNBOOK.md](docs/RUNBOOK.md) under “Step-by-Step: Install AriaNg”. It covers Pi-side direct download and PC-side staging + deploy, plus verification and troubleshooting.

For file sharing from Windows/Linux, see the “Samba Access” section in [docs/RUNBOOK.md](docs/RUNBOOK.md) with a single-command setup script.

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
