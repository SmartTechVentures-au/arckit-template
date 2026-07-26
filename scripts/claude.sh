#!/usr/bin/env python3
"""
Local development web server (stdlib only).

Serves static files from the  website root by default:
/workspaces/arckit → http://127.0.0.1:8080/

`.py` files get Content-Type: text/x-python; charset=utf-8. Access to `.git/` is denied.

Usage:
  python3 serve.py
  python3 serve.py 0.0.0.0 8080
  python3 serve.py 127.0.0.1 8080 /path/to/root
"""

from __future__ import annotations

import json
import mimetypes
import os
import sys
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent
DEFAULT_SITE_ROOT = REPO_ROOT


class SiteHandler(SimpleHTTPRequestHandler):
    """Static files from site root + JSON probe + .py MIME + block .git/."""

    def __init__(self, *args, serve_root: Path, **kwargs):
        self._serve_root = serve_root.resolve()
        super().__init__(*args, directory=str(serve_root), **kwargs)

    def guess_type(self, path: str) -> str:  # noqa: N802
        """stdlib 3.12+ SimpleHTTPRequestHandler.guess_type returns a single MIME string."""
        if path.lower().endswith(".py"):
            return "text/x-python; charset=utf-8"
        return super().guess_type(path)

    def _forbidden_path(self) -> bool:
        """Disallow serving anything under serve_root/.git/ (common when root = repo)."""
        try:
            fs = Path(self.translate_path(self.path)).resolve()
        except (OSError, ValueError):
            return True
        root = self._serve_root
        try:
            fs.relative_to(root)
        except ValueError:
            return True
        git_dir = root / ".git"
        if git_dir.is_dir():
            try:
                fs.relative_to(git_dir.resolve())
                return True
            except ValueError:
                pass
        return False

    def send_head(self):  # noqa: N802
        if self._forbidden_path():
            self.send_error(HTTPStatus.FORBIDDEN, "Access to this path is not allowed")
            return None
        return super().send_head()

    def do_GET(self) -> None:  # noqa: N802 — http.server API
        parsed = urlparse(self.path)
        if parsed.path == "/api/hello":
            self._send_json(
                {
                    "message": "hello from scripts/serve.py",
                    "serve_root": str(self._serve_root),
                }
            )
            return
        super().do_GET()

    def _send_json(self, payload: object) -> None:
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def _resolve_serve_root() -> Path:
    raw = os.environ.get("SERVE_ROOT") or os.environ.get("DOCS_ROOT")
    if raw:
        return Path(raw).expanduser().resolve()
    if len(sys.argv) >= 4:
        return Path(sys.argv[3]).expanduser().resolve()
    return DEFAULT_SITE_ROOT.resolve()


def main() -> None:
    mimetypes.init()
    mimetypes.add_type("text/x-python", ".py", strict=False)

    serve_root = _resolve_serve_root()
    if not serve_root.is_dir():
        sys.stderr.write(
            "Serve root not found: %s\n"
            "Set SERVE_ROOT or pass a path: python3 serve.py 127.0.0.1 8080 /path\n"
            % serve_root
        )
        sys.exit(1)

    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8080"))
    if len(sys.argv) >= 2:
        host = sys.argv[1]
    if len(sys.argv) >= 3:
        port = int(sys.argv[2])

    handler = partial(SiteHandler, serve_root=serve_root)
    httpd = ThreadingHTTPServer((host, port), handler)

    print(
        "Serving website root %s at http://%s:%s/ (Ctrl+C to stop)"
        % (serve_root, host, port)
    )
    print("  Example: /docs/index.html")
    print("  *.py → text/x-python; .git/ blocked; JSON: /api/hello")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
