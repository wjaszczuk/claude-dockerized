#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Syncing CLAUDE.md from $CLAUDE_DIR..."
cp "$CLAUDE_DIR/CLAUDE.md" "$SCRIPT_DIR/global-CLAUDE.md"

echo "Syncing skills from $CLAUDE_DIR/skills/..."
rm -rf "$SCRIPT_DIR/skills"
cp -rL "$CLAUDE_DIR/skills" "$SCRIPT_DIR/skills"

echo "Syncing plugins from $CLAUDE_DIR/plugins/..."
rm -rf "$SCRIPT_DIR/plugins"
cp -rL "$CLAUDE_DIR/plugins" "$SCRIPT_DIR/plugins"

echo "Building image claude-dockerized..."
podman build -t claude-dockerized "$SCRIPT_DIR"

echo ""
echo "Done. Launch with: $SCRIPT_DIR/run.sh"
