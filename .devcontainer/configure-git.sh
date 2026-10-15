#!/usr/bin/env bash
set -euo pipefail
WORKSPACE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if ! git config --global --get-all safe.directory | grep -Fxq "$WORKSPACE_ROOT"; then
  git config --global --add safe.directory "$WORKSPACE_ROOT"
fi
git config --global core.eol lf
git config --global core.autocrlf input
git config --global --bool push.autoSetupRemote true
git config --global credential.useHttpPath true
# Expand the argument when the alias runs, not during provisioning.
# shellcheck disable=SC2016
git config --global alias.wip '!f() { git add -A && git commit -m "${1:-WIP}" && git push; }; f'
git config --global alias.aliases "config --get-regexp '^alias.'"
[[ -z "${GIT_USERNAME:-}" ]] || git config --global user.name "$GIT_USERNAME"
[[ -z "${GIT_EMAIL:-}" ]] || git config --global user.email "$GIT_EMAIL"
# Retain forwarded credential helpers. gh reads GH_TOKEN/GITHUB_TOKEN without
# writing tokens to a plaintext credential store.
if [[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
  git config --global --replace-all credential.https://github.com.helper ''
  git config --global --add credential.https://github.com.helper '!gh auth git-credential'
fi
