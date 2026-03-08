FROM node:24-slim

RUN apt-get update && apt-get install -y \
    git \
    tmux \
    openssh-client \
    curl \
    nano \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get install -y gh \
    && ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in amd64) LH_ARCH="x86_64" ;; arm64) LH_ARCH="arm64" ;; *) LH_ARCH="$ARCH" ;; esac \
    && LH_VERSION=$(curl -fsSL "https://api.github.com/repos/evilmartians/lefthook/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/') \
    && curl -fsSL "https://github.com/evilmartians/lefthook/releases/download/v${LH_VERSION}/lefthook_${LH_VERSION}_Linux_${LH_ARCH}" -o /usr/local/bin/lefthook \
    && chmod +x /usr/local/bin/lefthook \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /workspace && chown node:node /workspace

ENV HOME=/home/node
ENV PATH="/home/node/.local/bin:${PATH}"

USER node

RUN mkdir -p /home/node/.local/bin /home/node/.cache /home/node/.claude /home/node/.agents

COPY --chown=node:node entrypoint.sh /home/node/entrypoint.sh
RUN chmod +x /home/node/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/home/node/entrypoint.sh"]
CMD ["claude", "--dangerously-skip-permissions"]
