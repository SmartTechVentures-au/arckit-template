FROM node:22.22.0-bookworm-slim AS node
FROM mcr.microsoft.com/devcontainers/python:3.13-bookworm

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root

# One Node installation, shared by image tools and all container shells.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq build-essential bubblewrap graphviz \
      shellcheck ripgrep zsh \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb -o /tmp/install-azure.sh \
    && bash /tmp/install-azure.sh \
    && rm /tmp/install-azure.sh \
    && rm -rf /var/lib/apt/lists/*

ARG UV_VERSION=0.13.1
ARG RUFF_VERSION=0.17.0
RUN python -m pip install --no-cache-dir "uv==${UV_VERSION}" \
    && uv pip install --system "ruff==${RUFF_VERSION}" \
      pylint pytest pyyaml requests pydantic click data-flow-diagram

ARG CODEX_VERSION=0.162.1
ARG MARP_VERSION=4.5.1
ARG MARKDOWNLINT_VERSION=0.23.3
RUN npm install --global "@openai/codex@${CODEX_VERSION}" \
      "@marp-team/marp-cli@${MARP_VERSION}" "markdownlint-cli2@${MARKDOWNLINT_VERSION}"

ENV PATH="/home/vscode/.local/bin:/home/vscode/.npm-global/bin:${PATH}"
ENV UV_LINK_MODE=copy
USER vscode
RUN mkdir -p "$HOME/.npm-global" && npm config set prefix "$HOME/.npm-global"

ARG CLAUDE_VERSION=2.1.300
RUN curl -fsSL https://claude.ai/install.sh -o /tmp/install-claude.sh \
    && bash /tmp/install-claude.sh "${CLAUDE_VERSION}" \
    && rm /tmp/install-claude.sh \
    && claude --version

# Versioned archive and layout from the official cursor.com/install script.
ARG CURSOR_VERSION=2026.10.14-941492e
RUN case "$(uname -m)" in \
      x86_64) cursor_arch=x64 ;; aarch64) cursor_arch=arm64 ;; \
      *) echo 'Unsupported Cursor architecture' >&2; exit 1 ;; esac \
    && cursor_dir="$HOME/.local/share/cursor-agent/versions/${CURSOR_VERSION}" \
    && mkdir -p "$cursor_dir" "$HOME/.local/bin" \
    && curl -fsSL "https://downloads.cursor.com/lab/${CURSOR_VERSION}/linux/${cursor_arch}/agent-cli-package.tar.gz" \
         -o /tmp/cursor-agent.tar.gz \
    && tar --strip-components=1 -xzf /tmp/cursor-agent.tar.gz -C "$cursor_dir" \
    && rm /tmp/cursor-agent.tar.gz \
    && ln -s "$cursor_dir/cursor-agent" "$HOME/.local/bin/agent" \
    && ln -s "$cursor_dir/cursor-agent" "$HOME/.local/bin/cursor-agent" \
    && agent --version

# Login Bash resets PATH in /etc/profile; restore the user-owned tool paths too.
USER root
RUN printf '%s\n' 'export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"' \
      > /etc/profile.d/arckit-path.sh
USER vscode

# Missing or broken required CLIs fail the image build, independently of IDEs.
RUN claude --version && codex --version && agent --version
