<?php
header('Content-Type: application/json');
$mount = '/mnt';

// Determine mounted state and fstype via /proc/mounts
$mounted = false; $fstype = null;
$proc = @file('/proc/mounts');
if ($proc) {
  foreach ($proc as $line) {
    $parts = preg_split('/\s+/', trim($line));
    if (isset($parts[1]) && $parts[1] === $mount) {
      $mounted = true;
      $fstype = $parts[2] ?? null;
      break;
    }
  }
}

// Disk stats
$total = null; $free = null; $used = null;
if ($mounted && is_dir($mount)) {
  $total = @disk_total_space($mount);
  $free = @disk_free_space($mount);
  if ($total !== false && $free !== false) {
    $used = max($total - $free, 0);
  }
}

echo json_encode([
  'mounted' => $mounted,
  'fstype' => $fstype,
  'totalBytes' => $total !== false ? $total : null,
  'freeBytes' => $free !== false ? $free : null,
  'usedBytes' => $used
]);
?>
