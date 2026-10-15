#!/usr/bin/env bash
set -euo pipefail
for tool in claude codex agent; do
  command -v "$tool" >/dev/null || { echo "ERROR: $tool missing; rebuild the container" >&2; exit 1; }
  "$tool" --version
done
