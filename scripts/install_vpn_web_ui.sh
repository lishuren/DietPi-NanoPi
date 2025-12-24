#!/bin/bash

# Script to install the VPN Web Control Page
# This creates a simple PHP page to toggle the VPN from the browser.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_ROOT="/var/www/html"
PHP_FILE="$WEB_ROOT/vpn.php"

# Scripts
TOGGLE_SCRIPT="/usr/local/bin/toggle_vpn.sh"
UPDATE_SCRIPT="/usr/local/bin/update_subscription.sh"

echo "Installing VPN Web Control..."

# Ensure web server is installed
if ! command -v php >/dev/null 2>&1; then
    echo "PHP not found; installing..."
    apt-get update && apt-get install -y php
fi

# Ensure web root exists
mkdir -p "$WEB_ROOT"

# 1. Copy scripts to system path
if [ -f "$SCRIPT_DIR/toggle_vpn.sh" ]; then
    cp "$SCRIPT_DIR/toggle_vpn.sh" "$TOGGLE_SCRIPT"
    chmod +x "$TOGGLE_SCRIPT"
else
    echo "Warning: toggle_vpn.sh not found at $SCRIPT_DIR"
fi

if [ -f "$SCRIPT_DIR/update_subscription.sh" ]; then
    cp "$SCRIPT_DIR/update_subscription.sh" "$UPDATE_SCRIPT"
    chmod +x "$UPDATE_SCRIPT"
else
    echo "Warning: update_subscription.sh not found at $SCRIPT_DIR"
fi

# 2. Configure Sudoers
# Allow www-data to run the scripts as root without password
SUDOERS_FILE="/etc/sudoers.d/vpn_control"
echo "www-data ALL=(ALL) NOPASSWD: $TOGGLE_SCRIPT, $UPDATE_SCRIPT" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"

# 3. Create PHP Page
cat <<PHP_EOF > "$PHP_FILE"
<!DOCTYPE html>
<html>
<head>
    <title>VPN Control</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; max-width: 600px; margin: 0 auto; }
        .btn { padding: 15px 30px; font-size: 20px; margin: 10px; cursor: pointer; border: none; border-radius: 5px; color: white; }
        .on { background-color: #4CAF50; }
        .off { background-color: #f44336; }
        .update { background-color: #2196F3; font-size: 16px; padding: 10px 20px; }
        .status { margin-top: 20px; font-size: 18px; margin-bottom: 30px; }
        .section { border-top: 1px solid #ccc; margin-top: 30px; padding-top: 30px; }
        input[type="text"] { padding: 10px; width: 70%; border-radius: 5px; border: 1px solid #ccc; }
        .message { margin-top: 15px; padding: 10px; border-radius: 5px; }
        .success { background-color: #dff0d8; color: #3c763d; }
        .error { background-color: #f2dede; color: #a94442; }
    </style>
</head>
<body>
    <h1>VPN Control</h1>
    
    <?php
    \$message = "";
    \$msg_type = "";

    if (\$_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset(\$_POST['action'])) {
            \$action = \$_POST['action'];
            if (\$action == 'on') {
                exec("sudo $TOGGLE_SCRIPT on 2>&1", \$output, \$return_var);
                if (\$return_var === 0) {
                    \$message = "VPN Turned ON";
                    \$msg_type = "success";
                } else {
                    \$message = "Error: " . implode(" ", \$output);
                    \$msg_type = "error";
                }
            } elseif (\$action == 'off') {
                exec("sudo $TOGGLE_SCRIPT off 2>&1", \$output, \$return_var);
                if (\$return_var === 0) {
                    \$message = "VPN Turned OFF";
                    \$msg_type = "success";
                } else {
                    \$message = "Error: " . implode(" ", \$output);
                    \$msg_type = "error";
                }
            }
        } elseif (isset(\$_POST['update_url'])) {
            \$url = escapeshellarg(\$_POST['update_url']);
            if (!empty(\$url)) {
                exec("sudo $UPDATE_SCRIPT \$url 2>&1", \$output, \$return_var);
                if (\$return_var === 0) {
                    \$message = "Subscription Updated Successfully!";
                    \$msg_type = "success";
                } else {
                    \$message = "Update Failed: " . implode(" ", \$output);
                    \$msg_type = "error";
                }
            }
        }
    }

    // Check Status
    \$status = exec("systemctl is-active mihomo");
    \$is_active = (\$status == 'active');
    ?>

    <?php if (!empty(\$message)): ?>
        <div class="message <?php echo \$msg_type; ?>">
            <?php echo htmlspecialchars(\$message); ?>
        </div>
    <?php endif; ?>

    <div class="status">
        Current Status: <strong><?php echo \$is_active ? '<span style="color:green">ON</span>' : '<span style="color:red">OFF</span>'; ?></strong>
    </div>

    <form method="post">
        <button type="submit" name="action" value="on" class="btn on" <?php if(\$is_active) echo 'disabled'; ?>>Turn ON</button>
        <button type="submit" name="action" value="off" class="btn off" <?php if(!\$is_active) echo 'disabled'; ?>>Turn OFF</button>
    </form>
    
    <div class="section">
        <h2>Update Subscription</h2>
        <form method="post">
            <input type="text" name="update_url" placeholder="Paste Subscription URL here..." required>
            <button type="submit" class="btn update">Update Config</button>
        </form>
    </div>

    <p style="margin-top: 50px;"><a href="/ariang">Back to AriaNg</a></p>
</body>
</html>
PHP_EOF

chown www-data:www-data "$PHP_FILE"

echo "VPN Web Control installed at http://<ip>/vpn.php"
