FROM mcr.microsoft.com/devcontainers/python:3.12

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    build-essential \
    nodejs \
    npm \
    bubblewrap \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI + Azure CLI as image layers. These were devcontainer features,
# which re-ran on every image build; as layers they cache until this file changes.
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @marp-team/marp-cli

RUN python -m pip install --upgrade pip setuptools wheel uv

RUN uv pip install --system \
      black \
      pylint \
      pytest \
      pyyaml \
      requests \
      pydantic \
      click \
      data-flow-diagram

RUN git config --system --add safe.directory /workspaces/arckit

ENV PATH="/home/vscode/.local/bin:${PATH}"

# Claude CLI + ArcKit plugins baked in as the vscode user (was in
# post-create.sh, re-downloaded on every container create). Plugin installs
# are tolerant so a marketplace hiccup doesn't fail the whole build.
USER vscode
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && export PATH="$HOME/.local/bin:$HOME/.claude/local:$PATH" \
    && command -v claude >/dev/null \
    && { claude plugin marketplace add https://github.com/tractorjuice/arc-kit.git \
           && claude plugin install arckit \
           && claude plugin install arckit-au \
           && claude plugin enable arckit-au@arc-kit \
           || echo "Warning: ArcKit plugin setup incomplete - rerun in container."; }

USER root
WORKDIR /workspaces/arckit
