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

# Create non-root user
RUN useradd -m -s /bin/bash -u 1000 claude \
    && mkdir -p /home/claude/.claude \
    && chown -R claude:claude /home/claude

USER claude
WORKDIR /workspace
ENV HOME=/home/claude
ENV TERM=xterm-256color

# Default command (overridden by the launcher)
CMD ["claude"]
