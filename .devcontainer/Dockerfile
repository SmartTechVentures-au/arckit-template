FROM mcr.microsoft.com/devcontainers/python:3.12

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    shellcheck \
    build-essential \
    nodejs \
    npm \
    bubblewrap \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @marp-team/marp-cli @openai/codex

RUN python -m pip install --upgrade pip setuptools wheel uv

# Python tooling used by the workspace (ruff is configured as the formatter
# in devcontainer.json). ArcKit itself is installed at runtime as a Claude
# Code plugin — see .devcontainer/post-create.sh.
RUN uv pip install --system \
      ruff \
      pylint \
      pytest \
      pyyaml \
      requests \
      pydantic \
      click

ENV PATH="/home/vscode/.local/bin:${PATH}"

WORKDIR /workspaces/arckit
