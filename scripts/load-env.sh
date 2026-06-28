#!/bin/bash
# Source .env from the project root. Safe to call multiple times.
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/load-env.sh"
LOAD_ENV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$LOAD_ENV_ROOT/.env" ]; then
  set -o allexport
  source "$LOAD_ENV_ROOT/.env"
  set +o allexport
fi
