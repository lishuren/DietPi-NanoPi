#!/bin/bash

# URL for DietPi NanoPi NEO2 image (ARM64)
# Note: Links can change, checking DietPi website is recommended.
# This is the direct link for NanoPi NEO2 Bookworm (stable)
IMAGE_URL="https://dietpi.com/downloads/images/DietPi_NanoPiNEO2-ARMv8-Bookworm.img.xz"
OUTPUT_FILE="DietPi_NanoPiNEO2-ARMv8-Bookworm.img.xz"

echo "Downloading DietPi image for NanoPi NEO2 (Bookworm, ~200MB)..."
curl -L -o "$OUTPUT_FILE" "$IMAGE_URL"

if [ $? -eq 0 ]; then
    echo "Download complete: $OUTPUT_FILE"
    echo "Please unzip this file and flash the .img to your SD card."
    echo "Recommended tool: BalenaEtcher or Raspberry Pi Imager."
else
    echo "Download failed."
    exit 1
fi
