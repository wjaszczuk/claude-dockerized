# claude-dockerized

Run Claude Code in a Podman container with agent teams enabled.

## Prerequisites

- Podman installed
- `ANTHROPIC_API_KEY` in macOS Keychain, exported in `~/.zshrc`:
  ```bash
  export ANTHROPIC_API_KEY="$(security find-generic-password -s anthropic-api-key -a $USER -w)"
  ```
- SSH agent running with your keys loaded (`ssh-add -l` to verify)

## Setup

```bash
./build.sh
```

Run again when `~/.claude/CLAUDE.md` or `~/.claude/skills/` change.

## Usage

```bash
cd ~/Projects/your-project
~/Projects/claude-dockerized/run.sh
```

Optional convenience symlink:
```bash
ln -s ~/Projects/claude-dockerized/run.sh ~/bin/claude-container
```

## What's inside the image

- `node:24-slim` + git + tmux + openssh-client
- `corepack` (yarn 4 support)
- `@anthropic-ai/claude-code` (global)
- Your `~/.claude/CLAUDE.md` and `~/.claude/skills/` (baked in at build time)
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `dangerouslySkipPermissions: true`
- `teammateMode: "tmux"`
