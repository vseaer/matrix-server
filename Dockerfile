# Use Conduit official image as base
FROM registry.gitlab.com/famedly/conduit/matrix-conduit:latest

# Switch to root for installing packages
USER root

# Install additional packages (Conduit image is Nix-based, need to add a package manager)
# Since it's a minimal nix image, we'll download static binaries instead

# Download static nginx
RUN mkdir -p /var/www/element /data /etc/conduit /tmp/nginx-build /var/log/nginx /var/lib/nginx/tmp \
    && CONDUIT_BIN=$(find /nix/store -name "conduit" -type f -executable 2>/dev/null | head -1) \
    && echo "Conduit binary found at: $CONDUIT_BIN" \
    && ln -sf "$CONDUIT_BIN" /usr/local/bin/conduit 2>/dev/null || true

# We need a different approach - let's use a multi-stage build properly
FROM debian:bookworm-slim

# Install runtime deps
RUN apt-get update && apt-get install -y \
    nginx wget ca-certificates supervisor curl \
    && rm -rf /var/lib/apt/lists/*

# Copy nix store from conduit image
COPY --from=0 /nix /nix

# Find and create a wrapper script for conduit
RUN CONDUIT_BIN=$(find /nix/store -name "conduit" -type f -executable 2>/dev/null | head -1) && \
    echo "#!/bin/sh" > /usr/local/bin/conduit && \
    echo "exec $CONDUIT_BIN \"\$@\"" >> /usr/local/bin/conduit && \
    chmod +x /usr/local/bin/conduit && \
    echo "Conduit wrapper created pointing to: $CONDUIT_BIN"

# Verify conduit works
RUN /usr/local/bin/conduit --version || echo "Warning: conduit --version failed, checking binary..." && \
    ls -la $(find /nix/store -name "conduit" -type f -executable 2>/dev/null | head -1) && \
    file $(find /nix/store -name "conduit" -type f -executable 2>/dev/null | head -1)

# Install Element Web
ARG ELEMENT_VERSION=v1.11.85
RUN mkdir -p /var/www/element && \
    wget "https://github.com/element-hq/element-web/releases/download/${ELEMENT_VERSION}/element-${ELEMENT_VERSION}.tar.gz" \
    -O /tmp/element.tar.gz && \
    tar xzf /tmp/element.tar.gz -C /var/www/element --strip-components=1 && \
    rm /tmp/element.tar.gz

# Create data directory
RUN mkdir -p /data

# Copy configuration files
COPY config/conduit.toml /etc/conduit/conduit.toml
COPY config/element-config.json /var/www/element/config.json
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7860

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
