import os
from http.server import HTTPServer, SimpleHTTPRequestHandler

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class DocsHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT_DIR, **kwargs)

if __name__ == "__main__":
    HTTPServer.allow_reuse_address = True
    server = HTTPServer(("", 8080), DocsHandler)
    print("Serving on http://localhost:8080")
    server.serve_forever()
