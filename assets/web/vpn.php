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
    $message = "";
    $msg_type = "";

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset($_POST['action'])) {
            $action = $_POST['action'];
            if ($action == 'on') {
                exec("sudo /usr/local/bin/toggle_vpn.sh on 2>&1", $output, $return_var);
                if ($return_var === 0) {
                    $message = "VPN Turned ON";
                    $msg_type = "success";
                } else {
                    $message = "Error: " . implode(" ", $output);
                    $msg_type = "error";
                }
            } elseif ($action == 'off') {
                exec("sudo /usr/local/bin/toggle_vpn.sh off 2>&1", $output, $return_var);
                if ($return_var === 0) {
                    $message = "VPN Turned OFF";
                    $msg_type = "success";
                } else {
                    $message = "Error: " . implode(" ", $output);
                    $msg_type = "error";
                }
            }
        } elseif (isset($_POST['update_url'])) {
            $url = escapeshellarg($_POST['update_url']);
            if (!empty($url)) {
                exec("sudo /usr/local/bin/update_subscription.sh $url 2>&1", $output, $return_var);
                if ($return_var === 0) {
                    $message = "Subscription Updated Successfully!";
                    $msg_type = "success";
                } else {
                    $message = "Update Failed: " . implode(" ", $output);
                    $msg_type = "error";
                }
            }
        }
    }

    // Check Status
    $status = exec("systemctl is-active mihomo");
    $is_active = ($status == 'active');
    ?>

    <?php if (!empty($message)): ?>
        <div class="message <?php echo $msg_type; ?>">
            <?php echo htmlspecialchars($message); ?>
        </div>
    <?php endif; ?>

    <div class="status">
        Current Status: <strong><?php echo $is_active ? '<span style="color:green">ON</span>' : '<span style="color:red">OFF</span>'; ?></strong>
    </div>

    <form method="post">
        <button type="submit" name="action" value="on" class="btn on" <?php if($is_active) echo 'disabled'; ?>>Turn ON</button>
        <button type="submit" name="action" value="off" class="btn off" <?php if(!$is_active) echo 'disabled'; ?>>Turn OFF</button>
    </form>
    
    <div class="section">
        <h2>Update Subscription</h2>
        <form method="post">
            <input type="text" name="update_url" placeholder="Paste Subscription URL here..." required>
            <button type="submit" class="btn update">Update Config</button>
        </form>
    </div>

    <p style="margin-top: 50px;"><a href="/ariang">Back to AriaNg</a> | <a href="/">Portal</a></p>
</body>
</html>
