FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    wget \
    ca-certificates \
    supervisor \
    sqlite3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Conduit (Matrix homeserver)
ARG CONDUIT_VERSION=v0.8.0
RUN wget -q "https://gitlab.com/famedly/conduit/-/releases/${CONDUIT_VERSION}/downloads/conduit-x86_64-unknown-linux-musl" \
    -O /usr/local/bin/conduit \
    && chmod +x /usr/local/bin/conduit

# Install Element Web
ARG ELEMENT_VERSION=v1.11.85
RUN mkdir -p /var/www/element \
    && wget -q "https://github.com/element-hq/element-web/releases/download/${ELEMENT_VERSION}/element-${ELEMENT_VERSION}.tar.gz" \
    -O /tmp/element.tar.gz \
    && tar xzf /tmp/element.tar.gz -C /var/www/element --strip-components=1 \
    && rm /tmp/element.tar.gz

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
