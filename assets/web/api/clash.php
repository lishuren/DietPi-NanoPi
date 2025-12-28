<?php

$api_url = 'http://127.0.0.1:9090';
$action = $_GET['action'] ?? '';

// Send JSON header for all responses
header('Content-Type: application/json');

function curl_request($url, $method = 'GET', $data = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3);
    if ($method !== 'GET') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        }
    }
    $result = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($result, true) ?? $result];
}

if ($action === 'status') {
    // Service active
    $service_cmd = file_exists('/usr/bin/systemctl') ? '/usr/bin/systemctl is-active mihomo' : '/bin/systemctl is-active mihomo';
    $service_active = trim(shell_exec($service_cmd)) === 'active';

    // Proxy IP
    $proxy = "http://127.0.0.1:7890";
    $ch = curl_init("http://ifconfig.me/ip");
    curl_setopt($ch, CURLOPT_PROXY, $proxy);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    $proxy_ip = trim(curl_exec($ch));
    $proxy_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $proxy_ok = $proxy_code === 200 && $proxy_ip;

    // Direct IP
    $ch2 = curl_init("http://ifconfig.me/ip");
    curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch2, CURLOPT_TIMEOUT, 5);
    $direct_ip = trim(curl_exec($ch2));
    $direct_code = curl_getinfo($ch2, CURLINFO_HTTP_CODE);
    curl_close($ch2);

    // Group status
    $res = curl_request("$api_url/proxies/VPN-Switch");
    $vpn_switch_now = $res['data']['now'] ?? 'DIRECT';

    // Current proxy
    $current_proxy = $vpn_switch_now === 'Proxy' ? curl_request("$api_url/proxies/Proxy")['data']['now'] ?? null : 'DIRECT';

    // Provider
    $provider_res = curl_request("$api_url/providers/proxies");
    $provider = null;
    if ($provider_res['code'] === 200) {
        $providers = $provider_res['data']['providers'] ?? [];
        foreach ($providers as $key => $p) {
            if ($p['type'] === 'Proxy' && isset($p['subscriptionInfo'])) {
                $provider = ['name' => $key, 'updated' => $p['updatedAt'] ?? '', 'info' => $p['subscriptionInfo'] ?? null];
                break;
            }
        }
    }

    // VPN on if service active, proxy ok, IPs differ, and group is not DIRECT
    $vpn_on = ($vpn_switch_now !== 'DIRECT');

    echo json_encode([
        'vpn_on' => $vpn_on,
        'proxy_ip' => $proxy_ip,
        'direct_ip' => $direct_ip,
        'current_proxy' => $current_proxy,
        'provider' => $provider
    ]);
    exit;
}

if ($action === 'proxies') {
    $res = curl_request("$api_url/proxies");
    echo json_encode($res['data'] ?? ['error' => 'Failed']);
    exit;
}

if ($action === 'select') {
    $group = $_GET['group'] ?? '';
    $name = $_GET['name'] ?? '';
    if (!$group || !$name) {
        echo json_encode(['error' => 'Missing params']);
        exit;
    }
    $res = curl_request("$api_url/proxies/" . rawurlencode($group), 'PUT', ['name' => $name]);
    echo json_encode(['success' => $res['code'] === 204]);
    exit;
}

if ($action === 'latency') {
    $name = $_GET['name'] ?? '';
    if (!$name) {
        echo json_encode(['error' => 'Missing name']);
        exit;
    }
    $res = curl_request("$api_url/proxies/" . rawurlencode($name) . "/delay?timeout=2000&url=http://www.gstatic.com/generate_204");
    echo json_encode($res['data'] ?? ['error' => 'Timeout']);
    exit;
}

if ($action === 'refresh_provider') {
    $res = curl_request("$api_url/providers/proxies/subscription", 'PUT');
    echo json_encode(['success' => $res['code'] === 204]);
    exit;
}

if ($action === 'provider') {
    $res = curl_request("$api_url/providers/proxies");
    $providers = $res['data']['providers'] ?? [];
    $sub = null;
    foreach ($providers as $key => $p) {
        if ($p['vehicleType'] === 'HTTP' && isset($p['subscriptionInfo'])) {
            $sub = ['name' => $key, 'updated' => $p['updatedAt'] ?? '', 'info' => $p['subscriptionInfo'] ?? null];
            break;
        }
    }
    echo json_encode($sub ?? ['error' => 'No subscription']);
    exit;
}

if ($action === 'traffic') {
    $fp = @fsockopen("127.0.0.1", 9090, $errno, $errstr, 1);
    if (!$fp) {
        echo json_encode(['up' => 0, 'down' => 0]);
        exit;
    }

    $request = "GET /traffic HTTP/1.1\r\nHost: 127.0.0.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: " . base64_encode(random_bytes(16)) . "\r\nSec-WebSocket-Version: 13\r\n\r\n";
    fwrite($fp, $request);

    while ($line = fgets($fp)) {
        if (trim($line) === '') break;
    }

    stream_set_timeout($fp, 1);
    $byte0 = fread($fp, 1);
    if ($byte0 === false) {
        fclose($fp);
        echo json_encode(['up' => 0, 'down' => 0]);
        exit;
    }
    $byte1 = fread($fp, 1);
    $len = ord($byte1) & 127;
    if ($len === 126) $len = unpack('n', fread($fp, 2))[1];
    elseif ($len === 127) $len = unpack('J', fread($fp, 8))[1];
    $payload = fread($fp, $len);
    fclose($fp);
    $data = json_decode($payload, true) ?? ['up' => 0, 'down' => 0];
    echo json_encode($data);
    exit;
}

echo json_encode(['error' => 'Unknown action']);