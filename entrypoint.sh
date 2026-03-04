#!/bin/bash
set -euo pipefail

# Enable corepack shims for this user
mkdir -p ~/.local/bin
corepack enable --install-directory ~/.local/bin 2>/dev/null || true

# Install claude on first run
if [ ! -f ~/.local/bin/claude ]; then
  echo "First run: installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  echo "Claude Code installed."
fi

# Install skills on first run (cd ~ so skills go to ~/.agents not ./agents)
if [ ! -f ~/.claude/.skills-installed ]; then
  echo "First run: installing skills..."
  cd ~
  npx skills add -y https://github.com/vercel-labs/skills --skill find-skills
  npx skills add -y https://github.com/vercel-labs/agent-skills \
    --skill vercel-react-best-practices --skill vercel-react-native-skills
  npx skills add -y https://github.com/callstackincubator/agent-skills \
    --skill react-native-best-practices
  npx skills add -y https://github.com/obra/superpowers \
    --skill brainstorming \
    --skill systematic-debugging \
    --skill writing-plans \
    --skill test-driven-development \
    --skill executing-plans \
    --skill requesting-code-review \
    --skill using-superpowers \
    --skill subagent-driven-development \
    --skill receiving-code-review \
    --skill verification-before-completion \
    --skill using-git-worktrees \
    --skill writing-skills \
    --skill dispatching-parallel-agents \
    --skill finishing-a-development-branch
  touch ~/.claude/.skills-installed
  echo "Skills installed."
fi

# Write default settings if not present
if [ ! -f ~/.claude/settings.json ]; then
  mkdir -p ~/.claude
  cat > ~/.claude/settings.json <<'EOF'
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "0",
    "OTEL_METRICS_EXPORTER": "otlp",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "effortLevel": "medium",
  "skipDangerousModePermissionPrompt": true
}
EOF
fi

# If claude wrote .claude.json as a real file, move it into the volume
if [ -f ~/.claude.json ] && [ ! -L ~/.claude.json ]; then
  mv ~/.claude.json ~/.claude/_auth.json
fi

# Symlink .claude.json → inside the volume so auth persists
if [ -f ~/.claude/_auth.json ] && [ ! -L ~/.claude.json ]; then
  ln -sf ~/.claude/_auth.json ~/.claude.json
fi

mkdir -p ~/.cache/tmp
export TMPDIR=~/.cache/tmp

exec "$@"