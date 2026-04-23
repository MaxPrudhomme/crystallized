#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class EchoHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(content_length)
        print(f"POST {self.path}")
        print(body.decode("utf-8", errors="replace"))

        content_type = self.headers.get("Content-Type", "application/octet-stream")
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        print(f"{self.client_address[0]} - {format % args}")


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8787), EchoHandler)
    print("Echo server listening on http://127.0.0.1:8787/echo")
    server.serve_forever()
