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

RUN mkdir -p /home/node/.claude/skills /home/node/.claude/plugins /workspace \
    && chown -R node:node /home/node/.claude /workspace

COPY --chown=node:node global-settings.json /home/node/.claude/settings.json
COPY --chown=node:node global-CLAUDE.md /home/node/.claude/CLAUDE.md
COPY --chown=node:node skills/ /home/node/.claude/skills/
COPY --chown=node:node plugins/ /home/node/.claude/plugins/

USER node
WORKDIR /workspace
