#!/bin/bash
set -e

# Load secrets from /run/secrets into environment variables
# Each file in /run/secrets becomes an environment variable
# with the filename as the variable name (uppercase) and file contents as value
SECRETS_DIR="/run/secrets"

if [ -d "$SECRETS_DIR" ]; then
    for secret_file in "$SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            secret_name=$(basename "$secret_file")
            # Convert to uppercase and replace dashes/dots with underscores
            var_name=$(echo "$secret_name" | tr '[:lower:]' '[:upper:]' | tr -- '-.' '__')
            # Read the secret value (trim trailing newline)
            secret_value=$(cat "$secret_file" | tr -d '\n')
            export "$var_name"="$secret_value"
        fi
    done
fi

# Start Xvfb for clipboard support
Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &

# Execute the main command
exec opencode "$@"
