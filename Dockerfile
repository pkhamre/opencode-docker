# Build stage: install dependencies
FROM node:25-slim AS builder

ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai @upstash/context7-mcp @modelcontextprotocol/server-sequential-thinking

# Runtime stage: minimal image
FROM node:25-slim

ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install --no-install-recommends -y \
    xvfb \
    wl-clipboard \
    xclip \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/*

COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

RUN usermod -u $USER_UID -o node && \
    groupmod -g $USER_GID node || true

RUN mkdir -p /app/.local /app/.local/share /app/.config/opencode /app/.cache && \
    chmod -R 755 /app/.local /app/.config/opencode /app/.cache && \
    chown -R $USER_UID:$USER_GID /app

WORKDIR /app

ENV DISPLAY=:99.0
ENV HOME=/app
ENV XDG_CONFIG_HOME=/app/.config
ENV OPENCODE_CONFIG_DIR=/app/.config/opencode
ENV XDG_DATA_HOME=/app/.local/share
ENV PATH=/usr/local/bin:$PATH

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER node

ENTRYPOINT ["entrypoint.sh"]
