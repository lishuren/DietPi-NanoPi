<?php
header('Content-Type: application/json');

$api_url = 'http://127.0.0.1:9090';
$action = $_GET['action'] ?? '';

function curl($url, $method = 'GET', $data = null) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3);
    if ($method === 'POST' || $method === 'PUT') {
        curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
        if ($data) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        }
    }
    $result = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'data' => json_decode($result, true)];
}

if ($action === 'proxies') {
    $res = curl("$api_url/proxies");
    if ($res['code'] !== 200) {
        echo json_encode(['error' => 'Failed to fetch proxies. Is VPN running?']);
        exit;
    }
    
    $proxies = $res['data']['proxies'] ?? [];
    $groups = [];
    $nodes = [];

    // Separate groups from nodes
    foreach ($proxies as $name => $p) {
        if (($p['type'] ?? '') === 'Selector') {
            $groups[$name] = [
                'now' => $p['now'] ?? '',
                'all' => $p['all'] ?? []
            ];
        } else {
            // Only keep relevant node info
            $nodes[$name] = [
                'type' => $p['type'] ?? '',
                'history' => $p['history'] ?? []
            ];
        }
    }
    
    // Sort groups so "Proxy" or "GLOBAL" usually come first if needed, 
    // but for now just return them.
    echo json_encode(['groups' => $groups, 'nodes' => $nodes]);
    exit;
}

if ($action === 'select') {
    $group = $_GET['group'] ?? '';
    $name = $_GET['name'] ?? '';
    if (!$group || !$name) {
        echo json_encode(['error' => 'Missing group or name']);
        exit;
    }
    
    // Clash API uses PUT for selection
    $url = "$api_url/proxies/" . rawurlencode($group);
    $res = curl($url, 'PUT', ['name' => $name]);
    
    echo json_encode(['success' => $res['code'] === 204]);
    exit;
}

if ($action === 'latency') {
    $name = $_GET['name'] ?? '';
    if (!$name) {
        echo json_encode(['error' => 'Missing name']);
        exit;
    }
    
    $url = "$api_url/proxies/" . rawurlencode($name) . "/delay?timeout=2000&url=http://www.gstatic.com/generate_204";
    $res = curl($url);
    
    if ($res['code'] === 200) {
        echo json_encode(['delay' => $res['data']['delay'] ?? 0]);
    } else {
        echo json_encode(['error' => 'Timeout or Error']);
    }
    exit;
}

if ($action === 'provider') {
    // Fetch provider info to get subscription stats
    $res = curl("$api_url/providers/proxies");
    if ($res['code'] !== 200) {
        echo json_encode(['error' => 'Failed to fetch providers']);
        exit;
    }
    
    $providers = $res['data']['providers'] ?? [];
    // Find the first provider that looks like a subscription (usually has vehicleType: HTTP)
    $sub = null;
    foreach ($providers as $key => $p) {
        if (($p['vehicleType'] ?? '') === 'HTTP' && isset($p['subscriptionInfo'])) {
            $sub = $p;
            break; // Use the first valid subscription found
        }
        // Fallback: check if name is 'default' or similar if no subscriptionInfo
        if ($key === 'default' || $key === 'Subscription') {
             if(!$sub) $sub = $p;
        }
    }
    
    if ($sub) {
        echo json_encode([
            'name' => $sub['name'] ?? 'Subscription',
            'updated' => $sub['updatedAt'] ?? '',
            'info' => $sub['subscriptionInfo'] ?? null
        ]);
    } else {
        echo json_encode(['error' => 'No subscription found']);
    }
    exit;
}

if ($action === 'check_ip') {
    $proxy = "http://127.0.0.1:7890"; // Default Clash HTTP port
    $ch = curl_init("http://ifconfig.me/ip");
    curl_setopt($ch, CURLOPT_PROXY, $proxy);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    $ip = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($code === 200 && $ip) {
        echo json_encode(['ip' => trim($ip)]);
    } else {
        echo json_encode(['error' => 'Failed to fetch IP']);
    }
    exit;
}

if ($action === 'traffic') {
    // Connect to websocket endpoint, read one frame, and exit
    $fp = @fsockopen("127.0.0.1", 9090, $errno, $errstr, 1);
    if (!$fp) {
        echo json_encode(['up' => 0, 'down' => 0, 'error' => 'Connection failed']);
        exit;
    }

    $request = "GET /traffic HTTP/1.1\r\n";
    $request .= "Host: 127.0.0.1\r\n";
    $request .= "Upgrade: websocket\r\n";
    $request .= "Connection: Upgrade\r\n";
    $request .= "Sec-WebSocket-Key: " . base64_encode(openssl_random_pseudo_bytes(16)) . "\r\n";
    $request .= "Sec-WebSocket-Version: 13\r\n";
    $request .= "\r\n";

    fwrite($fp, $request);

    // Read headers
    while ($line = fgets($fp)) {
        if (trim($line) === '') break;
    }

    // Read one frame (simplified, assuming unmasked text frame from server)
    // WebSocket frame format:
    // Byte 0: FIN(1) | RSV(3) | Opcode(4)
    // Byte 1: Mask(1) | Payload Len(7)
    // ...
    
    // Set timeout
    stream_set_timeout($fp, 1);
    
    $byte0 = fread($fp, 1);
    if ($byte0 === false) {
        echo json_encode(['up' => 0, 'down' => 0]);
        fclose($fp);
        exit;
    }
    
    $byte1 = fread($fp, 1);
    $len = ord($byte1) & 127;
    
    if ($len === 126) {
        $lenBytes = fread($fp, 2);
        $len = unpack('n', $lenBytes)[1];
    } elseif ($len === 127) {
        $lenBytes = fread($fp, 8);
        // PHP int is 64-bit usually, but let's hope it fits
        $len = unpack('J', $lenBytes)[1];
    }
    
    $payload = fread($fp, $len);
    fclose($fp);
    
    $data = json_decode($payload, true);
    echo json_encode([
        'up' => $data['up'] ?? 0,
        'down' => $data['down'] ?? 0
    ]);
    exit;
}

echo json_encode(['error' => 'Unknown action']);
?>
