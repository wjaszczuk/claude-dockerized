# Named Volumes Config Design

**Date:** 2026-03-04

## Problem

Current setup mounts `~/.claude`, `~/.claude.json`, and `~/.agents` from the host into the container. Goal: move all config into named Docker volumes, bake base config and skills into the image, remove host dependency for config.

## Requirements

- Config persists between container sessions (named volumes, not anonymous)
- No host directory mounts for config (`.claude`, `.claude.json`, `.agents`)
- Base config (skills + plugins) baked into image at build time
- User can reset to base config via a script
- Pre-installed: all obra/superpowers skills, find-skills, vercel-react-best-practices, vercel-react-native-skills, react-native-best-practices, claude-hud

## Design

### Named Volumes

| Volume | Mount path | Init behavior |
|--------|-----------|---------------|
| `claude-config` | `/home/node/.claude` | Docker auto-initializes from image contents on first use |
| `claude-agents` | `/home/node/.agents` | Starts empty |

Docker's behavior: on first use of a new named volume, if the image has content at the mount path, Docker copies it into the volume. Subsequent runs use the volume's own content.

### Dockerfile Changes

Install all skills/plugins during build as `node` user — they land in `/home/node/.claude/`.

```dockerfile
USER node
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/node/.local/bin:${PATH}"

RUN npx skills add https://github.com/vercel-labs/skills --skill find-skills && \
    npx skills add https://github.com/vercel-labs/agent-skills \
      --skill vercel-react-best-practices,vercel-react-native-skills && \
    npx skills add https://github.com/callstackincubator/agent-skills \
      --skill react-native-best-practices && \
    npx skills add https://github.com/obra/superpowers \
      --skill brainstorming,systematic-debugging,writing-plans,test-driven-development,\
executing-plans,requesting-code-review,using-superpowers,subagent-driven-development,\
receiving-code-review,verification-before-completion,using-git-worktrees,\
writing-skills,dispatching-parallel-agents,finishing-a-development-branch && \
    npx skills add https://github.com/jarrodwatts/claude-hud --skill claude-hud

COPY --chown=node:node entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/home/node/entrypoint.sh"]
CMD ["claude", "--dangerously-skip-permissions"]
```

### entrypoint.sh

Handles `.claude.json` auth file persistence inside the `claude-config` volume:

```bash
#!/bin/bash
set -euo pipefail

# Move .claude.json into volume if claude created it as a real file
if [ -f ~/.claude.json ] && [ ! -L ~/.claude.json ]; then
  mv ~/.claude.json ~/.claude/_auth.json
fi

# Create symlink so claude finds auth at expected location
if [ -f ~/.claude/_auth.json ] && [ ! -L ~/.claude.json ]; then
  ln -sf ~/.claude/_auth.json ~/.claude.json
fi

exec "$@"
```

### run.sh Changes

Remove host mounts for config, add named volume mounts:

```bash
$RUNTIME run -it --rm \
  -v "$(pwd)":/workspace:z \
  -v "$HOME/.gitconfig":/home/node/.gitconfig:ro,z \
  -v "$HOME/.ssh":/home/node/.ssh:ro,z \
  -v claude-config:/home/node/.claude:z \
  -v claude-agents:/home/node/.agents:z \
  -w /workspace \
  "$IMAGE"
```

### reset.sh (new)

Deletes named volumes so next `run.sh` re-initializes from image base config:

```bash
#!/usr/bin/env bash
set -euo pipefail
if command -v docker &>/dev/null; then RUNTIME=docker
elif command -v podman &>/dev/null; then RUNTIME=podman
else echo "Error: neither docker nor podman found" >&2; exit 1; fi

$RUNTIME volume rm claude-config claude-agents 2>/dev/null || true
echo "Config reset. Next run will initialize fresh from image."
```

## Lifecycle

```
build.sh        → skills/plugins installed in image at /home/node/.claude/
first run.sh    → Docker creates claude-config, copies image's /home/node/.claude/ into it
                  entrypoint runs, claude starts (requires login on first use)
subsequent runs → same claude-config volume, changes persist
reset.sh        → volumes deleted, next run starts fresh from image (requires re-login)
```

## Notes

- Updating base skills in image does NOT affect existing volumes (by design — user changes preserved)
- To pick up new base skills on existing volume: install manually or run `reset.sh`
- claude-hud still requires `/claude-hud:setup` on first run to configure the statusline