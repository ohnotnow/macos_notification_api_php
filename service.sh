#!/bin/bash

# Notification Server - macOS Launch Agent Manager
# Usage: ./service.sh [install|uninstall|status|logs|restart]

PLIST_NAME="com.ohnotnow.notification-server.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
LOG_DIR="$HOME/Library/Logs/notification-server"

# Read config from .env file (if it exists)
get_config() {
    local key="$1"
    local default="$2"
    if [ -f "$SCRIPT_DIR/.env" ]; then
        local value=$(grep "^${key}=" "$SCRIPT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
        if [ -n "$value" ]; then
            echo "$value"
            return
        fi
    fi
    echo "$default"
}

SERVER_HOST=$(get_config "SERVER_HOST" "0.0.0.0")
SERVER_PORT=$(get_config "SERVER_PORT" "8000")

# Generate plist content
generate_plist() {
    cat << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ohnotnow.notification-server</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/env</string>
        <string>php</string>
        <string>${SCRIPT_DIR}/server.php</string>
        <string>${SERVER_HOST}</string>
        <string>${SERVER_PORT}</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${LOG_DIR}/stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/stderr.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF
}

case "$1" in
    install)
        echo "Installing notification server..."
        echo "  Host: $SERVER_HOST"
        echo "  Port: $SERVER_PORT"
        echo ""

        # Create log directory
        mkdir -p "$LOG_DIR"

        # Create LaunchAgents directory if it doesn't exist
        mkdir -p "$HOME/Library/LaunchAgents"

        # Generate and install plist
        generate_plist > "$PLIST_DEST"

        # Load the service
        launchctl load "$PLIST_DEST"

        echo "Done! Server is now running."
        echo "It will start automatically on login."
        echo ""
        echo "Test it with:"
        echo "  curl 'http://localhost:${SERVER_PORT}/notify?title=Test&message=Hello'"
        ;;

    uninstall)
        echo "Uninstalling notification server..."

        # Unload the service (ignore errors if not loaded)
        launchctl unload "$PLIST_DEST" 2>/dev/null

        # Remove plist
        rm -f "$PLIST_DEST"

        echo "Done! Server has been removed."
        ;;

    status)
        if launchctl list | grep -q "com.ohnotnow.notification-server"; then
            echo "Service is running"
            echo "  Configured: http://${SERVER_HOST}:${SERVER_PORT}"
            launchctl list | grep "com.ohnotnow.notification-server"
            echo ""
            echo "Testing connection..."
            if curl -s -o /dev/null -w "%{http_code}" "http://localhost:${SERVER_PORT}/notify" | grep -q "204"; then
                echo "Server is responding OK"
            else
                echo "Server may not be responding - check logs with: ./service.sh logs"
            fi
        else
            echo "Service is not running"
            if [ -f "$PLIST_DEST" ]; then
                echo "(plist exists but service is not loaded)"
            else
                echo "(not installed - run ./service.sh install)"
            fi
        fi
        ;;

    logs)
        echo "=== Logs from $LOG_DIR ==="
        echo ""
        if [ -f "$LOG_DIR/stderr.log" ]; then
            echo "--- stderr.log ---"
            tail -50 "$LOG_DIR/stderr.log"
        fi
        if [ -f "$LOG_DIR/stdout.log" ]; then
            echo ""
            echo "--- stdout.log ---"
            tail -50 "$LOG_DIR/stdout.log"
        fi
        if [ ! -f "$LOG_DIR/stderr.log" ] && [ ! -f "$LOG_DIR/stdout.log" ]; then
            echo "No log files found yet."
        fi
        ;;

    restart)
        echo "Restarting notification server..."
        echo "  Host: $SERVER_HOST"
        echo "  Port: $SERVER_PORT"
        launchctl unload "$PLIST_DEST" 2>/dev/null
        # Regenerate plist in case config changed
        generate_plist > "$PLIST_DEST"
        launchctl load "$PLIST_DEST"
        echo "Done!"
        ;;

    *)
        echo "Notification Server - macOS Service Manager"
        echo ""
        echo "Usage: $0 {install|uninstall|status|logs|restart}"
        echo ""
        echo "Commands:"
        echo "  install    Install and start the service"
        echo "  uninstall  Stop and remove the service"
        echo "  status     Check if service is running"
        echo "  logs       Show recent log output"
        echo "  restart    Restart the service"
        echo ""
        echo "Configuration (via .env file):"
        echo "  SERVER_HOST  Currently: $SERVER_HOST"
        echo "  SERVER_PORT  Currently: $SERVER_PORT"
        exit 1
        ;;
esac
