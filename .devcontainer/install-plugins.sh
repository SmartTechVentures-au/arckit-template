#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
failed=0

install_claude_plugins() {
  local listing plugin
  if ! claude plugin marketplace list --json | jq -e 'any(.[]; .name == "arc-kit")' >/dev/null; then
    claude plugin marketplace add https://github.com/tractorjuice/arc-kit.git || return 1
  fi
  for plugin in arckit@arc-kit arckit-au@arc-kit; do
    listing="$(claude plugin list --json)" || return 1
    if ! jq -e --arg id "$plugin" 'any(.[]; .id == $id)' <<< "$listing" >/dev/null; then
      claude plugin install "$plugin" || return 1
      listing="$(claude plugin list --json)" || return 1
    fi
    if ! jq -e --arg id "$plugin" 'any(.[]; .id == $id and .enabled)' <<< "$listing" >/dev/null; then
      claude plugin enable "$plugin" || return 1
    fi
  done
}

install_codex_plugins() {
  # The repository is arckit-codex, but its marketplace name is arckit.
  if ! codex plugin marketplace list --json | jq -e 'any(.marketplaces[]; .name == "arckit")' >/dev/null; then
    codex plugin marketplace add https://github.com/tractorjuice/arckit-codex.git || return 1
  fi
  if ! codex plugin list --marketplace arckit --json | jq -e \
    'any(.installed[]; .name == "arckit-codex" and .installed and .enabled)' >/dev/null; then
    codex plugin add arckit-codex@arckit || return 1
  fi
}

install_claude_plugins || { echo 'WARNING: Claude ArcKit plugins incomplete' >&2; failed=1; }
install_codex_plugins || { echo 'WARNING: Codex ArcKit plugin incomplete' >&2; failed=1; }
bash "$SCRIPT_DIR/sync-cursor-commands.sh"
exit "$failed"
