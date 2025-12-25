<?php
header('Content-Type: application/json');

function svc($name) {
  $active = 0 === @exec("systemctl is-active --quiet ".$name, $o, $rc) ? true : false;
  $since = trim(@shell_exec("systemctl show -p ActiveEnterTimestamp ".$name." | cut -d= -f2"));
  return ['name' => $name, 'active' => $active, 'since' => $since ?: null];
}

echo json_encode([
  'services' => [
    svc('aria2'),
    svc('lighttpd'),
    svc('mihomo')
  ]
]);
?>
