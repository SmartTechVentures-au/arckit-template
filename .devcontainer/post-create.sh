#!/usr/bin/env bash
set -euo pipefail

echo "Setting up dev environment..."

cd "$WORKSPACE_DIR"

# Persist .env loading into ~/.bashrc so all future shells have the vars
if ! grep -q "Source project .env" ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<BASHRC

# Source project .env if it exists
if [ -f "$WORKSPACE_DIR/.env" ]; then
  set -a
  source "$WORKSPACE_DIR/.env"
  set +a
fi
BASHRC
fi

# Source now for the current post-create session
if [ -f "$WORKSPACE_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$WORKSPACE_DIR/.env"
  set +a
fi

echo "Tuning git..."

git config --global credential.helper store
git config --global core.eol lf
git config --global core.autocrlf input
git config --global --bool push.autoSetupRemote true
git config --global alias.wip '!f() { git add -A && git commit -m "${1:-WIP}" && git push; }; f'
git config --global alias.aliases "config --get-regexp '^alias.'"
git config --global credential.useHttpPath true

if [[ -n "${GIT_USERNAME:-}" ]]; then
  git config --global user.name "$GIT_USERNAME"
fi

if [[ -n "${GIT_EMAIL:-}" ]]; then
  git config --global user.email "$GIT_EMAIL"
fi

echo "Installing Claude CLI..."

if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh
  bash /tmp/claude-install.sh
fi

export PATH="$HOME/.local/bin:$HOME/.claude/local:$PATH"

command -v claude >/dev/null 2>&1 \
  || { echo "ERROR: claude not found after install"; exit 1; }

claude install latest \
  || echo "Warning: claude install latest failed — continuing."

echo "Installing ArcKit Claude plugins..."

claude plugin marketplace add https://github.com/tractorjuice/arc-kit.git \
  || echo "Warning: arckit plugin marketplace add failed — continuing."

# arckit-au installs disabled by default, so install then enable it explicitly.
claude plugin install arckit-au \
  && claude plugin enable arckit-au@arc-kit \
  || echo "Warning: arckit-au plugin install/enable failed — continuing without it."

echo "Dev environment ready."
