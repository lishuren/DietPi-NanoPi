#!/bin/bash

###############################################################################
# status.sh - Check Pi status and view logs
# Usage: ./status.sh [service_name]
#
# Examples:
#   ./status.sh          # Show all services
#   ./status.sh aria2    # Show only aria2 logs
#
# This script can be run periodically (via cron) for monitoring:
#   */5 * * * * cd /path/to/DietPi-NanoPi && ./status.sh > /tmp/dietpi-status.log 2>&1
###############################################################################

set -e

# Load configuration
if [ ! -f "pi.config" ]; then
    echo "Error: pi.config not found!"
    echo "Copy pi.config.example to pi.config and update with your values."
    exit 1
fi

source pi.config

SERVICE_FILTER="$1"

echo "=== Checking Status of $REMOTE_HOST ==="

ssh -i "$PEM_FILE" "${REMOTE_USER}@${REMOTE_HOST}" << EOF
    echo "=== System Status ==="
    uptime
    echo ""
    df -h / /mnt 2>/dev/null || df -h /
    echo ""
    
    echo "=== Service Status ==="
    for service in aria2 mihomo nginx smbd nmbd; do
        if [ -z "$SERVICE_FILTER" ] || [ "$SERVICE_FILTER" == "\$service" ]; then
            echo "--- \$service ---"
            systemctl status \$service --no-pager -l 2>/dev/null || echo "\$service: not found or not running"
            echo ""
        fi
    done
    
    if [ -n "$SERVICE_FILTER" ]; then
        echo "=== Recent Logs for $SERVICE_FILTER ==="
        journalctl -u "$SERVICE_FILTER" -n 30 --no-pager 2>/dev/null || echo "No logs found"
    else
        echo "=== Recent Aria2 Logs ==="
        journalctl -u aria2 -n 20 --no-pager 2>/dev/null || echo "No aria2 logs"
        
        echo ""
        echo "=== Recent Mihomo Logs ==="
        journalctl -u mihomo -n 20 --no-pager 2>/dev/null || echo "No mihomo logs"
    fi
EOF

echo ""
echo "=== Status Check Complete ==="
