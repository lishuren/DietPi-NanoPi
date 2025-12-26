<?php
header('Content-Type: application/json');

// Handle system actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_GET['action'] ?? '';
    
    if ($action === 'update') {
        // Run dietpi-update in background
        $cmd = 'nohup dietpi-update 1 > /tmp/dietpi-update.log 2>&1 &';
        exec($cmd, $output, $return);
        echo json_encode([
            'success' => $return === 0,
            'message' => 'Update started in background. Check /tmp/dietpi-update.log for progress.',
            'error' => $return !== 0 ? 'Command failed' : null
        ]);
        exit;
    }
    
    if ($action === 'reboot') {
        // Reboot system
        exec('nohup reboot > /dev/null 2>&1 &');
        echo json_encode(['success' => true, 'message' => 'Rebooting...']);
        exit;
    }
    
    echo json_encode(['success' => false, 'error' => 'Unknown action']);
    exit;
}

// Get system status (existing functionality)
$data = [];

// CPU load
$load = sys_getloadavg();
$data['cpu'] = [
    'load1' => round($load[0], 2),
    'load5' => round($load[1], 2),
    'load15' => round($load[2], 2)
];

// Memory
$meminfo = file_get_contents('/proc/meminfo');
preg_match('/MemTotal:\s+(\d+)/', $meminfo, $total);
preg_match('/MemAvailable:\s+(\d+)/', $meminfo, $avail);
$totalKB = (int)($total[1] ?? 0);
$availKB = (int)($avail[1] ?? 0);
$data['mem'] = [
    'total' => $totalKB * 1024,
    'available' => $availKB * 1024,
    'used' => ($totalKB - $availKB) * 1024
];

// Temperature (try multiple sources for NanoPi)
$temp = null;
$sources = [
    '/sys/class/thermal/thermal_zone0/temp',
    '/sys/devices/virtual/thermal/thermal_zone0/temp'
];
foreach ($sources as $file) {
    if (file_exists($file)) {
        $temp = intval(file_get_contents($file)) / 1000;
        break;
    }
}
$data['temp'] = $temp;

echo json_encode($data);
