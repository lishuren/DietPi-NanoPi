<?php
header('Content-Type: application/json');

$rpc = 'http://127.0.0.1:6800/jsonrpc';

function rpcCall($method, $params = []) {
  global $rpc;
  $payload = json_encode(['jsonrpc' => '2.0', 'id' => 1, 'method' => $method, 'params' => $params]);
  $ch = curl_init($rpc);
  curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_TIMEOUT => 2
  ]);
  $resp = curl_exec($ch);
  $err = curl_error($ch);
  curl_close($ch);
  if ($resp === false) return ['error' => $err ?: 'request failed'];
  $json = json_decode($resp, true);
  if (!$json) return ['error' => 'invalid json'];
  return $json;
}

$global = rpcCall('aria2.getGlobalStat');
$active = rpcCall('aria2.tellActive');

$out = ['global' => null, 'active' => []];
if (isset($global['result'])) {
  $g = $global['result'];
  $out['global'] = [
    'downloadSpeed' => isset($g['downloadSpeed']) ? intval($g['downloadSpeed']) : null,
    'uploadSpeed' => isset($g['uploadSpeed']) ? intval($g['uploadSpeed']) : null,
    'numActive' => isset($g['numActive']) ? intval($g['numActive']) : null,
    'numWaiting' => isset($g['numWaiting']) ? intval($g['numWaiting']) : null,
    'numStopped' => isset($g['numStopped']) ? intval($g['numStopped']) : null
  ];
}

if (isset($active['result']) && is_array($active['result'])) {
  foreach ($active['result'] as $t) {
    $name = null;
    if (!empty($t['files'][0]['path'])) {
      $name = basename($t['files'][0]['path']);
    } elseif (!empty($t['files'][0]['uris'][0]['uri'])) {
      $name = $t['files'][0]['uris'][0]['uri'];
    }
    $total = isset($t['totalLength']) ? intval($t['totalLength']) : 0;
    $done = isset($t['completedLength']) ? intval($t['completedLength']) : 0;
    $pct = $total > 0 ? round(($done / $total) * 100, 1) : null;
    $out['active'][] = [
      'gid' => $t['gid'] ?? null,
      'name' => $name,
      'progressPercent' => $pct,
      'downSpeed' => isset($t['downloadSpeed']) ? intval($t['downloadSpeed']) : null,
      'upSpeed' => isset($t['uploadSpeed']) ? intval($t['uploadSpeed']) : null
    ];
  }
}

echo json_encode($out);
?>
