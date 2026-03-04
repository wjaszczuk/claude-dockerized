# claude-dockerized

Run Claude Code in a container with your local settings and agents mounted as volumes.

## Prerequisites

- Docker or Podman installed
- Claude Code authenticated on the host (`claude login`)
- SSH agent running with keys loaded (`ssh-add -l` to verify)

## Versioning

The current version is stored in `VERSION`. Build tags the image as both `claude-dockerized:<version>` and `claude-dockerized:latest`. `run.sh` always uses the pinned version from `VERSION`.

To bump the version, edit `VERSION` and rebuild.

## Setup

```bash
./build.sh
```

## Usage

```bash
cd ~/Projects/your-project
~/Projects/claude-dockerized/run.sh
```

The script auto-detects Docker; falls back to Podman if Docker is not available.

Optional convenience symlink:
```bash
ln -s ~/Projects/claude-dockerized/run.sh ~/bin/claude-container
```

## Volumes mounted at runtime

| Host | Container |
|------|-----------|
| `$(pwd)` | `/workspace` |
| `~/.claude` | `/home/node/.claude` |
| `~/.claude.json` | `/home/node/.claude.json` |
| `~/.agents` | `/home/node/.agents` |
| `~/.gitconfig` | `/home/node/.gitconfig` (read-only) |
| `~/.ssh` | `/home/node/.ssh` (read-only) |

## What's inside the image

- `node:24-slim` + git + tmux + openssh-client + gh
- `corepack`
- Claude Code installed via `curl -fsSL https://claude.ai/install.sh | bash`
- Runs as `node` user with `--dangerously-skip-permissions`
