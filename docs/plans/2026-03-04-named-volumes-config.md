# Named Volumes Config Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace host directory mounts for Claude config with named Docker volumes, baking base skills and plugins into the image.

**Architecture:** Skills are installed into `/home/node/.claude/` during Docker build. Named volumes `claude-config` and `claude-agents` are mounted at runtime — Docker auto-initializes `claude-config` from the image on first use. An entrypoint script handles persisting `.claude.json` (auth file) by symlinking it to a file inside the `claude-config` volume.

**Tech Stack:** Docker/Podman named volumes, bash entrypoint, `npx skills add` CLI, node:24-slim base image.

---

### Task 1: Add entrypoint.sh

**Files:**
- Create: `entrypoint.sh`

**Step 1: Create the file**

```bash
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
```

**Step 2: Make it executable**

```bash
chmod +x entrypoint.sh
```

**Step 3: Verify**

```bash
head -1 entrypoint.sh
# Expected: #!/bin/bash
ls -la entrypoint.sh | grep -c '\-rwx'
# Expected: 1
```

**Step 4: Commit**

```bash
git add entrypoint.sh
git commit -m "feat: add entrypoint script for auth file persistence"
```

---

### Task 2: Update Dockerfile — install skills and wire entrypoint

**Files:**
- Modify: `Dockerfile`

**Step 1: Replace Dockerfile contents**

Replace the entire `Dockerfile` with:

```dockerfile
FROM node:24-slim

RUN apt-get update && apt-get install -y \
    git \
    tmux \
    openssh-client \
    curl \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

RUN mkdir -p /workspace && chown node:node /workspace

USER node

RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/node/.local/bin:${PATH}"

RUN npx skills add https://github.com/vercel-labs/skills --skill find-skills && \
    npx skills add https://github.com/vercel-labs/agent-skills \
      --skill vercel-react-best-practices,vercel-react-native-skills && \
    npx skills add https://github.com/callstackincubator/agent-skills \
      --skill react-native-best-practices && \
    npx skills add https://github.com/obra/superpowers \
      --skill brainstorming,systematic-debugging,writing-plans,test-driven-development,executing-plans,requesting-code-review,using-superpowers,subagent-driven-development,receiving-code-review,verification-before-completion,using-git-worktrees,writing-skills,dispatching-parallel-agents,finishing-a-development-branch && \
    npx skills add https://github.com/jarrodwatts/claude-hud --skill claude-hud

COPY --chown=node:node entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/home/node/entrypoint.sh"]
CMD ["claude", "--dangerously-skip-permissions"]
```

**Step 2: Verify diff**

```bash
git diff Dockerfile
# Should show: added RUN npx skills add ..., added COPY entrypoint.sh,
#              added ENTRYPOINT line, CMD unchanged
```

**Step 3: Commit**

```bash
git add Dockerfile
git commit -m "feat: install skills/plugins in image and wire entrypoint"
```

---

### Task 3: Update run.sh — named volumes instead of host mounts

**Files:**
- Modify: `run.sh`

**Step 1: Replace the `$RUNTIME run` block**

Change lines 17-25 from:

```bash
$RUNTIME run -it --rm \
  -v "$(pwd)":/workspace:z \
  -v "$HOME/.gitconfig":/home/node/.gitconfig:ro,z \
  -v "$HOME/.ssh":/home/node/.ssh:ro,z \
  -v "$HOME/.claude":/home/node/.claude:z \
  -v "$HOME/.claude.json":/home/node/.claude.json:z \
  -v "$HOME/.agents":/home/node/.agents:z \
  -w /workspace \
  "$IMAGE"
```

to:

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

**Step 2: Verify no host config mounts remain**

```bash
grep -c 'HOME.*\.claude\|HOME.*\.agents' run.sh
# Expected: 0
grep 'claude-config\|claude-agents' run.sh
# Expected: two lines with named volume mounts
```

**Step 3: Commit**

```bash
git add run.sh
git commit -m "feat: replace host config mounts with named volumes in run.sh"
```

---

### Task 4: Create reset.sh

**Files:**
- Create: `reset.sh`

**Step 1: Create the file**

```bash
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
```

**Step 2: Make it executable**

```bash
chmod +x reset.sh
```

**Step 3: Commit**

```bash
git add reset.sh
git commit -m "feat: add reset.sh to remove named volumes and restore base config"
```

---

### Task 5: Build and smoke-test

**Step 1: Build the image**

```bash
./build.sh
# Expected: build completes, skills install steps visible in output, no errors
```

**Step 2: Verify skills are present in image**

```bash
# Check that skill files exist inside the image
podman run --rm claude-dockerized:latest ls /home/node/.claude/skills/
# Expected: directory listing with find-skills, vercel-react-best-practices, etc.
```

**Step 3: First run — verify volume init**

```bash
./run.sh
# In the container:
ls ~/.claude/skills/
# Expected: skill directories present (copied from image into new volume)
exit
```

**Step 4: Verify named volumes were created**

```bash
podman volume ls | grep claude
# Expected:
# local  claude-config
# local  claude-agents
```

**Step 5: Second run — verify persistence**

```bash
./run.sh
# In the container, create a test file:
touch ~/.claude/test-persistence
exit

./run.sh
# In the container, check it's still there:
ls ~/.claude/test-persistence
# Expected: file exists
exit
```

**Step 6: Test reset.sh**

```bash
./reset.sh
# Expected: "Done. Next run.sh will initialize fresh config from the image."
podman volume ls | grep claude
# Expected: no claude-config or claude-agents volumes listed

./run.sh
# In the container:
ls ~/.claude/skills/
# Expected: skills are back (re-initialized from image)
# Check test file is gone:
ls ~/.claude/test-persistence 2>/dev/null || echo "gone"
# Expected: gone
exit
```

**Step 7: Commit**

```bash
# No code changes in this task — just verification
# If any fixes were needed during testing, commit them here
git add -A
git commit -m "fix: address any issues found during smoke testing" 2>/dev/null || echo "nothing to commit"
```