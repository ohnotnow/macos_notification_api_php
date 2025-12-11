<?php

namespace Ohnotnow\MacosNotificationApi;

class NotificationService
{
    public function __construct(
        private string $defaultTitle = 'Notification',
        private string $defaultMessage = 'Hello!',
        private string $defaultSound = 'Sosumi',
        private ?string $customSoundPath = null,
    ) {}

    public function send(?string $title = null, ?string $message = null, ?string $sound = null): void
    {
        $title = $this->escapeForAppleScript($title ?? $this->defaultTitle);
        $message = $this->escapeForAppleScript($message ?? $this->defaultMessage);
        $sound = $sound ?? $this->defaultSound;

        if ($this->customSoundPath !== null) {
            $script = sprintf('display notification "%s" with title "%s"', $message, $title);
            exec(sprintf('osascript -e %s', escapeshellarg($script)));
            exec(sprintf('afplay %s', escapeshellarg($this->customSoundPath . '/' . $sound)));
        } else {
            $script = sprintf('display notification "%s" with title "%s" sound name "%s"', $message, $title, $sound);
            exec(sprintf('osascript -e %s', escapeshellarg($script)));
        }
    }

    private function escapeForAppleScript(string $value): string
    {
        return str_replace(['\\', '"'], ['\\\\', '\\"'], $value);
    }
}
