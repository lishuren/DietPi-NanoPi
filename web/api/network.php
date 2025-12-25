<?php
header('Content-Type: application/json');

$hostname = gethostname();

// IP: prefer first IPv4 from `hostname -I`
$ip = null;
$ipLine = @shell_exec('hostname -I');
if ($ipLine) {
  $parts = preg_split('/\s+/', trim($ipLine));
  foreach ($parts as $p) { if (filter_var($p, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) { $ip = $p; break; } }
}
if (!$ip) {
  $ip = $_SERVER['SERVER_ADDR'] ?? null;
}

// Default interface from `ip route`
$iface = null;
$route = @shell_exec('ip route show default');
if ($route && preg_match('/dev\s+(\w+)/', $route, $m)) {
  $iface = $m[1];
}

// RX/TX bytes from sysfs
$rx = $tx = null; $speed = null;
if ($iface) {
  $rx = @file_get_contents("/sys/class/net/$iface/statistics/rx_bytes");
  $tx = @file_get_contents("/sys/class/net/$iface/statistics/tx_bytes");
  $rx = $rx !== false ? intval(trim($rx)) : null;
  $tx = $tx !== false ? intval(trim($tx)) : null;
  $speed = @file_get_contents("/sys/class/net/$iface/speed");
  $speed = $speed !== false ? intval(trim($speed)) : null;
}

echo json_encode([
  'hostname' => $hostname,
  'ip' => $ip,
  'iface' => ['name' => $iface, 'speedMbps' => $speed, 'rxBytes' => $rx, 'txBytes' => $tx]
]);
?>
