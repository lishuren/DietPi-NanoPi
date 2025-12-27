<?php
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$action = $input['action'] ?? '';

$api_url = 'http://127.0.0.1:9090/proxies/VPN-Switch';

function curl_request($url, $method, $data) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    $result = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return $code;
}

if ($action === 'on') {
    $code = curl_request($api_url, 'PUT', ['name' => 'Proxy']);
    echo json_encode([
        'success' => $code === 204,
        'message' => $code === 204 ? 'VPN Turned ON (Proxy)' : 'Failed to turn ON'
    ]);
} elseif ($action === 'off') {
    $code = curl_request($api_url, 'PUT', ['name' => 'DIRECT']);
    echo json_encode([
        'success' => $code === 204,
        'message' => $code === 204 ? 'VPN Turned OFF (Direct)' : 'Failed to turn OFF'
    ]);
} else {
    echo json_encode(['success' => false, 'error' => 'Invalid action']);
}
?>