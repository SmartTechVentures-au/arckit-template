#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/configure-git.sh"
bash "$SCRIPT_DIR/verify-tools.sh"
bash "$SCRIPT_DIR/sync-cursor-commands.sh"
