FROM mcr.microsoft.com/devcontainers/python:3.12

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    build-essential \
    nodejs \
    npm \
    docker.io \
    bubblewrap \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @marp-team/marp-cli

RUN python -m pip install --upgrade pip setuptools wheel uv

# Pin ArcKit to an immutable commit for reproducible builds.
RUN uv pip install --system \
      black \
      pylint \
      pytest \
      pyyaml \
      requests \
      pydantic \
      click \
      data-flow-diagram

ENV PATH="/home/vscode/.local/bin:${PATH}"

WORKDIR /workspaces/chorus