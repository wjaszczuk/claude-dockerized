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

ENV HOME=/home/node
ENV PATH="/home/node/.local/bin:${PATH}"

USER node

RUN curl -fsSL https://claude.ai/install.sh | bash

RUN npx skills add -y https://github.com/vercel-labs/skills --skill find-skills && \
    npx skills add -y https://github.com/vercel-labs/agent-skills \
      --skill vercel-react-best-practices --skill vercel-react-native-skills && \
    npx skills add -y https://github.com/callstackincubator/agent-skills \
      --skill react-native-best-practices && \
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
      --skill finishing-a-development-branch && \
    npx skills add -y https://github.com/jarrodwatts/claude-hud --skill claude-hud

COPY --chown=node:node entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/home/node/entrypoint.sh"]
CMD ["claude", "--dangerously-skip-permissions"]