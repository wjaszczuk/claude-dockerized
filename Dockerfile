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

RUN npm install -g @anthropic-ai/claude-code

RUN mkdir -p /root/.claude/skills /root/.claude/plugins

COPY global-settings.json /root/.claude/settings.json
COPY global-CLAUDE.md /root/.claude/CLAUDE.md
COPY skills/ /root/.claude/skills/
COPY plugins/ /root/.claude/plugins/

WORKDIR /workspace
