<?php

require __DIR__ . '/vendor/autoload.php';

use Ohffs\SimpleReactphpRouter\Attributes\Get;
use Ohffs\SimpleReactphpRouter\Attributes\Post;
use Ohffs\SimpleReactphpRouter\Request;
use Ohffs\SimpleReactphpRouter\Response;
use Ohffs\SimpleReactphpRouter\Server;
use Ohnotnow\MacosNotificationApi\NotificationService;
use Psr\Http\Message\ResponseInterface;

if (file_exists(__DIR__ . '/.env')) {
    $dotenv = Dotenv\Dotenv::createImmutable(__DIR__);
    $dotenv->load();
}

class NotificationController
{
    private NotificationService $notificationService;

    public function __construct()
    {
        $this->notificationService = new NotificationService(
            defaultTitle: $_ENV['DEFAULT_TITLE'] ?? 'Notification',
            defaultMessage: $_ENV['DEFAULT_MESSAGE'] ?? 'Hello!',
            defaultSound: $_ENV['DEFAULT_SOUND'] ?? 'Sosumi',
            customSoundPath: $_ENV['CUSTOM_SOUND_PATH'] ?? null,
        );
    }

    #[Get('/notify')]
    public function notifyGet(Request $request): ResponseInterface
    {
        $this->notificationService->send(
            $request->query('title'),
            $request->query('message'),
            $request->query('sound'),
        );
        return Response::noContent();
    }

    #[Post('/notify')]
    public function notifyPost(Request $request): ResponseInterface
    {
        $data = $request->json();
        if ($data === null) {
            return Response::badRequest('Invalid JSON');
        }
        $this->notificationService->send(
            $data['title'] ?? null,
            $data['message'] ?? null,
            $data['sound'] ?? null,
        );
        return Response::noContent();
    }
}

$host = $argv[1] ?? $_ENV['SERVER_HOST'] ?? '127.0.0.1';
$port = $argv[2] ?? $_ENV['SERVER_PORT'] ?? '8000';

$server = new Server(new NotificationController());
echo "macOS Notification API running at http://{$host}:{$port}\n";
$server->run($host, $port);
