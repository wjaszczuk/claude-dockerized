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

WORKDIR /workspace
