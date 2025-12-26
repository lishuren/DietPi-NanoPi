<?php
header('Content-Type: application/json');

/**
 * System Services Status API
 * Returns status of key services (aria2, mihomo, etc.)
 */

function get_service_status($service_name) {
    $cmd = "systemctl is-active {$service_name} 2>/dev/null";
    if (file_exists('/usr/bin/systemctl')) {
        $cmd = "/usr/bin/systemctl is-active {$service_name} 2>/dev/null";
    } elseif (file_exists('/bin/systemctl')) {
        $cmd = "/bin/systemctl is-active {$service_name} 2>/dev/null";
    }
    
    $output = trim(shell_exec($cmd));
    return [
        'name' => $service_name,
        'active' => $output === 'active'
    ];
}

$services = [
    get_service_status('aria2'),
    get_service_status('mihomo'),
    get_service_status('nginx'),
    get_service_status('smbd'),
    get_service_status('php-fpm')
];

echo json_encode(['services' => $services]);
?>
