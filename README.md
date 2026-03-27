# OpenCode Docker

This repository provides a Dockerized environment for running the [OpenCode](https://opencode.ai) CLI in an isolated container. It includes all necessary dependencies for clipboard support and headless execution.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your machine.
- An API key for your preferred AI provider (e.g., [Anthropic](https://console.anthropic.com/) or [OpenAI](https://platform.openai.com/)).

### Quick Start

```bash
# Build and run
make build
make run
```

## Makefile

```bash
make build   # Build with auto-detected UID/GID
make run     # Run container (interactive)
make shell   # Shell into container
make clean   # Remove image
```

## Manual Docker Run

Run the OpenCode CLI with security hardening enabled:

```bash
docker run --rm -it \
  --read-only \
  --tmpfs /tmp:exec,size=512m \
  --cap-drop ALL \
  --security-opt seccomp:unconfined \
  --memory=2g \
  --cpus=2 \
  -v ./homebase:/app:rw \
  -v ./config:/app/.config/opencode:ro \
  -v ./workspace:/workspace:rw \
  -e CONTEXT7_API_KEY=$CONTEXT7_API_KEY \
  -e GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS \
  opencode-cli /workspace
```

### Building the Image Manually

```bash
# Default UID/GID (1000)
docker build -t opencode-cli .

# With custom UID/GID
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t opencode-cli .
```

## Security Features

- **Read-only root filesystem:** Prevents any persistence or tampering inside the container
- **Dropped capabilities:** Only the minimum required capabilities
- **Unprivileged user:** Runs as UID 1000 by default (configurable at build time)
- **Memory/CPU limits:** Configurable to prevent resource exhaustion
- **tmpfs for /tmp:** Ensures /tmp is writable but memory-backed

## Configuration and Persistence

- **Project Files:** Mount `./workspace` to `/workspace` (writable).
- **Config:** Mount `./config` to `/app/.config/opencode` (read-only) for themes, provider credentials, and custom agent definitions.
- **Home Base:** Mount `./homebase` to `/app` (writable) for user settings and local state.

## Environment Variables

You can pass various environment variables to the container for different AI providers:

- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `CONTEXT7_API_KEY` (for Context7 MCP)
- `GOOGLE_APPLICATION_CREDENTIALS` (for Vertex AI)
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (for Bedrock)
