#!/bin/bash

# Deploy script to update the NanoPi remotely
# Usage: ./deploy.sh [ip-address] [script_name]
# 
# The script saves the IP address to ../config/deploy.env so you don't have to type it every time.

# Ensure we are in the scripts directory
cd "$(dirname "${BASH_SOURCE[0]}")"

CONFIG_FILE="../config/deploy.env"
SCRIPT_TO_RUN="install_vpn_web_ui.sh" # Default script

# 1. Load Config if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# 2. Parse Arguments
# Helper function to check if string is an IP address
is_ip() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

if is_ip "$1"; then
    # Case: ./deploy.sh 192.168.1.100 ...
    TARGET_IP="$1"
    shift # Move to next argument
elif [ -n "$1" ] && [ -z "$TARGET_IP" ]; then
    # Case: ./deploy.sh script.sh (but no IP saved yet)
    # We can't assume $1 is script if we don't have an IP.
    # But strictly speaking, if $1 isn't an IP, it must be the script name.
    # We will prompt for IP later.
    SCRIPT_TO_RUN="$1"
    shift
elif [ -n "$1" ]; then
    # Case: ./deploy.sh script.sh (and IP is already in config)
    SCRIPT_TO_RUN="$1"
    shift
fi

# If there's a second argument (e.g. ./deploy.sh IP script.sh), pick it up
if [ -n "$1" ]; then
    SCRIPT_TO_RUN="$1"
fi

# 3. Validate/Prompt for IP
if [ -z "$TARGET_IP" ]; then
    echo "No Target IP found in config or arguments."
    read -p "Enter NanoPi IP Address: " TARGET_IP
    if [ -z "$TARGET_IP" ]; then
        echo "Error: IP Address is required."
        exit 1
    fi
fi

# 4. Save IP to Config
# We only save if it's different or new
if [ ! -f "$CONFIG_FILE" ] || ! grep -q "TARGET_IP=$TARGET_IP" "$CONFIG_FILE"; then
    echo "TARGET_IP=$TARGET_IP" > "$CONFIG_FILE"
    echo "Saved IP $TARGET_IP to $CONFIG_FILE"
else
    echo "Using Target IP: $TARGET_IP"
fi

TARGET_USER="root"
REMOTE_DIR="/root/DietPi-NanoPi"

# Check if script exists locally
if [ ! -f "./$SCRIPT_TO_RUN" ]; then
    echo "Error: Script '$SCRIPT_TO_RUN' not found in scripts directory."
    exit 1
fi

echo "Deploying $SCRIPT_TO_RUN to $TARGET_IP..."

# 5. Sync files
# Get the absolute path of the project root (parent of scripts)
PROJECT_ROOT="$(cd .. && pwd)"

echo "Syncing project..."
if command -v rsync >/dev/null 2>&1; then
    # Use rsync to copy files
    rsync -avz --exclude '.git' --exclude '.DS_Store' --exclude 'deploy.env' "$PROJECT_ROOT/" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR/"
    if [ $? -ne 0 ]; then
        echo "Error: File sync failed via rsync. Make sure you have SSH access to root@$TARGET_IP."
        exit 1
    fi
else
    echo "rsync not found; falling back to scp (syncing scripts, config, downloads)."
    # Ensure remote directory exists
    ssh "$TARGET_USER@$TARGET_IP" "mkdir -p $REMOTE_DIR" || { echo "Error: Cannot create $REMOTE_DIR on remote"; exit 1; }
    SCP_SRC=("$PROJECT_ROOT/scripts" "$PROJECT_ROOT/config")
    if [ -d "$PROJECT_ROOT/downloads" ]; then
        SCP_SRC+=("$PROJECT_ROOT/downloads")
    fi
    scp -r "${SCP_SRC[@]}" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR" || { echo "Error: File sync failed via scp."; exit 1; }
fi

# 6. Run the script remotely
echo "Running $SCRIPT_TO_RUN on remote..."
ssh "$TARGET_USER@$TARGET_IP" "cd $REMOTE_DIR/scripts && chmod +x $SCRIPT_TO_RUN && ./$SCRIPT_TO_RUN"

echo "Deployment complete."
