# OpenCode Docker

This repository provides a Dockerized environment for running the [OpenCode](https://opencode.ai) CLI in an isolated container. It includes all necessary dependencies for clipboard support and headless execution.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your machine.
- An API key for your preferred AI provider (e.g., [Anthropic](https://console.anthropic.com/) or [OpenAI](https://platform.openai.com/)).

### Quick Start

```bash
# Build the image
make build

# Set up your secrets (one-time)
mkdir -p ~/.opencode-docker/secrets
echo "your-api-key" > ~/.opencode-docker/secrets/anthropic_api_key
chmod 600 ~/.opencode-docker/secrets/*

# Run using the wrapper script (recommended)
bin/opencode-docker
```

### Recommended: Using the Wrapper Script

The `bin/opencode-docker` script is the recommended way to run OpenCode Docker. It:

- Persists all data to `~/.opencode-docker/` (sessions, cache, settings)
- Reads secrets from `~/.opencode-docker/secrets/`
- Uses the current directory as the workspace
- Works from any directory once added to your PATH

#### Adding to PATH

##### Bash

Add to your `~/.bashrc`:

```bash
export PATH="$HOME/git/opencode-docker/bin:$PATH"
```

Then reload:

```bash
source ~/.bashrc
```

##### Fish

Add to your `~/.config/fish/config.fish`:

```fish
fish_add_path $HOME/git/opencode-docker/bin
```

Then reload:

```fish
source ~/.config/fish/config.fish
```

#### Usage

Once added to your PATH, you can run from any directory:

```bash
# Run in current directory
opencode-docker

# Continue a session
opencode-docker -s ses_2d068fdfaffefxNTts5doK0upT

# Override workspace directory
OPENCODE_WORKSPACE=/path/to/project opencode-docker
```

### Data Persistence

When using the wrapper script, all persistent data is stored in `~/.opencode-docker/`:

```
~/.opencode-docker/
├── .cache/           # OpenCode cache (plugins, packages)
├── .local/           # Local state and data
├── secrets/          # API keys (see Secrets Management below)
└── ...               # Other OpenCode runtime files
```

This directory is automatically created on first run.

## Makefile

The Makefile is primarily for development and testing within this repository:

```bash
make build                      # Build with auto-detected UID/GID (tagged as opencode-docker)
make build VERSION=1.3.17       # Build with version tag (opencode-docker:1.3.17)
make build-latest               # Auto-discover latest opencode-ai version, build & tag as latest
make tag-latest VERSION=1.3.17  # Tag latest to point to a version
make run                        # Run container (uses ./workspace as working dir)
make shell                      # Shell into container
make clean                      # Remove image
```

**Note:** `make run` uses local directories (`./homebase`, `./workspace`, `./secrets`) for development. For regular use, prefer the `bin/opencode-docker` wrapper script which uses `~/.opencode-docker/`.

## Manual Docker Run

For advanced users who want to run the container manually:

```bash
docker run --rm -it \
  --read-only \
  --tmpfs /tmp:exec,size=512m \
  --cap-drop ALL \
  --security-opt seccomp=unconfined \
  --memory=2g \
  --cpus=2 \
  -v ~/.opencode-docker:/app:rw \
  -v /path/to/opencode-docker/config:/app/.config/opencode:ro \
  -v $(pwd):/workspace:rw \
  -v ~/.opencode-docker/secrets:/run/secrets:ro \
  opencode-docker /workspace
```

### Building the Image Manually

```bash
# Default UID/GID (1000)
docker build -t opencode-docker .

# With custom UID/GID (recommended)
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t opencode-docker .

# With version tag
docker build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g) -t opencode-docker:1.3.17 .
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

When using the wrapper script (`bin/opencode-docker`):

| Data | Location | Description |
|------|----------|-------------|
| **Home Directory** | `~/.opencode-docker/` | Persistent home for OpenCode (cache, plugins, settings) |
| **Secrets** | `~/.opencode-docker/secrets/` | API keys (see below) |
| **Config** | `./config/` (this repo) | OpenCode config, mounted read-only |
| **Workspace** | Current directory | Your project files, mounted read-write |

When using `make run` (for development):

| Data | Location | Description |
|------|----------|-------------|
| **Home Directory** | `./homebase/` | Local persistent home |
| **Secrets** | `./secrets/` | Local secrets directory |
| **Config** | `./config/` | OpenCode config |
| **Workspace** | `./workspace/` | Local workspace |

## Secrets Management

This project uses file-based secrets instead of environment variables for improved security. Secrets stored in files are:
- Not visible in `docker inspect`
- Not exposed in process listings
- Not leaked in error messages or logs

### Setting Up Secrets

1. Create your secrets directory:
   ```bash
   mkdir -p ~/.opencode-docker/secrets
   chmod 700 ~/.opencode-docker/secrets
   ```

2. Add your API keys as individual files:
   ```bash
   echo "your-api-key" > ~/.opencode-docker/secrets/anthropic_api_key
   echo "your-api-key" > ~/.opencode-docker/secrets/openai_api_key
   echo "your-api-key" > ~/.opencode-docker/secrets/context7_api_key
   chmod 600 ~/.opencode-docker/secrets/*
   ```

3. The entrypoint script automatically loads all files from `/run/secrets` as environment variables:
   - Filenames are converted to uppercase
   - Dashes and dots are replaced with underscores
   - Example: `anthropic_api_key` becomes `ANTHROPIC_API_KEY`

### Supported Secrets

| Filename | Environment Variable | Provider |
|----------|---------------------|----------|
| `anthropic_api_key` | `ANTHROPIC_API_KEY` | Anthropic |
| `openai_api_key` | `OPENAI_API_KEY` | OpenAI |
| `context7_api_key` | `CONTEXT7_API_KEY` | Context7 MCP |
| `google_application_credentials` | `GOOGLE_APPLICATION_CREDENTIALS` | Vertex AI |
| `aws_access_key_id` | `AWS_ACCESS_KEY_ID` | AWS Bedrock |
| `aws_secret_access_key` | `AWS_SECRET_ACCESS_KEY` | AWS Bedrock |

## Environment Variables (Legacy)

You can still pass environment variables directly if preferred, but file-based secrets are recommended:

- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `CONTEXT7_API_KEY` (for Context7 MCP)
- `GOOGLE_APPLICATION_CREDENTIALS` (for Vertex AI)
- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (for Bedrock)

## Superpowers Visual Companion

The [Superpowers](https://github.com/obra/superpowers) plugin includes a visual brainstorming companion that runs a local web server for showing mockups, diagrams, and design options in your browser.

### Port Configuration

The visual companion server is exposed on port **42000** by default. This port is:

- Pre-configured in `bin/opencode-docker` and `make run`/`make shell`
- Set via the `BRAINSTORM_PORT=42000` environment variable
- Forwarded from the container to your host machine

### Usage

When the Superpowers brainstorming skill starts a server, it will use port 42000. Access it at:

```
http://localhost:42000
```

### Changing the Port

To use a different port, update both the `-p` flag and `-e BRAINSTORM_PORT=` value in your `docker run` command or the wrapper scripts.
