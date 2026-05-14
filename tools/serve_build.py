from __future__ import annotations

import argparse
import mimetypes
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


MIME_TYPES = {
    ".js": "application/javascript",
    ".mjs": "application/javascript",
    ".wasm": "application/wasm",
    ".json": "application/json",
    ".woff2": "font/woff2",
    ".woff": "font/woff",
    ".ttf": "font/ttf",
}


class FlutterWebHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        **MIME_TYPES,
    }

    def guess_type(self, path: str) -> str:
        suffix = Path(path).suffix.lower()
        if suffix in MIME_TYPES:
            return MIME_TYPES[suffix]
        return super().guess_type(path)

    def end_headers(self) -> None:
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve Flutter Web build with correct MIME types.")
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8082)
    parser.add_argument(
        "--directory",
        default=str(Path(__file__).resolve().parents[1] / "build" / "web"),
    )
    args = parser.parse_args()

    for suffix, mime_type in MIME_TYPES.items():
        mimetypes.add_type(mime_type, suffix)

    server = ThreadingHTTPServer(
        (args.bind, args.port),
        lambda *handler_args: FlutterWebHandler(*handler_args, directory=args.directory),
    )
    print(f"Serving {args.directory} at http://{args.bind}:{args.port}/")
    server.serve_forever()


if __name__ == "__main__":
    main()
