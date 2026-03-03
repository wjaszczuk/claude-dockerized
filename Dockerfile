FROM node:24-slim

RUN apt-get update && apt-get install -y \
    git \
    tmux \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable

RUN npm install -g @anthropic-ai/claude-code

RUN mkdir -p /root/.claude/skills

COPY global-settings.json /root/.claude/settings.json
COPY global-CLAUDE.md /root/.claude/CLAUDE.md
COPY skills/ /root/.claude/skills/

ENV CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

WORKDIR /workspace
