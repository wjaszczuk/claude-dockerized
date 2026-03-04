#!/usr/bin/env bash
set -euo pipefail

podman run -it --rm \
  -v "$(pwd)":/workspace:z \
  -v "$HOME/.gitconfig":/root/.gitconfig:ro,z \
  -v "$HOME/.ssh":/home/node/.ssh:ro,z \
  -v "$HOME/.claude":/home/node/.claude:z \
  -v "$HOME/.claude.json":/home/node/.claude.json:z \
  -v "$HOME/.agents":/home/node/.agents:z \
  -w /workspace \
  claude-dockerized \
  claude --dangerously-skip-permissions
