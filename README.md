# macOS Notification API (PHP)

A simple ReactPHP server that displays macOS notifications. Useful for receiving alerts from remote machines (e.g., a Raspberry Pi notifying you when a long-running task completes).

## Requirements

- PHP 8.1+
- Composer

## Installation

```bash
git clone https://github.com/ohnotnow/macos_notification_api_php.git
cd macos_notification_api_php
composer install
```

## Configuration

Copy the example environment file and edit as needed:

```bash
cp .env.example .env
```

Available options:

| Variable | Default | Description |
|----------|---------|-------------|
| `CUSTOM_SOUND_PATH` | _(none)_ | Path to a directory of custom sounds. |
| `DEFAULT_TITLE` | `Notification` | Default notification title |
| `DEFAULT_MESSAGE` | `Hello!` | Default notification message |
| `DEFAULT_SOUND` | `Sosumi` | Default sound name (system sound) or filename (if using custom path) |

## Usage

### Start the server

```bash
# Local only (default: 127.0.0.1:8000)
php server.php

# Available on your network (for remote notifications)
php server.php 0.0.0.0 8000
```

### Send notifications

Both endpoints return `204 No Content` on success.

**GET request:**

```bash
curl "http://localhost:8000/notify?title=Hello&message=World"
```

**POST request:**

```bash
curl -X POST http://localhost:8000/notify \
  -H "Content-Type: application/json" \
  -d '{"title": "Hello", "message": "World"}'
```

### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `title` | No | Notification title |
| `message` | No | Notification message |
| `sound` | No | Sound name (system) or filename (custom) |

### Example: Notify from a Raspberry Pi

On your Mac, find your local IP:

```bash
ipconfig getifaddr en0
```

Start the server on all interfaces:

```bash
php server.php 0.0.0.0 8000
```

Then from your Pi:

```bash
curl "http://192.168.1.100:8000/notify?title=Pi&message=Task%20complete&sound=Glass"
```

## Custom Sounds

To use your own sounds instead of system sounds:

1. Set `CUSTOM_SOUND_PATH` in your `.env` to a directory containing audio files
2. Use the `sound` parameter to specify the filename

```bash
# .env
CUSTOM_SOUND_PATH=/Users/you/my-sounds
DEFAULT_SOUND=generic-alert.mp3
```

```bash
# Play /Users/you/my-sounds/danger.mp3
curl "http://localhost:8000/notify?title=Warning&message=Something%20happened&sound=danger.mp3"
```

## License

MIT
