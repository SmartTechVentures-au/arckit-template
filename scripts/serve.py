import os
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class DocsHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT_DIR, **kwargs)

    def send_head(self):
        # The workspace contains credentials: reject hidden paths and symlinks
        # escaping the workspace, including URL-encoded requests and HEAD.
        requested = Path(self.translate_path(self.path))
        root = Path(ROOT_DIR).resolve()
        try:
            logical = requested.relative_to(root)
            resolved = requested.resolve().relative_to(root)
        except ValueError:
            self.send_error(403)
            return None
        if any(part.startswith(".") for part in (*logical.parts, *resolved.parts)):
            self.send_error(403)
            return None
        return super().send_head()


if __name__ == "__main__":
    HTTPServer.allow_reuse_address = True
    server = HTTPServer(("", 8080), DocsHandler)
    print("Serving on http://localhost:8080")
    server.serve_forever()
