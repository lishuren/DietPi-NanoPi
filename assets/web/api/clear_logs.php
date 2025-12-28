<?php
// clear_logs.php: Clear all files in /var/log
header('Content-Type: application/json');

function run_cmd($cmd) {
    exec($cmd . ' 2>&1', $out, $code);
    return ["code" => $code, "output" => implode("\n", $out)];
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);
$action = $data['action'] ?? $_POST['action'] ?? '';
if ($action === 'clear') {
    $out = run_cmd('sudo find /var/log -type f -exec truncate -s 0 {} +');
    echo json_encode(["success" => $out['code'] === 0, "output" => $out['output']]);
    exit;
}
echo json_encode(["success" => false, "message" => "Invalid action"]);
