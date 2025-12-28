#!/bin/bash
# SubscriptionVPN.sh: Download Clash/Mihomo subscription config for MetaCubeX
# Usage: ./SubscriptionVPN.sh <subscription_url> [output_file]
# Example: ./SubscriptionVPN.sh "https://clash.example.top/subscribe" ./local_configs/subscription.yaml

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <subscription_url> [output_file]"
  exit 1
fi

URL="$1"
OUT="${2:-./local_configs/subscription.yaml}"

# Download with correct User-Agent for full config
curl -sSL -H "User-Agent: clash" "$URL" -o "$OUT"

if [ $? -eq 0 ]; then
  echo "Downloaded subscription config to $OUT"
else
  echo "Failed to download subscription config."
  exit 2
fi
