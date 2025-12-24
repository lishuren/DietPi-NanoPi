#!/usr/bin/env bash

# Download AriaNg release zip locally and stage into downloads/ariang
# Run this on your PC (Git Bash) in the repo root.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST_DIR="$REPO_ROOT/downloads/ariang"
TMP_ZIP="$REPO_ROOT/downloads/AriaNg.zip"

VERSION="1.3.12"
# Candidate URLs: versioned asset (AriaNg-<ver>.zip), versioned generic name (AriaNg.zip), latest asset,
# plus ghproxy mirrors for each. Fallback to tag archive (contains dist/).
CANDIDATE_URLS=(
	"https://github.com/mayswind/AriaNg/releases/download/${VERSION}/AriaNg-${VERSION}.zip"
	"https://github.com/mayswind/AriaNg/releases/download/${VERSION}/AriaNg.zip"
	"https://github.com/mayswind/AriaNg/releases/latest/download/AriaNg.zip"
	"https://ghproxy.com/https://github.com/mayswind/AriaNg/releases/download/${VERSION}/AriaNg-${VERSION}.zip"
	"https://ghproxy.com/https://github.com/mayswind/AriaNg/releases/download/${VERSION}/AriaNg.zip"
	"https://ghproxy.com/https://github.com/mayswind/AriaNg/releases/latest/download/AriaNg.zip"
)
PRIMARY_TAG_ZIP="https://github.com/mayswind/AriaNg/archive/refs/tags/${VERSION}.zip"
FALLBACK_TAG_ZIP="https://ghproxy.com/https://github.com/mayswind/AriaNg/archive/refs/tags/${VERSION}.zip"

mkdir -p "$REPO_ROOT/downloads"

process_zip() {
	local zip_path="$1"
	echo "Extracting from ZIP: $zip_path"
	rm -rf "$DEST_DIR"
	mkdir -p "$DEST_DIR"
	echo "Extracting to $DEST_DIR ..."
	TMP_UNPACK_DIR="$REPO_ROOT/downloads/.aria_unpack"
	rm -rf "$TMP_UNPACK_DIR"
	mkdir -p "$TMP_UNPACK_DIR"
	unzip -q "$zip_path" -d "$TMP_UNPACK_DIR"
	# If the unpack contains dist/index.html, use that; else locate index.html somewhere and lift its directory
	if [ -f "$TMP_UNPACK_DIR"/dist/index.html ]; then
		cp -r "$TMP_UNPACK_DIR"/dist/* "$DEST_DIR"/
	else
		CAND_INDEX=$(find "$TMP_UNPACK_DIR" -type f -name index.html | head -n 1 || true)
		if [ -n "$CAND_INDEX" ]; then
			CAND_DIR=$(dirname "$CAND_INDEX")
			cp -r "$CAND_DIR"/* "$DEST_DIR"/
		else
			# Fallback: copy entire unpack
			cp -r "$TMP_UNPACK_DIR"/* "$DEST_DIR"/
		fi
	fi
	rm -rf "$TMP_UNPACK_DIR"

	# Sanity check
	if [ ! -f "$DEST_DIR/index.html" ]; then
		echo "Warning: index.html not found in extracted content. Contents:"
		ls -la "$DEST_DIR" | head
	fi
	echo "AriaNg assets staged in $DEST_DIR"
}

download_zip() {
	local url="$1"
	echo "Fetching AriaNg.zip from: $url"
	rm -f "$TMP_ZIP"
	# -fL: fail on HTTP errors, follow redirects; retries for flaky networks
	if ! curl -fL --connect-timeout 10 --retry 3 --retry-delay 2 -o "$TMP_ZIP" "$url"; then
		return 1
	fi
	# Quick sanity: ensure it looks like a zip by testing
	if ! unzip -t "$TMP_ZIP" >/dev/null 2>&1; then
		echo "Downloaded file is not a valid zip (likely blocked or intercepted)."
		return 1
	fi
	return 0
}

############################
# Local ZIP first, then network
############################

# If a path is provided and exists, use it
if [ "${1:-}" != "" ] && [ -f "$1" ]; then
	process_zip "$1"
	exit 0
fi

# If a local ZIP exists in downloads/, prefer it
LOCAL_CAND=$(ls -1 "$REPO_ROOT"/downloads/AriaNg-*.zip 2>/dev/null | head -n 1 || true)
if [ -z "$LOCAL_CAND" ] && [ -f "$REPO_ROOT"/downloads/AriaNg.zip ]; then
	LOCAL_CAND="$REPO_ROOT/downloads/AriaNg.zip"
fi
if [ -n "$LOCAL_CAND" ] && [ -f "$LOCAL_CAND" ]; then
	process_zip "$LOCAL_CAND"
	echo "Next: upload to NanoPi"
	echo "  scp -r \"$DEST_DIR\" root@<ip-address>:/root/DietPi-NanoPi/downloads/ariang"
	exit 0
fi

DL_SUCCESS=0
for url in "${CANDIDATE_URLS[@]}"; do
	if download_zip "$url"; then
		DL_SUCCESS=1
		break
	fi
done

if [ "$DL_SUCCESS" -eq 0 ]; then
	echo "Release assets failed. Trying tag archive (contains dist/)..."
	if ! download_zip "$PRIMARY_TAG_ZIP"; then
		echo "Primary tag archive failed. Trying proxy..."
		if ! download_zip "$FALLBACK_TAG_ZIP"; then
			echo "All automated downloads failed."
			echo "Manual option: pass the local ZIP path to this script, for example:"
			echo "  bash scripts/download_ariang.sh 'd:/dev/DietPi-NanoPi/downloads/AriaNg-1.3.12.zip'"
			echo "Or place the ZIP under downloads/ and re-run."
			exit 9
		fi
	fi
fi

process_zip "$TMP_ZIP"
rm -f "$TMP_ZIP"

echo "Next: upload to NanoPi"
echo "  scp -r \"$DEST_DIR\" root@<ip-address>:/root/DietPi-NanoPi/downloads/ariang"
