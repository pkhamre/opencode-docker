# AGENTS.md

OpenCode Docker - containerized environment for running OpenCode CLI.

## Structure

```
.
├── Dockerfile          # Multi-stage build: node:25-slim
├── Makefile            # Build commands (development use)
├── entrypoint.sh       # Loads secrets, starts Xvfb, runs opencode
├── bin/opencode-docker # Wrapper script (recommended for regular use)
├── config/             # Mounted read-only at /app/.config/opencode
│   ├── opencode.json   # MCP servers and plugin config
│   └── skills/         # Custom skills (e.g., frontend-design)
├── secrets/            # Local secrets for development (gitignored)
├── homebase/           # Local home dir for development (gitignored)
├── workspace/          # Local workspace for development (gitignored)
└── superpowers/        # Local superpowers dir for development (gitignored)
```

## Running OpenCode

**Recommended:** Use the wrapper script `bin/opencode-docker`. It:
- Persists data to `~/.opencode-docker/`
- Reads secrets from `~/.opencode-docker/secrets/`
- Uses current directory as workspace

**Development:** `make run` uses local directories (`./homebase`, `./workspace`, `./secrets`).

## Commands

```bash
make build   # Build image with current user's UID/GID
make run     # Run container (development, uses local dirs)
make shell   # Shell into container
make clean   # Remove image
```

## Secrets

Secrets are file-based, not environment variables. For regular use:

```bash
mkdir -p ~/.opencode-docker/secrets
echo "sk-..." > ~/.opencode-docker/secrets/anthropic_api_key
chmod 600 ~/.opencode-docker/secrets/*
```

Entrypoint converts filenames to uppercase env vars: `anthropic_api_key` → `ANTHROPIC_API_KEY`.

## Container environment

- Root filesystem is read-only (`--read-only`)
- `/tmp` is tmpfs with exec permission
- Runs as non-root user (UID/GID from build args)
- Memory: 2GB, CPUs: 2
- Xvfb starts automatically for clipboard support

## Config customization

Edit `config/opencode.json` to add MCP servers or plugins. Config is mounted read-only in container.

Custom skills go in `config/skills/<name>/SKILL.md`.
