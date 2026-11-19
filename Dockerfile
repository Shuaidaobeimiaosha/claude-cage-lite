# Claude Cage Lite - Lightweight isolated sandbox for Claude Code
# Designed for complete isolation of Claude login state from the host

FROM node:22-bookworm-slim

LABEL org.opencontainers.image.title="Claude Cage Lite"
LABEL org.opencontainers.image.description="Isolated Claude Code sandbox with persistent but host-isolated login state"
LABEL org.opencontainers.image.source="https://github.com/Shuaidaobeimiaosha/claude-cage-lite"

# Install essential tools Claude Code commonly needs
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    openssh-client \
    python3 \
    python3-pip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Use the existing 'node' user (UID 1000) from the official image
# Prepare home directory for Claude config (login state lives in a Docker volume)
RUN mkdir -p /home/node/.claude \
    && chown -R node:node /home/node

USER node
WORKDIR /workspace
ENV HOME=/home/node
ENV TERM=xterm-256color

# Default command (overridden by the launcher)
CMD ["claude"]
