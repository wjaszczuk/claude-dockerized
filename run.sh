#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ANTHROPIC_CLAUDE_CODE_AUTH_KEY:-}" ]]; then
  echo "Error: ANTHROPIC_CLAUDE_CODE_AUTH_KEY is not set."
  echo "Make sure it is exported in your ~/.zshrc from macOS Keychain."
  exit 1
fi

podman run -it --rm \
  -v "$(pwd)":/workspace:z \
  -v "$HOME/.gitconfig":/root/.gitconfig:ro,z \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_CLAUDE_CODE_AUTH_KEY" \
  -w /workspace \
  claude-dockerized \
  claude --dangerously-skip-permissions
