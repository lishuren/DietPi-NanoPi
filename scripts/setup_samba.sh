#!/bin/bash

set -euo pipefail

# One-shot Samba setup for NanoPi/DietPi
# Usage:
#   ./scripts/setup_samba.sh --guest
#   ./scripts/setup_samba.sh --user dietpi --password "yourpass"
# Defaults to guest access if no flags are provided.

MODE="guest"
SMB_USER="dietpi"
SMB_PASS=""
SHARE_PATH="/mnt/usb_drive/downloads"
FORCE_USER="dietpi"
FORCE_GROUP="dietpi"

while [ "${1:-}" != "" ]; do
  case "$1" in
    --guest)
      MODE="guest"
      shift 1
      ;;
    --user)
      MODE="user"
      SMB_USER="${2:-dietpi}"
      shift 2
      ;;
    --password)
      SMB_PASS="${2:-}"
      shift 2
      ;;
    --help|-h)
      echo "Usage: setup_samba.sh [--guest] [--user <name> --password <pass>]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Installing Samba packages..."
apt-get update >/dev/null 2>&1 || true
apt-get install -y samba smbclient >/dev/null 2>&1 || true

echo "Ensuring share path exists: $SHARE_PATH"
mkdir -p "$SHARE_PATH"
chown -R "$FORCE_USER":"$FORCE_GROUP" "$SHARE_PATH" || true
chmod -R 0775 "$SHARE_PATH" || true

SMB_CONF="/etc/samba/smb.conf"
BACKUP="/etc/samba/smb.conf.bak.$(date +%Y%m%d%H%M%S)"
if [ -f "$SMB_CONF" ]; then
  cp "$SMB_CONF" "$BACKUP"
fi

echo "Writing Samba configuration to $SMB_CONF (mode: $MODE)"
cat > "$SMB_CONF" <<EOF
[global]
   workgroup = WORKGROUP
   server string = NanoPi
   map to guest = Bad User
   dns proxy = no
   log file = /var/log/samba/log.%m
   max log size = 1000
   server role = standalone server
   usershare allow guests = yes
   server min protocol = SMB2
   ntlm auth = yes

[downloads]
   path = $SHARE_PATH
   browseable = yes
   read only = no
   create mask = 0664
   directory mask = 0775
   force user = $FORCE_USER
   force group = $FORCE_GROUP
EOF

if [ "$MODE" = "guest" ]; then
  cat >> "$SMB_CONF" <<'EOF'
   guest ok = yes
EOF
else
  cat >> "$SMB_CONF" <<EOF
   guest ok = no
   valid users = $SMB_USER
EOF
fi

if [ "$MODE" = "user" ]; then
  # Ensure system user exists
  id "$SMB_USER" >/dev/null 2>&1 || adduser --disabled-password --gecos "" "$SMB_USER"
  echo "Creating Samba user: $SMB_USER"
  if [ -n "$SMB_PASS" ]; then
    (echo "$SMB_PASS"; echo "$SMB_PASS") | smbpasswd -a -s "$SMB_USER"
  else
    echo "No --password provided. You will be prompted to set the Samba password."
    smbpasswd -a "$SMB_USER"
  fi
fi

echo "Testing Samba configuration..."
testparm -s >/dev/null || { echo "Samba config test failed"; exit 2; }

echo "Restarting Samba services..."
systemctl enable smbd nmbd >/dev/null 2>&1 || true
systemctl restart smbd nmbd

echo "Samba share ready: //$(hostname -I | awk '{print $1}')/downloads"
echo "Windows: use \\$(hostname -I | awk '{print $1}')\downloads"
if [ "$MODE" = "user" ]; then
  echo "Use credentials: $SMB_USER / (the password you set)"
else
  echo "Guest access enabled."
fi

echo "Done."
