#!/bin/bash
set -e

# Find and symlink the conduit binary from nix store
if [ ! -x /usr/local/bin/conduit ]; then
    CONDUIT_BIN=$(find /nix/store -name "conduit" -type f -executable 2>/dev/null | head -1)
    if [ -n "$CONDUIT_BIN" ]; then
        ln -sf "$CONDUIT_BIN" /usr/local/bin/conduit
        echo "Found conduit at: $CONDUIT_BIN"
    else
        echo "ERROR: conduit binary not found in /nix/store!"
        exit 1
    fi
fi

# Detect Hugging Face Spaces URL for dynamic configuration
if [ -n "$SPACE_ID" ]; then
    HF_URL="https://${SPACE_HOST:-$(echo $SPACE_ID | tr '/' '-' | tr '[:upper:]' '[:lower:]').hf.space}"
    SERVER_NAME="${SPACE_HOST:-$(echo $SPACE_ID | tr '/' '-' | tr '[:upper:]' '[:lower:]').hf.space}"

    echo "Detected HF Space: $HF_URL"
    echo "Server name: $SERVER_NAME"

    # Update Conduit config with actual server name
    sed -i "s|server_name = .*|server_name = \"${SERVER_NAME}\"|" /etc/conduit/conduit.toml

    # Update Element config with actual URLs
    sed -i "s|\"base_url\": \"\"|\"base_url\": \"${HF_URL}\"|g" /var/www/element/config.json
    sed -i "s|\"server_name\": \".*\"|\"server_name\": \"${SERVER_NAME}\"|" /var/www/element/config.json
else
    echo "Not running on HF Spaces, using default config"
    sed -i "s|\"base_url\": \"\"|\"base_url\": \"http://localhost:7860\"|g" /var/www/element/config.json
fi

# Ensure data directory exists
mkdir -p /data

echo "Starting Matrix server..."
exec "$@"
