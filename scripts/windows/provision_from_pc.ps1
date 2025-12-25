param(
    [Parameter(Mandatory=$true)][string]$IP,
    [switch]$FormatExt4,
    [string]$Device = "",
    [string]$Label = "usbdata"
)

# Simple Windows helper to run provisioning from PC
# Usage examples:
#   powershell -File scripts/windows/provision_from_pc.ps1 -IP 192.168.0.140
#   powershell -File scripts/windows/provision_from_pc.ps1 -IP 192.168.0.140 -FormatExt4 -Device /dev/sda1 -Label usbdata

$ErrorActionPreference = 'Stop'

function Invoke-Remote($cmd) {
    Write-Host "[SSH] $cmd" -ForegroundColor Cyan
    ssh "root@$IP" $cmd
}

function Copy-Repo() {
    Write-Host "[SCP] Syncing scripts, config, downloads to $IP" -ForegroundColor Cyan
    scp -r ./scripts ./config ./downloads "root@$IP:/root/DietPi-NanoPi"
}

function Remote-Provision() {
    Invoke-Remote 'bash -lc "cd /root/DietPi-NanoPi && chmod +x scripts/*.sh && bash scripts/provision.sh"'
}

function Remote-FormatExt4() {
    if ([string]::IsNullOrWhiteSpace($Device)) {
        Write-Host "[SSH] Detecting USB device (auto)" -ForegroundColor Cyan
        $detect = 'bash -lc "lsblk -rno NAME,TRAN | awk \''$2==\"usb\"{print $1; exit}\''\n"'
        $usbDev = ssh "root@$IP" $detect
        if ([string]::IsNullOrWhiteSpace($usbDev)) { throw "No USB device detected" }
        $Device = "/dev/$usbDev" + "1"
        Write-Host "Auto-detected device: $Device" -ForegroundColor Yellow
    }
    $cmd = "bash -lc \"cd /root/DietPi-NanoPi && echo YES | bash scripts/prepare_usb_ext4.sh $Device $Label\""
    Invoke-Remote $cmd
}

# 1) Copy repo
Copy-Repo

# 2) Optionally format ext4
if ($FormatExt4) { Remote-FormatExt4 }

# 3) Provision
Remote-Provision()

# 4) Quick checks
Invoke-Remote 'systemctl status aria2 --no-pager || true'
Invoke-Remote 'findmnt /mnt/usb_drive || true'
Invoke-Remote 'systemctl status smbd nmbd --no-pager || true'
