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

This container is configured with multiple layers of security hardening:

- **Read-only root filesystem:** Prevents any persistence or tampering inside the container
- **Dropped capabilities:** Only the minimum required capabilities
- **Unprivileged user:** Runs as UID 1000 by default (configurable at build time)
- **Memory/CPU limits:** Configurable to prevent resource exhaustion
- **tmpfs for /tmp:** Ensures /tmp is writable but memory-backed

### Docker Options Explained

#### Container Lifecycle

| Option | Description |
|--------|-------------|
| `--rm` | Automatically removes the container when it exits. Prevents accumulation of stopped containers that could contain sensitive data. |
| `-it` | Interactive terminal (`-i` = interactive, `-t` = TTY). Allows you to interact with the CLI. |

#### Filesystem Security

| Option | Description |
|--------|-------------|
| `--read-only` | Makes the container's root filesystem read-only. Prevents malware or exploits from modifying system binaries or installing persistence mechanisms. |
| `--tmpfs /tmp:exec,size=512m` | Creates a writable tmpfs (RAM-based) mount at `/tmp` with execute permission and 512MB limit. Provides a controlled writable area that's ephemeral (disappears when container stops) and size-limited to prevent resource exhaustion. |

#### Capability & Privilege Restriction

| Option | Description |
|--------|-------------|
| `--cap-drop ALL` | Drops all Linux capabilities. By default, containers get a subset of root capabilities. Dropping all removes abilities like changing file ownership, binding to privileged ports, loading kernel modules, etc. |
| `--security-opt seccomp=unconfined` | Disables seccomp filtering. This weakens security by allowing all system calls, but is needed for compatibility with Bun/Node.js. Ideally, use a custom seccomp profile instead. |

#### Resource Limits

| Option | Description |
|--------|-------------|
| `--memory=2g` | Limits container memory to 2GB. Prevents denial-of-service through memory exhaustion (fork bombs, memory leaks). |
| `--cpus=2` | Limits container to 2 CPU cores. Prevents CPU exhaustion attacks and ensures the container can't monopolize host resources. |

#### Volume Mounts

| Option | Description |
|--------|-------------|
| `-v .../homebase:/app:rw` | Mounts homebase as read-write home directory. Isolates persistent data; container only has access to this specific directory. |
| `-v .../config:/app/.config/opencode:ro` | Mounts config as read-only. Prevents the container from modifying its own configuration (defense against tampering). |
| `-v .../workspace:/workspace:rw` | Mounts workspace as read-write. Limits file access to only the intended working directory. |

#### Environment Variables

| Option | Description |
|--------|-------------|
| `-e VAR=value` | Passes environment variables into the container. Note: Credentials passed this way are visible in `docker inspect` and process listings. Consider using Docker secrets for sensitive values. |

### Security Considerations

**Strong points:**
- `--read-only` + `--tmpfs` implements the immutable infrastructure pattern
- `--cap-drop ALL` follows the principle of least privilege
- Resource limits prevent denial-of-service attacks
- Read-only config mount prevents configuration tampering

**Potential improvement:**
- `seccomp=unconfined` weakens security. If possible, create a custom seccomp profile that allows only the syscalls OpenCode needs, rather than disabling filtering entirely.

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
