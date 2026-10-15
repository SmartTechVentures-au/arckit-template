#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "$WORKSPACE_ROOT"

# .env is injected by Docker before any lifecycle command runs.
bash "$SCRIPT_DIR/configure-git.sh"
bash "$WORKSPACE_ROOT/scripts/git-oh-my-zsh.sh"
bash "$SCRIPT_DIR/verify-tools.sh"
if [[ -f package-lock.json ]]; then
  npm ci
fi
bash "$SCRIPT_DIR/install-plugins.sh" || echo 'WARNING: optional ArcKit plugins incomplete; rerun .devcontainer/install-plugins.sh' >&2
bash "$SCRIPT_DIR/sync-cursor-commands.sh"
echo 'Dev environment ready (Claude, Codex, Cursor Agent).'
