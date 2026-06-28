#!/usr/bin/env bash
# Manual / host install of Claude Code + ArcKit plugins.
# The dev container runs the same steps automatically via
# .devcontainer/post-create.sh — keep the two in sync.
set -euo pipefail

# Install Claude Code and update to latest (ArcKit requires v2.1.172+).
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
claude install latest

# Add the ArcKit marketplace and install the core plugin.
claude plugin marketplace add https://github.com/tractorjuice/arc-kit.git
claude plugin install arckit

# arckit-au ships disabled by default — install then enable it explicitly.
claude plugin install arckit-au
claude plugin enable arckit-au@arc-kit
