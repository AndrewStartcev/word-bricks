<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$player = isset($_GET['player']) ? (string)$_GET['player'] : '';
$action = isset($_GET['action']) ? (string)$_GET['action'] : '';

if ($player === '' || strlen($player) > 256) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'bad_player']);
    exit;
}

$storage = __DIR__ . '/.pikabu_saves';
if (!is_dir($storage)) {
    @mkdir($storage, 0755, true);
}
if (!is_dir($storage) || !is_writable($storage)) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'storage_unavailable']);
    exit;
}

$file = $storage . '/' . hash('sha256', $player) . '.json';

if ($action === 'load') {
    if (!is_file($file)) {
        echo json_encode(['ok' => true, 'data' => new stdClass()]);
        exit;
    }
    $raw = @file_get_contents($file);
    $data = json_decode((string)$raw, true);
    if (!is_array($data)) {
        $data = [];
    }
    echo json_encode(['ok' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($action === 'save' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw = file_get_contents('php://input');
    if ($raw === false || strlen($raw) > 262144) {
        http_response_code(413);
        echo json_encode(['ok' => false, 'error' => 'payload_too_large']);
        exit;
    }
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        http_response_code(400);
        echo json_encode(['ok' => false, 'error' => 'bad_json']);
        exit;
    }
    $tmp = $file . '.tmp';
    $json = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if (@file_put_contents($tmp, $json, LOCK_EX) === false || !@rename($tmp, $file)) {
        @unlink($tmp);
        http_response_code(500);
        echo json_encode(['ok' => false, 'error' => 'write_failed']);
        exit;
    }
    echo json_encode(['ok' => true]);
    exit;
}

http_response_code(404);
echo json_encode(['ok' => false, 'error' => 'bad_action']);
