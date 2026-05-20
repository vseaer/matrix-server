#!/bin/bash
set -e

# Detect Hugging Face Spaces URL for dynamic configuration
if [ -n "$SPACE_ID" ]; then
    # SPACE_ID format: username/space-name
    HF_URL="https://${SPACE_HOST:-$(echo $SPACE_ID | tr '/' '-' | tr '[:upper:]' '[:lower:]').hf.space}"
    SERVER_NAME="${SPACE_HOST:-$(echo $SPACE_ID | tr '/' '-' | tr '[:upper:]' '[:lower:]').hf.space}"

    echo "Detected HF Space: $HF_URL"
    echo "Server name: $SERVER_NAME"

    # Update Conduit config with actual server name
    sed -i "s|server_name = .*|server_name = \"${SERVER_NAME}\"|" /etc/conduit/conduit.toml

    # Update Element config with actual URLs
    sed -i "s|\"base_url\": \"\"|\"base_url\": \"${HF_URL}\"|" /var/www/element/config.json
    sed -i "s|\"server_name\": \".*\"|\"server_name\": \"${SERVER_NAME}\"|" /var/www/element/config.json
else
    echo "Not running on HF Spaces, using default config"
    # For local testing, use localhost
    sed -i "s|\"base_url\": \"\"|\"base_url\": \"http://localhost:7860\"|" /var/www/element/config.json
fi

# Ensure data directory exists and has correct permissions
mkdir -p /data

echo "Starting Matrix server..."
exec "$@"
