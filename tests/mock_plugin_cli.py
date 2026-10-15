#!/usr/bin/env python3
"""CLI fixture used only by provisioning regression tests."""

import json
import os
import sys
from pathlib import Path

state_path = Path(os.environ["ARCKIT_TEST_PLUGIN_STATE"])
state = json.loads(state_path.read_text())
tool = Path(sys.argv[0]).name
args = sys.argv[1:]
if tool == "claude":
    if os.environ.get("ARCKIT_TEST_FAIL_CLAUDE"):
        sys.exit(1)
    if args == ["plugin", "marketplace", "list", "--json"]:
        print(json.dumps([{"name": "arc-kit"}]))
    elif args == ["plugin", "list", "--json"]:
        print(json.dumps([{"id": p, "enabled": True} for p in state["claude"]]))
    elif args[:2] == ["plugin", "install"]:
        state["claude"].append(args[2])
        state["events"].append(f"claude install {args[2]}")
    else:
        sys.exit(f"Unexpected Claude command: {args}")
elif tool == "codex":
    if args == ["plugin", "marketplace", "list", "--json"]:
        print(json.dumps({"marketplaces": [{"name": "arckit"}]}))
    elif args == ["plugin", "list", "--marketplace", "arckit", "--json"]:
        installed = (
            [{"name": "arckit-codex", "installed": True, "enabled": True}]
            if state["codex"]
            else []
        )
        print(json.dumps({"installed": installed, "available": []}))
    elif args == ["plugin", "add", "arckit-codex@arckit"]:
        state["codex"] = True
        state["events"].append("codex add arckit-codex@arckit")
    else:
        sys.exit(f"Unexpected Codex command: {args}")
else:
    sys.exit(f"Unexpected executable: {tool}")
state_path.write_text(json.dumps(state))
