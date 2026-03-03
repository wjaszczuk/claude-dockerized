#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ANTHROPIC_CLAUDE_CODE_AUTH_KEY:-}" ]]; then
  echo "Error: ANTHROPIC_CLAUDE_CODE_AUTH_KEY is not set."
  echo "Make sure it is exported in your ~/.zshrc from macOS Keychain."
  exit 1
fi

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
  echo "Warning: SSH_AUTH_SOCK is not set. Git over SSH may not work."
fi

podman run -it --rm \
  -v "$(pwd)":/workspace:z \
  -v "$HOME/.gitconfig":/root/.gitconfig:ro,z \
  ${SSH_AUTH_SOCK:+-v "$SSH_AUTH_SOCK":/ssh-agent:z} \
  ${SSH_AUTH_SOCK:+-e SSH_AUTH_SOCK=/ssh-agent} \
  -e ANTHROPIC_CLAUDE_CODE_AUTH_KEY \
  -w /workspace \
  claude-dockerized \
  claude --dangerously-skip-permissions
