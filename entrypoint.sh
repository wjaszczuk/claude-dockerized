#!/bin/bash
set -euo pipefail

# If claude wrote .claude.json as a real file, move it into the volume
if [ -f ~/.claude.json ] && [ ! -L ~/.claude.json ]; then
  mv ~/.claude.json ~/.claude/_auth.json
fi

# Symlink .claude.json → inside the volume so auth persists
if [ -f ~/.claude/_auth.json ] && [ ! -L ~/.claude.json ]; then
  ln -sf ~/.claude/_auth.json ~/.claude.json
fi

exec "$@"