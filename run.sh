#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(cat "$SCRIPT_DIR/VERSION")"
IMAGE="claude-dockerized:$VERSION"

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
  -v claude-config:/home/node/.claude:z \
  -v claude-agents:/home/node/.agents:z \
  -w /workspace \
  "$IMAGE"
