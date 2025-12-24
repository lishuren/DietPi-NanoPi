#!/bin/bash

# Install and configure Lighttpd + PHP (FastCGI)
# Code-first installer (no manual DietPi menu required)

set -euo pipefail

echo "Installing Lighttpd and PHP..."
apt-get update
apt-get install -y lighttpd php-cgi

# Ensure Apache is not conflicting on port 80
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true

echo "Enabling FastCGI modules..."
lighttpd-enable-mod fastcgi
lighttpd-enable-mod fastcgi-php

systemctl daemon-reload
systemctl enable lighttpd
systemctl restart lighttpd

echo "Web stack installed. Lighttpd is listening on port 80."
