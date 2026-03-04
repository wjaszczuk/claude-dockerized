# claude-dockerized

Run Claude Code in a container with named Docker volumes for persistent config, skills, and auth.

## Prerequisites

- Docker or Podman installed
- SSH agent running with keys loaded (`ssh-add -l` to verify)

## Setup

```bash
./build.sh
```

## First run

```bash
cd ~/Projects/your-project
~/Projects/claude-dockerized/run.sh
```

On first run the entrypoint automatically:
1. Installs Claude Code into the `claude-local` volume
2. Installs all skills into the `claude-agents` volume
3. Sets up auth symlink so login persists across runs

This takes a few minutes. Subsequent runs start instantly.

Optional convenience symlink:
```bash
ln -s ~/Projects/claude-dockerized/run.sh ~/bin/claude-container
```

## claude-hud plugin

After the first run, install the HUD plugin from inside claude:

```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/claude-hud:setup
```

## Named volumes

| Volume | Container path | Contents |
|--------|---------------|----------|
| `claude-local` | `/home/node/.local` | Claude Code binary |
| `claude-config` | `/home/node/.claude` | Claude config, skills symlinks, auth |
| `claude-agents` | `/home/node/.agents` | Skills (source files) |

Host mounts (read-only):

| Host | Container |
|------|-----------|
| `$(pwd)` | `/workspace` |
| `~/.gitconfig` | `/home/node/.gitconfig` |
| `~/.ssh` | `/home/node/.ssh` |

## Reset

To wipe all volumes and start fresh (re-runs full first-run setup on next launch):

```bash
./reset.sh
```

## Versioning

Version stored in `VERSION`. Build tags the image as `claude-dockerized:<version>` and `claude-dockerized:latest`. To bump: edit `VERSION` and rebuild.

## What's inside the image

- `node:24-slim` + git + tmux + openssh-client + gh
- Runs as `node` user with `--dangerously-skip-permissions`
- Entrypoint handles first-run install + auth persistence + TMPDIR setup