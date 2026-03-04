#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Building image claude-dockerized..."
podman build -t claude-dockerized "$SCRIPT_DIR"

echo "Done. Launch with: $SCRIPT_DIR/run.sh"
