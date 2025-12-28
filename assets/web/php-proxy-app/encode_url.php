<?php
require("vendor/autoload.php");
use Proxy\Config;

Config::load('./config.php');
if (file_exists('./custom_config.php')) {
    Config::load('./custom_config.php');
}

header('Content-Type: application/json');

$url = $_GET['url'] ?? '';
$host = $_GET['host'] ?? $_SERVER['HTTP_HOST'];

// Emulate the same key logic as index.php
if (Config::get('url_mode') == 2) {
    Config::set('encryption_key', md5(Config::get('app_key') . $host));
} elseif (Config::get('url_mode') == 3) {
    Config::set('encryption_key', md5(Config::get('app_key') . session_id()));
}

require_once("vendor/athlon1600/php-proxy/src/helpers.php");
$q = url_encrypt($url);

echo json_encode(['q' => $q]);
