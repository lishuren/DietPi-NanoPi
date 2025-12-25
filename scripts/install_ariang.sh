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

# Prefer locally staged assets: if present, install them even if target already has content
if [ -d "$LOCAL_DIR" ]; then
    # Determine the correct source dir inside LOCAL_DIR that contains index.html
    SRC_DIR=""
    if [ -f "$LOCAL_DIR/index.html" ]; then
        SRC_DIR="$LOCAL_DIR"
    else
        CAND_INDEX=$(find "$LOCAL_DIR" -type f -name index.html | head -n 1 || true)
        if [ -n "$CAND_INDEX" ]; then
            SRC_DIR=$(dirname "$CAND_INDEX")
        elif [ -d "$LOCAL_DIR/dist" ] && [ -f "$LOCAL_DIR/dist/index.html" ]; then
            SRC_DIR="$LOCAL_DIR/dist"
        fi
    fi

    if [ -n "$SRC_DIR" ]; then
        echo "Installing AriaNg from local staged assets: $SRC_DIR"
        rm -rf "$TARGET_DIR"
        mkdir -p "$TARGET_DIR"
        # Copy contents of SRC_DIR (not the dir itself), including hidden files
        # Prefer locally staged assets: if present, always install them (overwrite target)
        if [ -d "$LOCAL_DIR" ]; then
            SRC_DIR=""
            if [ -f "$LOCAL_DIR/index.html" ]; then
                SRC_DIR="$LOCAL_DIR"
            elif [ -f "$LOCAL_DIR/dist/index.html" ]; then
                SRC_DIR="$LOCAL_DIR/dist"
            else
                CAND_INDEX=$(find "$LOCAL_DIR" -type f -name index.html | head -n 1 || true)
                if [ -n "$CAND_INDEX" ]; then
                    SRC_DIR=$(dirname "$CAND_INDEX")
                fi
            fi

            if [ -n "$SRC_DIR" ]; then
                echo "Installing AriaNg from local staged assets: $SRC_DIR"
                rm -rf "$TARGET_DIR"
                mkdir -p "$TARGET_DIR"
                # Copy contents of SRC_DIR (not the dir itself), preserving dotfiles
                cp -a "$SRC_DIR"/. "$TARGET_DIR"/
                # Ensure permissions
                chown -R www-data:www-data "$TARGET_DIR" || true
                find "$TARGET_DIR" -type d -exec chmod 755 {} \; || true
                find "$TARGET_DIR" -type f -exec chmod 644 {} \; || true
                systemctl restart lighttpd || true
                if [ -f "$TARGET_DIR/index.html" ]; then
                    echo "AriaNg installed from local assets to $TARGET_DIR"
                    exit 0
                fi
            fi
        fi
        # Normalize nested folder if needed
        if [ ! -f "$TARGET_DIR/index.html" ]; then
            for sub in "ariang" "AriaNg" "dist"; do
                if [ -d "$TARGET_DIR/$sub" ] && [ -f "$TARGET_DIR/$sub/index.html" ]; then
                    echo "Normalizing structure: moving $sub/* to $TARGET_DIR"
                    cp -r "$TARGET_DIR/$sub/"* "$TARGET_DIR/" || true
                    rm -rf "$TARGET_DIR/$sub"
                    break
                fi
            done
            # Fallback: search recursively for index.html and lift its directory contents
            if [ ! -f "$TARGET_DIR/index.html" ]; then
                CAND_INDEX=$(find "$TARGET_DIR" -type f -name index.html | head -n 1 || true)
                if [ -n "$CAND_INDEX" ]; then
                    CAND_DIR=$(dirname "$CAND_INDEX")
                    if [ "$CAND_DIR" != "$TARGET_DIR" ]; then
                        echo "Found index.html in $CAND_DIR; lifting contents to $TARGET_DIR"
                        find "$CAND_DIR" -mindepth 1 -maxdepth 1 -exec cp -r {} "$TARGET_DIR" \; || true
                        rm -rf "$CAND_DIR"
                    fi
                fi
            fi
        fi
        chown -R www-data:www-data "$TARGET_DIR" || true
        find "$TARGET_DIR" -type d -exec chmod 755 {} \; || true
        find "$TARGET_DIR" -type f -exec chmod 644 {} \; || true
        systemctl restart lighttpd || true
        if [ -f "$TARGET_DIR/index.html" ]; then
            echo "AriaNg ready at $TARGET_DIR"
            exit 0
        else
            echo "Warning: index.html is still missing at $TARGET_DIR. Installing placeholder page."
            cat > "$TARGET_DIR/index.html" <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>AriaNg not installed</title></head>
<body>
<h1>AriaNg not installed</h1>
<p>Assets not found. Please stage the contents of the AriaNg <code>dist/</code> folder into /var/www/html/ariang or into downloads/ariang and re-run the installer.</p>
</body></html>
HTML
            systemctl restart lighttpd || true
            exit 0
        fi
    fi
fi

if [ -d "$LOCAL_DIR" ]; then
    echo "Installing AriaNg from local directory: $LOCAL_DIR"
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    # Copy contents of local dir (not the dir itself), including hidden files
    find "$LOCAL_DIR" -mindepth 1 -maxdepth 1 -exec cp -r {} "$TARGET_DIR" \;
else
    echo "Local AriaNg not found. Attempting to download release zip..."
    apt-get update && apt-get install -y unzip curl || true
    TMP_ZIP="/tmp/AriaNg.zip"
    if curl -L -o "$TMP_ZIP" "https://github.com/mayswind/AriaNg/releases/latest/download/AriaNg.zip"; then
        rm -rf "$TARGET_DIR"
        mkdir -p "$TARGET_DIR"
        if unzip -q "$TMP_ZIP" -d "$TARGET_DIR"; then
            rm -f "$TMP_ZIP"
        else
            echo "Warning: Failed to unzip AriaNg.zip. Creating placeholder page."
            rm -f "$TMP_ZIP"
            mkdir -p "$TARGET_DIR"
            cat > "$TARGET_DIR/index.html" <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>AriaNg not installed</title></head>
<body>
<h1>AriaNg not installed</h1>
<p>Failed to extract AriaNg release. Please upload pre-downloaded assets to /var/www/html/ariang or run the PC-side downloader.</p>
</body></html>
HTML
        fi
    else
        echo "Warning: Failed to download AriaNg.zip (network/GitHub blocked). Creating placeholder page."
        rm -rf "$TARGET_DIR"
        mkdir -p "$TARGET_DIR"
        cat > "$TARGET_DIR/index.html" <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>AriaNg not installed</title></head>
<body>
<h1>AriaNg not installed</h1>
<p>Network download was blocked. Upload the contents of downloads/ariang from your PC to /var/www/html/ariang.</p>
</body></html>
HTML
    fi
fi

echo "AriaNg installed to $TARGET_DIR"

# Normalize structure if content was copied into a nested folder (common when using scp)
if [ ! -f "$TARGET_DIR/index.html" ]; then
    # Try common nested folder names first
    for sub in "ariang" "AriaNg" "dist"; do
        if [ -d "$TARGET_DIR/$sub" ] && [ -f "$TARGET_DIR/$sub/index.html" ]; then
            echo "Normalizing structure: moving $sub/* to $TARGET_DIR"
            find "$TARGET_DIR/$sub" -mindepth 1 -maxdepth 1 -exec cp -r {} "$TARGET_DIR" \; || true
            rm -rf "$TARGET_DIR/$sub"
            break
        fi
    done
    # Fallback: locate index.html anywhere underneath and lift its directory contents
    if [ ! -f "$TARGET_DIR/index.html" ]; then
        CAND_INDEX=$(find "$TARGET_DIR" -type f -name index.html | head -n 1 || true)
        if [ -n "$CAND_INDEX" ]; then
            CAND_DIR=$(dirname "$CAND_INDEX")
            if [ "$CAND_DIR" != "$TARGET_DIR" ]; then
                echo "Found index.html in $CAND_DIR; lifting contents to $TARGET_DIR"
                find "$CAND_DIR" -mindepth 1 -maxdepth 1 -exec cp -r {} "$TARGET_DIR" \; || true
                rm -rf "$CAND_DIR"
            fi
        fi
    fi
fi

# Ensure permissions suitable for Lighttpd
chown -R www-data:www-data "$TARGET_DIR" || true
find "$TARGET_DIR" -type d -exec chmod 755 {} \; || true
find "$TARGET_DIR" -type f -exec chmod 644 {} \; || true

systemctl restart lighttpd || true

# Final sanity: ensure index.html exists; if not, install placeholder to avoid 403
if [ ! -f "$TARGET_DIR/index.html" ]; then
    echo "Warning: index.html not found after install. Installing placeholder page."
    cat > "$TARGET_DIR/index.html" <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>AriaNg not installed</title></head>
<body>
<h1>AriaNg not installed</h1>
<p>Network download was blocked or assets were incomplete. Upload the contents of AriaNg <code>dist/</code> to /var/www/html/ariang and re-run the installer.</p>
</body></html>
HTML
    chown -R www-data:www-data "$TARGET_DIR" || true
    find "$TARGET_DIR" -type d -exec chmod 755 {} \; || true
    find "$TARGET_DIR" -type f -exec chmod 644 {} \; || true
    systemctl restart lighttpd || true
fi
