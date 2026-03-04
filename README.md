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
3. Writes default `settings.json`
4. Sets up auth symlink so login persists across runs

This takes a few minutes. Subsequent runs start instantly.

Optional convenience symlink:
```bash
ln -s ~/Projects/claude-dockerized/run.sh ~/bin/claude-container
```

## Passing a command

`run.sh` accepts an optional command that overrides the default (`claude --dangerously-skip-permissions`):

```bash
./run.sh bash        # interactive shell
./run.sh claude -p "hello"  # one-shot prompt
```

## Editing settings manually

To edit `~/.claude/settings.json` or other config inside the container:

```bash
./run.sh bash
nano ~/.claude/settings.json
exit
```

Changes persist in the `claude-config` volume.

## claude-hud plugin

After the first run, install the HUD plugin from inside claude:

```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/claude-hud:setup
```

## Named volumes

| Volume | Container path | Contents |
|--------|----------------|----------|
| `claude-local` | `/home/node/.local` | Claude Code binary |
| `claude-config` | `/home/node/.claude` | Claude config, skills symlinks, auth |
| `claude-agents` | `/home/node/.agents` | Skills (source files) |

Host mounts:

| Host | Container | Mode |
|------|-----------|------|
| `$(pwd)` | `/workspace` | rw |
| `~/.gitconfig` | `/home/node/.gitconfig` | ro |
| `~/.ssh` | `/home/node/.ssh` | ro |

## Per-project instances with Docker Compose

By default all projects share the same three volumes (same claude config, skills, auth). If you want isolated instances per project — separate config, separate skills, separate auth — use Docker Compose with project-scoped volume names.

Create a `compose.yml` in your project:

```yaml
services:
  claude:
    image: claude-dockerized:latest
    volumes:
      - ./:/workspace:z
      - ~/.gitconfig:/home/node/.gitconfig:ro,z
      - ~/.ssh:/home/node/.ssh:ro,z
      - claude-local:/home/node/.local:z
      - claude-config:/home/node/.claude:z
      - claude-agents:/home/node/.agents:z
    working_dir: /workspace
    stdin_open: true
    tty: true

volumes:
  claude-local:
  claude-config:
  claude-agents:
```

Run with:
```bash
docker compose run --rm claude
# or with a command:
docker compose run --rm claude bash
```

Docker Compose automatically prefixes volume names with the project name (directory name by default), so each project gets its own `myproject_claude-config` etc. Override the project name with `-p`:

```bash
docker compose -p shared run --rm claude   # share volumes across projects
docker compose -p projectA run --rm claude  # isolated instance for projectA
```

## Reset

Wipe all shared volumes and start fresh (full first-run setup on next launch):

```bash
./reset.sh
```

For per-project volumes created by Compose, remove them with:
```bash
docker compose down --volumes
```

## Versioning

Version stored in `VERSION`. Build tags the image as `claude-dockerized:<version>` and `claude-dockerized:latest`. To bump: edit `VERSION` and rebuild.

## What's inside the image

- `node:24-slim` + git + tmux + openssh-client + curl + nano + gh
- Runs as `node` user with `--dangerously-skip-permissions`
- Entrypoint handles first-run install + auth persistence + TMPDIR setup