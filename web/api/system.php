<?php
header('Content-Type: application/json');

function readFirstExisting($paths) {
  foreach ($paths as $p) {
    if (@is_readable($p)) {
      return @file_get_contents($p);
    }
  }
  return null;
}

// Load averages
$loadavg = @file('/proc/loadavg');
$load1 = $load5 = $load15 = null;
if ($loadavg && isset($loadavg[0])) {
  $parts = explode(' ', trim($loadavg[0]));
  $load1 = floatval($parts[0]);
  $load5 = floatval($parts[1]);
  $load15 = floatval($parts[2]);
}

// Memory
$meminfo = @file('/proc/meminfo');
$memTotal = $memAvailable = null;
if ($meminfo) {
  foreach ($meminfo as $line) {
    if (strpos($line, 'MemTotal:') === 0) {
      $memTotal = intval(preg_replace('/[^0-9]/', '', $line)) * 1024; // kB -> bytes
    } elseif (strpos($line, 'MemAvailable:') === 0) {
      $memAvailable = intval(preg_replace('/[^0-9]/', '', $line)) * 1024;
    }
  }
}
$memUsed = ($memTotal !== null && $memAvailable !== null) ? max($memTotal - $memAvailable, 0) : null;

// Uptime
$uptimeRaw = @file('/proc/uptime');
$uptime = null;
if ($uptimeRaw && isset($uptimeRaw[0])) {
  $uptime = intval(floatval(explode(' ', trim($uptimeRaw[0]))[0]));
}

// Temperature (try common thermal zones)
$tempC = null;
$candidates = glob('/sys/class/thermal/thermal_zone*/temp');
foreach ($candidates as $path) {
  $v = @file_get_contents($path);
  if ($v !== false) {
    $val = intval(trim($v));
    if ($val > 1000) $val = $val / 1000.0; // millidegrees to C
    $tempC = round($val, 1);
    break;
  }
}

echo json_encode([
  'cpu' => ['load1' => $load1, 'load5' => $load5, 'load15' => $load15],
  'mem' => ['total' => $memTotal, 'used' => $memUsed, 'available' => $memAvailable],
  'uptime' => $uptime,
  'temp' => $tempC
]);
?>
