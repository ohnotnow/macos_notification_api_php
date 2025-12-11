<?php

require __DIR__ . '/vendor/autoload.php';

use Ohnotnow\MacosNotificationApi\NotificationService;
use Psr\Http\Message\ServerRequestInterface;
use React\Http\HttpServer;
use React\Http\Message\Response;
use React\Socket\SocketServer;

if (file_exists(__DIR__ . '/.env')) {
    $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
    $dotenv->load();
}

$host = $argv[1] ?? '127.0.0.1';
$port = $argv[2] ?? '8000';

$notificationService = new NotificationService(
    defaultTitle: $_ENV['DEFAULT_TITLE'] ?? 'Notification',
    defaultMessage: $_ENV['DEFAULT_MESSAGE'] ?? 'Hello!',
    defaultSound: $_ENV['DEFAULT_SOUND'] ?? 'Sosumi',
    customSoundPath: $_ENV['CUSTOM_SOUND_PATH'] ?? null,
);

$server = new HttpServer(function (ServerRequestInterface $request) use ($notificationService) {
    $path = $request->getUri()->getPath();
    $method = $request->getMethod();

    if ($path !== '/notify') {
        return new Response(404, ['Content-Type' => 'application/json'], json_encode(['error' => 'Not found']));
    }

    if ($method === 'GET') {
        parse_str($request->getUri()->getQuery(), $params);
        $notificationService->send(
            $params['title'] ?? null,
            $params['message'] ?? null,
            $params['sound'] ?? null,
        );
        return new Response(204);
    }

    if ($method === 'POST') {
        $body = json_decode((string) $request->getBody(), true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            return new Response(400, ['Content-Type' => 'application/json'], json_encode(['error' => 'Invalid JSON']));
        }
        $notificationService->send(
            $body['title'] ?? null,
            $body['message'] ?? null,
            $body['sound'] ?? null,
        );
        return new Response(204);
    }

    return new Response(405, ['Content-Type' => 'application/json'], json_encode(['error' => 'Method not allowed']));
});

$socket = new SocketServer("{$host}:{$port}");
$server->listen($socket);

echo "macOS Notification API running at http://{$host}:{$port}\n";
