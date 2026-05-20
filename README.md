---
title: Matrix Messenger
emoji: 💬
colorFrom: purple
colorTo: blue
sdk: docker
app_port: 7860
pinned: false
---

# Matrix Messenger

Self-hosted Matrix server with Element Web client, running on Hugging Face Spaces.

## Components

- **Conduit** — lightweight Matrix homeserver (Rust)
- **Element Web** — feature-rich Matrix client
- **Nginx** — reverse proxy

## Features

- End-to-end encryption
- 1-on-1 voice/video calls via TURN
- Open registration
- Dark theme by default
- No federation (private server)

## Usage

1. Open the Space URL
2. Register a new account
3. Start messaging

## Local Development

```bash
docker build -t matrix-server .
docker run -p 7860:7860 matrix-server
```
