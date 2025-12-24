#!/bin/bash

# Download Mihomo (Clash Meta) binary and GeoIP data locally
# Run this on your PC before uploading to the NanoPi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOWNLOAD_DIR="$SCRIPT_DIR/../downloads"

# Mihomo version and architecture
VERSION="v1.18.1"
ARCH="armv7"
MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/${VERSION}/mihomo-linux-${ARCH}-${VERSION}.gz"
COUNTRY_MMDB_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"
GEOSITE_DAT_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"

echo "Creating download directory..."
mkdir -p "$DOWNLOAD_DIR"

echo "Downloading Mihomo ${VERSION} for ${ARCH}..."
curl -L -o "$DOWNLOAD_DIR/mihomo-linux-${ARCH}-${VERSION}.gz" "$MIHOMO_URL"

echo "Extracting Mihomo binary..."
gzip -d -f "$DOWNLOAD_DIR/mihomo-linux-${ARCH}-${VERSION}.gz"
mv "$DOWNLOAD_DIR/mihomo-linux-${ARCH}-${VERSION}" "$DOWNLOAD_DIR/mihomo"
chmod +x "$DOWNLOAD_DIR/mihomo"

echo "Downloading Country.mmdb..."
curl -L -o "$DOWNLOAD_DIR/Country.mmdb" "$COUNTRY_MMDB_URL"

echo "Downloading GeoSite.dat..."
curl -L -o "$DOWNLOAD_DIR/GeoSite.dat" "$GEOSITE_DAT_URL"

echo ""
echo "Download complete! Files are in: $DOWNLOAD_DIR"
echo ""
echo "Next steps:"
echo "1. Upload to NanoPi: scp -r $DOWNLOAD_DIR root@<ip>:/root/DietPi-NanoPi/"
echo "2. SSH to NanoPi and run: cd /root/DietPi-NanoPi && ./scripts/install_clash.sh"
