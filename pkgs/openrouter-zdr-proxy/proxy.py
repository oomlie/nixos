import argparse
import hmac
import http.server
import json
import os
import urllib.error
import urllib.parse
import urllib.request


UPSTREAM = "https://openrouter.ai/api/v1"
ZDR_ENDPOINTS = {"/v1/chat/completions", "/v1/responses"}
HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
}


def authorized(header, expected):
    prefix = "Bearer "
    return bool(
        expected
        and header.startswith(prefix)
        and hmac.compare_digest(header[len(prefix) :], expected)
    )


def enforce_zdr(payload):
    if not isinstance(payload, dict):
        raise ValueError("JSON request body must be an object")
    provider = payload.setdefault("provider", {})
    if not isinstance(provider, dict):
        raise ValueError("provider must be an object")
    provider["zdr"] = True
    provider["data_collection"] = "deny"
    return payload


def request_path(target):
    return urllib.parse.urlsplit(target).path


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "openrouter-zdr-proxy/1"

    def authenticate(self):
        if authorized(
            self.headers.get("Authorization", ""),
            os.environ.get("OPENROUTER_PROXY_KEY", ""),
        ):
            return True
        self.send_error(401, "unauthorized")
        return False

    def upstream_url(self):
        if not self.path.startswith("/v1/"):
            raise ValueError("only /v1 endpoints are supported")
        return UPSTREAM + self.path[3:]

    def forward(self, body=None):
        if not self.authenticate():
            return
        try:
            url = self.upstream_url()
        except ValueError as exc:
            self.send_error(404, str(exc))
            return

        headers = {
            "Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}",
            "Accept": self.headers.get("Accept", "application/json"),
            "HTTP-Referer": "https://chat.daze.lol",
            "X-Title": "daze chat",
        }
        if body is not None:
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(
            url,
            data=body,
            headers=headers,
            method=self.command,
        )
        try:
            response = urllib.request.urlopen(request, timeout=3600)
        except urllib.error.HTTPError as exc:
            response = exc
        except urllib.error.URLError:
            self.send_error(502, "OpenRouter unavailable")
            return

        self.send_response(response.status or 502)
        for name, value in response.headers.items():
            if name.lower() not in HOP_HEADERS:
                self.send_header(name, value)
        self.send_header("Connection", "close")
        self.end_headers()
        while chunk := response.read(65536):
            self.wfile.write(chunk)
            self.wfile.flush()
        self.close_connection = True

    def do_GET(self):
        self.forward()

    def do_POST(self):
        if request_path(self.path) not in ZDR_ENDPOINTS:
            self.send_error(404, "unsupported inference endpoint")
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if not 0 < length <= 20 * 1024 * 1024:
            self.send_error(413, "invalid request size")
            return
        try:
            payload = json.loads(self.rfile.read(length))
            enforce_zdr(payload)
            body = json.dumps(payload, separators=(",", ":")).encode()
        except (ValueError, json.JSONDecodeError) as exc:
            self.send_error(400, str(exc))
            return
        self.forward(body)

    def log_message(self, format, *args):
        print(f"{self.address_string()} {format % args}", flush=True)


def self_test(_args):
    payload = enforce_zdr({"model": "example/model", "messages": []})
    assert payload["provider"] == {"zdr": True, "data_collection": "deny"}
    payload = enforce_zdr({"provider": {"sort": "latency"}})
    assert payload["provider"] == {
        "sort": "latency",
        "zdr": True,
        "data_collection": "deny",
    }
    assert authorized("Bearer internal-key", "internal-key")
    assert not authorized("Bearer wrong", "internal-key")
    assert request_path("/v1/chat/completions?trace=1") in ZDR_ENDPOINTS
    assert request_path("/v1/embeddings") not in ZDR_ENDPOINTS
    print("OpenRouter ZDR proxy self-test passed")


def serve(args):
    for name in ("OPENROUTER_API_KEY", "OPENROUTER_PROXY_KEY"):
        if not os.environ.get(name):
            raise SystemExit(f"{name} is required")
    http.server.ThreadingHTTPServer((args.host, args.port), Handler).serve_forever()


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(required=True)
    serve_parser = subparsers.add_parser("serve")
    serve_parser.add_argument("--host", default="127.0.0.1")
    serve_parser.add_argument("--port", type=int, default=8318)
    serve_parser.set_defaults(func=serve)
    test_parser = subparsers.add_parser("self-test")
    test_parser.set_defaults(func=self_test)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
