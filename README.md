# ArcKit Workspace Template

A ready-to-use **GitHub template** that spins up a VS Code Dev Container with
[Claude Code](https://claude.com/claude-code) and [ArcKit](https://arckit.org/)
pre-installed.

ArcKit is an AI harness that wraps your AI coding assistant — it gates, traces,
and provenance-stamps everything the assistant produces, generating audit-ready
architecture and governance artifacts.

> Use this repo to start a new ArcKit project in minutes: click **Use this
> template**, open it in a container, and start running ArcKit commands in
> Claude Code.

## What's included

- **Dev Container** (Python 3.12) with Git, Node, `uv`, `ruff`, `pytest`,
  `pylint`, and the [Marp](https://marp.app/) CLI for slide decks.
- **Claude Code** installed and updated to the latest version (ArcKit needs
  `v2.1.172+`).
- **ArcKit plugins** installed from the
  [`tractorjuice/arc-kit`](https://github.com/tractorjuice/arc-kit) marketplace:
  the core `arckit` plugin plus the `arckit-au` (Australian government) overlay.
- A small static **docs server** (`npm run serve` → http://localhost:8080).
- VS Code extensions for Python, Ruff, Copilot, Claude Code, Marp, and Mermaid.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [VS Code](https://code.visualstudio.com/) with the
  [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  extension — **or** [GitHub Codespaces](https://github.com/features/codespaces).
- An **Anthropic API key** (and optionally an OpenAI key).

## Getting started

1. Click **Use this template → Create a new repository**, then clone it.
2. Copy the env template and fill in your values:
   ```bash
   cp .env.example .env
   ```
3. Provide your API keys. They are read from your **host environment** and
   forwarded into the container (see [`devcontainer.json`](.devcontainer/devcontainer.json)).
   Export them before launching VS Code:
   ```bash
   export ANTHROPIC_API_KEY=sk-ant-...
   export OPENAI_API_KEY=sk-...        # optional
   export GIT_USERNAME="Your Name"     # optional
   export GIT_EMAIL="you@example.com"  # optional
   ```
4. Open the folder in VS Code and choose **Reopen in Container**. The
   `post-create` step installs Claude Code and the ArcKit plugins automatically.
5. Start Claude Code and run an ArcKit command:
   ```bash
   claude
   ```
   Then try `/arckit` commands inside the session.

## Useful commands

| Command          | What it does                                         |
| ---------------- | ---------------------------------------------------- |
| `npm run serve`  | Serve the workspace as static docs on port `8080`.   |
| `npm run yolo`   | Launch Claude Code with permission prompts skipped.  |
| `bash scripts/claude.sh` | Manually (re)install Claude Code + ArcKit plugins. |

## Configuration

- **`.env.example`** — copy to `.env`; documents the supported variables.
  `.env` is gitignored and must **never** be committed.
- **`.devcontainer/`** — `Dockerfile`, `devcontainer.json`, and the
  `post-create` / `post-start` scripts.
- **`scripts/`** — helper scripts (static server, env loader, Claude installer).

## Security

This is a template — keep secrets out of it. `.env` is gitignored; only
`.env.example` (with placeholder values) is tracked. Never commit real API keys
or personal access tokens.

## License

[MIT](LICENSE)
