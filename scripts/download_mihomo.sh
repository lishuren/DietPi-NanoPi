#!/usr/bin/env bash

# Download Mihomo (Clash Meta) binary and GeoIP data locally
# Run this on your PC before uploading to the NanoPi

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOWNLOAD_DIR="$SCRIPT_DIR/../downloads"

# Mihomo version and architecture
VERSION="v1.18.1"
ARCH="armv7"
MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/${VERSION}/mihomo-linux-${ARCH}-${VERSION}.gz"
COUNTRY_MMDB_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
GEOSITE_DAT_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"

show_manual_instructions() {
    cat <<EOF

==================== MANUAL DOWNLOAD REQUIRED ====================

Automatic download failed. Please download these files manually:

1. Mihomo binary:
   URL: https://github.com/MetaCubeX/mihomo/releases/download/${VERSION}/mihomo-linux-${ARCH}-${VERSION}.gz
   - Download and extract the .gz file
   - Rename the extracted file to: mihomo
   - Place in: $DOWNLOAD_DIR/mihomo
   - Make executable: chmod +x $DOWNLOAD_DIR/mihomo

2. Country.mmdb:
   URL: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb
   - Save as: $DOWNLOAD_DIR/Country.mmdb

3. GeoSite.dat:
   URL: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
   - Save as: $DOWNLOAD_DIR/GeoSite.dat

Alternatively, visit these pages in your browser:
- Mihomo releases: https://github.com/MetaCubeX/mihomo/releases
- GeoIP data: https://github.com/MetaCubeX/meta-rules-dat/releases

===================================================================

EOF
}

echo "Creating download directory..."
mkdir -p "$DOWNLOAD_DIR"

echo "Downloading Mihomo ${VERSION} for ${ARCH}..."
if curl -fL --connect-timeout 30 --max-time 120 -o "$DOWNLOAD_DIR/mihomo-linux-${ARCH}-${VERSION}.gz" "$MIHOMO_URL"; then
    echo "Extracting Mihomo binary..."
    gzip -d -f "$DOWNLOAD_DIR/mihomo-linux-${ARCH}-${VERSION}.gz"
    mv "$DOWNLOAD_DIR/mihomo-linux-${ARCH}-${VERSION}" "$DOWNLOAD_DIR/mihomo"
    chmod +x "$DOWNLOAD_DIR/mihomo"
    echo "✓ Mihomo binary downloaded"
else
    echo "✗ Mihomo download failed"
    show_manual_instructions
    exit 1
fi

echo "Downloading Country.mmdb..."
if curl -fL --connect-timeout 30 --max-time 120 -o "$DOWNLOAD_DIR/Country.mmdb" "$COUNTRY_MMDB_URL"; then
    echo "✓ Country.mmdb downloaded"
else
    echo "✗ Country.mmdb download failed"
    show_manual_instructions
    exit 1
fi

echo "Downloading GeoSite.dat..."
if curl -fL --connect-timeout 30 --max-time 120 -o "$DOWNLOAD_DIR/GeoSite.dat" "$GEOSITE_DAT_URL"; then
    echo "✓ GeoSite.dat downloaded"
else
    echo "✗ GeoSite.dat download failed"
    show_manual_instructions
    exit 1
fi

echo ""
echo "Download complete! Files are in: $DOWNLOAD_DIR"
echo ""
echo "Next steps:"
echo "1. Upload to NanoPi: scp -r $DOWNLOAD_DIR root@<ip>:/root/DietPi-NanoPi/"
echo "2. SSH to NanoPi and run: cd /root/DietPi-NanoPi && ./scripts/install_clash.sh"
