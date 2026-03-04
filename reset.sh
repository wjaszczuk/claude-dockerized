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

echo "Removing named volumes claude-config and claude-agents..."
$RUNTIME volume rm claude-config claude-agents 2>/dev/null || true
echo "Done. Next run.sh will initialize fresh config from the image."