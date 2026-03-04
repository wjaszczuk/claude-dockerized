#!/usr/bin/env bash
set -euo pipefail

if command -v docker &>/dev/null; then
  RUNTIME=docker
elif command -v podman &>/dev/null; then
  RUNTIME=podman
else
  echo "Error: neither docker nor podman found" >&2
  exit 1
fi

$RUNTIME run -it --rm \
  -v "$(pwd)":/workspace:z \
  -v "$HOME/.gitconfig":/home/node/.gitconfig:ro,z \
  -v "$HOME/.ssh":/home/node/.ssh:ro,z \
  -v "$HOME/.claude":/home/node/.claude:z \
  -v "$HOME/.claude.json":/home/node/.claude.json:z \
  -v "$HOME/.agents":/home/node/.agents:z \
  -w /workspace \
  claude-dockerized
