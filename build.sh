#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(cat "$SCRIPT_DIR/VERSION")"

echo "Building image claude-dockerized:$VERSION..."
podman build --memory 4g \
  -t "claude-dockerized:$VERSION" \
  -t "claude-dockerized:latest" \
  "$SCRIPT_DIR"

echo "Done. Launch with: $SCRIPT_DIR/run.sh"
