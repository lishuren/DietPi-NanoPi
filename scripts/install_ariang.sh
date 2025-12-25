#!/usr/bin/env bash

# Install AriaNg static UI under /var/www/html/ariang
# Prefers local pre-downloaded assets; falls back to fetching release if needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WEB_ROOT="/var/www/html"
TARGET_DIR="$WEB_ROOT/ariang"
LOCAL_DIR="$REPO_ROOT/downloads/ariang"

ZIP_PATH=""
URL=""

while [ "${1:-}" != "" ]; do
    case "$1" in
        --zip)
            ZIP_PATH="${2:-}"
            shift 2
            ;;
        --url)
            URL="${2:-}"
            shift 2
            ;;
        --help|-h)
            echo "Usage: install_ariang.sh [--zip /path/AriaNg.zip] [--url https://...AriaNg.zip]"
            echo "If neither is provided, installs from locally staged assets in downloads/ariang if present."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

mkdir -p "$WEB_ROOT"

stage_from_zip() {
    local zip="$1"
    if [ ! -f "$zip" ]; then
        echo "ZIP not found: $zip"
        return 1
    fi
    apt-get update >/dev/null 2>&1 || true
    apt-get install -y unzip >/dev/null 2>&1 || true
    local unpack="/tmp/aria_unpack"
    rm -rf "$unpack" && mkdir -p "$unpack"
    unzip -q "$zip" -d "$unpack"
    mkdir -p "$LOCAL_DIR"
    rm -rf "$LOCAL_DIR"/*
    if [ -f "$unpack/dist/index.html" ]; then
        cp -a "$unpack/dist"/. "$LOCAL_DIR"/
    else
        local cand
        cand=$(find "$unpack" -type f -name index.html 2>/dev/null | head -n 1 || true)
        if [ -n "$cand" ]; then
            cp -a "$(dirname "$cand")"/. "$LOCAL_DIR"/
        else
            cp -a "$unpack"/. "$LOCAL_DIR"/
        fi
    fi
    rm -rf "$unpack"
    return 0
}

stage_from_url() {
    local url="$1"
    apt-get update >/dev/null 2>&1 || true
    apt-get install -y unzip curl >/dev/null 2>&1 || true
    local tmp="/tmp/AriaNg.zip"
    echo "Downloading: $url"
    if ! curl -fL -H "User-Agent: Mozilla/5.0" -o "$tmp" "$url"; then
        echo "Failed to download: $url"
        return 1
    fi
    stage_from_zip "$tmp"
    local ret=$?
    rm -f "$tmp"
    return $ret
}

install_from_local() {
    local src=""
    if [ -f "$LOCAL_DIR/index.html" ]; then
        src="$LOCAL_DIR"
    elif [ -f "$LOCAL_DIR/dist/index.html" ]; then
        src="$LOCAL_DIR/dist"
    else
        local cand
        cand=$(find "$LOCAL_DIR" -type f -name index.html 2>/dev/null | head -n 1 || true)
        if [ -n "$cand" ]; then
            src="$(dirname "$cand")"
        fi
    fi
    
    if [ -z "$src" ]; then
        echo "No valid index.html found in $LOCAL_DIR"
        return 1
    fi
    
    echo "Installing AriaNg from: $src"
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cp -a "$src"/. "$TARGET_DIR"/
    chown -R www-data:www-data "$TARGET_DIR" || true
    find "$TARGET_DIR" -type d -exec chmod 755 {} \; 2>/dev/null || true
    find "$TARGET_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
    systemctl restart lighttpd || true
    
    if [ -f "$TARGET_DIR/index.html" ]; then
        echo "AriaNg installed successfully to $TARGET_DIR"
        return 0
    fi
    return 1
}

install_placeholder() {
    echo "Installing placeholder page..."
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cat > "$TARGET_DIR/index.html" <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>AriaNg not installed</title></head>
<body>
<h1>AriaNg not installed</h1>
<p>Assets not found. Please stage the contents of the AriaNg <code>dist/</code> folder into /var/www/html/ariang or into downloads/ariang and re-run the installer.</p>
</body></html>
HTML
    chown -R www-data:www-data "$TARGET_DIR" || true
    systemctl restart lighttpd || true
}

# Main install flow
if [ -n "$ZIP_PATH" ]; then
    if stage_from_zip "$ZIP_PATH" && install_from_local; then
        exit 0
    fi
    echo "Failed to install from ZIP: $ZIP_PATH"
    install_placeholder
    exit 0
fi

if [ -n "$URL" ]; then
    if stage_from_url "$URL" && install_from_local; then
        exit 0
    fi
    echo "Failed to install from URL: $URL"
    install_placeholder
    exit 0
fi

# Try local staged assets first
if [ -d "$LOCAL_DIR" ]; then
    if install_from_local; then
        exit 0
    fi
fi

# Try local ZIP file
LOCAL_ZIP=$(find "$REPO_ROOT/downloads" -maxdepth 1 -type f -name "AriaNg*.zip" 2>/dev/null | head -n 1 || true)
if [ -n "$LOCAL_ZIP" ]; then
    echo "Found local ZIP: $LOCAL_ZIP"
    if stage_from_zip "$LOCAL_ZIP" && install_from_local; then
        exit 0
    fi
fi

# No local assets found; install placeholder with instructions
echo "No local AriaNg assets found in $LOCAL_DIR or $REPO_ROOT/downloads/"
echo "Please download AriaNg on your PC and sync to the device."
install_placeholder
exit 0